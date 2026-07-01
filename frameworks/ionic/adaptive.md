# Ionic — Adaptive (the `mode` engine)

**Purpose:** Ionic is the only v1 pack with **built-in** per-platform styling. Get the `mode` engine right so output feels native on both OSes without hand-branching. Read alongside `PLAT-*`.

## Table of contents
- [How mode works](#how-mode-works)
- [Choosing your strategy](#choosing-your-strategy)
- [Overriding mode](#overriding-mode)
- [Where you still design per-platform](#where-you-still-design-per-platform)
- [Testing both modes](#testing-both-modes)

## How mode works
Every Ionic component renders in one **mode**:
- **`ios`** — Cupertino-like: translucent large-title headers, thinner type, iOS switch/segment shapes, push-slide page transitions.
- **`md`** — Material: solid toolbars, ripples, MD switches, elevation, MD transitions.

Ionic **auto-detects** at startup: iOS devices → `ios`; Android, PWA, and desktop → `md`. Ionic then puts a `.ios` or `.md` class on the element, so a single tokenized component tree adapts for free — no `Platform.select`, no `.ios.tsx`/`.android.tsx` files.

## Choosing your strategy
| Strategy | When | How |
|---|---|---|
| **Auto (recommended)** | You want native feel per OS with one codebase | Do nothing — let detection run; author tokenized content once |
| **Force one mode** | Brand wants a single look everywhere (often Material) | `setupIonicReact({ mode: 'md' })` / `IonicModule.forRoot({ mode: 'md' })` / `createApp().use(IonicVue, { mode: 'md' })` |
| **Per-surface override** | One component must differ | `<IonButton mode="ios">` |

Forcing a mode is a legitimate brand choice (`PLAT-*`) — but be deliberate: forcing `ios` on Android users removes the ripples and back-behavior Android users expect.

## Overriding mode
```ts
// React — app entry
import { setupIonicReact } from '@ionic/react';
setupIonicReact({ mode: 'md' });        // global
```
```tsx
<IonModal mode="ios">…</IonModal>       // per component
```
```css
/* mode-specific CSS when a rule truly must diverge */
.ios .brand-header { backdrop-filter: blur(20px); }   /* iOS Liquid-Glass-like */
.md  .brand-header { box-shadow: var(--app-elevation-1); }
```

## Where you still design per-platform
The mode engine handles chrome/shape, but **you** own these (`PLAT-*`):
- **Alert / action-sheet button order** — Ionic follows mode, but confirm destructive actions read correctly in both.
- **Back navigation** — `ion-back-button` renders the mode-correct chevron; never intercept the hardware/gesture back on Android (`GES-*`).
- **Icons** — `ion-icon` can auto-swap `ios`/`md` glyph variants; pass both (`icon={{ ios: chevronBack, md: arrowBack }}`) or an `ionicon` that ships both.
- **Haptics** — Capacitor `Haptics` on meaningful events only, never as sole feedback (`HAP-*`).
- **Type & density** — respect the OS Dynamic Type / font-scale; don't pin `px` font sizes (`TYP-*`, `A11Y-*`).

## Testing both modes
The top Ionic failure mode is shipping having tested only the mode your dev machine emulates. Before done (`PLAT-*`):
1. Run the app forced to **`md`** and to **`ios`** (`?ionic:mode=ios` in the browser, or the force config) and eyeball headers, toggles, alerts, transitions.
2. Verify **both palettes × both modes** for contrast (`contrast_check.py`, `DRK-*`).
3. Confirm safe-area insets on a notched iOS profile *and* an Android gesture-nav profile (`A11Y-*`).
