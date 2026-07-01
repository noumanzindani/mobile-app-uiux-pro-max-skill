# React Native — The 7 UI States

**Purpose:** Every data-backed screen ships all 7 states (`STATE-*`; `state_coverage.py` fails a loaded-only screen). This file shows the idiomatic RN shape for each. Model state as a discriminated union, then switch on it.

## Table of contents
- [Model the state](#model-the-state)
- [The switchboard](#the-switchboard)
- [1. Ideal](#1-ideal-loaded) · [2. Empty](#2-empty) · [3. Loading](#3-loading) · [4. Error](#4-error) · [5. Offline](#5-offline) · [6. Success](#6-success) · [7. Permission-denied](#7-permission-denied)

## Model the state
A discriminated union gives you exhaustive handling in TypeScript:
```ts
type ScreenState<T> =
  | { status: 'loading' }
  | { status: 'empty' }
  | { status: 'loaded'; data: T }
  | { status: 'error'; message: string }
  | { status: 'offline' };
```
`success` (transient confirmation) and `permission-denied` are usually overlays/banners orthogonal to this union — handled below.

## The switchboard
```tsx
function Screen({ state, actions }: { state: ScreenState<Item[]>; actions: Actions }) {
  switch (state.status) {
    case 'loading': return <SkeletonList />;
    case 'empty':   return <EmptyView onCreate={actions.create} />;
    case 'error':   return <ErrorView message={state.message} onRetry={actions.reload} />;
    case 'offline': return <OfflineView onRetry={actions.reload} />;
    case 'loaded':
      return state.data.length === 0
        ? <EmptyView onCreate={actions.create} />
        : <List data={state.data} />;
  }
}
```

## 1. Ideal (loaded)
The populated happy path — the virtualized `FlashList`/`FlatList`, detail, or grid. Token-driven, targets ≥44×44. The other six states are the differentiator over loaded-only generation.

## 2. Empty
Distinct from loading. Explain *why* + one primary action (`STATE-*`, `BDG-*`). Three flavors: first-run, user-cleared, and **zero-results** (search/filter → offer "Clear filters", `SRCH-*`). Wire via `ListEmptyComponent`.
```tsx
export function EmptyView({ onCreate }: { onCreate: () => void }) {
  const t = useTheme();
  return (
    <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', padding: t.spacing.lg }}>
      <Inbox color={t.colors.muted} size={48} />
      <Text style={{ ...type.titleMedium, marginTop: t.spacing.md }}>No transactions yet</Text>
      <Text style={{ ...type.body, color: t.colors.muted, marginTop: t.spacing.sm }}>Your activity will show up here.</Text>
      <PrimaryButton label="Add money" onPress={onCreate} style={{ marginTop: t.spacing.lg }} />
    </View>
  );
}
```

## 3. Loading
Prefer a **skeleton** matching the loaded layout over a bare spinner (`STATE-*`). Animate a reduce-motion-aware shimmer (Reanimated). Mark the container `accessibilityRole="progressbar"` and announce.
```tsx
export function SkeletonList() {
  return (
    <View accessibilityRole="progressbar" accessibilitylabel="Loading">
      {Array.from({ length: 8 }).map((_, i) => (
        <View key={i} style={{ flexDirection: 'row', padding: 16, alignItems: 'center' }}>
          <SkeletonBox w={40} h={40} radius={20} />
          <SkeletonBox w={'70%'} h={14} style={{ marginLeft: 16 }} />
        </View>
      ))}
    </View>
  );
}
```
`SkeletonBox` background = `theme.colors.border`; shimmer gated on `useReducedMotion()`.

## 4. Error
Human-readable message (not a stack trace) + **Retry** + an exit (`STATE-*`). Never a dead end.
```tsx
export function ErrorView({ message, onRetry }: { message: string; onRetry: () => void }) {
  const t = useTheme();
  return (
    <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', padding: t.spacing.lg }}>
      <AlertCircle color={t.colors.danger} size={48} />
      <Text style={{ ...type.titleMedium, marginTop: t.spacing.md }}>Couldn't load your data</Text>
      <Text style={{ ...type.body, color: t.colors.muted, textAlign: 'center', marginTop: t.spacing.sm }}>{message}</Text>
      <PrimaryButton label="Try again" variant="tonal" onPress={onRetry} style={{ marginTop: t.spacing.lg }} />
    </View>
  );
}
```

## 5. Offline
Detect with `@react-native-community/netinfo`; show a **non-blocking** banner when data is cached, or a full offline view when nothing's available (`OFF-*`, `BDG-*`). Optimistic writes queue with visible rollback.
```tsx
const net = useNetInfo();
{!net.isConnected && (
  <View accessibilityRole="alert" accessibilityLiveRegion="polite"
        style={{ flexDirection: 'row', alignItems: 'center', gap: 8, padding: 12, backgroundColor: t.colors.border }}>
    <CloudOff size={18} />
    <Text style={{ flex: 1 }}>You're offline. Showing cached data.</Text>
    <Pressable onPress={onRetry} accessibilityRole="button" accessibilityLabel="Retry" hitSlop={8}><Text>Retry</Text></Pressable>
  </View>
)}
```

## 6. Success
Transient confirmation — a toast/snackbar with **Undo** where reversible (`BDG-*`), or an inline check animation. Auto-dismiss; announce for screen readers.
```tsx
showToast({ message: 'Payment sent', action: { label: 'Undo', onPress: undo } });
AccessibilityInfo.announceForAccessibility('Payment sent');
```

## 7. Permission-denied
When camera/location/notifications is denied, show a value-first explanation + a deep-link to Settings (`PERM-*`) — never a blank screen.
```tsx
import * as Linking from 'expo-linking';
export function PermissionDenied() {
  const t = useTheme();
  return (
    <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', padding: t.spacing.lg }}>
      <MapPinOff color={t.colors.muted} size={48} />
      <Text style={{ ...type.titleMedium, marginTop: t.spacing.md }}>Location is off</Text>
      <Text style={{ ...type.body, color: t.colors.muted }}>Turn on location to see nearby results.</Text>
      <PrimaryButton label="Open Settings" onPress={() => Linking.openSettings()} style={{ marginTop: t.spacing.lg }} />
    </View>
  );
}
```

> Self-check: run `state_coverage.py`; confirm loading, empty (incl. zero-results), error, and offline are reachable, plus success + permission-denied where the screen has actions/capabilities.
