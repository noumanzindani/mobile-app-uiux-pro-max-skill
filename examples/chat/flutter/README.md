# Chat — Flutter reference implementation

A real, compiling Flutter build of the chat spec in [`../spec.md`](../spec.md).
Reliability-first messaging: optimistic send with a full delivery lifecycle, an
offline outbox that auto-flushes on reconnect, correct keyboard + safe-area
handling, a virtualized inverted list, and complete accessibility — **100 % token
driven** so a rebrand or dark-mode swap is a token change, not a refactor.

| File | Role |
|---|---|
| `chat_tokens.dart` | The semantic token layer — color / spacing / radius / size / opacity / motion / typography. The **only** file allowed raw values (each raw line ends with `// ux:ignore`). Own/other bubble colors ship as fg+bg pairs that meet **≥ 4.5:1** in both themes. |
| `chat_screen.dart` | The `ChatScreen` widget — all 7 states, delivery lifecycle, offline queue, keyboard avoidance, RTL-safe alignment, a11y. References tokens only. |

Verified on **Flutter 3.41 / Dart 3** (`flutter analyze` clean) and scores
**100/100** on `quality-checks/validators/run_all.py`.

## What it demonstrates

**All 7 states** via `enum ChatStatus { idle, empty, loading, error, offline,
success, permissionDenied }`:

- **idle** — grouped bubbles by sender + time, read receipts, composer ready,
  auto-scrolled to the latest.
- **empty** — a friendly first-message prompt ("Say hi 👋"), not a blank list.
- **loading** — skeleton bubbles matching the loaded layout; **pull-up loads
  older** messages with a top spinner that preserves the scroll anchor.
- **error** — history-load failure shows a non-blocking inline **retry banner
  that keeps cached messages**; with nothing cached it becomes a full error view.
  Per-message send failure is handled on the bubble (below).
- **offline** — non-blocking live-region banner; the conversation stays readable
  and sends are **queued**, then **auto-flushed with backoff on reconnect** —
  never dropped.
- **success** — the optimistic bubble transitions
  `sending → sent → delivered → read`; "delivered/read" is announced discreetly.
- **permissionDenied** — an attach permission denial opens a sheet that explains,
  offers **Open Settings** and a **Pick from files** fallback, and never
  dead-ends — the chat keeps working.

**Optimistic-send lifecycle** — `enum MessageStatus { sending, sent, delivered,
read, failed, queued }`:

- On send, an optimistic bubble appears **immediately**, ghosted (`sending`), then
  transitions as the network acks it.
- **Failed** send keeps the message content and shows a **badge + tap-to-retry**
  (retry re-sends the preserved text; nothing is silently dropped).
- **Offline** sends are `queued`; on reconnect the outbox flushes with a backoff
  delay between messages.
- Status is conveyed by **icon + text** (clock / check / double-check / error),
  **never color alone**, and is included in each bubble's screen-reader label.

**List & composer:**

- **Virtualized, inverted** `ListView.builder(reverse: true)` — newest pinned to
  the bottom, so pull-**up** naturally loads history.
- Messages **grouped by sender**: sender name shown once per group, tighter gaps
  within a group (`space.2`) and larger gaps between groups (`space.4`); the
  last bubble in a group gets a flattened tail corner.
- Own vs other bubbles align to **opposite sides via `AlignmentDirectional`** and
  logical `BorderRadiusDirectional`, so they **mirror in RTL**.
- **Date separators** between days (Today / Yesterday / weekday).
- A **"N new messages" pill** fades/slides in when you're scrolled up; tapping it
  smooth-scrolls to the latest.
- The **composer** (attach · growing field · send) grows to 5 lines then scrolls
  internally, and rides **above the keyboard** (`MediaQuery.viewInsetsOf`) and
  **above the home indicator** when the keyboard is dismissed (`SafeArea`).

**Accessibility (WCAG 2.2):**

- Each bubble is a **grouped Semantics node** read as "sender, message, time,
  status"; failed bubbles expose a retry action.
- **Incoming messages announce** via a `Semantics(liveRegion: true)` region; the
  **typing indicator** is exposed as status text (`"Alex is typing…"`), not
  decoration.
- Composer, send, and attach are **labeled**; send reflects its enabled/disabled
  state.
- Delivery status is **icon + text** (not color-only); bubble text meets
  **≥ 4.5:1** on both bubble fills, both themes.
- Targets ≥ 48 dp; text uses `Theme` text styles (no fixed heights, no sub-12
  fonts) so it scales past 200 %.

**Motion:** only opacity/transform — outgoing bubble fade-in, status cross-fade,
pill reveal, looping typing dots — all collapsed to `Duration.zero` and the
typing dots **paused** under `MediaQuery.disableAnimationsOf` (reduce motion).

## Drop into an app

`ChatScreen` is self-contained — with no arguments it runs a demo (seed
transcript, simulated network, a simulated reply + typing indicator). Wire the
callbacks to make it real:

```dart
import 'chat_screen.dart';

ChatScreen(
  contactName: conversation.title,
  presence: presence.label,                 // "Online" / "last seen 2m ago"
  initialMessages: conversation.messages,    // oldest → newest; const [] for empty
  // Return true on success, false (or throw) to route the bubble to failed+retry.
  sendMessage: (text) => api.send(conversation.id, text),
  // Return a page of older messages (oldest → newest); [] at the history head.
  loadOlder: () => api.olderThan(conversation.oldestId),
  // Return false (or throw) to route to the permission-denied sheet.
  requestAttachment: () => permissions.requestPhotos(),
  onBack: () => context.pop(),
  onOpenSettings: () => AppSettings.openAppSettings(),
  isOffline: connectivity.isOffline,         // e.g. from connectivity_plus
);
```

Notes:

- **Try the states** in the demo: send a message containing `fail` to see the
  failed + tap-to-retry path; a normal send runs `sending → sent → delivered →
  read` and triggers a simulated typing indicator + reply; tap the attach (`+`)
  button to see the permission-denied sheet; pass `initialStatus:
  ChatStatus.loading` or `initialMessages: const []` to preview loading / empty.
- **Offline & queue:** drive `isOffline` from the platform. While offline, sends
  are `queued`; flipping `isOffline` back to `false` flushes the outbox with a
  backoff (see `didUpdateWidget`).
- **Colors** resolve through `ChatColors.of(context)` off `Theme.brightness`. In
  a production app, promote `chat_tokens.dart` onto a `ThemeExtension<T>` (see
  `frameworks/flutter/tokens.md`) and read via `Theme.of(context)`.
- **Localization:** copy lives in the private `_Strings` class as a placeholder —
  route it through your i18n layer (whole messages, no concatenation, so they
  translate and mirror correctly in RTL).
- The **`_maybeDemoReply` / demo transcript** helpers are for the stand-alone demo
  only; they no-op once you pass a real `sendMessage`.

## Validate

```bash
python3 quality-checks/validators/run_all.py examples/chat/flutter
# → Readiness score: 100/100 — PASS — clean
```
