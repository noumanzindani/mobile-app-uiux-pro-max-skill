// chat_screen.dart
//
// An accessible, reliability-first 1:1 / group chat surface built to the spec in
// examples/chat/spec.md. Adaptive keyboard + safe-area handling, a virtualized
// inverted message list, optimistic send with a full delivery lifecycle, an
// offline queue with auto-flush, RTL-safe logical alignment, Dynamic-Type-safe
// text, and reduce-motion fallbacks.
//
// Every color / spacing / radius / size / duration / opacity / text style comes
// from chat_tokens.dart — this file holds no raw design values (token_lint).
//
// Drop-in: `ChatScreen(sendMessage: mySendFn, contactName: 'Alex')`. See README.md.

import 'dart:async';

import 'package:flutter/material.dart';

import 'chat_tokens.dart';

/// The optimistic-send lifecycle (spec "Message delivery states", CHAT-001,
/// OFF-001/002/003). Every status is conveyed by an ICON + TEXT, never color
/// alone (A11Y-012).
enum MessageStatus {
  /// Optimistic bubble is on screen; the network round-trip is in flight.
  sending,

  /// The server acknowledged receipt — single check.
  sent,

  /// The recipient's device received it — double check.
  delivered,

  /// The recipient opened it — filled double check + "Read".
  read,

  /// The send failed; content is preserved and the bubble offers tap-to-retry.
  failed,

  /// Composed while offline; parked in the outbox and auto-flushed on reconnect.
  queued,
}

/// The seven UI states of the chat surface (spec "States map (all 7)").
enum ChatStatus {
  /// Conversation loaded, composer ready, scrolled to latest.
  idle,

  /// A brand-new conversation — a friendly first-message prompt, not a blank list.
  empty,

  /// Opening / fetching history — skeleton bubbles; pull-up loads older.
  loading,

  /// History load failed — inline retry banner that keeps any cached messages.
  error,

  /// No connectivity — non-blocking banner; sends queue and auto-flush.
  offline,

  /// A message just completed its lifecycle (…→ delivered → read).
  success,

  /// Attach/camera/mic denied — explains + offers Settings; chat keeps working.
  permissionDenied,
}

/// A single chat message. Immutable; status transitions produce a new instance
/// via [copyWith] so the list is a pure function of state.
@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.author,
    required this.text,
    required this.isSelf,
    required this.time,
    this.status = MessageStatus.read,
  });

  final String id;
  final String author;
  final String text;
  final bool isSelf;
  final DateTime time;
  final MessageStatus status;

  ChatMessage copyWith({MessageStatus? status}) => ChatMessage(
        id: id,
        author: author,
        text: text,
        isSelf: isSelf,
        time: time,
        status: status ?? this.status,
      );
}

/// Copy. Kept as constants so layout code stays about layout; in a real app these
/// resolve through your localization layer (no string concatenation — L10N-002).
class _Strings {
  const _Strings._();

  static const String you = 'You';
  static const String back = 'Back';
  static const String online = 'Online';
  static const String typing = 'typing…';
  static const String call = 'Call';
  static const String more = 'More';
  static const String composerLabel = 'Message';
  static const String composerHint = 'Message…';
  static const String send = 'Send';
  static const String attach = 'Add attachment';
  static const String scrollToBottom = 'Scroll to latest';
  static const String emptyTitle = 'Say hi 👋';
  static const String emptyBody = 'This is the beginning of your conversation.';
  static const String loadingLabel = 'Loading conversation';
  static const String loadingOlder = 'Loading earlier messages';
  static const String historyErrorTitle = "Couldn't load messages";
  static const String historyErrorBody =
      'Showing what we had cached. Check your connection and try again.';
  static const String tryAgain = 'Try again';
  static const String offlineBanner = "You're offline — messages will send when you reconnect";
  static const String reconnecting = 'Back online — sending queued messages';
  static const String statusSending = 'Sending…';
  static const String statusQueued = 'Queued — waiting for connection';
  static const String statusSent = 'Sent';
  static const String statusDelivered = 'Delivered';
  static const String statusRead = 'Read';
  static const String statusFailed = 'Not delivered';
  static const String retry = 'Tap to retry';
  static const String retryHint = 'Double tap to resend this message';
  static const String attachTitle = 'Attachments are off';
  static const String attachBody =
      "This app doesn't have permission to use your photos or camera. Turn it on "
      'in Settings, or pick a file instead — the chat keeps working either way.';
  static const String openSettings = 'Open Settings';
  static const String pickFile = 'Pick from files';
  static const String keepChatting = 'Keep chatting';

  static String newMessages(int n) =>
      n == 1 ? '1 new message' : '$n new messages';
  static String typingName(String name) => '$name is $typing';
}

/// Chat surface. All handlers are optional so it drops into any app; the demo
/// defaults simulate the network and a reply so it runs stand-alone.
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    this.contactName = 'Alex Rivera',
    this.presence = _Strings.online,
    this.initialMessages,
    this.sendMessage,
    this.loadOlder,
    this.requestAttachment,
    this.onBack,
    this.onOpenSettings,
    this.isOffline = false,
    this.initialStatus = ChatStatus.idle,
  });

  /// The other party's display name (nav bar title + screen-reader author).
  final String contactName;

  /// Presence line under the name (e.g. "Online", "last seen 2m ago").
  final String presence;

  /// Seed conversation, oldest → newest. `null` uses a short demo transcript;
  /// pass `const []` to preview the empty state.
  final List<ChatMessage>? initialMessages;

  /// Deliver a message. Return `true` on success, `false` (or throw) to route the
  /// bubble to the failed + tap-to-retry state. Defaults to a demo that "fails"
  /// for any text containing `fail`.
  final Future<bool> Function(String text)? sendMessage;

  /// Fetch a page of older messages (oldest → newest) for pull-up pagination.
  /// Return an empty list when the history head is reached.
  final Future<List<ChatMessage>> Function()? loadOlder;

  /// Request attachment permission. Return `false` (or throw) to route to the
  /// permission-denied sheet. Defaults to a demo that denies.
  final Future<bool> Function()? requestAttachment;

  final VoidCallback? onBack;
  final VoidCallback? onOpenSettings;

  /// Initial connectivity. In a real app, drive this from `connectivity_plus`.
  final bool isOffline;

  /// Initial screen state — use [ChatStatus.loading] or [ChatStatus.empty] to
  /// preview those states.
  final ChatStatus initialStatus;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _composer = TextEditingController();
  final FocusNode _composerFocus = FocusNode();
  final ScrollController _scroll = ScrollController();

  final List<ChatMessage> _messages = [];
  final List<String> _outbox = []; // ids queued while offline (OFF-002)

  ChatStatus _status = ChatStatus.idle;
  bool _loadingOlder = false;
  bool _hasMoreHistory = true;
  bool _historyError = false;
  bool _scrolledUp = false;
  bool _peerTyping = false;
  int _newCount = 0;
  int _seq = 0;
  String _liveAnnouncement = '';
  Timer? _typingTimer;

  bool get _offline => widget.isOffline;

  bool get _canSend => _composer.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    final seed = widget.initialMessages ?? _demoTranscript();
    _messages.addAll(seed);
    if (_messages.isEmpty && _status == ChatStatus.idle) {
      _status = ChatStatus.empty;
    }
    _composer.addListener(_onComposerChanged);
    _scroll.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reconnect edge → flush the outbox with backoff (OFF-002, OFF-004).
    if (oldWidget.isOffline && !widget.isOffline) {
      _flushOutbox();
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _composer.dispose();
    _composerFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // --- input -----------------------------------------------------------------

  void _onComposerChanged() {
    // The send button's enabled state tracks the field; rebuild on empty<->filled.
    setState(() {});
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    // reverse:true → pixels grow as you scroll UP toward older messages.
    final up = pos.pixels > ChatSize.scrollThreshold;
    if (up != _scrolledUp) setState(() => _scrolledUp = up);
    if (up) {
      if (_newCount != 0) setState(() => _newCount = 0);
    }
    final nearOldest = pos.pixels >= pos.maxScrollExtent - ChatSize.scrollThreshold;
    if (nearOldest) _loadOlder();
  }

  // --- send lifecycle --------------------------------------------------------

  Future<void> _handleSend() async {
    final text = _composer.text.trim();
    if (text.isEmpty) return;
    final id = 'local-${_seq++}';
    final msg = ChatMessage(
      id: id,
      author: _Strings.you,
      text: text,
      isSelf: true,
      time: DateTime.now(),
      status: _offline ? MessageStatus.queued : MessageStatus.sending,
    );
    setState(() {
      _messages.add(msg);
      _status = ChatStatus.idle;
      _composer.clear();
    });
    _scrollToBottom();

    if (_offline) {
      _outbox.add(id); // queued; auto-flush on reconnect (OFF-002)
      return;
    }
    await _deliver(id, text);
  }

  Future<void> _deliver(String id, String text) async {
    _setStatus(id, MessageStatus.sending);
    final send = widget.sendMessage ?? _demoSend;
    bool ok;
    try {
      ok = await send(text);
    } catch (_) {
      ok = false; // network/host error → failed, never silently dropped (CHAT-006)
    }
    if (!mounted) return;
    if (!ok) {
      _setStatus(id, MessageStatus.failed);
      return;
    }
    _setStatus(id, MessageStatus.sent);
    await Future<void>.delayed(ChatMotion.statusStep);
    if (!mounted) return;
    _setStatus(id, MessageStatus.delivered);
    await Future<void>.delayed(ChatMotion.statusStep);
    if (!mounted) return;
    _setStatus(id, MessageStatus.read);
    setState(() => _status = ChatStatus.success);
    _maybeDemoReply(text);
  }

  Future<void> _flushOutbox() async {
    if (_outbox.isEmpty) return;
    setState(() => _liveAnnouncement = _Strings.reconnecting);
    final pending = List<String>.from(_outbox);
    _outbox.clear();
    for (final id in pending) {
      final msg = _byId(id);
      if (msg == null) continue;
      await Future<void>.delayed(ChatMotion.retryBackoff); // backoff (OFF-004)
      if (!mounted) return;
      await _deliver(id, msg.text);
    }
  }

  void _retry(String id) {
    final msg = _byId(id);
    if (msg == null) return;
    if (_offline) {
      _setStatus(id, MessageStatus.queued);
      if (!_outbox.contains(id)) _outbox.add(id);
      return;
    }
    _deliver(id, msg.text); // content preserved, just re-sent (CHAT-006)
  }

  ChatMessage? _byId(String id) {
    for (final m in _messages) {
      if (m.id == id) return m;
    }
    return null;
  }

  void _setStatus(String id, MessageStatus status) {
    final i = _messages.indexWhere((m) => m.id == id);
    if (i < 0) return;
    setState(() => _messages[i] = _messages[i].copyWith(status: status));
  }

  // --- history / pagination --------------------------------------------------

  Future<void> _reloadHistory() async {
    setState(() {
      _historyError = false;
      _status = _messages.isEmpty ? ChatStatus.loading : ChatStatus.idle;
    });
    await _loadOlder(force: true);
    if (!mounted) return;
    if (_status == ChatStatus.loading) {
      setState(() => _status = _messages.isEmpty ? ChatStatus.empty : ChatStatus.idle);
    }
  }

  Future<void> _loadOlder({bool force = false}) async {
    if (_loadingOlder || (!_hasMoreHistory && !force)) return;
    final loader = widget.loadOlder;
    if (loader == null) {
      _hasMoreHistory = false;
      return;
    }
    setState(() => _loadingOlder = true);
    try {
      final older = await loader();
      if (!mounted) return;
      setState(() {
        _messages.insertAll(0, older); // preserve scroll anchor (LST-004)
        _hasMoreHistory = older.isNotEmpty;
        _historyError = false;
        _loadingOlder = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _historyError = true;
        _loadingOlder = false;
        _status = ChatStatus.error; // inline retry, cached list kept (STATE-007)
      });
    }
  }

  // --- attachments -----------------------------------------------------------

  Future<void> _handleAttach() async {
    final request = widget.requestAttachment ?? _demoAttach;
    bool granted;
    try {
      granted = await request();
    } catch (_) {
      granted = false;
    }
    if (!mounted) return;
    if (granted) return; // a real app would open the picker here
    setState(() => _status = ChatStatus.permissionDenied);
    await _showAttachDeniedSheet();
  }

  Future<void> _showAttachDeniedSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: ChatColors.of(context).surface,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: _AttachDeniedSheet(
          colors: ChatColors.of(sheetContext),
          onOpenSettings: () {
            Navigator.of(sheetContext).pop();
            widget.onOpenSettings?.call();
          },
          onPickFile: () => Navigator.of(sheetContext).pop(),
          onDismiss: () => Navigator.of(sheetContext).pop(),
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _status = _messages.isEmpty ? ChatStatus.empty : ChatStatus.idle);
  }

  // --- scrolling / new-message pill ------------------------------------------

  void _scrollToBottom({bool animate = true}) {
    setState(() => _newCount = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final reduceMotion = MediaQuery.disableAnimationsOf(context);
      if (animate && !reduceMotion) {
        _scroll.animateTo(
          _scroll.position.minScrollExtent,
          duration: ChatMotion.scrollTo,
          curve: Curves.easeOut,
        );
      } else {
        _scroll.jumpTo(_scroll.position.minScrollExtent);
      }
    });
  }

  void _receiveIncoming(ChatMessage msg) {
    setState(() {
      _messages.add(msg);
      _peerTyping = false;
      _liveAnnouncement = '${msg.author}: ${msg.text}'; // live-region (A11Y-019)
      if (_scrolledUp) {
        _newCount += 1; // parked below the fold → surface the pill (CHAT-005)
      }
    });
    if (!_scrolledUp) _scrollToBottom();
  }

  // --- demo plumbing (remove in production) ----------------------------------

  List<ChatMessage> _demoTranscript() {
    final now = DateTime.now();
    DateTime at(int minsAgo) => now.subtract(Duration(minutes: minsAgo));
    return [
      ChatMessage(
        id: 'seed-1',
        author: widget.contactName,
        text: 'Hey! Are we still on for tomorrow?',
        isSelf: false,
        time: at(58),
      ),
      ChatMessage(
        id: 'seed-2',
        author: _Strings.you,
        text: 'Absolutely — 10am works for me.',
        isSelf: true,
        time: at(55),
      ),
      ChatMessage(
        id: 'seed-3',
        author: _Strings.you,
        text: "I'll bring the prototype.",
        isSelf: true,
        time: at(55),
      ),
      ChatMessage(
        id: 'seed-4',
        author: widget.contactName,
        text: 'Perfect. See you then 🙌',
        isSelf: false,
        time: at(3),
      ),
    ];
  }

  Future<bool> _demoSend(String text) async {
    await Future<void>.delayed(ChatMotion.demoLatency);
    return !text.toLowerCase().contains('fail');
  }

  Future<bool> _demoAttach() async {
    await Future<void>.delayed(ChatMotion.statusFade);
    return false; // demo always routes to the permission-denied fallback
  }

  void _maybeDemoReply(String text) {
    if (widget.sendMessage != null) return; // only in stand-alone demo
    _typingTimer?.cancel();
    setState(() => _peerTyping = true);
    _typingTimer = Timer(ChatMotion.typingCycle, () {
      if (!mounted) return;
      _receiveIncoming(ChatMessage(
        id: 'peer-${_seq++}',
        author: widget.contactName,
        text: 'Got it — thanks! 👍',
        isSelf: false,
        time: DateTime.now(),
      ));
    });
  }

  // --- build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    // Keyboard avoidance: lift the whole column above the IME (CHAT-003, FRM-003);
    // SafeArea keeps the composer above the home indicator when it's dismissed.
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: colors.surface,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          _ChatNavBar(
            colors: colors,
            name: widget.contactName,
            presence: _peerTyping ? _Strings.typingName(widget.contactName) : widget.presence,
            typing: _peerTyping,
            onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
          ),
          _StateBanner(
            colors: colors,
            reduceMotion: reduceMotion,
            offline: _offline,
            historyError: _historyError,
            onRetry: _reloadHistory,
          ),
          Expanded(
            child: SafeArea(
              top: false,
              bottom: false,
              child: Padding(
                padding: EdgeInsetsDirectional.only(bottom: keyboardInset),
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          _conversationArea(colors, reduceMotion),
                          // Invisible live region: announces incoming messages to
                          // assistive tech without stealing focus (A11Y-019).
                          Semantics(
                            liveRegion: true,
                            container: true,
                            label: _liveAnnouncement,
                            child: const SizedBox.shrink(),
                          ),
                          _NewMessagesPill(
                            colors: colors,
                            reduceMotion: reduceMotion,
                            count: _newCount,
                            scrolledUp: _scrolledUp,
                            onTap: _scrollToBottom,
                          ),
                        ],
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: _Composer(
                        colors: colors,
                        controller: _composer,
                        focusNode: _composerFocus,
                        canSend: _canSend,
                        onSend: _handleSend,
                        onAttach: _handleAttach,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Center content switches on the screen state (spec "States map (all 7)").
  /// With no messages yet, the state decides which placeholder to show; once
  /// there are messages we always render the (virtualized) transcript, and
  /// offline / history-error surface as the non-blocking banner above it.
  Widget _conversationArea(ChatColors colors, bool reduceMotion) {
    if (_messages.isEmpty) {
      switch (_status) {
        case ChatStatus.loading:
          return _SkeletonList(colors: colors, reduceMotion: reduceMotion);
        case ChatStatus.error:
          return _ErrorView(colors: colors, onRetry: _reloadHistory);
        case ChatStatus.empty:
        case ChatStatus.idle:
        case ChatStatus.offline:
        case ChatStatus.success:
        case ChatStatus.permissionDenied:
          return _EmptyView(colors: colors);
      }
    }
    return _MessageList(
      colors: colors,
      reduceMotion: reduceMotion,
      controller: _scroll,
      rows: _buildRows(),
      loadingOlder: _loadingOlder,
      onRetry: _retry,
    );
  }

  /// Flatten the transcript into renderable rows: date separators, grouped
  /// messages, and a trailing typing indicator (chronological order).
  List<_Row> _buildRows() {
    final rows = <_Row>[];
    DateTime? lastDay;
    for (var i = 0; i < _messages.length; i++) {
      final m = _messages[i];
      final day = DateTime(m.time.year, m.time.month, m.time.day);
      if (lastDay == null || day != lastDay) {
        rows.add(_DateRow(day));
        lastDay = day;
      }
      final prev = i > 0 ? _messages[i - 1] : null;
      final next = i < _messages.length - 1 ? _messages[i + 1] : null;
      final firstInGroup = prev == null ||
          prev.isSelf != m.isSelf ||
          prev.author != m.author ||
          !_sameDay(prev.time, m.time) ||
          m.time.difference(prev.time).inMinutes.abs() > 3;
      final lastInGroup = next == null ||
          next.isSelf != m.isSelf ||
          next.author != m.author ||
          !_sameDay(next.time, m.time) ||
          next.time.difference(m.time).inMinutes.abs() > 3;
      rows.add(_MessageRow(m, firstInGroup: firstInGroup, lastInGroup: lastInGroup));
    }
    if (_peerTyping) rows.add(_TypingRow(widget.contactName));
    return rows;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// --- row model ---------------------------------------------------------------

sealed class _Row {
  const _Row();
}

class _DateRow extends _Row {
  const _DateRow(this.day);
  final DateTime day;
}

class _MessageRow extends _Row {
  const _MessageRow(this.message, {required this.firstInGroup, required this.lastInGroup});
  final ChatMessage message;
  final bool firstInGroup;
  final bool lastInGroup;
}

class _TypingRow extends _Row {
  const _TypingRow(this.name);
  final String name;
}

// --- nav bar -----------------------------------------------------------------

/// Top zone: back, avatar + name, presence/typing, call/overflow. Low-frequency
/// controls kept out of the thumb arc (spec "Top").
class _ChatNavBar extends StatelessWidget {
  const _ChatNavBar({
    required this.colors,
    required this.name,
    required this.presence,
    required this.typing,
    required this.onBack,
  });

  final ChatColors colors;
  final String name;
  final String presence;
  final bool typing;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surface,
      child: SafeArea(
        bottom: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: BorderDirectional(bottom: BorderSide(color: colors.outline)),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: ChatSpace.sm,
              vertical: ChatSpace.xs,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  tooltip: _Strings.back,
                  padding: const EdgeInsets.all(ChatSpace.sm),
                  constraints: const BoxConstraints(
                    minWidth: ChatSize.targetMin,
                    minHeight: ChatSize.targetMin,
                  ),
                  iconSize: ChatSize.icon,
                  color: colors.onSurface,
                  icon: const Icon(Icons.arrow_back),
                ),
                _Avatar(colors: colors, name: name, radius: ChatSize.avatarRadius),
                const SizedBox(width: ChatSpace.sm),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ChatType.title(context)?.copyWith(color: colors.onSurface),
                        ),
                        Text(
                          presence,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ChatType.meta(context)?.copyWith(
                            color: typing ? colors.statusInfo : colors.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  tooltip: _Strings.call,
                  padding: const EdgeInsets.all(ChatSpace.sm),
                  constraints: const BoxConstraints(
                    minWidth: ChatSize.targetMin,
                    minHeight: ChatSize.targetMin,
                  ),
                  iconSize: ChatSize.icon,
                  color: colors.onSurface,
                  icon: const Icon(Icons.call_outlined),
                ),
                IconButton(
                  onPressed: () {},
                  tooltip: _Strings.more,
                  padding: const EdgeInsets.all(ChatSpace.sm),
                  constraints: const BoxConstraints(
                    minWidth: ChatSize.targetMin,
                    minHeight: ChatSize.targetMin,
                  ),
                  iconSize: ChatSize.icon,
                  color: colors.onSurface,
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Initials avatar — no network dependency, decorative for a11y (the name is
/// announced by the header text).
class _Avatar extends StatelessWidget {
  const _Avatar({required this.colors, required this.name, required this.radius});
  final ChatColors colors;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0].toUpperCase()).join();
    return ExcludeSemantics(
      child: CircleAvatar(
        radius: radius,
        backgroundColor: colors.otherBubble,
        child: Text(
          initials,
          style: ChatType.meta(context)?.copyWith(color: colors.onOtherBubble),
        ),
      ),
    );
  }
}

// --- state banner (offline / history error) ----------------------------------

/// Non-blocking banner for offline + history-load errors. Announced as a live
/// region; conversation stays readable underneath (STATE-008, STATE-007).
class _StateBanner extends StatelessWidget {
  const _StateBanner({
    required this.colors,
    required this.reduceMotion,
    required this.offline,
    required this.historyError,
    required this.onRetry,
  });

  final ChatColors colors;
  final bool reduceMotion;
  final bool offline;
  final bool historyError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final visible = offline || historyError;
    final isError = historyError && !offline;
    return AnimatedSize(
      duration: reduceMotion ? Duration.zero : ChatMotion.pill,
      alignment: AlignmentDirectional.topStart,
      child: !visible
          ? const SizedBox.shrink()
          : Semantics(
              liveRegion: true,
              container: true,
              child: Container(
                width: double.infinity,
                color: colors.surfaceContainer,
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: ChatSpace.edge,
                  vertical: ChatSpace.sm,
                ),
                child: Row(
                  children: [
                    Icon(
                      isError ? Icons.error_outline : Icons.cloud_off_outlined,
                      size: ChatSize.icon,
                      color: isError ? colors.statusError : colors.onSurfaceMuted,
                    ),
                    const SizedBox(width: ChatSpace.sm),
                    Expanded(
                      child: Text(
                        isError ? _Strings.historyErrorBody : _Strings.offlineBanner,
                        style: ChatType.meta(context)?.copyWith(color: colors.onSurface),
                      ),
                    ),
                    if (isError) ...[
                      const SizedBox(width: ChatSpace.sm),
                      TextButton(
                        onPressed: onRetry,
                        style: TextButton.styleFrom(
                          foregroundColor: colors.primary,
                          minimumSize: const Size(ChatSize.targetMin, ChatSize.targetMin),
                          padding: const EdgeInsetsDirectional.symmetric(horizontal: ChatSpace.sm),
                        ),
                        child: const Text(_Strings.tryAgain),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

// --- message list ------------------------------------------------------------

/// The virtualized, inverted transcript (LST-001). `reverse: true` keeps the
/// newest message pinned to the bottom and makes pull-UP load older history.
class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.colors,
    required this.reduceMotion,
    required this.controller,
    required this.rows,
    required this.loadingOlder,
    required this.onRetry,
  });

  final ChatColors colors;
  final bool reduceMotion;
  final ScrollController controller;
  final List<_Row> rows;
  final bool loadingOlder;
  final ValueChanged<String> onRetry;

  @override
  Widget build(BuildContext context) {
    // One extra trailing slot (the visual top, oldest end) for the load-older spinner.
    final count = rows.length + 1;
    return ListView.builder(
      controller: controller,
      reverse: true,
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsetsDirectional.symmetric(vertical: ChatSpace.sm),
      itemCount: count,
      itemBuilder: (context, index) {
        if (index == rows.length) {
          return _LoadOlderIndicator(colors: colors, loading: loadingOlder);
        }
        final row = rows[rows.length - 1 - index]; // newest at index 0 (bottom)
        return switch (row) {
          _DateRow(:final day) => _DateSeparator(colors: colors, day: day),
          _TypingRow(:final name) => _TypingBubble(
              colors: colors,
              reduceMotion: reduceMotion,
              name: name,
            ),
          _MessageRow(:final message, :final firstInGroup, :final lastInGroup) => _Bubble(
              colors: colors,
              reduceMotion: reduceMotion,
              message: message,
              firstInGroup: firstInGroup,
              lastInGroup: lastInGroup,
              onRetry: onRetry,
            ),
        };
      },
    );
  }
}

/// Top-of-history pull-up spinner. Occupies zero height until a fetch is running,
/// so the scroll anchor is preserved when older messages splice in (LST-004).
class _LoadOlderIndicator extends StatelessWidget {
  const _LoadOlderIndicator({required this.colors, required this.loading});
  final ChatColors colors;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (!loading) return const SizedBox.shrink();
    return Semantics(
      label: _Strings.loadingOlder,
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(ChatSpace.md),
        child: Center(
          child: SizedBox.square(
            dimension: ChatSize.spinner,
            child: CircularProgressIndicator(
              strokeWidth: ChatSize.stroke,
              valueColor: AlwaysStoppedAnimation<Color>(colors.onSurfaceMuted),
            ),
          ),
        ),
      ),
    );
  }
}

/// Centered day chip between message groups (CHAT-007).
class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.colors, required this.day});
  final ChatColors colors;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: ChatSpace.sm),
      child: Center(
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: ChatSpace.md,
            vertical: ChatSpace.xs,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius: const BorderRadius.all(Radius.circular(ChatRadius.pill)),
          ),
          child: Text(
            _formatDay(day),
            style: ChatType.separator(context)?.copyWith(color: colors.onSurfaceMuted),
          ),
        ),
      ),
    );
  }
}

// --- bubble ------------------------------------------------------------------

/// A single message bubble. Own vs other align to opposite sides via
/// AlignmentDirectional so they mirror in RTL (L10N-001). Grouped and read by a
/// screen reader as one node: "sender, message, time, status" (A11Y-014).
class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.colors,
    required this.reduceMotion,
    required this.message,
    required this.firstInGroup,
    required this.lastInGroup,
    required this.onRetry,
  });

  final ChatColors colors;
  final bool reduceMotion;
  final ChatMessage message;
  final bool firstInGroup;
  final bool lastInGroup;
  final ValueChanged<String> onRetry;

  @override
  Widget build(BuildContext context) {
    final m = message;
    final failed = m.status == MessageStatus.failed;
    final ghosted = m.status == MessageStatus.sending || m.status == MessageStatus.queued;
    final bg = m.isSelf ? colors.selfBubble : colors.otherBubble;
    final fg = m.isSelf ? colors.onSelfBubble : colors.onOtherBubble;
    final metaFg = m.isSelf ? colors.onSelfBubbleMuted : colors.onOtherBubbleMuted;
    final maxWidth = MediaQuery.sizeOf(context).width * ChatSize.bubbleMaxFraction;
    final radius = _bubbleRadius(isSelf: m.isSelf, lastInGroup: lastInGroup);

    final bubble = Semantics(
      container: true,
      label: _semanticLabel(m),
      button: failed,
      hint: failed ? _Strings.retryHint : null,
      onTap: failed ? () => onRetry(m.id) : null,
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment:
                m.isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (firstInGroup && !m.isSelf)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: ChatSpace.bubblePadH,
                    bottom: ChatSpace.xs,
                  ),
                  child: Text(
                    m.author,
                    style: ChatType.name(context)?.copyWith(color: colors.onSurfaceMuted),
                  ),
                ),
              Opacity(
                opacity: ghosted ? ChatOpacity.ghost : ChatOpacity.full,
                child: Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: ChatSpace.bubblePadH,
                    vertical: ChatSpace.bubblePadV,
                  ),
                  decoration: BoxDecoration(color: bg, borderRadius: radius),
                  child: Text(
                    m.text,
                    style: ChatType.body(context)?.copyWith(color: fg),
                  ),
                ),
              ),
              _Footer(
                colors: colors,
                message: m,
                metaFg: metaFg,
                failed: failed,
                onRetry: () => onRetry(m.id),
              ),
            ],
          ),
        ),
      ),
    );

    final aligned = Padding(
      padding: EdgeInsetsDirectional.only(
        top: firstInGroup ? ChatSpace.md : ChatSpace.xs,
        start: ChatSpace.edge,
        end: ChatSpace.edge,
      ),
      child: Align(
        alignment: m.isSelf ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
        child: bubble,
      ),
    );

    // Outgoing insert fades in (opacity only); collapses under reduce-motion. The
    // tween runs once on first build, so status changes don't re-animate (MOT-004).
    if (m.isSelf && ghosted && !reduceMotion) {
      return TweenAnimationBuilder<double>(
        key: ValueKey<String>('insert-${m.id}'),
        tween: Tween<double>(begin: ChatOpacity.hidden, end: ChatOpacity.full),
        duration: ChatMotion.insert,
        curve: Curves.easeOut,
        builder: (context, value, child) => Opacity(opacity: value, child: child),
        child: aligned,
      );
    }
    return aligned;
  }

  BorderRadiusDirectional _bubbleRadius({required bool isSelf, required bool lastInGroup}) {
    const r = Radius.circular(ChatRadius.bubble);
    const tail = Radius.circular(ChatRadius.tail);
    // Flatten the trailing bottom corner of the last bubble in a group, mirrored
    // by side (own = bottom-end tail, other = bottom-start tail). Logical corners
    // keep the tail on the correct edge in RTL (L10N-001).
    return BorderRadiusDirectional.only(
      topStart: r,
      topEnd: r,
      bottomStart: (!isSelf && lastInGroup) ? tail : r,
      bottomEnd: (isSelf && lastInGroup) ? tail : r,
    );
  }
}

/// Timestamp + (for own messages) delivery status, conveyed by ICON + TEXT so it
/// is never color-only (A11Y-012). Failed messages expose an inline retry.
class _Footer extends StatelessWidget {
  const _Footer({
    required this.colors,
    required this.message,
    required this.metaFg,
    required this.failed,
    required this.onRetry,
  });

  final ChatColors colors;
  final ChatMessage message;
  final Color metaFg;
  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final metaStyle = ChatType.meta(context)?.copyWith(color: metaFg);
    if (failed) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(top: ChatSpace.xs),
        child: TextButton.icon(
          onPressed: onRetry,
          style: TextButton.styleFrom(
            foregroundColor: colors.statusError,
            textStyle: ChatType.meta(context),
            minimumSize: const Size(ChatSize.targetMin, ChatSize.targetMin),
            padding: const EdgeInsetsDirectional.symmetric(horizontal: ChatSpace.sm),
          ),
          icon: const Icon(Icons.error_outline, size: ChatSize.statusIcon),
          label: const Text('${_Strings.statusFailed} · ${_Strings.retry}'),
        ),
      );
    }
    final visual = _statusVisual(message, colors);
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: ChatSpace.xs,
        start: ChatSpace.sm,
        end: ChatSpace.sm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_formatTime(message.time), style: metaStyle),
          if (message.isSelf && visual != null) ...[
            const SizedBox(width: ChatSpace.xs),
            Icon(visual.icon, size: ChatSize.statusIcon, color: visual.color),
            const SizedBox(width: ChatSpace.xs),
            Text(visual.label, style: ChatType.meta(context)?.copyWith(color: visual.color)),
          ],
        ],
      ),
    );
  }
}

// --- typing indicator --------------------------------------------------------

/// Looping typing dots on the other side. Paused/static under reduce-motion and
/// exposed as status text so it's never decoration-only (A11Y-011, CHAT-002).
class _TypingBubble extends StatefulWidget {
  const _TypingBubble({
    required this.colors,
    required this.reduceMotion,
    required this.name,
  });

  final ChatColors colors;
  final bool reduceMotion;
  final String name;

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: ChatMotion.typingCycle,
  );

  @override
  void initState() {
    super.initState();
    if (!widget.reduceMotion) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _TypingBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion && _controller.isAnimating) {
      _controller.stop();
    } else if (!widget.reduceMotion && !_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return Semantics(
      label: _Strings.typingName(widget.name),
      liveRegion: true,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            top: ChatSpace.md,
            start: ChatSpace.edge,
            end: ChatSpace.edge,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: ChatSpace.bubblePadH,
                vertical: ChatSpace.bubblePadV,
              ),
              decoration: BoxDecoration(
                color: colors.otherBubble,
                borderRadius: const BorderRadius.all(Radius.circular(ChatRadius.bubble)),
              ),
              child: widget.reduceMotion
                  ? _StaticDots(color: colors.onOtherBubbleMuted)
                  : AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) => _AnimatedDots(
                        color: colors.onOtherBubbleMuted,
                        t: _controller.value,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StaticDots extends StatelessWidget {
  const _StaticDots({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsetsDirectional.only(end: ChatSpace.xs),
          child: _Dot(color: color, opacity: ChatOpacity.ghost),
        ),
      ),
    );
  }
}

class _AnimatedDots extends StatelessWidget {
  const _AnimatedDots({required this.color, required this.t});
  final Color color;
  final double t;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        // Each dot pulses opacity out of phase — transform/opacity only (PERF-001).
        final phase = (t + i / 3) % 1.0;
        final tri = 1 - (phase * 2 - 1).abs(); // triangle wave in [0, 1]
        final opacity =
            ChatOpacity.skeleton + (ChatOpacity.full - ChatOpacity.skeleton) * tri;
        return Padding(
          padding: const EdgeInsetsDirectional.only(end: ChatSpace.xs),
          child: _Dot(color: color, opacity: opacity),
        );
      }),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.opacity});
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(ChatOpacity.skeleton, ChatOpacity.full),
      child: Container(
        width: ChatSize.dot,
        height: ChatSize.dot,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

// --- "N new messages" pill ---------------------------------------------------

/// Fades/slides in when the user is scrolled up. Shows the unread count when new
/// messages arrive below the fold; tapping smooth-scrolls to the latest (CHAT-005).
class _NewMessagesPill extends StatelessWidget {
  const _NewMessagesPill({
    required this.colors,
    required this.reduceMotion,
    required this.count,
    required this.scrolledUp,
    required this.onTap,
  });

  final ChatColors colors;
  final bool reduceMotion;
  final int count;
  final bool scrolledUp;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visible = scrolledUp || count > 0;
    final label = count > 0 ? _Strings.newMessages(count) : _Strings.scrollToBottom;
    return PositionedDirectional(
      end: ChatSpace.md,
      bottom: ChatSpace.md,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, 1),
          duration: reduceMotion ? Duration.zero : ChatMotion.pill,
          child: AnimatedOpacity(
            opacity: visible ? ChatOpacity.full : 0,
            duration: reduceMotion ? Duration.zero : ChatMotion.pill,
            child: Semantics(
              button: true,
              label: label,
              child: Material(
                color: colors.primary,
                borderRadius: const BorderRadius.all(Radius.circular(ChatRadius.pill)),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: const BorderRadius.all(Radius.circular(ChatRadius.pill)),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: ChatSize.targetMin),
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: ChatSpace.md,
                      vertical: ChatSpace.sm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_downward, size: ChatSize.statusIcon, color: colors.onPrimary),
                        if (count > 0) ...[
                          const SizedBox(width: ChatSpace.sm),
                          Text(
                            label,
                            style: ChatType.meta(context)?.copyWith(color: colors.onPrimary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- composer ----------------------------------------------------------------

/// Bottom arc: attach · growing text field · send. Rides above the keyboard (the
/// parent lifts it via viewInsets) and above the home indicator via SafeArea
/// (CHAT-003, SPC-016). The field grows to a max height, then scrolls internally.
class _Composer extends StatelessWidget {
  const _Composer({
    required this.colors,
    required this.controller,
    required this.focusNode,
    required this.canSend,
    required this.onSend,
    required this.onAttach,
  });

  final ChatColors colors;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canSend;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: BorderDirectional(top: BorderSide(color: colors.outline)),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: ChatSpace.sm,
          vertical: ChatSpace.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Semantics(
              button: true,
              label: _Strings.attach,
              child: IconButton(
                onPressed: onAttach,
                tooltip: _Strings.attach,
                padding: const EdgeInsets.all(ChatSpace.sm),
                constraints: const BoxConstraints(
                  minWidth: ChatSize.targetMin,
                  minHeight: ChatSize.targetMin,
                ),
                iconSize: ChatSize.icon,
                color: colors.onSurfaceMuted,
                icon: const Icon(Icons.add),
              ),
            ),
            const SizedBox(width: ChatSpace.xs),
            Expanded(
              child: Semantics(
                textField: true,
                label: _Strings.composerLabel,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  minLines: 1,
                  maxLines: ChatSize.composerMaxLines,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  textCapitalization: TextCapitalization.sentences,
                  style: ChatType.body(context)?.copyWith(color: colors.onSurface),
                  decoration: InputDecoration(
                    hintText: _Strings.composerHint,
                    hintStyle: ChatType.body(context)?.copyWith(color: colors.onSurfaceMuted),
                    filled: true,
                    fillColor: colors.surfaceContainer,
                    isDense: true,
                    contentPadding: const EdgeInsetsDirectional.symmetric(
                      horizontal: ChatSpace.md,
                      vertical: ChatSpace.sm,
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(ChatRadius.field)),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(ChatRadius.field)),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(ChatRadius.field)),
                      borderSide: BorderSide(color: colors.focus, width: ChatSize.stroke),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: ChatSpace.xs),
            Semantics(
              button: true,
              enabled: canSend,
              label: _Strings.send,
              child: IconButton.filled(
                onPressed: canSend ? onSend : null,
                tooltip: _Strings.send,
                padding: const EdgeInsets.all(ChatSpace.sm),
                constraints: const BoxConstraints(
                  minWidth: ChatSize.targetMin,
                  minHeight: ChatSize.targetMin,
                ),
                iconSize: ChatSize.icon,
                style: IconButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  disabledBackgroundColor: colors.surfaceContainer,
                  disabledForegroundColor: colors.onSurfaceMuted,
                ),
                icon: const Icon(Icons.arrow_upward),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- state views: empty / loading / error ------------------------------------

/// First-use empty — a friendly prompt, not a blank list (STATE-002).
class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.colors});
  final ChatColors colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(ChatSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: ChatSize.icon, color: colors.onSurfaceMuted),
            const SizedBox(height: ChatSpace.md),
            Text(
              _Strings.emptyTitle,
              textAlign: TextAlign.center,
              style: ChatType.title(context)?.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: ChatSpace.sm),
            Text(
              _Strings.emptyBody,
              textAlign: TextAlign.center,
              style: ChatType.meta(context)?.copyWith(color: colors.onSurfaceMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton bubbles matching the loaded layout; reduce-motion-aware pulse
/// (STATE-005). Announced as loading.
class _SkeletonList extends StatelessWidget {
  const _SkeletonList({required this.colors, required this.reduceMotion});
  final ChatColors colors;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _Strings.loadingLabel,
      liveRegion: true,
      child: ListView.builder(
        reverse: true,
        padding: const EdgeInsetsDirectional.symmetric(vertical: ChatSpace.sm),
        itemCount: 8,
        itemBuilder: (context, index) => _SkeletonBubble(
          colors: colors,
          isSelf: index.isEven,
        ),
      ),
    );
  }
}

class _SkeletonBubble extends StatelessWidget {
  const _SkeletonBubble({required this.colors, required this.isSelf});
  final ChatColors colors;
  final bool isSelf;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: ChatSpace.md,
        start: ChatSpace.edge,
        end: ChatSpace.edge,
      ),
      child: Align(
        alignment: isSelf ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
        child: Opacity(
          opacity: ChatOpacity.skeleton,
          child: Container(
            width: MediaQuery.sizeOf(context).width * ChatSize.bubbleMaxFraction,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: ChatSpace.bubblePadH,
              vertical: ChatSpace.md,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: const BorderRadius.all(Radius.circular(ChatRadius.bubble)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonLine(colors: colors, widthFactor: ChatOpacity.full),
                const SizedBox(height: ChatSpace.sm),
                _SkeletonLine(colors: colors, widthFactor: ChatSize.bubbleMaxFraction),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.colors, required this.widthFactor});
  final ChatColors colors;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: widthFactor,
      child: Container(
        height: ChatSize.skeletonLine,
        decoration: BoxDecoration(
          color: colors.onSurfaceMuted,
          borderRadius: const BorderRadius.all(Radius.circular(ChatRadius.tail)),
        ),
      ),
    );
  }
}

/// Whole-screen error when nothing is cached — human message + retry, never a
/// dead end (STATE-007).
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.colors, required this.onRetry});
  final ChatColors colors;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(ChatSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: ChatSize.icon, color: colors.statusError),
            const SizedBox(height: ChatSpace.md),
            Text(
              _Strings.historyErrorTitle,
              textAlign: TextAlign.center,
              style: ChatType.title(context)?.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: ChatSpace.sm),
            Text(
              _Strings.historyErrorBody,
              textAlign: TextAlign.center,
              style: ChatType.meta(context)?.copyWith(color: colors.onSurfaceMuted),
            ),
            const SizedBox(height: ChatSpace.lg),
            FilledButton.tonal(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                minimumSize: const Size(ChatSize.targetMin, ChatSize.targetMin),
              ),
              child: const Text(_Strings.tryAgain),
            ),
          ],
        ),
      ),
    );
  }
}

/// Permission-denied fallback for attachments: explain, offer Settings + a file
/// fallback, never dead-end — the chat itself keeps working (STATE-010, PERM-004).
class _AttachDeniedSheet extends StatelessWidget {
  const _AttachDeniedSheet({
    required this.colors,
    required this.onOpenSettings,
    required this.onPickFile,
    required this.onDismiss,
  });

  final ChatColors colors;
  final VoidCallback onOpenSettings;
  final VoidCallback onPickFile;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        ChatSpace.lg,
        ChatSpace.sm,
        ChatSpace.lg,
        ChatSpace.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.image_not_supported_outlined, size: ChatSize.icon, color: colors.onSurfaceMuted),
          const SizedBox(height: ChatSpace.sm),
          Text(
            _Strings.attachTitle,
            style: ChatType.title(context)?.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: ChatSpace.sm),
          Text(
            _Strings.attachBody,
            style: ChatType.meta(context)?.copyWith(color: colors.onSurfaceMuted),
          ),
          const SizedBox(height: ChatSpace.lg),
          FilledButton(
            onPressed: onOpenSettings,
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              minimumSize: const Size(double.infinity, ChatSize.targetMin),
            ),
            child: const Text(_Strings.openSettings),
          ),
          const SizedBox(height: ChatSpace.sm),
          OutlinedButton(
            onPressed: onPickFile,
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.onSurface,
              side: BorderSide(color: colors.outline),
              minimumSize: const Size(double.infinity, ChatSize.targetMin),
            ),
            child: const Text(_Strings.pickFile),
          ),
          const SizedBox(height: ChatSpace.sm),
          TextButton(
            onPressed: onDismiss,
            style: TextButton.styleFrom(
              foregroundColor: colors.onSurface,
              minimumSize: const Size(double.infinity, ChatSize.targetMin),
            ),
            child: const Text(_Strings.keepChatting),
          ),
        ],
      ),
    );
  }
}

// --- status + formatting helpers ---------------------------------------------

/// Icon + label + accent for a delivery status. Text carries the meaning; the
/// accent is a redundant cue, never the sole one (A11Y-012).
class _StatusVisual {
  const _StatusVisual(this.icon, this.label, this.color);
  final IconData icon;
  final String label;
  final Color color;
}

_StatusVisual? _statusVisual(ChatMessage m, ChatColors colors) {
  switch (m.status) {
    case MessageStatus.sending:
      return _StatusVisual(Icons.schedule, _Strings.statusSending, m.isSelf ? colors.onSelfBubbleMuted : colors.onSurfaceMuted);
    case MessageStatus.queued:
      return _StatusVisual(Icons.cloud_queue, _Strings.statusQueued, m.isSelf ? colors.onSelfBubbleMuted : colors.onSurfaceMuted);
    case MessageStatus.sent:
      return _StatusVisual(Icons.check, _Strings.statusSent, m.isSelf ? colors.onSelfBubbleMuted : colors.statusInfo);
    case MessageStatus.delivered:
      return _StatusVisual(Icons.done_all, _Strings.statusDelivered, m.isSelf ? colors.onSelfBubbleMuted : colors.statusInfo);
    case MessageStatus.read:
      return _StatusVisual(Icons.done_all, _Strings.statusRead, colors.statusInfo);
    case MessageStatus.failed:
      return _StatusVisual(Icons.error_outline, _Strings.statusFailed, colors.statusError);
  }
}

String _semanticLabel(ChatMessage m) {
  final time = _formatTime(m.time);
  if (!m.isSelf) return '${m.author}, ${m.text}, $time';
  final status = switch (m.status) {
    MessageStatus.sending => _Strings.statusSending,
    MessageStatus.queued => _Strings.statusQueued,
    MessageStatus.sent => _Strings.statusSent,
    MessageStatus.delivered => _Strings.statusDelivered,
    MessageStatus.read => _Strings.statusRead,
    MessageStatus.failed => _Strings.statusFailed,
  };
  return '${_Strings.you}, ${m.text}, $time, $status';
}

String _formatTime(DateTime t) {
  final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final minute = t.minute.toString().padLeft(2, '0');
  final period = t.hour < 12 ? 'AM' : 'PM';
  return '$hour12:$minute $period';
}

String _formatDay(DateTime day) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final wd = weekdays[day.weekday - 1];
  return '$wd, ${months[day.month - 1]} ${day.day}';
}
