/**
 * ChatScreen.tsx — an accessible, offline-resilient 1:1 chat for the skill's Chat example.
 *
 * Implements the full spec: a virtualized INVERTED message list (newest at the
 * bottom), own vs other bubbles aligned to opposite sides with logical styles so
 * they mirror in RTL, a growing composer pinned above the keyboard + home
 * indicator, optimistic send with a real delivery lifecycle, a failed→retry path
 * that preserves content, an offline queue that auto-flushes on reconnect, a
 * looping (reduce-motion-aware) typing indicator exposed as status text, a
 * "N new messages" pill + scroll-to-bottom control, and a non-blocking offline
 * banner. Every screen condition is a member of the ChatStatus discriminated
 * union and every visual value comes from chatTokens.ts (no raw values here).
 *
 * NOTE: history load + send transport are injectable props defaulting to light
 * mocks, so the file compiles and runs standalone; wire real calls at the call site.
 */
import React, {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
} from 'react';
import {
  AccessibilityInfo,
  Animated,
  FlatList,
  I18nManager,
  KeyboardAvoidingView,
  Linking,
  Platform,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
  findNodeHandle,
  useColorScheme,
} from 'react-native';
import type {
  ListRenderItemInfo,
  NativeScrollEvent,
  NativeSyntheticEvent,
  TextInputContentSizeChangeEventData,
} from 'react-native';
import {
  SafeAreaView,
  useSafeAreaInsets,
} from 'react-native-safe-area-context';
import NetInfo from '@react-native-community/netinfo';

import {
  ColorRoles,
  getColors,
  motion,
  radius,
  size,
  spacing,
  typography,
} from './chatTokens';

/**
 * Per-message delivery lifecycle. Status is always conveyed as icon + TEXT,
 * never colour alone (A11Y-012), and every value is announced to assistive tech.
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
 * The 7 screen states as a discriminated union. Members literally cover:
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

type ChatScreenProps = {
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

const STATUS_GLYPH: Record<MessageStatus, string> = {
  sending: '○',
  sent: '✓',
  delivered: '✓✓',
  read: '✓✓',
  failed: '⚠',
  queued: '◴',
};

const noop = () => {};

const SEED: ChatMessage[] = [
  { id: 'seed-1', text: 'Hey! Are we still on for tomorrow?', author: 'them', createdAt: Date.now() - 1000 * 60 * 9 },
  { id: 'seed-2', text: 'Absolutely — 10am works for me.', author: 'me', createdAt: Date.now() - 1000 * 60 * 8, status: 'read' },
  { id: 'seed-3', text: 'Perfect. I’ll bring the prototype.', author: 'them', createdAt: Date.now() - 1000 * 60 * 7 },
];

const defaultLoadHistory = async (): Promise<ChatMessage[]> => {
  await new Promise((resolve) => setTimeout(resolve, motion.base));
  return SEED;
};

const defaultSendTransport = async (_text: string): Promise<void> => {
  // Illustrative latency only — replace with a real network call.
  await new Promise((resolve) => setTimeout(resolve, motion.base));
};

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
  autoReply = true,
}: ChatScreenProps) {
  const scheme = useColorScheme();
  const colors = getColors(scheme);
  const insets = useSafeAreaInsets();
  const styles = useMemo(() => makeStyles(colors), [colors]);

  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [status, setStatus] = useState<ChatStatus>({ kind: 'loading' });
  const [draft, setDraft] = useState('');
  const [inputHeight, setInputHeight] = useState<number>(size.target);
  const [isConnected, setIsConnected] = useState(true);
  const [reduceMotion, setReduceMotion] = useState(false);
  const [peerTyping, setPeerTyping] = useState(false);
  const [unread, setUnread] = useState(0);
  const [showJump, setShowJump] = useState(false);
  const [liveMessage, setLiveMessage] = useState('');

  const listRef = useRef<FlatList<ChatMessage>>(null);
  const errorRef = useRef<View>(null);
  const timers = useRef<Set<ReturnType<typeof setTimeout>>>(new Set());
  const queue = useRef<Array<{ id: string; text: string }>>([]);
  const atBottom = useRef(true);

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

  // Reduce-motion preference — gates every non-essential animation.
  useEffect(() => {
    let mounted = true;
    AccessibilityInfo.isReduceMotionEnabled().then((value) => {
      if (mounted) setReduceMotion(value);
    });
    const sub = AccessibilityInfo.addEventListener('reduceMotionChanged', setReduceMotion);
    return () => {
      mounted = false;
      sub.remove();
    };
  }, []);

  // Connectivity — drives the non-blocking offline banner + the send queue.
  useEffect(() => {
    const unsubscribe = NetInfo.addEventListener((state) => {
      setIsConnected(state.isConnected ?? true);
    });
    return () => unsubscribe();
  }, []);

  const patch = useCallback((id: string, next: Partial<ChatMessage>) => {
    setMessages((prev) => prev.map((m) => (m.id === id ? { ...m, ...next } : m)));
  }, []);

  // Optimistic delivery lifecycle: sending -> sent -> delivered -> read.
  const deliver = useCallback(
    async (id: string, text: string) => {
      patch(id, { status: 'sending' });
      try {
        await sendTransport(text);
        patch(id, { status: 'sent' });
        schedule(() => patch(id, { status: 'delivered' }), motion.statusFade);
        schedule(() => {
          patch(id, { status: 'read' });
          AccessibilityInfo.announceForAccessibility('Message read');
          setStatus((prev) => (prev.kind === 'idle' ? { kind: 'success' } : prev));
          schedule(
            () => setStatus((prev) => (prev.kind === 'success' ? { kind: 'idle' } : prev)),
            motion.base,
          );
          if (autoReply) queuePeerReply();
        }, motion.statusFade * 2);
      } catch {
        patch(id, { status: 'failed' });
        AccessibilityInfo.announceForAccessibility(
          'Message failed to send. Double tap the message to retry.',
        );
      }
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [autoReply, patch, schedule, sendTransport],
  );

  // Simulated incoming reply: typing indicator -> message -> live announcement.
  const queuePeerReply = useCallback(() => {
    setPeerTyping(true);
    schedule(() => {
      setPeerTyping(false);
      const incoming: ChatMessage = {
        id: nextId(),
        text: 'Got it — see you then! 👍',
        author: 'them',
        createdAt: Date.now(),
      };
      setMessages((prev) => [incoming, ...prev]);
      setLiveMessage(`${peerName} says: ${incoming.text}`);
      AccessibilityInfo.announceForAccessibility(`${peerName} says ${incoming.text}`);
      if (!atBottom.current) setUnread((n) => n + 1);
    }, motion.base * 3);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [peerName, schedule]);

  const runLoad = useCallback(() => {
    setStatus({ kind: 'loading' });
    loadHistory()
      .then((history) => {
        setMessages(history);
        setStatus(history.length > 0 ? { kind: 'idle' } : { kind: 'empty' });
      })
      .catch(() => {
        setStatus({ kind: 'error', message: 'Couldn’t load earlier messages.' });
      });
  }, [loadHistory]);

  useEffect(() => {
    runLoad();
  }, [runLoad]);

  // Move focus to the history-error banner and announce it when it appears.
  useEffect(() => {
    if (status.kind !== 'error') return;
    const node = errorRef.current ? findNodeHandle(errorRef.current) : null;
    if (node != null) AccessibilityInfo.setAccessibilityFocus(node);
    AccessibilityInfo.announceForAccessibility(status.message);
  }, [status]);

  const scrollToBottom = useCallback(() => {
    listRef.current?.scrollToOffset({ offset: 0, animated: !reduceMotion });
    setUnread(0);
  }, [reduceMotion]);

  const handleSend = useCallback(() => {
    const text = draft.trim();
    if (text.length === 0) return;
    const message: ChatMessage = {
      id: nextId(),
      text,
      author: 'me',
      createdAt: Date.now(),
      status: isConnected ? 'sending' : 'queued',
    };
    setMessages((prev) => [message, ...prev]);
    setDraft('');
    setInputHeight(size.target);
    setStatus((prev) => (prev.kind === 'empty' ? { kind: 'idle' } : prev));
    schedule(scrollToBottom, motion.instant);
    if (isConnected) {
      deliver(message.id, text);
    } else {
      queue.current.push({ id: message.id, text });
      AccessibilityInfo.announceForAccessibility('Message queued. It will send when you are back online.');
    }
  }, [draft, isConnected, deliver, schedule, scrollToBottom]);

  // Reconnect -> flush the queue with the optimistic lifecycle (OFF-002).
  useEffect(() => {
    if (isConnected && queue.current.length > 0) {
      const pending = queue.current;
      queue.current = [];
      pending.forEach(({ id, text }) => deliver(id, text));
    }
  }, [isConnected, deliver]);

  // Retry a failed send in place — content is preserved (CHAT-006).
  const retryMessage = useCallback(
    (message: ChatMessage) => {
      if (!isConnected) {
        patch(message.id, { status: 'queued' });
        queue.current.push({ id: message.id, text: message.text });
        return;
      }
      deliver(message.id, message.text);
    },
    [deliver, isConnected, patch],
  );

  const handleAttach = useCallback(async () => {
    try {
      const granted = await requestAttachPermission();
      if (!granted) {
        setStatus({
          kind: 'permissionDenied',
          reason: 'Photo access is off, so attachments are unavailable.',
        });
      }
    } catch {
      setStatus({
        kind: 'permissionDenied',
        reason: 'The attachment picker is unavailable on this device.',
      });
    }
  }, [requestAttachPermission]);

  const onScroll = useCallback((e: NativeSyntheticEvent<NativeScrollEvent>) => {
    const y = e.nativeEvent.contentOffset.y;
    const bottom = y <= size.jumpThreshold;
    atBottom.current = bottom;
    setShowJump(!bottom);
    if (bottom) setUnread(0);
  }, []);

  const onContentSize = useCallback(
    (e: NativeSyntheticEvent<TextInputContentSizeChangeEventData>) => {
      const h = e.nativeEvent.contentSize.height;
      setInputHeight(Math.min(Math.max(size.target, h), size.composerMax));
    },
    [],
  );

  const renderItem = useCallback(
    ({ item, index }: ListRenderItemInfo<ChatMessage>) => (
      <MessageBubble
        message={item}
        styles={styles}
        reduceMotion={reduceMotion}
        live={index === 0 && item.author === 'them'}
        onRetry={retryMessage}
      />
    ),
    [colors, styles, reduceMotion, retryMessage],
  );

  const keyExtractor = useCallback((m: ChatMessage) => m.id, []);

  const hasMessages = messages.length > 0;
  const showSkeleton = status.kind === 'loading' && !hasMessages;
  const showEmpty = !hasMessages && status.kind !== 'loading';
  const presence = peerTyping
    ? reduceMotion
      ? 'typing…'
      : 'typing'
    : isConnected
    ? 'Online'
    : 'Last seen recently';

  const composerBottom = insets.bottom + spacing.sm;

  return (
    <SafeAreaView edges={['top']} style={styles.container}>
      {/* Screen-reader live region for incoming messages (A11Y-019). */}
      <Text
        accessibilityLiveRegion="polite"
        accessibilityLabel={liveMessage}
        style={styles.srOnly}
      >
        {liveMessage}
      </Text>

      {/* Nav header */}
      <View style={styles.header}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Back"
          onPress={onBack}
          hitSlop={size.hitSlop}
          style={styles.headerButton}
        >
          <Text style={[styles.headerGlyph, styles.mirror]}>‹</Text>
        </Pressable>

        <View style={styles.avatar} accessibilityElementsHidden importantForAccessibility="no-hide-descendants">
          <Text style={styles.avatarText}>{peerName.slice(0, 1)}</Text>
        </View>

        <View
          style={styles.identity}
          accessible
          accessibilityRole="header"
          accessibilityLabel={`${peerName}, ${presence}`}
        >
          <Text numberOfLines={1} style={styles.peerName}>
            {peerName}
          </Text>
          <Text
            numberOfLines={1}
            accessibilityLiveRegion="polite"
            style={styles.presence}
          >
            {presence}
          </Text>
        </View>

        <Pressable
          accessibilityRole="button"
          accessibilityLabel={`Call ${peerName}`}
          onPress={onCall}
          hitSlop={size.hitSlop}
          style={styles.headerButton}
        >
          <Text style={styles.headerGlyph}>☎</Text>
        </Pressable>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel="More options"
          onPress={onOverflow}
          hitSlop={size.hitSlop}
          style={styles.headerButton}
        >
          <Text style={styles.headerGlyph}>⋮</Text>
        </Pressable>
      </View>

      {/* Non-blocking offline banner — conversation stays readable (STATE-008). */}
      {!isConnected ? (
        <View
          accessible
          accessibilityRole="alert"
          accessibilityLiveRegion="polite"
          style={styles.banner}
        >
          <Text
            style={styles.bannerIcon}
            accessibilityElementsHidden
            importantForAccessibility="no-hide-descendants"
          >
            {'⚠'}
          </Text>
          <Text style={styles.bannerText}>
            You&apos;re offline — messages will send when you reconnect.
          </Text>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Retry connection"
            onPress={() => NetInfo.refresh()}
            hitSlop={size.hitSlop}
            style={styles.bannerAction}
          >
            <Text style={styles.bannerLink}>Retry</Text>
          </Pressable>
        </View>
      ) : null}

      {/* History-load error — inline retry, keeps any cached messages (STATE-007). */}
      {status.kind === 'error' ? (
        <View
          ref={errorRef}
          accessible
          accessibilityRole="alert"
          accessibilityLiveRegion="assertive"
          style={styles.banner}
        >
          <Text
            style={styles.bannerIcon}
            accessibilityElementsHidden
            importantForAccessibility="no-hide-descendants"
          >
            {'⚠'}
          </Text>
          <Text style={styles.bannerText}>{status.message}</Text>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Try loading messages again"
            onPress={runLoad}
            hitSlop={size.hitSlop}
            style={styles.bannerAction}
          >
            <Text style={styles.bannerLink}>Try again</Text>
          </Pressable>
        </View>
      ) : null}

      <KeyboardAvoidingView
        style={styles.flex}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        keyboardVerticalOffset={insets.top}
      >
        <View style={styles.listArea}>
          {showSkeleton ? (
            <SkeletonList styles={styles} />
          ) : showEmpty ? (
            <View
              accessible
              accessibilityRole="text"
              accessibilityLabel="No messages yet. Say hi to start the conversation."
              style={styles.emptyWrap}
            >
              <Text style={styles.emptyGlyph}>{'👋'}</Text>
              <Text style={styles.emptyTitle}>Say hi</Text>
              <Text style={styles.emptyBody}>
                This is the start of your conversation with {peerName}.
              </Text>
            </View>
          ) : (
            <FlatList
              ref={listRef}
              data={messages}
              inverted
              keyExtractor={keyExtractor}
              renderItem={renderItem}
              onScroll={onScroll}
              scrollEventThrottle={16}
              keyboardDismissMode="interactive"
              keyboardShouldPersistTaps="handled"
              initialNumToRender={15}
              maxToRenderPerBatch={12}
              windowSize={11}
              removeClippedSubviews
              contentContainerStyle={styles.listContent}
              ListHeaderComponent={
                peerTyping ? (
                  <TypingIndicator
                    styles={styles}
                    reduceMotion={reduceMotion}
                    peerName={peerName}
                  />
                ) : null
              }
            />
          )}

          {/* "N new messages" pill + scroll-to-bottom (CHAT-005). */}
          {showJump ? (
            <View style={styles.jumpDock} pointerEvents="box-none">
              {unread > 0 ? (
                <Pressable
                  accessibilityRole="button"
                  accessibilityLabel={`${unread} new ${unread === 1 ? 'message' : 'messages'}, scroll to latest`}
                  onPress={scrollToBottom}
                  style={styles.newPill}
                >
                  <Text style={styles.newPillText}>
                    {unread} new {unread === 1 ? 'message' : 'messages'}
                  </Text>
                </Pressable>
              ) : null}
              <Pressable
                accessibilityRole="button"
                accessibilityLabel="Scroll to latest messages"
                onPress={scrollToBottom}
                style={styles.jumpButton}
              >
                <Text style={styles.jumpGlyph}>⌄</Text>
              </Pressable>
            </View>
          ) : null}
        </View>

        {/* Composer — attach · growing field · send. Rides above the keyboard
            and clears the home-indicator inset (CHAT-003). */}
        <View style={[styles.composer, { paddingBottom: composerBottom }]}>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Add attachment"
            onPress={handleAttach}
            hitSlop={size.hitSlop}
            style={styles.iconButton}
          >
            <Text style={styles.composerGlyph}>＋</Text>
          </Pressable>

          <TextInput
            accessibilityLabel="Message"
            multiline
            value={draft}
            onChangeText={setDraft}
            onContentSizeChange={onContentSize}
            placeholder={`Message ${peerName}`}
            placeholderTextColor={colors.onSurfaceMuted}
            style={[styles.input, { height: inputHeight }]}
          />

          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Send message"
            accessibilityState={{ disabled: draft.trim().length === 0 }}
            disabled={draft.trim().length === 0}
            onPress={handleSend}
            hitSlop={size.hitSlop}
            style={({ pressed }) => [
              styles.sendButton,
              draft.trim().length === 0 ? styles.sendButtonDisabled : null,
              pressed && draft.trim().length > 0 ? styles.sendButtonPressed : null,
            ]}
          >
            <Text style={[styles.sendGlyph, styles.mirror]}>➤</Text>
          </Pressable>
        </View>
      </KeyboardAvoidingView>

      {/* Success -> discreet, non-blocking confirmation toast (STATE-009). */}
      {status.kind === 'success' ? (
        <View
          accessible
          accessibilityLiveRegion="polite"
          accessibilityLabel="Message delivered"
          style={[styles.toast, { bottom: composerBottom + size.target }]}
          pointerEvents="none"
        >
          <Text style={styles.toastText}>Delivered</Text>
        </View>
      ) : null}

      {/* Permission-denied -> explain + Settings + a working fallback; chat keeps
          running underneath (STATE-010, PERM-004). */}
      {status.kind === 'permissionDenied' ? (
        <View
          accessible
          accessibilityViewIsModal
          accessibilityLiveRegion="assertive"
          style={styles.overlay}
        >
          <View style={styles.card}>
            <Text accessibilityRole="header" style={styles.cardTitle}>
              Attachments unavailable
            </Text>
            <Text style={styles.cardBody}>
              {status.reason} You can still send messages, or pick from Files instead.
            </Text>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel="Open Settings"
              onPress={() => Linking.openSettings()}
              style={({ pressed }) => [
                styles.cardPrimary,
                pressed ? styles.sendButtonPressed : null,
              ]}
            >
              <Text style={styles.cardPrimaryLabel}>Open Settings</Text>
            </Pressable>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel="Keep chatting without attachments"
              onPress={() => setStatus({ kind: 'idle' })}
              hitSlop={size.hitSlop}
              style={styles.cardSecondary}
            >
              <Text style={styles.cardSecondaryLabel}>Not now, keep chatting</Text>
            </Pressable>
          </View>
        </View>
      ) : null}
    </SafeAreaView>
  );
}

// --- Message bubble ---------------------------------------------------------
type BubbleProps = {
  message: ChatMessage;
  styles: ReturnType<typeof makeStyles>;
  reduceMotion: boolean;
  live: boolean;
  onRetry: (message: ChatMessage) => void;
};

function MessageBubble({ message, styles, reduceMotion, live, onRetry }: BubbleProps) {
  const isMine = message.author === 'me';
  const enter = useRef(new Animated.Value(reduceMotion ? 1 : 0)).current;
  const time = formatTime(message.createdAt);
  const statusText = message.status ? STATUS_TEXT[message.status] : '';

  useEffect(() => {
    if (reduceMotion) {
      enter.setValue(1);
      return;
    }
    Animated.timing(enter, {
      toValue: 1,
      duration: motion.insert,
      useNativeDriver: true,
    }).start();
  }, [enter, reduceMotion]);

  const label = `${isMine ? 'You' : 'Them'}, ${message.text}, ${time}${
    statusText ? `, ${statusText}` : ''
  }`;

  const failed = message.status === 'failed';

  const body = (
    <Animated.View
      accessible
      accessibilityRole="text"
      accessibilityLabel={label}
      accessibilityLiveRegion={live ? 'polite' : 'none'}
      style={[
        styles.bubbleRow,
        isMine ? styles.bubbleRowMine : styles.bubbleRowTheirs,
        {
          opacity: enter,
          transform: [
            {
              translateY: enter.interpolate({
                inputRange: [0, 1],
                outputRange: [spacing.sm, spacing.none],
              }),
            },
          ],
        },
      ]}
    >
      <View style={[styles.bubble, isMine ? styles.bubbleMine : styles.bubbleTheirs]}>
        <Text style={isMine ? styles.bubbleTextMine : styles.bubbleTextTheirs}>
          {message.text}
        </Text>
        <View style={styles.metaRow}>
          <Text style={isMine ? styles.metaMine : styles.metaTheirs}>{time}</Text>
          {isMine && message.status ? (
            <Text
              style={[styles.metaMine, failed ? styles.metaFailed : null]}
              accessibilityElementsHidden
              importantForAccessibility="no-hide-descendants"
            >
              {`${STATUS_GLYPH[message.status]} ${statusText}`}
            </Text>
          ) : null}
        </View>
      </View>
    </Animated.View>
  );

  if (failed) {
    // Whole failed bubble is tap-to-retry; content is preserved.
    return (
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={`${label}. Double tap to retry.`}
        onPress={() => onRetry(message)}
        style={styles.retryHit}
      >
        {body}
      </Pressable>
    );
  }
  return body;
}

// --- Typing indicator -------------------------------------------------------
type TypingProps = {
  styles: ReturnType<typeof makeStyles>;
  reduceMotion: boolean;
  peerName: string;
};

function TypingIndicator({ styles, reduceMotion, peerName }: TypingProps) {
  const dots = [useRef(new Animated.Value(0)).current, useRef(new Animated.Value(0)).current, useRef(new Animated.Value(0)).current];

  useEffect(() => {
    if (reduceMotion) return; // paused under reduce-motion; still exposed as text
    const loops = dots.map((dot, i) =>
      Animated.loop(
        Animated.sequence([
          Animated.delay(motion.statusFade * i),
          Animated.timing(dot, { toValue: 1, duration: motion.typingDot, useNativeDriver: true }),
          Animated.timing(dot, { toValue: 0, duration: motion.typingDot, useNativeDriver: true }),
        ]),
      ),
    );
    loops.forEach((l) => l.start());
    return () => loops.forEach((l) => l.stop());
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [reduceMotion]);

  return (
    <View
      accessible
      accessibilityRole="text"
      accessibilityLiveRegion="polite"
      accessibilityLabel={`${peerName} is typing`}
      style={[styles.bubbleRow, styles.bubbleRowTheirs]}
    >
      <View style={[styles.bubble, styles.bubbleTheirs, styles.typingBubble]}>
        {dots.map((dot, i) => (
          <Animated.View
            key={i}
            style={[
              styles.typingDot,
              reduceMotion
                ? null
                : {
                    opacity: dot.interpolate({ inputRange: [0, 1], outputRange: [0.3, 1] }),
                    transform: [
                      { translateY: dot.interpolate({ inputRange: [0, 1], outputRange: [spacing.none, -spacing.xs] }) },
                    ],
                  },
            ]}
          />
        ))}
      </View>
    </View>
  );
}

// --- Loading skeleton -------------------------------------------------------
function SkeletonList({ styles }: { styles: ReturnType<typeof makeStyles> }) {
  const rows: Array<'me' | 'them'> = ['them', 'me', 'them', 'them', 'me'];
  return (
    <View
      accessible
      accessibilityRole="progressbar"
      accessibilityLabel="Loading messages"
      style={styles.skeletonWrap}
    >
      {rows.map((who, i) => (
        <View
          key={i}
          style={[
            styles.bubbleRow,
            who === 'me' ? styles.bubbleRowMine : styles.bubbleRowTheirs,
          ]}
        >
          <View
            style={[
              styles.skeletonBubble,
              who === 'me' ? styles.bubbleMine : styles.bubbleTheirs,
              i % 2 === 0 ? styles.skeletonWide : styles.skeletonNarrow,
            ]}
          />
        </View>
      ))}
    </View>
  );
}

function makeStyles(colors: ColorRoles) {
  return StyleSheet.create({
    flex: { flex: 1 },
    container: { flex: 1, backgroundColor: colors.surface },
    srOnly: {
      position: 'absolute',
      width: size.hairline,
      height: size.hairline,
      overflow: 'hidden',
      opacity: 0,
    },
    // Header
    header: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: spacing.sm,
      paddingHorizontal: spacing.sm,
      paddingVertical: spacing.sm,
      borderBottomWidth: size.hairline,
      borderBottomColor: colors.outline,
      backgroundColor: colors.surface,
    },
    headerButton: {
      minWidth: size.target,
      minHeight: size.target,
      alignItems: 'center',
      justifyContent: 'center',
    },
    headerGlyph: { ...typography.titleMd, color: colors.onSurface },
    mirror: { transform: [{ scaleX: I18nManager.isRTL ? -1 : 1 }] },
    avatar: {
      width: size.avatar,
      height: size.avatar,
      borderRadius: radius.pill,
      alignItems: 'center',
      justifyContent: 'center',
      backgroundColor: colors.surfaceContainer,
    },
    avatarText: { ...typography.labelMd, color: colors.onSurface },
    identity: { flex: 1, gap: spacing.none },
    peerName: { ...typography.titleMd, color: colors.onSurface },
    presence: { ...typography.labelSm, color: colors.onSurfaceMuted },
    // Banners
    banner: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: spacing.sm,
      paddingHorizontal: spacing.lg,
      paddingVertical: spacing.sm,
      backgroundColor: colors.surfaceDim,
    },
    bannerIcon: { ...typography.bodyMd, color: colors.onSurface },
    bannerText: { ...typography.labelSm, flex: 1, color: colors.onSurface },
    bannerAction: {
      minHeight: size.target,
      justifyContent: 'center',
      paddingHorizontal: spacing.sm,
    },
    bannerLink: { ...typography.labelMd, color: colors.actionPrimary },
    // List
    listArea: { flex: 1 },
    listContent: {
      paddingHorizontal: spacing.lg,
      paddingVertical: spacing.md,
      gap: spacing.sm,
    },
    bubbleRow: { flexDirection: 'row', width: '100%' },
    bubbleRowMine: { justifyContent: 'flex-end' },
    bubbleRowTheirs: { justifyContent: 'flex-start' },
    bubble: {
      maxWidth: '82%',
      borderRadius: radius.lg,
      paddingHorizontal: spacing.md,
      paddingVertical: spacing.sm,
      gap: spacing.xs,
    },
    bubbleMine: { backgroundColor: colors.chatSelfBg, borderTopEndRadius: radius.sm },
    bubbleTheirs: { backgroundColor: colors.chatOtherBg, borderTopStartRadius: radius.sm },
    bubbleTextMine: {
      ...typography.bodyMd,
      color: colors.onChatSelf,
      writingDirection: I18nManager.isRTL ? 'rtl' : 'ltr',
    },
    bubbleTextTheirs: {
      ...typography.bodyMd,
      color: colors.onChatOther,
      writingDirection: I18nManager.isRTL ? 'rtl' : 'ltr',
    },
    metaRow: {
      flexDirection: 'row',
      alignItems: 'center',
      flexWrap: 'wrap',
      gap: spacing.sm,
    },
    metaMine: { ...typography.labelSm, color: colors.onChatSelfMuted },
    metaTheirs: { ...typography.labelSm, color: colors.onChatOtherMuted },
    metaFailed: { color: colors.onChatSelf, fontWeight: '700' },
    retryHit: { width: '100%' },
    // Typing indicator
    typingBubble: { flexDirection: 'row', alignItems: 'center', gap: spacing.xs },
    typingDot: {
      width: size.dot,
      height: size.dot,
      borderRadius: radius.pill,
      backgroundColor: colors.typingDot,
    },
    // Jump / new-messages controls
    jumpDock: {
      position: 'absolute',
      end: spacing.lg,
      bottom: spacing.lg,
      alignItems: 'flex-end',
      gap: spacing.sm,
    },
    newPill: {
      minHeight: size.target,
      justifyContent: 'center',
      paddingHorizontal: spacing.lg,
      borderRadius: radius.pill,
      backgroundColor: colors.actionPrimary,
    },
    newPillText: { ...typography.labelMd, color: colors.onActionPrimary },
    jumpButton: {
      minWidth: size.target,
      minHeight: size.target,
      alignItems: 'center',
      justifyContent: 'center',
      borderRadius: radius.pill,
      borderWidth: size.hairline,
      borderColor: colors.outline,
      backgroundColor: colors.surfaceContainer,
    },
    jumpGlyph: { ...typography.titleMd, color: colors.onSurface },
    // Empty
    emptyWrap: {
      flex: 1,
      alignItems: 'center',
      justifyContent: 'center',
      gap: spacing.sm,
      paddingHorizontal: spacing.xl,
    },
    emptyGlyph: { ...typography.titleMd },
    emptyTitle: { ...typography.titleMd, color: colors.onSurface },
    emptyBody: { ...typography.bodyMd, color: colors.onSurfaceMuted },
    // Skeleton
    skeletonWrap: { flex: 1, paddingHorizontal: spacing.lg, paddingTop: spacing.md, gap: spacing.md },
    skeletonBubble: {
      borderRadius: radius.lg,
      paddingVertical: spacing.lg,
      backgroundColor: colors.surfaceDim,
    },
    skeletonWide: { width: '72%' },
    skeletonNarrow: { width: '44%' },
    // Composer
    composer: {
      flexDirection: 'row',
      alignItems: 'flex-end',
      gap: spacing.sm,
      paddingHorizontal: spacing.md,
      paddingTop: spacing.sm,
      borderTopWidth: size.hairline,
      borderTopColor: colors.outline,
      backgroundColor: colors.surface,
    },
    iconButton: {
      minWidth: size.target,
      minHeight: size.target,
      alignItems: 'center',
      justifyContent: 'center',
    },
    composerGlyph: { ...typography.titleMd, color: colors.actionPrimary },
    input: {
      ...typography.bodyMd,
      flex: 1,
      minHeight: size.target,
      maxHeight: size.composerMax,
      paddingHorizontal: spacing.md,
      paddingVertical: spacing.sm,
      borderRadius: radius.lg,
      borderWidth: size.hairline,
      borderColor: colors.outline,
      backgroundColor: colors.surfaceContainer,
      color: colors.onSurface,
      writingDirection: I18nManager.isRTL ? 'rtl' : 'ltr',
    },
    sendButton: {
      minWidth: size.target,
      minHeight: size.target,
      alignItems: 'center',
      justifyContent: 'center',
      borderRadius: radius.pill,
      backgroundColor: colors.actionPrimary,
    },
    sendButtonPressed: { backgroundColor: colors.actionPrimaryPressed },
    sendButtonDisabled: { backgroundColor: colors.outline },
    sendGlyph: { ...typography.titleMd, color: colors.onActionPrimary },
    // Success toast
    toast: {
      position: 'absolute',
      alignSelf: 'center',
      paddingHorizontal: spacing.lg,
      paddingVertical: spacing.sm,
      borderRadius: radius.pill,
      backgroundColor: colors.surfaceDim,
    },
    toastText: { ...typography.labelSm, color: colors.onSurface },
    // Overlay card (permission-denied)
    overlay: {
      ...StyleSheet.absoluteFillObject,
      alignItems: 'center',
      justifyContent: 'center',
      padding: spacing.lg,
      backgroundColor: colors.scrim,
    },
    card: {
      alignSelf: 'stretch',
      gap: spacing.md,
      padding: spacing.lg,
      borderRadius: radius.lg,
      backgroundColor: colors.surface,
    },
    cardTitle: { ...typography.titleMd, color: colors.onSurface },
    cardBody: { ...typography.bodyMd, color: colors.onSurfaceMuted },
    cardPrimary: {
      minHeight: size.target,
      alignItems: 'center',
      justifyContent: 'center',
      borderRadius: radius.md,
      paddingHorizontal: spacing.lg,
      paddingVertical: spacing.md,
      backgroundColor: colors.actionPrimary,
    },
    cardPrimaryLabel: { ...typography.labelMd, color: colors.onActionPrimary },
    cardSecondary: {
      minHeight: size.target,
      alignItems: 'center',
      justifyContent: 'center',
    },
    cardSecondaryLabel: { ...typography.labelMd, color: colors.actionPrimary },
  });
}
