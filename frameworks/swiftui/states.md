# SwiftUI — The 7 UI States

**Purpose:** How to implement the mandatory state model in SwiftUI. Drive the view from an explicit state enum (never boolean soup) so every data-backed screen ships all seven states. Rules referenced, not restated: `STATE-*`, `OFF-*`, `PERM-*`, `A11Y-*`, `LST-*`.

## Table of contents
- [State-driven view switch](#state-driven-view-switch)
- [1. Ideal (loaded)](#1-ideal-loaded)
- [2. Empty (×3)](#2-empty-3)
- [3. Loading](#3-loading)
- [4. Error](#4-error)
- [5. Offline](#5-offline)
- [6. Success](#6-success)
- [7. Permission-denied](#7-permission-denied)

## State-driven view switch
Model the phase as an enum and `switch` in the body — this makes state coverage auditable (`STATE-*`, `state_coverage.py`):

```swift
enum LoadPhase<T> { case loading, empty, loaded(T), failed(Error) }

var body: some View {
    switch phase {
    case .loading:      SkeletonList()
    case .empty:        EmptyStateView(...)
    case .loaded(let v): LoadedList(v)
    case .failed(let e): ErrorStateView(error: e) { Task { await reload() } }
    }
}
```
Offline and success are **cross-cutting overlays** (banner / toast), not enum cases; permission-denied is its own gate before the fetch. Reduce Motion applies to all transitions (`A11Y-*`).

## 1. Ideal (loaded)
The virtualized happy path (`List`/`LazyVStack`, `LST-*`). Nothing special beyond token binding and a11y grouping — see `components.md`.

## 2. Empty (×3)
Distinguish **first-run empty**, **user-cleared empty**, and **no-results empty** (`STATE-*`, `SRCH-*`). `ContentUnavailableView` (iOS 17+) is the system-native container — it centers, sizes for Dynamic Type, and reads correctly in VoiceOver:

```swift
ContentUnavailableView {
    Label("No transactions yet", systemImage: "creditcard")
} description: {
    Text("Your purchases will show up here.")
} actions: {
    Button("Add account") { … }.buttonStyle(.borderedProminent)
}
// Search variant:
ContentUnavailableView.search(text: query)   // no-results (SRCH-*)
```

## 3. Loading
Skeleton over spinner for content-shaped screens (`STATE-*`, `LST-*`). Use `.redacted(reason: .placeholder)` on real row layout so the skeleton matches final metrics; `ProgressView()` only for indeterminate short waits:

```swift
List(0..<8, id: \.self) { _ in ItemRow(item: .placeholder) }
    .redacted(reason: .placeholder)
    .accessibilityLabel("Loading")            // announce (A11Y-*)
```

## 4. Error
Recoverable, with a **retry** — never a dead end (`STATE-*`). `ContentUnavailableView` again, plus a bordered-prominent Retry that re-runs the async task:

```swift
ContentUnavailableView {
    Label("Couldn't load", systemImage: "exclamationmark.triangle")
} description: {
    Text(error.userMessage)                   // human copy, not raw error (COPY norms)
} actions: {
    Button("Try again") { Task { await reload() } }.buttonStyle(.borderedProminent)
}
```

## 5. Offline
Non-blocking banner pinned via `.safeAreaInset` so it never covers content or the home indicator, plus optimistic UI with visible rollback for writes (`OFF-*`, `STATE-*`, `BSH-*`). Announce as a live region (`A11Y-*`):

```swift
content
    .safeAreaInset(edge: .top) {
        if !network.isOnline {
            OfflineBanner()                              // auto-dismisses on reconnect
                .accessibilityAddTraits(.isStaticText)
                .accessibilityLabel("You're offline. Changes will sync later.")
        }
    }
```

## 6. Success
Transient confirmation — a toast/snackbar with optional Undo, or an inline checkmark; do not block the flow with a modal for routine success (`STATE-*`, `BDG-*`). Trigger a success haptic (`.notificationOccurred(.success)`) as reinforcement, never as the sole signal (`HAP-*`, `A11Y-*`).

## 7. Permission-denied
Gate the feature and, when the user has denied, route them to Settings (you cannot re-prompt) with value-first copy (`PERM-*`, `STATE-*`):

```swift
switch camera.authorizationStatus {
case .authorized:  CameraView()
case .notDetermined: PrimingView { await camera.request() }   // just-in-time priming (PERM-*)
default:
    ContentUnavailableView {
        Label("Camera access needed", systemImage: "camera")
    } description: {
        Text("Enable camera in Settings to scan receipts.")
    } actions: {
        Button("Open Settings") {
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        }.buttonStyle(.borderedProminent)
    }
}
```

> Self-check: `state_coverage.py` should find loading, all three empties, error, offline, and permission-denied for any data-backed screen (`STATE-*`).
