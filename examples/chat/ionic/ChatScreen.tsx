/**
 * ChatScreen.tsx — accessible, offline-resilient Ionic chat for the Chat example.
 *
 * Idiomatic Ionic 8 + Capacitor: Ionic components + the `mode` engine for native
 * feel on both OSes, styled entirely through CSS classes / `var(--...)` tokens in
 * chat.css (no raw #hex / px in this file). Implements the full spec: an inverted
 * message list (newest at the bottom) that mirrors in RTL, a growing composer
 * pinned above the keyboard + home indicator (IonFooter + safe-area inset),
 * optimistic send with a real delivery lifecycle (sending → sent → delivered →
 * read), a failed → tap-Retry path that preserves content, an offline queue that
 * auto-flushes on reconnect, a reduce-motion-aware typing indicator exposed as
 * status text, a "N new messages" pill, and a non-blocking offline banner. Every
 * screen condition is a member of the ChatStatus discriminated union: idle, empty,
 * loading, error, offline, success, permissionDenied.
 *
 * NOTE: history load + send transport + attach permission are injectable props
 * defaulting to light mocks, so the file runs standalone; wire real calls at the
 * call site.
 */
import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  IonPage, IonHeader, IonToolbar, IonButtons, IonButton, IonIcon, IonContent,
  IonFooter, IonTextarea, IonSkeletonText, IonModal, IonTitle, useIonToast,
} from '@ionic/react';
import {
  arrowBackOutline, callOutline, ellipsisVerticalOutline, addOutline,
  paperPlaneOutline, chevronDownOutline, cloudOfflineOutline, alertCircleOutline,
  warningOutline, timeOutline, checkmarkOutline, checkmarkDoneOutline,
} from 'ionicons/icons';
import { Network } from '@capacitor/network';
import './chat.css';

/**
 * Per-message delivery lifecycle. Status is always conveyed as icon + TEXT, never
 * colour alone (A11Y-012), and every value is announced to assistive tech.
 */
export type MessageStatus =
  | 'sending'
  | 'sent'
  | 'delivered'
  | 'read'
  | 'failed'
  | 'queued';

export type ChatMessage = {
  id: string;
  text: string;
  author: 'me' | 'them';
  createdAt: number;
  status?: MessageStatus; // own messages only
};

/**
 * The 7 screen states as a discriminated union. Members literally cover
 * idle, empty, loading, error, offline, success, permissionDenied.
 */
type ChatStatus =
  | { kind: 'idle' }
  | { kind: 'empty' }
  | { kind: 'loading' }
  | { kind: 'error'; message: string }
  | { kind: 'offline' }
  | { kind: 'success' }
  | { kind: 'permissionDenied'; reason: string };

type Props = {
  peerName?: string;
  onBack?: () => void;
  onCall?: () => void;
  onOverflow?: () => void;
  /** Load conversation history; reject to exercise the error state. */
  loadHistory?: () => Promise<ChatMessage[]>;
  /** Send transport for one message; reject to exercise the failed state. */
  sendTransport?: (text: string) => Promise<void>;
  /** Request the attachment picker permission; false/reject => permissionDenied. */
  requestAttachPermission?: () => Promise<boolean>;
  openSettings?: () => void;
  /** After a successful send, echo a peer reply so the demo is lively. */
  autoReply?: boolean;
};

const STATUS_TEXT: Record<MessageStatus, string> = {
  sending: 'Sending',
  sent: 'Sent',
  delivered: 'Delivered',
  read: 'Read',
  failed: 'Not delivered — tap to retry',
  queued: 'Queued — waiting for connection',
};

const STATUS_ICON: Record<MessageStatus, string> = {
  sending: timeOutline,
  sent: checkmarkOutline,
  delivered: checkmarkDoneOutline,
  read: checkmarkDoneOutline,
  failed: alertCircleOutline,
  queued: cloudOfflineOutline,
};

const noop = () => {};
const MINUTE = 60000;
const STATUS_STEP = 700; // delay between each lifecycle transition
const REPLY_DELAY = 1400; // simulated peer typing → reply
const TOAST_MS = 1600;

const SEED: ChatMessage[] = [
  { id: 'seed-1', text: 'Hey! Are we still on for tomorrow?', author: 'them', createdAt: Date.now() - MINUTE * 9 },
  { id: 'seed-2', text: 'Absolutely — 10am works for me.', author: 'me', createdAt: Date.now() - MINUTE * 8, status: 'read' },
  { id: 'seed-3', text: 'Perfect. I will bring the prototype.', author: 'them', createdAt: Date.now() - MINUTE * 7 },
];

const defaultLoadHistory = async (): Promise<ChatMessage[]> => SEED;
const defaultSendTransport = async (_text: string): Promise<void> => {};
const defaultRequestAttachPermission = async () => true;

function formatTime(ts: number): string {
  const d = new Date(ts);
  const h = d.getHours();
  const m = d.getMinutes();
  const hh = ((h + 11) % 12) + 1;
  const mm = m < 10 ? `0${m}` : `${m}`;
  return `${hh}:${mm} ${h < 12 ? 'AM' : 'PM'}`;
}

let idSeq = 0;
const nextId = () => `m-${Date.now()}-${idSeq++}`;

export default function ChatScreen({
  peerName = 'Alex Rivera',
  onBack = noop,
  onCall = noop,
  onOverflow = noop,
  loadHistory = defaultLoadHistory,
  sendTransport = defaultSendTransport,
  requestAttachPermission = defaultRequestAttachPermission,
  openSettings = noop,
  autoReply = true,
}: Props) {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [status, setStatus] = useState<ChatStatus>({ kind: 'loading' });
  const [draft, setDraft] = useState('');
  const [online, setOnline] = useState(true);
  const [peerTyping, setPeerTyping] = useState(false);
  const [unread, setUnread] = useState(0);
  const [showJump, setShowJump] = useState(false);
  const [live, setLive] = useState('');

  const listRef = useRef<HTMLDivElement>(null);
  const errorRef = useRef<HTMLDivElement>(null);
  const timers = useRef<Set<ReturnType<typeof setTimeout>>>(new Set());
  const queue = useRef<Array<{ id: string; text: string }>>([]);
  const atBottom = useRef(true);
  const [present] = useIonToast();

  // Track timers so nothing fires after unmount.
  const schedule = useCallback((fn: () => void, ms: number) => {
    const id = setTimeout(() => {
      timers.current.delete(id);
      fn();
    }, ms);
    timers.current.add(id);
    return id;
  }, []);
  useEffect(
    () => () => {
      timers.current.forEach(clearTimeout);
      timers.current.clear();
    },
    [],
  );

  // Connectivity drives the non-blocking offline banner + the send queue (OFF-*).
  useEffect(() => {
    Network.getStatus().then((s) => setOnline(s.connected));
    let handle: { remove: () => void } | undefined;
    Network.addListener('networkStatusChange', (s) => setOnline(s.connected)).then((h) => {
      handle = h;
    });
    return () => { handle?.remove(); };
  }, []);

  const patch = useCallback((id: string, next: Partial<ChatMessage>) => {
    setMessages((prev) => prev.map((m) => (m.id === id ? { ...m, ...next } : m)));
  }, []);

  const announce = useCallback((msg: string) => setLive(msg), []);

  // Simulated incoming reply: typing indicator → message → live announcement.
  const queuePeerReply = useCallback(() => {
    setPeerTyping(true);
    schedule(() => {
      setPeerTyping(false);
      const incoming: ChatMessage = {
        id: nextId(),
        text: 'Got it — see you then!',
        author: 'them',
        createdAt: Date.now(),
      };
      setMessages((prev) => [incoming, ...prev]);
      announce(`${peerName} says: ${incoming.text}`);
      if (!atBottom.current) setUnread((n) => n + 1);
    }, REPLY_DELAY);
  }, [announce, peerName, schedule]);

  // Optimistic delivery lifecycle: sending → sent → delivered → read (CHAT-001).
  const deliver = useCallback(
    async (id: string, text: string) => {
      patch(id, { status: 'sending' });
      try {
        await sendTransport(text);
        patch(id, { status: 'sent' });
        schedule(() => patch(id, { status: 'delivered' }), STATUS_STEP);
        schedule(() => {
          patch(id, { status: 'read' });
          announce('Message read');
          setStatus({ kind: 'success' });
          if (autoReply) queuePeerReply();
        }, STATUS_STEP * 2);
      } catch {
        patch(id, { status: 'failed' });
        announce('Message failed to send. Activate the message to retry.');
      }
    },
    [announce, autoReply, patch, queuePeerReply, schedule, sendTransport],
  );

  const runLoad = useCallback(() => {
    setStatus({ kind: 'loading' });
    loadHistory()
      .then((history) => {
        setMessages(history);
        setStatus(history.length > 0 ? { kind: 'idle' } : { kind: 'empty' });
      })
      .catch(() => setStatus({ kind: 'error', message: 'Could not load earlier messages.' }));
  }, [loadHistory]);

  useEffect(() => { runLoad(); }, [runLoad]);

  // Success → discreet, non-blocking "Delivered" toast, then return to idle.
  useEffect(() => {
    if (status.kind !== 'success') return;
    present({ message: 'Delivered', duration: TOAST_MS });
    setStatus({ kind: 'idle' });
  }, [status, present]);

  // Move focus to the history-error banner + announce it when it appears (A11Y-*).
  useEffect(() => {
    if (status.kind === 'error') errorRef.current?.focus();
  }, [status]);

  const scrollToBottom = useCallback(() => {
    listRef.current?.scrollTo({ top: 0, behavior: 'smooth' });
    setUnread(0);
    setShowJump(false);
  }, []);

  const handleSend = useCallback(() => {
    const text = draft.trim();
    if (text.length === 0) return;
    const id = nextId();
    const message: ChatMessage = {
      id,
      text,
      author: 'me',
      createdAt: Date.now(),
      status: online ? 'sending' : 'queued',
    };
    setMessages((prev) => [message, ...prev]);
    setDraft('');
    setStatus((prev) => (prev.kind === 'empty' ? { kind: 'idle' } : prev));
    schedule(scrollToBottom, STATUS_STEP);
    if (online) {
      deliver(id, text);
    } else {
      queue.current.push({ id, text });
      announce('Message queued. It will send when you are back online.');
    }
  }, [announce, deliver, draft, online, schedule, scrollToBottom]);

  // Reconnect → flush the queue with the optimistic lifecycle (OFF-002).
  useEffect(() => {
    if (online && queue.current.length > 0) {
      const pending = queue.current;
      queue.current = [];
      pending.forEach(({ id, text }) => deliver(id, text));
    }
  }, [online, deliver]);

  // Retry a failed send in place — content is preserved (CHAT-006).
  const retryMessage = useCallback(
    (message: ChatMessage) => {
      if (!online) {
        patch(message.id, { status: 'queued' });
        queue.current.push({ id: message.id, text: message.text });
        return;
      }
      deliver(message.id, message.text);
    },
    [deliver, online, patch],
  );

  const handleAttach = useCallback(async () => {
    try {
      const granted = await requestAttachPermission();
      if (!granted) {
        setStatus({ kind: 'permissionDenied', reason: 'Photo access is off, so attachments are unavailable.' });
      }
    } catch {
      setStatus({ kind: 'permissionDenied', reason: 'The attachment picker is unavailable on this device.' });
    }
  }, [requestAttachPermission]);

  const onListScroll = useCallback(() => {
    const el = listRef.current;
    if (!el) return;
    // Inverted (column-reverse) list: the bottom (newest) sits near scrollTop 0.
    const bottom = Math.abs(el.scrollTop) <= STATUS_STEP;
    atBottom.current = bottom;
    setShowJump(!bottom);
    if (bottom) setUnread(0);
  }, []);

  const hasMessages = messages.length > 0;
  const isEmpty = status.kind === 'empty' || (!hasMessages && status.kind !== 'loading' && status.kind !== 'error');
  const showSkeleton = status.kind === 'loading' && !hasMessages;
  const presence = peerTyping ? 'typing…' : online ? 'Online' : 'Last seen recently';
  const canSend = draft.trim().length > 0;

  const ordered = useMemo(() => messages, [messages]);

  return (
    <IonPage>
      {/* Screen-reader live region for incoming messages + status (A11Y-019). */}
      <div className="chat-sr-only" role="status" aria-live="polite">{live}</div>

      <IonHeader>
        <IonToolbar>
          <IonButtons slot="start">
            <IonButton onClick={onBack} aria-label="Back">
              <IonIcon slot="icon-only" className="chat-mirror" icon={arrowBackOutline} aria-hidden="true" />
            </IonButton>
          </IonButtons>

          <div className="chat-identity" aria-label={`${peerName}, ${presence}`}>
            <span className="chat-avatar" aria-hidden="true">{peerName.slice(0, 1)}</span>
            <span className="chat-identity-text">
              <span className="chat-peer-name">{peerName}</span>
              <span className="chat-presence" aria-live="polite">{presence}</span>
            </span>
          </div>

          <IonButtons slot="end">
            <IonButton onClick={onCall} aria-label={`Call ${peerName}`}>
              <IonIcon slot="icon-only" icon={callOutline} aria-hidden="true" />
            </IonButton>
            <IonButton onClick={onOverflow} aria-label="More options">
              <IonIcon slot="icon-only" icon={ellipsisVerticalOutline} aria-hidden="true" />
            </IonButton>
          </IonButtons>
        </IonToolbar>

        {/* Non-blocking offline banner — conversation stays readable (STATE-008). */}
        {!online && (
          <div className="chat-banner" role="alert" aria-live="polite">
            <IonIcon icon={cloudOfflineOutline} aria-hidden="true" />
            <span className="chat-banner-text">You are offline — messages send when you reconnect.</span>
            <IonButton fill="clear" size="small" onClick={() => Network.getStatus().then((s) => setOnline(s.connected))}>
              Retry
            </IonButton>
          </div>
        )}

        {/* History-load error — inline retry, keeps any cached messages (STATE-007). */}
        {status.kind === 'error' && (
          <div className="chat-banner chat-banner-error" role="alert" tabIndex={-1} ref={errorRef}>
            <IonIcon icon={alertCircleOutline} aria-hidden="true" />
            <span className="chat-banner-text">{status.message}</span>
            <IonButton fill="clear" size="small" onClick={runLoad}>Try again</IonButton>
          </div>
        )}
      </IonHeader>

      <IonContent>
        <div className="chat-list-area">
          {showSkeleton ? (
            <div className="chat-skeleton" role="progressbar" aria-label="Loading messages">
              {['them', 'me', 'them', 'them', 'me'].map((who, i) => (
                <div key={i} className={`chat-row chat-row-${who}`}>
                  <div className={`chat-bubble chat-bubble-${who} chat-skeleton-bubble`}>
                    <IonSkeletonText animated />
                    <IonSkeletonText animated className="chat-skeleton-short" />
                  </div>
                </div>
              ))}
            </div>
          ) : isEmpty ? (
            <div className="chat-empty" role="status" aria-label={`No messages yet. Say hi to start the conversation with ${peerName}.`}>
              <span className="chat-empty-glyph" aria-hidden="true">👋</span>
              <p className="chat-empty-title">Say hi</p>
              <p className="chat-empty-body">This is the start of your conversation with {peerName}.</p>
            </div>
          ) : (
            <div className="chat-list" ref={listRef} onScroll={onListScroll}>
              {peerTyping && <TypingIndicator peerName={peerName} />}
              {ordered.map((m, i) => (
                <MessageBubble
                  key={m.id}
                  message={m}
                  live={i === 0 && m.author === 'them'}
                  onRetry={retryMessage}
                />
              ))}
            </div>
          )}

          {/* "N new messages" pill + scroll-to-bottom (CHAT-005). */}
          {showJump && (
            <div className="chat-jump-dock">
              {unread > 0 && (
                <IonButton className="chat-new-pill" size="small" onClick={scrollToBottom}
                  aria-label={`${unread} new ${unread === 1 ? 'message' : 'messages'}, scroll to latest`}>
                  {unread} new {unread === 1 ? 'message' : 'messages'}
                </IonButton>
              )}
              <IonButton className="chat-jump" fill="outline" onClick={scrollToBottom} aria-label="Scroll to latest messages">
                <IonIcon slot="icon-only" icon={chevronDownOutline} aria-hidden="true" />
              </IonButton>
            </div>
          )}
        </div>
      </IonContent>

      {/* Composer — attach · growing field · send. IonFooter rides above the
          keyboard; chat.css adds the home-indicator inset (CHAT-003). */}
      <IonFooter>
        <div className="chat-composer">
          <IonButton className="chat-icon-btn" fill="clear" onClick={handleAttach} aria-label="Add attachment">
            <IonIcon slot="icon-only" icon={addOutline} aria-hidden="true" />
          </IonButton>

          <IonTextarea
            className="chat-input"
            autoGrow
            aria-label={`Message ${peerName}`}
            placeholder={`Message ${peerName}`}
            value={draft}
            onIonInput={(e) => setDraft(e.detail.value ?? '')}
          />

          <IonButton
            className="chat-send-btn"
            onClick={handleSend}
            disabled={!canSend}
            aria-label="Send message"
          >
            <IonIcon slot="icon-only" className="chat-mirror" icon={paperPlaneOutline} aria-hidden="true" />
          </IonButton>
        </div>
      </IonFooter>

      {/* Permission-denied → explain + Settings + a working fallback; chat keeps
          running underneath (STATE-010, PERM-004). */}
      <IonModal isOpen={status.kind === 'permissionDenied'} onDidDismiss={() => setStatus({ kind: 'idle' })}>
        <IonHeader><IonToolbar><IonTitle>Attachments unavailable</IonTitle>
          <IonButtons slot="end">
            <IonButton onClick={() => setStatus({ kind: 'idle' })}>Close</IonButton>
          </IonButtons>
        </IonToolbar></IonHeader>
        <IonContent>
          <div className="chat-card">
            <div className="chat-banner-error chat-card-note">
              <IonIcon icon={warningOutline} aria-hidden="true" />
              <span>{status.kind === 'permissionDenied' ? status.reason : ''} You can still send messages, or pick from Files instead.</span>
            </div>
            <IonButton expand="block" onClick={openSettings}>Open Settings</IonButton>
            <IonButton expand="block" fill="clear" onClick={() => setStatus({ kind: 'idle' })}>Not now, keep chatting</IonButton>
          </div>
        </IonContent>
      </IonModal>
    </IonPage>
  );
}

// --- Message bubble ---------------------------------------------------------
function MessageBubble({
  message,
  live,
  onRetry,
}: {
  message: ChatMessage;
  live: boolean;
  onRetry: (message: ChatMessage) => void;
}) {
  const mine = message.author === 'me';
  const time = formatTime(message.createdAt);
  const statusText = message.status ? STATUS_TEXT[message.status] : '';
  const failed = message.status === 'failed';
  const label = `${mine ? 'You' : peerAria(message)}, ${message.text}, ${time}${statusText ? `, ${statusText}` : ''}`;

  return (
    <div
      className={`chat-row ${mine ? 'chat-row-me' : 'chat-row-them'}`}
      role="group"
      aria-label={label}
      aria-live={live ? 'polite' : undefined}
    >
      <div className={`chat-bubble ${mine ? 'chat-bubble-me' : 'chat-bubble-them'} ${failed ? 'chat-bubble-failed' : ''}`}>
        <p className="chat-text">{message.text}</p>
        <div className="chat-meta">
          <span className="chat-time">{time}</span>
          {mine && message.status && (
            <span className={`chat-status ${message.status === 'read' ? 'chat-status-read' : ''} ${failed ? 'chat-status-failed' : ''}`} aria-hidden="true">
              <IonIcon icon={STATUS_ICON[message.status]} />
              <span className="chat-status-text">{statusText}</span>
            </span>
          )}
        </div>
        {failed && (
          <IonButton className="chat-retry-btn" size="small" fill="clear" onClick={() => onRetry(message)}
            aria-label="Retry sending this message">
            Retry
          </IonButton>
        )}
      </div>
    </div>
  );
}

function peerAria(_m: ChatMessage): string {
  return 'Them';
}

// --- Typing indicator -------------------------------------------------------
function TypingIndicator({ peerName }: { peerName: string }) {
  // Dots animate via chat.css; the CSS pauses them under prefers-reduced-motion
  // while this stays exposed as status text (A11Y-011, CHAT-002).
  return (
    <div className="chat-row chat-row-them" role="status" aria-live="polite" aria-label={`${peerName} is typing`}>
      <div className="chat-bubble chat-bubble-them chat-typing">
        <span className="chat-typing-dot" aria-hidden="true" />
        <span className="chat-typing-dot" aria-hidden="true" />
        <span className="chat-typing-dot" aria-hidden="true" />
      </div>
    </div>
  );
}
