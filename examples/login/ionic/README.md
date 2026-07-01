# Login — Ionic (React + Capacitor, TypeScript)

A real implementation of the [Login spec](../spec.md) for **Ionic 8**. Every visual
value resolves through CSS custom properties; every one of the 7 UI states is modeled
explicitly; the screen passes all six `quality-checks/validators` (**100/100**).

```
ionic/
  login.css        — token + style layer: --app-* / --ion-* variables and classes.
                     The ONLY file with raw values; the screen references var(...) only.
  LoginScreen.tsx  — the LoginScreen component (all 7 states, accessible, mode-adaptive).
  README.md        — this file.
```

> Bindings shown are `@ionic/react`; the same component/token approach applies to
> `@ionic/angular` and `@ionic/vue`.

## What it demonstrates

**All 7 states, as a discriminated union.** `LoginStatus` has members literally named
`idle · empty · loading · error · offline · success · permissionDenied`, so TypeScript
forces exhaustive handling.

| State | Behaviour |
|---|---|
| **idle / empty** | Ready form with visible labels; `empty` shows a polite hint and blocks submit. |
| **loading** | `IonButton` swaps its label for an `IonSpinner`, disables itself, locks inputs, **blocks double-submit**. |
| **error** | Generic *"Email or password is incorrect"* — never reveals which field (AUTH-*). Input preserved; `role="alert"` receives focus and is announced. |
| **offline** | Non-blocking banner + Retry (via `@capacitor/network`); Sign in disabled; auto-recovers on reconnect. |
| **success** | `IonModal` offers opt-in biometric enrollment with an explicit **password fallback**; an `ion-toast` confirms. |
| **permissionDenied** | If biometrics are unavailable, an `IonModal` explains why + **Open Settings** + continue-with-password — never a dead end. |

**Tokens via CSS variables.** `LoginScreen.tsx` holds zero raw `#hex`/`px` — colors come
from `--ion-color-*` / `--ion-color-step-*`, spacing/radius from `--app-space-*` /
`--app-radius-*`, all defined in `login.css`. Dark mode is a class **palette**
(`.ion-palette-dark`) — the component doesn't change, only the variable values do; verify
both with `contrast_check.py`.

**Adaptive (`mode`).** Ionic auto-renders `ios` vs `md` chrome/shape; the single component
tree feels native on both. Verify both modes before shipping (`PLAT-*`).

**Accessible auth (WCAG 2.2 · 3.3.8).** `IonInput` with `type="email"`/`type="password"`
+ `autocomplete="email"`/`"current-password"` enables **paste, autofill, password
managers, and passkeys**. Every field has a visible `<label>`; icon-only actions carry
`aria-label`; SSO buttons expose a text label, never logo colour alone.

**Thumb-zone & safe area.** The primary **Sign in** action + SSO live in a sticky footer
padded by `calc(var(--app-space-md) + var(--ion-safe-area-bottom))` so it clears the home
indicator; `IonContent` handles top insets (requires `viewport-fit=cover`).

**Targets.** All interactive controls are `IonButton` (≥48px); no bare tappable icons.

**Dynamic Type & RTL.** No fixed text heights, no sub-12px fonts; layout uses logical CSS
(flex, `slot="start"/"end"`, `padding-inline`) — no physical `left/right` — so it mirrors
in RTL.

## Dependencies

| Package | Why |
|---|---|
| `@ionic/react` + `ionicons` | Ionic components + icon set. |
| `@capacitor/network` | Connectivity for the `offline` state / banner. |

```bash
npm install @ionic/react ionicons @capacitor/network
```

Add `<meta name="viewport" content="viewport-fit=cover" />` and import a dark palette
(`@ionic/react/css/palettes/dark.system.css` or `dark.class.css`) once in the app entry.

## Usage

```tsx
import LoginScreen from './examples/login/ionic/LoginScreen';

<LoginScreen
  authenticate={async (email, password) => { /* your API; throw to show error */ }}
  enrollBiometric={async () => true /* false / throw => permission-denied */}
  onAuthenticated={() => history.replace('/home')}
  openSettings={() => NativeSettings.open(/* … */)}
/>;
```

`authenticate` / `enrollBiometric` are injectable and default to mocks, so the file runs
standalone.

## Validators

`python3 quality-checks/validators/run_all.py examples/login/ionic/` →
**100/100, 0 errors** (`token_lint · contrast_check · target_size_lint · state_coverage ·
dynamic_type_check · rtl_check` all PASS).
