# Chat — SwiftUI

A real, compiling SwiftUI implementation of the chat example in [`../spec.md`](../spec.md).
It renders an accessible, all-states 1:1 conversation with optimistic send, an
offline queue with auto-retry, keyboard-safe composer, and full accessibility —
built entirely from semantic tokens.

## Files

| File | Role |
|---|---|
| `ChatTokens.swift` | Semantic token layer — Color / spacing / radius / size / Font / motion. **The only file allowed raw values** (each raw line ends with `// ux:ignore`). |
| `ChatScreen.swift` | The `ChatScreen` view + `ChatViewModel` — all 7 states, virtualized list, optimistic send, keyboard-safe, accessible, RTL-safe. Zero literals; everything reads from `ChatTokens`. |

> **One target / one module.** Both files belong to the **same Xcode target
> (module)**. `ChatScreen.swift` references `ChatTokens` directly (same-module,
> no `import`), and the private `Color` shim in `ChatTokens.swift` is `internal`
> to that module. Add both files to the same app/framework target — do not split
> them across modules or the token references won't resolve.

## What it demonstrates

- **7-state model** via `enum ChatStatus { idle, empty, loading, error, offline, success, permissionDenied }` — the body switches on state instead of boolean soup. Loading shows skeleton bubbles; empty shows a friendly "Say hi 👋" first-message prompt; error keeps cached messages under an inline retry banner; offline shows a non-blocking banner and stays readable; success/idle show the live conversation; permission-denied degrades the attach flow only.
- **Optimistic send** via `enum MessageStatus { sending, sent, delivered, read, failed, queued }`. `ChatViewModel.send()` appends the bubble instantly, then transitions `sending → sent → delivered → read`. A message containing "fail" is rejected → **failed badge + tap-to-retry** with content preserved. When offline, the send is **queued** and `flushQueue()` re-sends automatically on reconnect — nothing is silently dropped.
- **Status = icon + text, never color-only.** Each `MessageStatus` carries an SF Symbol *and* a text `label` ("Sending", "Sent", "Delivered", "Read", "Failed", "Queued"). The semantic info/error tint is applied to the **icon** (a graphical object, WCAG ≥ 3:1); the label text uses the muted label role (≥ 4.5:1).
- **Virtualized, newest-at-bottom list:** `ScrollView` + `LazyVStack` with `.defaultScrollAnchor(.bottom)`. A `ScrollViewReader` scrolls to the latest on send; a bottom sentinel tracks whether the newest message is on screen, driving the **"N new messages" pill** that fades/slides in and smooth-scrolls to bottom on tap. Per-day **date separators** are interleaved.
- **Own vs other bubbles on opposite sides** using logical `.leading` / `.trailing` and `Spacer(minLength:)` on the opposite edge — so they **mirror automatically in RTL**. No literal left/right, no physical `Alignment`, no numeric offsets.
- **Composer** (attach · growing `TextField(axis: .vertical)` · send) pinned with `.safeAreaInset(edge: .bottom)`, so it rides above the keyboard and above the home indicator; the offline banner rides `.safeAreaInset(edge: .top)`. The field grows from `composerMinLines` to `composerMaxLines`, then scrolls internally. Send/attach are 48pt hit areas.
- **Typing indicator:** gentle looping dots that **pause under `@Environment(\.accessibilityReduceMotion)`** and are exposed as status text ("typing…") in the nav bar and as an accessibility label.
- **Accessibility:** each bubble is one element via `.accessibilityElement(children: .combine)` read as **"sender, message, time, status"**; failed bubbles expose a "Retry" `.accessibilityAction`. Incoming messages and typing are announced with `AccessibilityNotification.Announcement(...).post()` (live region). Composer, send, and attach are labeled; send reflects enabled/disabled.
- **Motion:** only opacity/offset transitions, all collapsed to ~instant under Reduce Motion via `ChatTokens.reveal(reduceMotion:)` / `statusChange(reduceMotion:)` / `typingLoop(reduceMotion:)`.
- **Dynamic Type:** every text uses a scaling `Font` text style — no fixed point sizes, no fixed heights on text-bearing views — so bubbles and composer grow to 200% without clipping.

## Cross-SDK color shim

`ChatTokens.swift` copies the login example's cross-platform pattern exactly: a
`private extension Color` guarded with `#if canImport(UIKit) … #elseif
canImport(AppKit) … #endif`, returning Apple **semantic** system colors
(`.systemBackground`/`.windowBackgroundColor`, `.label`/`.labelColor`,
`.systemIndigo`, `.systemRed`, …). This keeps the token layer compiling on
**both** the iOS (UIKit) and macOS (AppKit) toolchains — never bare
`Color(uiColor: .systemBackground)` at the top level, which fails under the macOS
SDK. Bubble contrast is verified ≥ 4.5:1 on both fills in both themes (white on
`systemIndigo` ≈ 5:1; label on the secondary background ≈ 15:1).

## iOS target notes

- **Deployment target: iOS 17+.** Uses `.defaultScrollAnchor(.bottom)`,
  `ContentUnavailableView`, the two-parameter `.onChange(of:)`,
  `.contentTransition(.symbolEffect(.replace))`, and `.topBarLeading` /
  `.topBarTrailing` placements. `TextField(axis:)`, `.scrollDismissesKeyboard`,
  and `Duration`-based `Task.sleep(for:)` are iOS 16+.
- **Reachability** uses `NWPathMonitor` (Network framework). A demo "Go offline"
  menu toggle lets you exercise the queue/flush path without dropping Wi‑Fi.
- The attach flow **simulates** a denied photo authorization to demonstrate the
  permission-denied fallback (Settings link + "choose a file instead"); swap
  `requestPhotos()` for a real `PHPhotoLibrary.requestAuthorization(...)` call
  (add `NSPhotoLibraryUsageDescription`) in production.
- Drop `ChatScreen()` into a `WindowGroup` and pass `onBack` to wire navigation.

## Validators

Passes `quality-checks/validators/run_all.py examples/chat/swiftui` — **100/100**:

- **token_lint** — no hex / `Color(0x…)` and no off-grid spacing in `ChatScreen.swift`; raw values live only in `ChatTokens.swift`, each suppressed with `// ux:ignore`. Spacing is on the 4/8 grid.
- **contrast_check** — theme token pairs meet WCAG 2.2; bubble fills chosen ≥ 4.5:1.
- **target_size_lint** — send / attach / retry / back use `.frame(minHeight: ChatTokens.targetMin)` (48); no undersized interactive frames.
- **state_coverage** — `loading`, `empty` (`isEmpty`), `error` / `retry`, `offline` (and `success`) all referenced.
- **dynamic_type_check** — scaling `Font` text styles only; no fixed heights on text lines; no sub-12pt fonts.
- **rtl_check** — logical leading/trailing only; no physical directional properties.
