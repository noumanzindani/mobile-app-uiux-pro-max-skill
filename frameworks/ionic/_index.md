# Ionic Framework Pack

**Purpose:** Map the skill's semantic design system to idiomatic **Ionic** (web components rendered on-device via Capacitor). Ionic is unique among the packs: it has a **built-in adaptive engine** (`mode="ios" | "md"`) that restyles components per platform for free, and it themes through **CSS custom properties** (`--ion-*`). This `_index.md` routes the pack; rules are *referenced by ID* (`A11Y-*`, `STATE-*`, `LST-*`) — never restated. Corpus lives in `rules/`.

> Volatile-fact baseline (date-stamp per §11.2): Ionic **8.x**, Capacitor **6/7**, `@ionic/react` / `@ionic/angular` / `@ionic/vue` bindings, `@capacitor/network`, `@capacitor/preferences`, `@capacitor/geolocation|camera|push-notifications`. Ionic 8 dark mode uses the **`.ion-palette-dark`** class palettes (`@ionic/<fw>/css/palettes/dark.class.css` or `dark.system.css`). `ion-virtual-scroll` was **removed** (v6) — virtualize with a framework library instead. Re-verify on the quarterly standards refresh.

## Table of contents
- [When to reach for Ionic](#when-to-reach-for-ionic)
- [Capability summary](#capability-summary)
- [Adaptive: the `mode` engine](#adaptive-the-mode-engine)
- [Sub-file map](#sub-file-map)
- [Non-negotiables in this pack](#non-negotiables-in-this-pack)

## When to reach for Ionic
Web technology (HTML/CSS/TS + Angular, React, or Vue) packaged as a native app through **Capacitor**. Strong when: a web team wants one codebase across iOS + Android + PWA, you want **automatic per-platform styling** without hand-branching, or you're migrating an existing web app to mobile. The trade: you're rendering a **WebView**, so heavy lists and animations need more care than on true-native stacks (`PERF-*`), and native "feel" comes from Ionic's mode engine rather than platform views.

Because everything is CSS, the token mandate is satisfied by **CSS custom properties** — but that same openness makes hardcoded `#hex`/`px` in component styles the top failure mode (`COL-*`, `SPC-*`).

## Capability summary
| Concern | Idiomatic Ionic primitive | Rules |
|---|---|---|
| Tokens / theming | **CSS variables** (`--ion-color-*`, `--ion-background-color`, stepped `--ion-color-step-*`) | `COL-*`, `SPC-*`, `SHP-*` |
| Safe area | `ion-content` (auto) + `--ion-safe-area-*` / `env(safe-area-inset-*)`; needs `viewport-fit=cover` | `A11Y-*`, `BSH-*` |
| Buttons | `ion-button` (`fill`, `expand`, `shape`, `size`) | `BTN-*` |
| Lists | `ion-list` / `ion-item` + **framework virtualization** (`@tanstack/virtual`, CDK, `react-window`) | `LST-*`, `PERF-*` |
| Sheets | `ion-modal` with `breakpoints` + `initialBreakpoint` (= detents) | `BSH-*` |
| Navigation | `ion-tabs` / `ion-tab-bar` (≤5), `ion-router` / framework router, `ion-menu` | `NAV-*`, `GRD-*` |
| Dark mode | `.ion-palette-dark` class palettes (system or manual toggle) | `DRK-*` |
| A11y | Web **ARIA** + Ionic's built-in roles; `aria-label`, `role`, `aria-live` | `A11Y-*` |
| Motion | **Ionic Animations** (`createAnimation`, Web Animations API) — honor `prefers-reduced-motion` | `MOT-*`, `MIC-*` |
| Responsive | `ion-grid` / CSS grid + breakpoints; `ion-split-pane` for list-detail ≥ md | `GRD-*` |
| Adaptive | **`mode="ios" \| "md"`** — automatic, override-able | `PLAT-*` |
| Offline / native | Capacitor plugins (`@capacitor/network`, `@capacitor/preferences`, permissions) | `OFF-*`, `PERM-*` |

## Adaptive: the `mode` engine
Ionic's differentiator. Every component renders in a **mode**: `ios` (Cupertino-like) or `md` (Material). Ionic **auto-detects** — iOS devices → `ios`, everything else (Android, PWA, desktop) → `md` — so a single component tree feels native on both without `Platform.select` branching.

- **Default (recommended):** let auto-detection run; author tokenized content once.
- **Force globally:** `setupIonicReact({ mode: 'md' })` / `IonicModule.forRoot({ mode: 'md' })` — e.g. a brand that wants Material everywhere.
- **Force per component:** `<ion-button mode="ios">` for a single surface.
- **Mode-specific CSS:** target `.ios` / `.md` classes Ionic puts on elements when a rule must differ.

Divergence you still design for (`PLAT-*`): iOS large-title vs MD toolbar, back-button chrome, alert/action-sheet button order, and switch/toggle shape — the mode engine handles most, but **verify both modes**, not just the one your dev machine emulates.

## Sub-file map
| Task | Read |
|---|---|
| Set up CSS-variable tokens + palettes | `tokens.md` |
| Build button / list / modal / tabs / a11y / animation | `components.md` |
| Implement the 7 UI states | `states.md` |
| Get the mode engine right per OS | `adaptive.md` |
| Copy-paste stubs | `snippets/{button,list,sheet,safe-area,theme}.md` |

## Non-negotiables in this pack
1. **Tokens are CSS variables** — components read `var(--ion-color-primary)` / `var(--app-space-md)`, never inline `#hex`/`px` (`COL-*`, `SPC-*`).
2. **Lists virtualize** — `ion-virtual-scroll` is gone; wrap `ion-item`s in a framework virtualizer for long lists, never render thousands of DOM nodes (`LST-*`, `PERF-*`).
3. **Safe area via `ion-content`** + `viewport-fit=cover`; read `--ion-safe-area-*`, never hardcode `44`/`34` (`A11Y-*`, `BSH-*`).
4. **Sheets use breakpoints** — `ion-modal` `breakpoints` + `initialBreakpoint` as detents; the sheet respects the bottom inset (`BSH-*`).
5. **Verify both modes** — check `ios` and `md`; never ship having tested only one (`PLAT-*`).
6. **Motion honors `prefers-reduced-motion`** — gate `createAnimation` sequences (`MOT-*`).
