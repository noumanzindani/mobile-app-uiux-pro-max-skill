# Ionic — Tokens & Theming

**Purpose:** Ionic themes entirely through **CSS custom properties**. This file maps the skill's DTCG semantic tokens to Ionic's variable system without hardcoding values, and wires light/dark palettes. Read alongside `COL-*`, `DRK-*`, `SPC-*`, `SHP-*`.

## Table of contents
- [The pipeline](#the-pipeline)
- [Ionic's variable layers](#ionics-variable-layers)
- [Map DTCG → `--ion-*`](#map-dtcg--ion-)
- [App-level spacing/radius tokens](#app-level-spacingradius-tokens)
- [Dark mode](#dark-mode)
- [Anti-patterns](#anti-patterns)

## The pipeline
```
design-system/tokens/*.json  (DTCG semantic)
        │  Style Dictionary v4 → css target (custom properties)
        ▼
theme/variables.css  (:root { --ion-color-* } + .ion-palette-dark { … })
        │  imported once in the app entry
        ▼
Components use var(--ion-color-primary) / var(--app-space-md)
        ▼
Never a raw #hex or px in a component style.
```
Only `variables.css` touches raw values; components reference semantic variables (`COL-*`, `SPC-*`).

## Ionic's variable layers
Three tiers ship out of the box:
1. **Stepped neutrals** — `--ion-background-color`, `--ion-text-color`, and the generated `--ion-color-step-50 … -950` ramp between them. Dark mode flips these and every step recomputes.
2. **Named colors** — eight roles (`primary secondary tertiary success warning danger light medium dark`), each with a **required 5-variable set**:
   `--ion-color-primary`, `-rgb`, `-contrast`, `-contrast-rgb`, `-shade`, `-tint`.
   Ship the whole set or fills/ripples/contrast break (`A11Y-*`).
3. **Component variables** — per-component overrides (`--background`, `--color`, `--border-radius`, `--padding-start`) scoped to an element.

## Map DTCG → `--ion-*`
```css
/* theme/variables.css — generated from DTCG semantic tokens */
:root {
  /* named role: primary (semantic action color) */
  --ion-color-primary:          #3d5afe;
  --ion-color-primary-rgb:      61, 90, 254;
  --ion-color-primary-contrast: #ffffff;   /* must be ≥4.5:1 on the role — COL-*/A11Y- */
  --ion-color-primary-contrast-rgb: 255, 255, 255;
  --ion-color-primary-shade:    #3650e0;   /* ~12% darker — pressed */
  --ion-color-primary-tint:     #506bfe;   /* ~12% lighter — hover */

  --ion-color-danger:  #d32f2f; --ion-color-danger-rgb: 211,47,47;
  --ion-color-danger-contrast: #ffffff; --ion-color-danger-contrast-rgb: 255,255,255;
  --ion-color-danger-shade: #b92929; --ion-color-danger-tint: #d74444;

  /* stepped neutrals — surface + text; steps interpolate for borders/muted */
  --ion-background-color: #ffffff; --ion-background-color-rgb: 255,255,255;
  --ion-text-color:       #1a1c1e; --ion-text-color-rgb: 26,28,30;
}
```
Component styles then read roles, never raw values:
```css
.balance-card { background: var(--ion-color-step-50); border: 1px solid var(--ion-color-step-150); }
.error-text  { color: var(--ion-color-danger); }
```

## App-level spacing/radius tokens
Ionic ships colors but **not** a spacing scale — define your own custom properties so `SPC-*`/`SHP-*` are enforceable and greppable:
```css
:root {
  --app-space-xs: 4px;  --app-space-sm: 8px;  --app-space-md: 16px;   /* 4/8pt grid — SPC-* */
  --app-space-lg: 24px; --app-space-xl: 32px;
  --app-radius-sm: 8px; --app-radius-md: 12px; --app-radius-lg: 16px; --app-radius-pill: 9999px; /* SHP-* */
}
.list-row { padding: var(--app-space-md); gap: var(--app-space-sm); border-radius: var(--app-radius-md); }
```

## Dark mode
Ionic 8 uses **class palettes**. Import one in the app entry, then toggle a class on `<html>`:
```ts
// system-driven (follows OS) — no toggle needed
import '@ionic/react/css/palettes/dark.system.css';
```
```ts
// manual toggle (Settings switch, SET-*) — class-based
import '@ionic/react/css/palettes/dark.class.css';
document.documentElement.classList.toggle('ion-palette-dark', enabled);
```
Because components read semantic variables, none change — only the palette's values do. The dark palette overrides `--ion-background-color`, `--ion-text-color`, and each role's set. Never pure `#000` surfaces (`DRK-*`); run `contrast_check.py` against **both** palettes.

## Anti-patterns
- ❌ `color: #3d5afe` in a component → ✅ `color: var(--ion-color-primary)` (`COL-*`).
- ❌ `padding: 16px` literal → ✅ `var(--app-space-md)` (`SPC-*`).
- ❌ Defining `--ion-color-primary` without its `-contrast`/`-shade`/`-tint` → broken fills/ripple (`A11Y-*`).
- ❌ Two hand-maintained light/dark stylesheets → ✅ one variable set, one dark **palette** override (`DRK-*`).
- ❌ Hardcoding `padding-top: 44px` for the notch → ✅ `var(--ion-safe-area-top)` / `env(safe-area-inset-top)` (`A11Y-*`).
