# Ionic — Components (idiomatic + accessible)

**Purpose:** The idiomatic Ionic primitive for each core component, wired to tokens, safe area, ARIA, and the mode engine. Rules referenced by ID. Snippets in `snippets/`.

## Table of contents
- [Buttons](#buttons) · [Lists](#lists) · [Modals & sheets](#modals--sheets)
- [Navigation & tabs](#navigation--tabs) · [Safe area](#safe-area)
- [Accessibility](#accessibility) · [Motion](#motion) · [Responsive](#responsive)

## Buttons
`ion-button` — `fill` (`solid`/`outline`/`clear`), `expand="block"` (full width), `shape="round"`, `size`. One primary action per view (`BTN-*`).
```tsx
<IonButton expand="block" onClick={submit}>Sign in</IonButton>
<IonButton fill="clear" color="danger">Delete</IonButton>
```
- **Targets:** default `ion-button` height clears 44px; for **icon-only** actions use `IonButton` (not a bare `IonIcon`) so the tap area is padded to ≥44×44 (`BTN-*`, `A11Y-*`, `ICN-*`):
  ```tsx
  <IonButton fill="clear" aria-label="Close"><IonIcon slot="icon-only" icon={close} /></IonButton>
  ```
- **Loading/disabled:** disable + swap label for an `ion-spinner` during async so the action can't double-fire (`BTN-*`, safety-critical for `PAY-*`).

## Lists
`ion-list` + `ion-item`. `ion-item` with `button` is a single tap target; `ion-item-sliding` gives swipe actions (always with a visible non-gesture alternative — `GES-*`).
```tsx
<IonList>
  <IonItem button detail onClick={open}>
    <IonLabel><h2>{title}</h2><p>{subtitle}</p></IonLabel>
  </IonItem>
</IonList>
```
- **Virtualize long lists** (`LST-*`, `PERF-*`): `ion-virtual-scroll` was removed — wrap items in a framework virtualizer (`@tanstack/virtual`, Angular CDK `*cdkVirtualFor`, `react-window`). Rendering thousands of DOM nodes stalls the WebView.
- **Pull-to-refresh:** `ion-refresher` + `ion-refresher-content` (`FEED-*`).

## Modals & sheets
`ion-modal`. A **sheet** modal uses `breakpoints` + `initialBreakpoint` — Ionic's detents (`BSH-*`):
```tsx
<IonModal isOpen={open} breakpoints={[0, 0.25, 0.5, 1]} initialBreakpoint={0.5}
          onDidDismiss={close}>
  <IonContent className="ion-padding">{/* … */}</IonContent>
</IonModal>
```
- The sheet respects the bottom safe-area inset automatically inside `ion-content`.
- Alerts/confirms: `ion-alert` (destructive confirm explicit; button order follows mode — `DLG-*`). Prefer `ion-action-sheet` for a list of actions.

## Navigation & tabs
`ion-tabs` + `ion-tab-bar` (≤5 tabs — `NAV-*`); `ion-menu` (drawer) for secondary nav; the framework router (`ion-router`, React Router, Angular Router, Vue Router) for stacks. Never override the hardware/gesture back (`PLAT-*`, `GES-*`).
```tsx
<IonTabs>
  <IonRouterOutlet>{/* routes */}</IonRouterOutlet>
  <IonTabBar slot="bottom">
    <IonTabButton tab="home" href="/home"><IonIcon icon={home} /><IonLabel>Home</IonLabel></IonTabButton>
    {/* … ≤5 */}
  </IonTabBar>
</IonTabs>
```

## Safe area
`ion-content` applies safe-area padding automatically. Requirements (`A11Y-*`, `BSH-*`):
1. `<meta name="viewport" content="viewport-fit=cover" />` — without it the insets are 0.
2. Custom fixed/floating elements (FAB, sticky footer) read `var(--ion-safe-area-bottom)` / `env(safe-area-inset-bottom)`.
```css
.floating-cta { bottom: calc(var(--app-space-md) + var(--ion-safe-area-bottom)); }
```

## Accessibility
Ionic components ship ARIA roles/states; you supply names and meaning (`A11Y-*`):
- **Name every control:** `aria-label` on icon-only buttons/inputs; `IonLabel` provides the accessible name for form controls.
- **State not color-only:** selected chips/segments carry `aria-selected`/`aria-pressed`, not just a color (`A11Y-*`, `CHP-*`).
- **Live regions:** wrap async status in `aria-live="polite"`; use `ion-toast` for announcements.
- **Contrast:** run `contrast_check.py` against both palettes; the mode engine doesn't fix a low-contrast token.
- **Focus:** visible focus ring on web/keyboard; don't remove `outline` without a replacement (`A11Y-*`, WCAG 2.4.11/2.4.7).

## Motion
Ionic **Animations** (`createAnimation`) wrap the Web Animations API. Prefer transform/opacity (`PERF-*`) and **gate on reduced motion** (`MOT-*`):
```ts
if (!window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
  createAnimation().addElement(el).duration(250).fromTo('opacity', '0', '1').play();
}
```
Page transitions come from the mode engine (iOS push vs MD); don't hand-roll route animations that fight it.

## Responsive
`ion-grid`/`ion-row`/`ion-col` or CSS grid with breakpoints; **`ion-split-pane`** turns a list into list-detail at ≥ `md` (`GRD-*`) — the Ionic path to the ≥840dp two-pane rule.
```tsx
<IonSplitPane when="md"><IonMenu>{/* list */}</IonMenu><div className="ion-page">{/* detail */}</div></IonSplitPane>
```
