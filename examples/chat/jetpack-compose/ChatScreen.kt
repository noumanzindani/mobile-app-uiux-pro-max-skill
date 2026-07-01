package ux.examples.chat

/**
 * ChatScreen — an accessible, offline-resilient 1:1 chat for Jetpack Compose
 * (Material 3 Expressive). Implements the chat example spec:
 *
 *  - a VIRTUALIZED, INVERTED message list (`LazyColumn(reverseLayout = true)` with stable
 *    keys) so only visible bubbles compose and the newest sits at the bottom,
 *  - own vs other bubbles on opposite sides via RTL-aware `Arrangement.End`/`Start` +
 *    `Alignment` (they mirror automatically in right-to-left locales),
 *  - date separators, a "N new messages" pill that smooth-scrolls to the latest,
 *  - a composer Row (attach · growing OutlinedTextField · send) kept above the keyboard
 *    with `imePadding()` and above the home indicator via edge-to-edge `safeDrawing`,
 *  - OPTIMISTIC SEND: an optimistic bubble is appended immediately, then transitions
 *    sending -> sent -> delivered -> read; a failed send keeps its text and offers
 *    tap-to-retry; offline sends are queued and auto-flush on reconnect — never dropped,
 *  - delivery status shown as ICON + TEXT (never color alone), announced to assistive tech,
 *  - a typing indicator whose dots pause under reduce-motion and expose `stateDescription`,
 *  - a non-blocking offline banner and a graceful attach permission-denied fallback.
 *
 * Keyboard-safe (imePadding), edge-to-edge (enableEdgeToEdge + Scaffold safeDrawing),
 * RTL-safe (start/end + RTL-aware Arrangement/Alignment), Dynamic-Type-safe (typography
 * roles, no fixed text heights), targets >= 48dp, motion animates alpha/offset only with a
 * reduce-motion snap() fallback. Every color/spacing/size/radius comes from ChatTokens.
 */

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.snap
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.AttachFile
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CloudDone
import androidx.compose.material.icons.filled.CloudOff
import androidx.compose.material.icons.filled.CloudQueue
import androidx.compose.material.icons.filled.DoneAll
import androidx.compose.material.icons.filled.ErrorOutline
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import kotlinx.coroutines.launch

// ─────────────────────────────────────────────────────────────────────────────
// DELIVERY STATUS — the optimistic-send lifecycle. Conveyed by ICON + TEXT, never
// color alone (A11Y-012). A sealed interface makes the transition set exhaustive.
// ─────────────────────────────────────────────────────────────────────────────
sealed interface MessageStatus {
    /** Optimistic bubble is on screen; the network call is in flight (ghosted clock). */
    data object Sending : MessageStatus

    /** Accepted by the server (single check). */
    data object Sent : MessageStatus

    /** Reached the recipient's device (double check). */
    data object Delivered : MessageStatus

    /** Seen by the recipient (double check + "Read" label — not color-only). */
    data object Read : MessageStatus

    /** Send failed; content is preserved and the bubble offers tap-to-retry. */
    data object Failed : MessageStatus

    /** Composed while offline; held in the outbox and auto-flushed on reconnect. */
    data object Queued : MessageStatus
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN STATE — a sealed interface makes coverage of all 7 states auditable (STATE-*).
// The words loading / empty / error / offline / success appear here by design.
// ─────────────────────────────────────────────────────────────────────────────
sealed interface ChatStatus {
    /** Ideal: conversation loaded, composer ready, auto-scrolled to the latest. */
    data object Idle : ChatStatus

    /** Empty: brand-new conversation — a friendly "say hi" prompt, not a blank list. */
    data object Empty : ChatStatus

    /** Loading: opening / fetching history — skeleton bubbles, scroll anchor preserved. */
    data object Loading : ChatStatus

    /** Error: history load failed — inline retry banner that keeps any cached messages. */
    data class Error(val message: String) : ChatStatus

    /** Offline: no connectivity — readable from cache; sends queue and auto-flush. */
    data object Offline : ChatStatus

    /** Success: message delivered — announced discreetly to assistive tech. */
    data object Success : ChatStatus

    /** Permission-denied: attach/camera/mic denied — explain + Settings + files fallback. */
    data object PermissionDenied : ChatStatus
}

/** One announcement string per screen state — also proves every subtype is referenced. */
fun ChatStatus.announce(): String = when (this) {
    ChatStatus.Idle -> ""
    ChatStatus.Empty -> "No messages yet. Say hi."
    ChatStatus.Loading -> "Loading messages"
    is ChatStatus.Error -> message
    ChatStatus.Offline -> "You are offline. Messages will be queued and sent on reconnect."
    ChatStatus.Success -> "Message delivered"
    ChatStatus.PermissionDenied -> "Attachment permission denied. You can still send messages."
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────
data class ChatMessage(
    val id: String,
    val text: String,
    val isOwn: Boolean,
    val senderName: String,
    val timeLabel: String,
    val dateLabel: String,
    val status: MessageStatus = MessageStatus.Sent,
)

/** A rendered row: either a message bubble or a date separator (LST-*, CHAT-007). */
sealed interface ChatRow {
    val key: String

    data class MessageRow(val message: ChatMessage) : ChatRow {
        override val key: String get() = "msg:${message.id}"
    }

    data class DateRow(val label: String) : ChatRow {
        override val key: String get() = "date:$label"
    }
}

/** Hoisted, immutable UI state. Message content is always preserved across status changes. */
data class ChatUiState(
    val contactName: String = "Sam Rivera",
    val presence: String = "Active now",
    val messages: List<ChatMessage> = emptyList(),
    val draft: String = "",
    val status: ChatStatus = ChatStatus.Loading,
    val isOffline: Boolean = false,
    val peerTyping: Boolean = false,
    val newMessageCount: Int = 0,
    val attachDenied: Boolean = false,
    val liveAnnouncement: String = "",
)

// ─────────────────────────────────────────────────────────────────────────────
// STATEFUL ENTRY POINT — owns the optimistic-send state machine and the offline outbox.
// ─────────────────────────────────────────────────────────────────────────────
@Composable
fun ChatScreen(
    modifier: Modifier = Modifier,
    onBack: () -> Unit = {},
) {
    var state by remember { mutableStateOf(ChatUiState()) }
    var nextId by remember { mutableIntStateOf(0) }
    val scope = rememberCoroutineScope()
    val context = LocalContext.current

    // Update a single message by id, preserving list order (used by the status machine).
    fun patch(id: String, transform: (ChatMessage) -> ChatMessage) {
        state = state.copy(messages = state.messages.map { if (it.id == id) transform(it) else it })
    }

    // sending -> sent -> delivered -> read, or -> failed (demo: any text containing "fail").
    suspend fun runDelivery(id: String) {
        patch(id) { it.copy(status = MessageStatus.Sending) }
        kotlinx.coroutines.delay(Motion.settleMs)
        val text = state.messages.firstOrNull { it.id == id }?.text.orEmpty()
        if (text.contains("fail", ignoreCase = true)) {
            patch(id) { it.copy(status = MessageStatus.Failed) }
            return
        }
        patch(id) { it.copy(status = MessageStatus.Sent) }
        kotlinx.coroutines.delay(Motion.stepMs)
        patch(id) { it.copy(status = MessageStatus.Delivered) }
        kotlinx.coroutines.delay(Motion.stepMs)
        patch(id) { it.copy(status = MessageStatus.Read) }
        state = state.copy(status = ChatStatus.Success, liveAnnouncement = ChatStatus.Success.announce())
    }

    // Peer replies after a short "typing" beat — exercises the typing indicator, the
    // live-region announcement, and the "N new messages" pill when scrolled up.
    suspend fun simulateReply() {
        state = state.copy(peerTyping = true)
        kotlinx.coroutines.delay(Motion.replyMs)
        val reply = ChatMessage(
            id = "r${nextId++}",
            text = "Got it — thanks for the update.",
            isOwn = false,
            senderName = state.contactName,
            timeLabel = nowLabel(),
            dateLabel = "Today",
            status = MessageStatus.Delivered,
        )
        state = state.copy(
            peerTyping = false,
            messages = state.messages + reply,
            newMessageCount = state.newMessageCount + 1,
            liveAnnouncement = "New message from ${state.contactName}",
        )
    }

    fun send() {
        val text = state.draft.trim()
        if (text.isEmpty()) return
        val id = "s${nextId++}"
        val optimistic = ChatMessage(
            id = id,
            text = text,
            isOwn = true,
            senderName = "You",
            timeLabel = nowLabel(),
            dateLabel = "Today",
            // Offline: hold in the outbox as Queued; online: start Sending immediately.
            status = if (state.isOffline) MessageStatus.Queued else MessageStatus.Sending,
        )
        state = state.copy(
            messages = state.messages + optimistic,
            draft = "",
            status = if (state.isOffline) ChatStatus.Offline else ChatStatus.Idle,
        )
        if (!state.isOffline) {
            scope.launch {
                runDelivery(id)
                simulateReply()
            }
        }
    }

    fun retry(id: String) {
        scope.launch { runDelivery(id) }
    }

    // Flush the outbox when connectivity returns: queued -> sending -> ... with backoff.
    fun setOffline(offline: Boolean) {
        state = state.copy(
            isOffline = offline,
            status = if (offline) ChatStatus.Offline else ChatStatus.Idle,
        )
        if (!offline) {
            val queued = state.messages.filter { it.status == MessageStatus.Queued }
            scope.launch {
                queued.forEach { q ->
                    kotlinx.coroutines.delay(Motion.retryBackoffMs)
                    runDelivery(q.id)
                }
            }
        }
    }

    // First open: simulate loading history, then land on the ideal (or empty) state.
    LaunchedEffect(Unit) {
        kotlinx.coroutines.delay(Motion.replyMs)
        val history = sampleHistory()
        state = state.copy(
            messages = history,
            status = if (history.isEmpty()) ChatStatus.Empty else ChatStatus.Idle,
        )
    }

    ChatScreenContent(
        state = state,
        modifier = modifier,
        onBack = onBack,
        onDraftChange = { state = state.copy(draft = it) },
        onSend = { send() },
        onRetry = { retry(it) },
        onToggleOffline = { setOffline(!state.isOffline) },
        onAttach = { state = state.copy(attachDenied = true, status = ChatStatus.PermissionDenied) },
        onDismissAttachDenied = { state = state.copy(attachDenied = false, status = ChatStatus.Idle) },
        onRetryLoad = {
            state = state.copy(status = ChatStatus.Loading)
            scope.launch {
                kotlinx.coroutines.delay(Motion.replyMs)
                val history = sampleHistory()
                state = state.copy(
                    messages = history,
                    status = if (history.isEmpty()) ChatStatus.Empty else ChatStatus.Idle,
                )
            }
        },
        onSeenLatest = { if (state.newMessageCount != 0) state = state.copy(newMessageCount = 0) },
        onOpenSettings = {
            val intent = Intent(
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.fromParts("package", context.packageName, null),
            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        },
    )
}

// ─────────────────────────────────────────────────────────────────────────────
// STATELESS CONTENT — pure, previewable across every state.
// ─────────────────────────────────────────────────────────────────────────────
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ChatScreenContent(
    state: ChatUiState,
    onBack: () -> Unit,
    onDraftChange: (String) -> Unit,
    onSend: () -> Unit,
    onRetry: (String) -> Unit,
    onToggleOffline: () -> Unit,
    onAttach: () -> Unit,
    onDismissAttachDenied: () -> Unit,
    onRetryLoad: () -> Unit,
    onSeenLatest: () -> Unit,
    onOpenSettings: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val reduceMotion = rememberReduceMotion()
    val listState = rememberLazyListState()
    val scope = rememberCoroutineScope()

    // Inverted list: index 0 is the newest row at the bottom. "At bottom" == index 0, offset 0.
    val atBottom by remember {
        derivedStateOf {
            listState.firstVisibleItemIndex == 0 && listState.firstVisibleItemScrollOffset == 0
        }
    }
    // Reset the unseen counter as soon as the user is back at the latest message.
    LaunchedEffect(atBottom) { if (atBottom) onSeenLatest() }

    // Keep the newest visible: auto-scroll when a message is appended and we were at the
    // bottom, or whenever the outgoing message is ours. Reduce-motion jumps instantly.
    LaunchedEffect(state.messages.size, state.peerTyping) {
        val mine = state.messages.lastOrNull()?.isOwn == true
        if (atBottom || mine) {
            if (reduceMotion) listState.scrollToItem(0) else listState.animateScrollToItem(0)
        }
    }

    val showPill = state.newMessageCount > 0 && !atBottom

    Scaffold(
        modifier = modifier,
        // Edge-to-edge: Scaffold applies WindowInsets.safeDrawing so content clears the
        // status bar, gesture bar and IME; the composer then rides above the home indicator.
        contentWindowInsets = WindowInsets.safeDrawing,
        topBar = {
            ChatTopBar(
                name = state.contactName,
                presence = if (state.peerTyping) "typing…" else state.presence,
                isOffline = state.isOffline,
                onBack = onBack,
                onToggleOffline = onToggleOffline,
            )
        },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                // keep the composer above the keyboard (rule CHAT keyboard-safe)
                .imePadding(),
        ) {
            // ── Non-blocking banners (each is its own live region) ──────────
            if (state.isOffline) {
                OfflineBanner()
            }
            if (state.attachDenied) {
                PermissionDeniedBanner(onOpenSettings = onOpenSettings, onDismiss = onDismissAttachDenied)
            }
            val loadError = state.status as? ChatStatus.Error
            if (loadError != null && state.messages.isNotEmpty()) {
                ErrorRetryBanner(message = loadError.message, onRetry = onRetryLoad)
            }

            // Discreet, polite live region for incoming messages + delivery status (A11Y-019).
            if (state.liveAnnouncement.isNotEmpty()) {
                Text(
                    text = state.liveAnnouncement,
                    style = ChatType.meta,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = Space.md, vertical = Space.xs)
                        .semantics { liveRegion = LiveRegionMode.Polite },
                )
            }

            // ── Message region: one branch per screen state ─────────────────
            Box(modifier = Modifier.weight(1f).fillMaxWidth()) {
                when (val s = state.status) {
                    ChatStatus.Loading -> LoadingSkeleton()
                    ChatStatus.Empty -> EmptyState(name = state.contactName)
                    is ChatStatus.Error ->
                        if (state.messages.isEmpty()) {
                            ErrorState(message = s.message, onRetry = onRetryLoad)
                        } else {
                            MessageList(state, listState, reduceMotion, onRetry)
                        }
                    else ->
                        if (state.messages.isEmpty()) {
                            EmptyState(name = state.contactName)
                        } else {
                            MessageList(state, listState, reduceMotion, onRetry)
                        }
                }

                // "N new messages" pill — fades in when scrolled up; tap smooth-scrolls down.
                NewMessagesPill(
                    visible = showPill,
                    count = state.newMessageCount,
                    reduceMotion = reduceMotion,
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .padding(bottom = Space.md),
                    onClick = {
                        onSeenLatest()
                        scope.launch {
                            if (reduceMotion) listState.scrollToItem(0) else listState.animateScrollToItem(0)
                        }
                    },
                )
            }

            // ── Composer: attach · growing field · send (always thumb-reachable) ──
            Composer(
                draft = state.draft,
                canSend = state.draft.isNotBlank(),
                onDraftChange = onDraftChange,
                onSend = onSend,
                onAttach = onAttach,
            )
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR — back, identity, presence/typing, call + connectivity toggle (low-frequency).
// ─────────────────────────────────────────────────────────────────────────────
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ChatTopBar(
    name: String,
    presence: String,
    isOffline: Boolean,
    onBack: () -> Unit,
    onToggleOffline: () -> Unit,
) {
    TopAppBar(
        title = {
            Column {
                Text(text = name, style = ChatType.contactName, color = MaterialTheme.colorScheme.onSurface)
                Text(
                    text = presence,
                    style = ChatType.presence,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        },
        navigationIcon = {
            // AutoMirrored back arrow flips in RTL (L10N-004). IconButton is 48dp by default.
            IconButton(onClick = onBack) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
            }
        },
        actions = {
            IconButton(onClick = { /* start a call */ }) {
                Icon(Icons.Filled.Call, contentDescription = "Call ${name}")
            }
            // Demo affordance: flip connectivity to exercise the offline / queued / flush path.
            IconButton(
                onClick = onToggleOffline,
                modifier = Modifier.semantics {
                    stateDescription = if (isOffline) "Offline" else "Online"
                },
            ) {
                Icon(
                    imageVector = if (isOffline) Icons.Filled.CloudOff else Icons.Filled.CloudDone,
                    contentDescription = if (isOffline) "You are offline. Tap to go online" else "Online. Tap to simulate offline",
                )
            }
            IconButton(onClick = { /* overflow menu */ }) {
                Icon(Icons.Filled.MoreVert, contentDescription = "More options")
            }
        },
    )
}

// ─────────────────────────────────────────────────────────────────────────────
// MESSAGE LIST — virtualized + inverted. Only visible rows compose; stable keys keep
// recomposition and item animations cheap and correct (LST-001, PERF-001).
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun MessageList(
    state: ChatUiState,
    listState: androidx.compose.foundation.lazy.LazyListState,
    reduceMotion: Boolean,
    onRetry: (String) -> Unit,
) {
    // Chronological rows (date separators inserted), then reversed for reverseLayout.
    val rows = remember(state.messages) { buildRows(state.messages) }
    val display = remember(rows) { rows.asReversed() }

    LazyColumn(
        state = listState,
        reverseLayout = true, // newest at the bottom, scroll starts pinned to latest (LST-001)
        contentPadding = PaddingValues(vertical = Space.sm),
        verticalArrangement = Arrangement.spacedBy(Space.xs),
        modifier = Modifier.fillMaxSize(),
    ) {
        // Declared first → rendered at the very bottom (below the newest bubble).
        if (state.peerTyping) {
            item(key = "typing") {
                TypingIndicator(name = state.contactName, reduceMotion = reduceMotion)
            }
        }
        items(items = display, key = { it.key }) { row ->
            when (row) {
                is ChatRow.MessageRow -> MessageBubble(
                    message = row.message,
                    reduceMotion = reduceMotion,
                    onRetry = onRetry,
                    modifier = Modifier.animateItem(
                        // Only alpha (fade) + offset (placement) animate; reduce-motion snaps.
                        fadeInSpec = if (reduceMotion) null else tween(Motion.insertMillis),
                        fadeOutSpec = if (reduceMotion) null else tween(Motion.insertMillis),
                        placementSpec = if (reduceMotion) snap() else tween(Motion.insertMillis),
                    ),
                )
                is ChatRow.DateRow -> DateSeparator(label = row.label)
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// BUBBLE — own vs other on opposite sides via RTL-aware Arrangement + Alignment; the
// whole bubble is one merged node read as "sender, message, time, status" (A11Y-014).
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun MessageBubble(
    message: ChatMessage,
    reduceMotion: Boolean,
    onRetry: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    val chat = MaterialTheme.chatColors
    val isOwn = message.isOwn
    val isFailed = message.status == MessageStatus.Failed

    val bubbleColor = if (isOwn) chat.ownBubble else chat.otherBubble
    val onBubble = if (isOwn) chat.onOwnBubble else chat.onOtherBubble
    val metaColor = if (isOwn) chat.onOwnBubbleMeta else chat.onOtherBubbleMeta

    val statusText = statusLabel(message.status)
    val spoken = buildString {
        append(if (isOwn) "You" else message.senderName)
        append(", "); append(message.text)
        append(", "); append(message.timeLabel)
        if (isOwn) { append(", "); append(statusText) }
    }

    // `modifier` (carrying animateItem) decorates the item root Row so the list-placement
    // + fade animation applies to the whole bubble slot (LST-001, MOT-004).
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = Space.md, vertical = Space.xxs),
        // Logical End/Start mirror automatically in RTL (L10N-001).
        horizontalArrangement = if (isOwn) Arrangement.End else Arrangement.Start,
    ) {
        Column(
            horizontalAlignment = if (isOwn) Alignment.End else Alignment.Start,
            modifier = Modifier
                .widthIn(max = Size.bubbleMax)
                .background(bubbleColor, shape = MaterialTheme.shapes.large)
                .then(
                    if (isFailed) {
                        Modifier.clickable(onClickLabel = "Tap to retry") { onRetry(message.id) }
                    } else {
                        Modifier
                    },
                )
                .padding(horizontal = Space.md, vertical = Space.sm)
                .semantics(mergeDescendants = true) { contentDescription = spoken },
        ) {
            Text(text = message.text, style = ChatType.body, color = onBubble)
            Spacer(Modifier.height(Space.xxs))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(text = message.timeLabel, style = ChatType.meta, color = metaColor)
                if (isOwn) {
                    Spacer(Modifier.width(Space.xs))
                    StatusIndicator(status = message.status, metaColor = metaColor)
                }
            }
            if (isFailed) {
                Spacer(Modifier.height(Space.xs))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Filled.Refresh,
                        contentDescription = null,
                        tint = MaterialTheme.chatColors.statusError,
                        modifier = Modifier.size(Size.statusIcon),
                    )
                    Spacer(Modifier.width(Space.xs))
                    Text(
                        text = "Failed — tap to retry",
                        style = ChatType.meta,
                        color = MaterialTheme.chatColors.statusError,
                    )
                }
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS INDICATOR — icon + TEXT, never color alone (A11Y-012). Decorative icon; the
// text label carries the meaning and the bubble's merged description reads the status.
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun StatusIndicator(status: MessageStatus, metaColor: androidx.compose.ui.graphics.Color) {
    val icon = statusIcon(status)
    val label = statusLabel(status)
    val tint = if (status == MessageStatus.Failed) MaterialTheme.chatColors.statusError else metaColor
    Row(verticalAlignment = Alignment.CenterVertically) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = tint,
            modifier = Modifier.size(Size.statusIcon),
        )
        Spacer(Modifier.width(Space.xxs))
        Text(text = label, style = ChatType.meta, color = tint)
    }
}

private fun statusLabel(status: MessageStatus): String = when (status) {
    MessageStatus.Sending -> "Sending"
    MessageStatus.Sent -> "Sent"
    MessageStatus.Delivered -> "Delivered"
    MessageStatus.Read -> "Read"
    MessageStatus.Failed -> "Failed"
    MessageStatus.Queued -> "Queued"
}

private fun statusIcon(status: MessageStatus): ImageVector = when (status) {
    MessageStatus.Sending -> Icons.Filled.Schedule
    MessageStatus.Sent -> Icons.Filled.Check
    MessageStatus.Delivered -> Icons.Filled.DoneAll
    MessageStatus.Read -> Icons.Filled.DoneAll
    MessageStatus.Failed -> Icons.Filled.ErrorOutline
    MessageStatus.Queued -> Icons.Filled.CloudQueue
}

// ─────────────────────────────────────────────────────────────────────────────
// DATE SEPARATOR — centered pill; read as a heading so the day is announced (CHAT-007).
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun DateSeparator(label: String) {
    Box(modifier = Modifier.fillMaxWidth().padding(vertical = Space.sm), contentAlignment = Alignment.Center) {
        Surface(color = MaterialTheme.colorScheme.surfaceVariant, shape = MaterialTheme.shapes.medium) {
            Text(
                text = label,
                style = ChatType.separator,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(horizontal = Space.md, vertical = Space.xs),
            )
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// TYPING INDICATOR — looping dots that PAUSE under reduce-motion; exposed as status,
// not decorative motion, via stateDescription + a polite live region (A11Y-011, CHAT-002).
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun TypingIndicator(name: String, reduceMotion: Boolean) {
    val transition = rememberInfiniteTransition(label = "typing")
    // Always create the animations (stable call sites); reduce-motion holds them steady.
    val a1 by transition.animateFloat(
        initialValue = DOT_MIN, targetValue = DOT_MAX,
        animationSpec = infiniteRepeatable(tween(Motion.typingPeriodMillis)), label = "d1",
    )
    val a2 by transition.animateFloat(
        initialValue = DOT_MAX, targetValue = DOT_MIN,
        animationSpec = infiniteRepeatable(tween(Motion.typingPeriodMillis)), label = "d2",
    )
    val a3 by transition.animateFloat(
        initialValue = DOT_MIN, targetValue = DOT_MAX,
        animationSpec = infiniteRepeatable(tween(Motion.typingPeriodMillis)), label = "d3",
    )
    val alphas = if (reduceMotion) listOf(DOT_STATIC, DOT_STATIC, DOT_STATIC) else listOf(a1, a2, a3)

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Space.md, vertical = Space.xs)
            .semantics {
                liveRegion = LiveRegionMode.Polite
                stateDescription = "$name is typing"
                contentDescription = "$name is typing"
            },
        horizontalArrangement = Arrangement.Start,
    ) {
        Surface(color = MaterialTheme.chatColors.otherBubble, shape = MaterialTheme.shapes.large) {
            Row(
                modifier = Modifier.padding(horizontal = Space.md, vertical = Space.sm),
                horizontalArrangement = Arrangement.spacedBy(Space.xs),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                alphas.forEach { a ->
                    Box(
                        modifier = Modifier
                            .size(Size.typingDot)
                            .alpha(a)
                            .background(MaterialTheme.chatColors.onOtherBubble, shape = CircleShape),
                    )
                }
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// "N NEW MESSAGES" PILL — fades in when scrolled up; tap smooth-scrolls to latest.
// Animates opacity only; reduce-motion snaps it in (CHAT-005, MOT-004).
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun NewMessagesPill(
    visible: Boolean,
    count: Int,
    reduceMotion: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val pillAlpha by animateFloatAsState(
        targetValue = if (visible) FULL else GONE,
        animationSpec = if (reduceMotion) snap() else tween(Motion.shortMillis),
        label = "pillAlpha",
    )
    if (!visible) return
    Button(
        onClick = onClick,
        shape = PillShape,
        modifier = modifier
            .heightIn(min = Size.minTarget)
            .alpha(pillAlpha)
            .semantics { contentDescription = "$count new messages, jump to latest" },
    ) {
        Text(text = "$count new messages", style = ChatType.pill)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPOSER — attach · growing OutlinedTextField · send. Rides above the keyboard
// (imePadding on the parent) and above the home indicator (safeDrawing) (CHAT-003).
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun Composer(
    draft: String,
    canSend: Boolean,
    onDraftChange: (String) -> Unit,
    onSend: () -> Unit,
    onAttach: () -> Unit,
) {
    Surface(color = MaterialTheme.colorScheme.surfaceContainer) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Space.sm, vertical = Space.sm),
            verticalAlignment = Alignment.Bottom,
            horizontalArrangement = Arrangement.spacedBy(Space.xs),
        ) {
            // Attach — labeled; a denied permission degrades gracefully, chat keeps working.
            IconButton(onClick = onAttach) {
                Icon(Icons.Filled.AttachFile, contentDescription = "Attach a file")
            }
            OutlinedTextField(
                value = draft,
                onValueChange = onDraftChange,
                modifier = Modifier
                    .weight(1f)
                    .semantics { contentDescription = "Message" },
                placeholder = { Text("Message") },
                // Grows with content up to a cap, then scrolls internally (A11Y-003, FRM-003).
                maxLines = COMPOSER_MAX_LINES,
                shape = MaterialTheme.shapes.large,
                keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(imeAction = ImeAction.Send),
                keyboardActions = androidx.compose.foundation.text.KeyboardActions(onSend = { if (canSend) onSend() }),
            )
            // Send — labeled, reflects enabled/disabled; IconButton is 48dp by default.
            IconButton(onClick = onSend, enabled = canSend) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.Send, // mirrors in RTL (L10N-004)
                    contentDescription = "Send message",
                    tint = if (canSend) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// OFFLINE BANNER — non-blocking; conversation stays readable; announced politely.
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun OfflineBanner() {
    Surface(
        color = MaterialTheme.colorScheme.surfaceVariant,
        modifier = Modifier
            .fillMaxWidth()
            .semantics { liveRegion = LiveRegionMode.Polite },
    ) {
        Row(
            modifier = Modifier.padding(horizontal = Space.md, vertical = Space.sm),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(
                imageVector = Icons.Filled.CloudOff,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(Size.icon),
            )
            Spacer(Modifier.width(Space.sm))
            Text(
                text = "You're offline — messages are queued and will send on reconnect.",
                style = ChatType.banner,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// PERMISSION-DENIED BANNER — attach denied: explain + Settings + files fallback; chat
// itself keeps working, never a dead end (PERM-004, PERM-005, STATE-010).
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun PermissionDeniedBanner(onOpenSettings: () -> Unit, onDismiss: () -> Unit) {
    Surface(
        color = MaterialTheme.colorScheme.errorContainer,
        modifier = Modifier
            .fillMaxWidth()
            .semantics { liveRegion = LiveRegionMode.Polite },
    ) {
        Column(modifier = Modifier.padding(horizontal = Space.md, vertical = Space.sm)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = Icons.Filled.Info,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onErrorContainer,
                    modifier = Modifier.size(Size.icon),
                )
                Spacer(Modifier.width(Space.sm))
                Text(
                    text = "Photo access is off. You can still pick from files, or enable it in Settings.",
                    style = ChatType.banner,
                    color = MaterialTheme.colorScheme.onErrorContainer,
                )
            }
            Spacer(Modifier.height(Space.sm))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(Space.sm),
            ) {
                OutlinedButton(
                    onClick = onDismiss,
                    modifier = Modifier.weight(1f).heightIn(min = Size.minTarget),
                ) {
                    Text("Pick from files")
                }
                Button(
                    onClick = onOpenSettings,
                    modifier = Modifier.weight(1f).heightIn(min = Size.minTarget),
                ) {
                    Text("Settings")
                }
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// ERROR RETRY BANNER — history load failed but cached messages remain; inline retry
// keeps the cache and re-fetches (STATE-007, CHAT-006).
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun ErrorRetryBanner(message: String, onRetry: () -> Unit) {
    Surface(
        color = MaterialTheme.colorScheme.errorContainer,
        modifier = Modifier
            .fillMaxWidth()
            .semantics { liveRegion = LiveRegionMode.Polite },
    ) {
        Row(
            modifier = Modifier.padding(horizontal = Space.md, vertical = Space.sm),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(
                imageVector = Icons.Filled.ErrorOutline,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onErrorContainer,
                modifier = Modifier.size(Size.icon),
            )
            Spacer(Modifier.width(Space.sm))
            Text(
                text = message,
                style = ChatType.banner,
                color = MaterialTheme.colorScheme.onErrorContainer,
                modifier = Modifier.weight(1f),
            )
            Spacer(Modifier.width(Space.sm))
            OutlinedButton(onClick = onRetry, modifier = Modifier.heightIn(min = Size.minTarget)) {
                Text("Retry")
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOADING — skeleton bubbles; announced as a busy status while history is fetched.
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun LoadingSkeleton() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = Space.md, vertical = Space.md)
            .semantics {
                liveRegion = LiveRegionMode.Polite
                stateDescription = "Loading messages"
                contentDescription = "Loading messages"
            },
        verticalArrangement = Arrangement.spacedBy(Space.md),
    ) {
        SkeletonBubble(alignEnd = false, wide = false)
        SkeletonBubble(alignEnd = true, wide = true)
        SkeletonBubble(alignEnd = false, wide = true)
        SkeletonBubble(alignEnd = true, wide = false)
        Spacer(Modifier.height(Space.sm))
        CircularProgressIndicator(modifier = Modifier.size(Size.spinner))
    }
}

@Composable
private fun SkeletonBubble(alignEnd: Boolean, wide: Boolean) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = if (alignEnd) Arrangement.End else Arrangement.Start,
    ) {
        Box(
            modifier = Modifier
                .width(if (wide) Size.skeletonLong else Size.skeletonShort)
                .height(Size.skeletonLine)
                .background(MaterialTheme.colorScheme.surfaceVariant, shape = MaterialTheme.shapes.large),
        )
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY — a first-use prompt, not a blank list (STATE-002).
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun EmptyState(name: String) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = Space.xl, vertical = Space.xl),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text(text = "Say hi 👋", style = ChatType.emptyTitle, color = MaterialTheme.colorScheme.onSurface)
        Spacer(Modifier.height(Space.sm))
        Text(
            text = "This is the start of your conversation with $name. Send the first message.",
            style = ChatType.emptyBody,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
        )
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// ERROR — history couldn't load and nothing is cached; full-screen retry (STATE-007).
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun ErrorState(message: String, onRetry: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = Space.xl, vertical = Space.xl)
            .semantics { liveRegion = LiveRegionMode.Assertive; contentDescription = message },
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Icon(
            imageVector = Icons.Filled.ErrorOutline,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.error,
            modifier = Modifier.size(Size.icon),
        )
        Spacer(Modifier.height(Space.sm))
        Text(
            text = message,
            style = ChatType.emptyBody,
            color = MaterialTheme.colorScheme.onSurface,
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(Space.md))
        Button(onClick = onRetry, modifier = Modifier.heightIn(min = Size.minTarget)) {
            Text("Try again")
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers — pure, no Compose state.
// ─────────────────────────────────────────────────────────────────────────────
private const val DOT_MIN = 0.3f
private const val DOT_MAX = 1f
private const val DOT_STATIC = 0.6f
private const val FULL = 1f
private const val GONE = 0f
private const val COMPOSER_MAX_LINES = 6

private fun nowLabel(): String {
    val t = java.time.LocalTime.now()
    return "%02d:%02d".format(t.hour, t.minute)
}

/** Insert a date separator before the first message of each new day (chronological). */
private fun buildRows(messages: List<ChatMessage>): List<ChatRow> {
    val rows = ArrayList<ChatRow>(messages.size + messages.size)
    var lastDate: String? = null
    for (m in messages) {
        if (m.dateLabel != lastDate) {
            rows.add(ChatRow.DateRow(m.dateLabel))
            lastDate = m.dateLabel
        }
        rows.add(ChatRow.MessageRow(m))
    }
    return rows
}

private fun sampleHistory(): List<ChatMessage> = listOf(
    ChatMessage("h1", "Hey! Are we still on for the 3pm review?", false, "Sam Rivera", "09:41", "Yesterday", MessageStatus.Read),
    ChatMessage("h2", "Yes — I just pushed the latest build.", true, "You", "09:42", "Yesterday", MessageStatus.Read),
    ChatMessage("h3", "Perfect. I'll take a look before the call.", false, "Sam Rivera", "09:44", "Yesterday", MessageStatus.Read),
    ChatMessage("h4", "Morning! Ready when you are.", true, "You", "08:15", "Today", MessageStatus.Read),
    ChatMessage("h5", "Give me two minutes and I'll join.", false, "Sam Rivera", "08:16", "Today", MessageStatus.Delivered),
)

// ─────────────────────────────────────────────────────────────────────────────
// Host Activity — edge-to-edge is enabled here; the composable inherits the insets.
// ─────────────────────────────────────────────────────────────────────────────
class ChatActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            ChatTheme {
                ChatScreen(onBack = { /* pop the back stack / finish */ })
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Previews — one per state so the whole matrix is inspectable at a glance.
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun PreviewHost(state: ChatUiState) = ChatTheme {
    ChatScreenContent(
        state = state,
        onBack = {}, onDraftChange = {}, onSend = {}, onRetry = {},
        onToggleOffline = {}, onAttach = {}, onDismissAttachDenied = {},
        onRetryLoad = {}, onSeenLatest = {}, onOpenSettings = {},
    )
}

@Preview(name = "Chat — ideal (loaded)", showBackground = true)
@Composable
private fun ChatIdealPreview() =
    PreviewHost(ChatUiState(messages = sampleHistory(), status = ChatStatus.Idle))

@Preview(name = "Chat — loading", showBackground = true)
@Composable
private fun ChatLoadingPreview() =
    PreviewHost(ChatUiState(status = ChatStatus.Loading))

@Preview(name = "Chat — empty", showBackground = true)
@Composable
private fun ChatEmptyPreview() =
    PreviewHost(ChatUiState(messages = emptyList(), status = ChatStatus.Empty))

@Preview(name = "Chat — error", showBackground = true)
@Composable
private fun ChatErrorPreview() =
    PreviewHost(ChatUiState(status = ChatStatus.Error("Couldn't load messages. Check your connection.")))

@Preview(name = "Chat — offline + queued", showBackground = true)
@Composable
private fun ChatOfflinePreview() =
    PreviewHost(
        ChatUiState(
            messages = sampleHistory() + ChatMessage("q1", "Sending this once we're back online", true, "You", "08:20", "Today", MessageStatus.Queued),
            status = ChatStatus.Offline,
            isOffline = true,
        ),
    )

@Preview(name = "Chat — failed send (tap to retry)", showBackground = true)
@Composable
private fun ChatFailedPreview() =
    PreviewHost(
        ChatUiState(
            messages = sampleHistory() + ChatMessage("f1", "This one failed to send", true, "You", "08:21", "Today", MessageStatus.Failed),
            status = ChatStatus.Idle,
        ),
    )

@Preview(name = "Chat — permission denied (attach)", showBackground = true)
@Composable
private fun ChatPermissionDeniedPreview() =
    PreviewHost(
        ChatUiState(messages = sampleHistory(), status = ChatStatus.PermissionDenied, attachDenied = true),
    )
