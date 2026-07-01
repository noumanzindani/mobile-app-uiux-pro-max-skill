# Flutter — The 7 UI States

**Purpose:** Every data-backed screen ships all 7 states (`STATE-*`, and `state_coverage.py` will fail a loaded-only screen). This file shows the idiomatic Flutter shape for each. Model state explicitly, then switch on it — don't scatter `if (loading)` across the tree.

## Table of contents
- [Model the state](#model-the-state)
- [The switchboard](#the-switchboard)
- [1. Ideal](#1-ideal-loaded) · [2. Empty](#2-empty) · [3. Loading](#3-loading) · [4. Error](#4-error) · [5. Offline](#5-offline) · [6. Success](#6-success) · [7. Permission-denied](#7-permission-denied)

## Model the state
Use a sealed class (Dart 3) so the compiler forces you to handle every case:
```dart
sealed class ScreenState<T> {}
class Loading<T> extends ScreenState<T> {}
class Empty<T>   extends ScreenState<T> {}
class Loaded<T>  extends ScreenState<T> { Loaded(this.data); final T data; }
class Failure<T> extends ScreenState<T> { Failure(this.message); final String message; }
class Offline<T> extends ScreenState<T> {}
```
`success` (transient confirmation) and `permission-denied` are usually orthogonal overlays/banners rather than whole-screen states — see below.

## The switchboard
```dart
Widget build(BuildContext context) => switch (state) {
      Loading()        => const _SkeletonList(),
      Empty()          => _EmptyView(onCreate: create),
      Failure(:final message) => _ErrorView(message: message, onRetry: reload),
      Offline()        => _OfflineView(onRetry: reload),
      Loaded(:final data) when data.isEmpty => _EmptyView(onCreate: create),
      Loaded(:final data) => _list(data),
    };
```

## 1. Ideal (loaded)
The populated happy path — the virtualized list/grid/detail. Everything token-driven, all targets ≥48dp. This is the only state most generators produce; the other six are the differentiator.

## 2. Empty
Distinct from loading. Explain *why it's empty* + one primary action to fill it (`STATE-*`, `BDG-*`). Three flavors: first-run empty, user-cleared empty, and **zero-results** (search/filter — offer "clear filters", `SRCH-*`).
```dart
class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onCreate});
  final VoidCallback onCreate;
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.inbox_outlined, size: 48, color: context.colors.onSurfaceVariant),
          SizedBox(height: context.space.md),
          Text('No transactions yet', style: context.text.titleMedium),
          SizedBox(height: context.space.sm),
          Text('Your activity will show up here.', style: context.text.bodyMedium),
          SizedBox(height: context.space.lg),
          FilledButton(onPressed: onCreate, child: const Text('Add money')),
        ]),
      );
}
```

## 3. Loading
Prefer a **skeleton** matching the loaded layout over a bare spinner for content areas (`STATE-*`, NN/g). Use a shimmer or a `disableAnimations`-aware pulse. Announce with `Semantics(label: 'Loading', liveRegion: true)`.
```dart
class _SkeletonList extends StatelessWidget {
  const _SkeletonList();
  @override
  Widget build(BuildContext context) => ListView.builder(
        itemCount: 8,
        itemBuilder: (context, _) => Padding(
          padding: EdgeInsets.symmetric(horizontal: context.space.md, vertical: context.space.sm),
          child: Row(children: [
            const _Box(40, 40, radius: 20),
            SizedBox(width: context.space.md),
            const Expanded(child: _Box(double.infinity, 14)),
          ]),
        ),
      );
}
```
Skeleton boxes use `context.colors.surfaceContainerHighest`; wrap in a reduce-motion-aware shimmer.

## 4. Error
Human-readable message (not a stack trace) + **Retry** + a way out (`STATE-*`). Never a dead end.
```dart
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message; final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline, size: 48, color: context.colors.error),
          SizedBox(height: context.space.md),
          Text("Couldn't load your data", style: context.text.titleMedium),
          SizedBox(height: context.space.sm),
          Text(message, textAlign: TextAlign.center, style: context.text.bodyMedium),
          SizedBox(height: context.space.lg),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Try again')),
        ]),
      );
}
```

## 5. Offline
Detect connectivity (e.g. `connectivity_plus`) and show a **non-blocking** banner when data is cached, or a full offline view when nothing is available (`OFF-*`, `BDG-*`). Optimistic writes queue with visible rollback.
```dart
MaterialBanner(
  content: const Text("You're offline. Showing cached data."),
  leading: const Icon(Icons.cloud_off),
  backgroundColor: context.colors.surfaceContainerHigh,
  actions: [TextButton(onPressed: onRetry, child: const Text('Retry'))],
); // announce via liveRegion Semantics
```

## 6. Success
Transient confirmation of a completed action — `SnackBar` (with **Undo** where reversible, `BDG-*`) for lightweight actions, or an inline check animation for in-context ones. Auto-dismiss; announce to screen readers.
```dart
ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  content: const Text('Payment sent'),
  action: SnackBarAction(label: 'Undo', onPressed: undo),
  behavior: SnackBarBehavior.floating,
));
```

## 7. Permission-denied
When a capability (camera, location, notifications) is denied, show a value-first explanation + deep-link to Settings (`PERM-*`) — never a blank screen or a silent failure.
```dart
Column(mainAxisSize: MainAxisSize.min, children: [
  Icon(Icons.location_off, size: 48, color: context.colors.onSurfaceVariant),
  SizedBox(height: context.space.md),
  Text('Location is off', style: context.text.titleMedium),
  Text('Turn on location to see nearby results.', style: context.text.bodyMedium),
  SizedBox(height: context.space.lg),
  FilledButton(onPressed: openAppSettings, child: const Text('Open Settings')), // permission_handler
]);
```

> Self-check: run `state_coverage.py`; confirm loading, empty (incl. zero-results), error, and offline are all reachable, plus success + permission-denied where the screen has actions/capabilities.
