# Login — React Native (TypeScript)

A real, compiling implementation of the [Login spec](../spec.md) for React Native.
Every visual value resolves through semantic tokens; every one of the 7 UI states
is modeled explicitly; the screen passes all six `quality-checks/validators`.

```
react-native/
  loginTokens.ts   — semantic tokens (color/spacing/radius/typography/size/motion).
                     The ONLY file allowed to hold raw literals; each is `// ux:ignore`.
  LoginScreen.tsx  — the LoginScreen component (all 7 states, keyboard-aware, accessible).
  README.md        — this file.
```

## What it demonstrates

**All 7 states, as a discriminated union.** `LoginStatus` has members literally
named `idle · empty · loading · error · offline · success · permissionDenied`, so
TypeScript forces exhaustive handling and the UI can never fall into an unhandled
state.

| State | Behaviour in this screen |
|---|---|
| **idle / empty** | Ready form: visible labels, format placeholders, no premature error styling. `empty` shows a polite hint and blocks submit. |
| **loading** | Primary button swaps its label for an `ActivityIndicator`, disables itself, locks the inputs, and **blocks double-submit**. |
| **error** | Generic message *"Email or password is incorrect"* above the button — never reveals which field failed (AUTH-004). All input is preserved (FRM-009). Focus moves to the message and it is announced via an `assertive` live region. |
| **offline** | Non-blocking banner *"You're offline — check your connection"* with a Retry; Sign in is disabled with an `accessibilityHint` reason; inputs preserved; auto-recovers when connectivity returns. |
| **success** | Opt-in biometric enrollment card (*"Use biometrics"*) with an explicit **password fallback** (*"Not now, use my password"*). |
| **permissionDenied** | If biometrics are unavailable/denied, a card explains why and offers **Open Settings** + continue-with-password — never a dead end. |

**Accessible authentication (WCAG 2.2 · 3.3.8).**
- Email uses `textContentType="username"` + `autoComplete="email"`; password uses
  `textContentType="password"` + `autoComplete="current-password"`. This enables
  **paste, OS autofill, password managers, and passkey/QuickType suggestions** — no
  "retype your password", no CAPTCHA.
- Every field has a visible label wired programmatically (`nativeID` +
  `accessibilityLabelledBy`).
- **Show/hide password** is a real toggle: `accessibilityRole="button"` with
  `accessibilityState={{ selected }}` and a label that flips between *Show
  password* / *Hide password*.
- SSO buttons expose `accessibilityRole="button"` + a text label (never conveyed
  by logo colour alone). Apple appears only on iOS; Google on both.

**Layout & thumb-zone.** The primary **Sign in** button is full-width and lives in
a sticky footer kept above the keyboard via `KeyboardAvoidingView`
(`behavior: padding | height`) and above the home-indicator via
`useSafeAreaInsets().bottom`. SSO, sign-up, and guest links sit in the same
bottom reach-arc; the brand/title stays at the top.

**Tokens only.** `LoginScreen.tsx` contains zero raw hex/spacing literals — colors,
spacing (4/8 grid), radius, type roles, target sizes, and motion durations all come
from `loginTokens.ts`. Dark mode is automatic via `useColorScheme()` → `getColors()`.

**Dynamic Type & RTL.** Text uses scalable token roles (`fontSize ≥ 12`,
`allowFontScaling` left at its default `true`, no fixed text heights). Layout uses
logical properties (`paddingStart`, `marginStart`, `flex-start`,
`writingDirection`) — no `left/right` — so it mirrors in RTL.

**Motion & reduce-motion.** The only animation is the error reveal (opacity via
`Animated`, ≤150 ms). It collapses to an instant state change when
`AccessibilityInfo.isReduceMotionEnabled()` is on. Only `opacity` is animated.

## Dependencies

Beyond `react` / `react-native`:

| Package | Why |
|---|---|
| [`react-native-safe-area-context`](https://github.com/th3rdwave/react-native-safe-area-context) | `useSafeAreaInsets()` + `SafeAreaView` — precise per-edge insets so the sticky footer clears the home indicator (never hardcode `34`/`44`). |
| [`@react-native-community/netinfo`](https://github.com/react-native-netinfo/react-native-netinfo) | Connectivity detection that drives the `offline` state / banner and the disabled Sign in. |

```bash
npm install react-native-safe-area-context @react-native-community/netinfo
# or: yarn add react-native-safe-area-context @react-native-community/netinfo
```

Wrap the app once in `<SafeAreaProvider>` (from `react-native-safe-area-context`)
so `useSafeAreaInsets()` resolves.

## Usage

```tsx
import LoginScreen from './examples/login/react-native/LoginScreen';

<LoginScreen
  authenticate={async (email, password) => { /* your API call; throw to show error */ }}
  enrollBiometric={async () => true /* false / throw => permission-denied */}
  onAuthenticated={() => navigation.replace('Home')}   // honor deep-link return here
  onForgotPassword={() => navigation.navigate('ResetPassword')}
  onSignUp={() => navigation.navigate('SignUp')}
  onContinueAsGuest={() => navigation.replace('Home')}
  onAppleSignIn={signInWithApple}
  onGoogleSignIn={signInWithGoogle}
/>;
```

`authenticate` and `enrollBiometric` are injectable and default to lightweight
mocks, so the file compiles and runs standalone; reject `authenticate` to exercise
the error state and resolve `enrollBiometric` to `false` (or throw) to exercise
permission-denied.

## Validators

`python3 quality-checks/validators/run_all.py examples/login/react-native/` →
**100/100, 0 errors** (`token_lint · contrast_check · target_size_lint ·
state_coverage · dynamic_type_check · rtl_check` all PASS).
