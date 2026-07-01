# Ionic — The 7 UI States

**Purpose:** Every data-backed screen ships all 7 states (`STATE-*`; `state_coverage.py` fails a loaded-only screen). This file gives the idiomatic Ionic shape for each. Model state as a discriminated union, then switch on it.

## Table of contents
- [Model the state](#model-the-state)
- [The switchboard](#the-switchboard)
- [1. Ideal](#1-ideal-loaded) · [2. Empty](#2-empty) · [3. Loading](#3-loading) · [4. Error](#4-error) · [5. Offline](#5-offline) · [6. Success](#6-success) · [7. Permission-denied](#7-permission-denied)

## Model the state
```ts
type ScreenState<T> =
  | { status: 'loading' }
  | { status: 'empty' }
  | { status: 'loaded'; data: T }
  | { status: 'error'; message: string }
  | { status: 'offline' };
```
`success` (transient) and `permission-denied` are usually overlays/banners orthogonal to this union.

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
        : <ItemList data={state.data} />;
  }
}
```

## 1. Ideal (loaded)
The populated happy path inside `ion-content` — a virtualized `ion-list`, detail, or grid. Token-driven (CSS variables), targets ≥44×44. The other six states are the differentiator over loaded-only generation.

## 2. Empty
Distinct from loading. Explain *why* + one primary action (`STATE-*`, `BDG-*`). Three flavors: first-run, user-cleared, and **zero-results** (search/filter → "Clear filters", `SRCH-*`).
```tsx
export function EmptyView({ onCreate }: { onCreate: () => void }) {
  return (
    <div className="state-center">
      <IonIcon icon={fileTrayOutline} className="state-glyph" aria-hidden="true" />
      <h2>No transactions yet</h2>
      <p className="muted">Your activity will show up here.</p>
      <IonButton onClick={onCreate}>Add money</IonButton>
    </div>
  );
}
```
`.state-center` centers with `padding: var(--app-space-lg)`; `.state-glyph` uses `color: var(--ion-color-step-500)`.

## 3. Loading
Prefer **`ion-skeleton-text`** matching the loaded layout over a bare spinner (`STATE-*`). Mark the container as busy and announce.
```tsx
export function SkeletonList() {
  return (
    <IonList aria-busy="true" aria-label="Loading">
      {Array.from({ length: 8 }).map((_, i) => (
        <IonItem key={i}>
          <IonThumbnail slot="start"><IonSkeletonText animated /></IonThumbnail>
          <IonLabel>
            <h3><IonSkeletonText animated style={{ width: '60%' }} /></h3>
            <p><IonSkeletonText animated style={{ width: '80%' }} /></p>
          </IonLabel>
        </IonItem>
      ))}
    </IonList>
  );
}
```
`ion-skeleton-text[animated]` shimmer already respects `prefers-reduced-motion`.

## 4. Error
Human-readable message (not a stack trace) + **Retry** + an exit (`STATE-*`). Never a dead end.
```tsx
export function ErrorView({ message, onRetry }: { message: string; onRetry: () => void }) {
  return (
    <div className="state-center" role="alert">
      <IonIcon icon={alertCircleOutline} className="state-glyph" style={{ color: 'var(--ion-color-danger)' }} aria-hidden="true" />
      <h2>Couldn't load your data</h2>
      <p className="muted">{message}</p>
      <IonButton fill="outline" onClick={onRetry}>Try again</IonButton>
    </div>
  );
}
```

## 5. Offline
Detect with **`@capacitor/network`**; show a **non-blocking** banner when data is cached, or a full offline view when nothing's available (`OFF-*`, `BDG-*`). Optimistic writes queue with visible rollback.
```tsx
import { Network } from '@capacitor/network';
const [online, setOnline] = useState(true);
useEffect(() => {
  Network.getStatus().then(s => setOnline(s.connected));
  const h = Network.addListener('networkStatusChange', s => setOnline(s.connected));
  return () => { h.remove(); };
}, []);
{!online && (
  <div className="offline-banner" role="status" aria-live="polite">
    <IonIcon icon={cloudOfflineOutline} aria-hidden="true" />
    <span>You're offline. Showing cached data.</span>
    <IonButton fill="clear" size="small" onClick={onRetry}>Retry</IonButton>
  </div>
)}
```
`.offline-banner` background `var(--ion-color-step-100)`; padded with `var(--app-space-sm)`.

## 6. Success
Transient confirmation — **`ion-toast`** with an Undo where reversible (`BDG-*`); auto-dismiss; toasts announce to screen readers by default.
```tsx
const [present] = useIonToast();
present({ message: 'Payment sent', duration: 2500, buttons: [{ text: 'Undo', handler: undo }] });
```

## 7. Permission-denied
When a Capacitor capability (camera/location/notifications) is denied, show a value-first explanation + a route to Settings (`PERM-*`) — never a blank screen.
```tsx
import { Geolocation } from '@capacitor/geolocation';
const perm = await Geolocation.checkPermissions();
if (perm.location === 'denied') {
  // render:
  <div className="state-center">
    <IonIcon icon={locationOutline} className="state-glyph" aria-hidden="true" />
    <h2>Location is off</h2>
    <p className="muted">Turn on location to see nearby results.</p>
    <IonButton onClick={openAppSettings}>Open Settings</IonButton>
  </div>
}
```
`openAppSettings` → `@capacitor/app` `App` or the `NativeSettings` plugin.

> Self-check: run `state_coverage.py`; confirm loading, empty (incl. zero-results), error, and offline are reachable, plus success + permission-denied where the screen has actions/capabilities.
