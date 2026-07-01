# Snippet — Tokens & palettes (CSS variables)

DTCG semantic tokens as `--ion-*` custom properties, with a system dark palette and a manual override. Components read variables only. See `tokens.md`, `COL-*`, `DRK-*`.

```css
/* theme/variables.css — generated from DTCG semantic tokens; imported once in the app entry */
:root {
  /* named role: primary — ship the full 5-var set (COL-*/A11Y-) */
  --ion-color-primary: #3d5afe;         --ion-color-primary-rgb: 61,90,254;
  --ion-color-primary-contrast: #ffffff; --ion-color-primary-contrast-rgb: 255,255,255;
  --ion-color-primary-shade: #3650e0;    --ion-color-primary-tint: #506bfe;

  --ion-color-danger: #d32f2f;          --ion-color-danger-rgb: 211,47,47;
  --ion-color-danger-contrast: #ffffff;  --ion-color-danger-contrast-rgb: 255,255,255;
  --ion-color-danger-shade: #b92929;     --ion-color-danger-tint: #d74444;

  /* stepped neutrals */
  --ion-background-color: #ffffff; --ion-background-color-rgb: 255,255,255;
  --ion-text-color: #1a1c1e;       --ion-text-color-rgb: 26,28,30;

  /* app spacing/radius — Ionic ships no scale (SPC-*/SHP-*) */
  --app-space-xs: 4px; --app-space-sm: 8px; --app-space-md: 16px; --app-space-lg: 24px; --app-space-xl: 32px;
  --app-radius-sm: 8px; --app-radius-md: 12px; --app-radius-lg: 16px; --app-radius-pill: 9999px;
}
```

```ts
// app entry — pick ONE dark strategy
import '@ionic/react/css/palettes/dark.system.css';   // follows OS (no toggle)
// — or —
import '@ionic/react/css/palettes/dark.class.css';     // manual toggle (SET-*)
```

```ts
// manual toggle, driven from a Settings switch
export function setDark(enabled: boolean) {
  document.documentElement.classList.toggle('ion-palette-dark', enabled);  // DRK-*
}
```

```css
/* consuming — no raw values in component CSS */
.balance-card {
  background: var(--ion-color-step-50);
  border: 1px solid var(--ion-color-step-150);
  padding: var(--app-space-md);
  border-radius: var(--app-radius-md);
}
```
