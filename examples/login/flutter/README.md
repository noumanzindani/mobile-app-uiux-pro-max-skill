# Login — Flutter reference implementation

A real, compiling Flutter build of the login spec in [`../spec.md`](../spec.md).
Adaptive (Material 3 base, Cupertino accents on iOS), keyboard-avoiding,
accessible, RTL- and Dynamic-Type-safe, reduce-motion aware — and **100 % token
driven** so a rebrand or dark-mode swap is a token change, not a refactor.

| File | Role |
|---|---|
| `login_tokens.dart` | The semantic token layer — color / spacing / radius / size / motion / typography. The **only** file allowed raw values (each raw line ends with `// ux:ignore`). Maps 1:1 to `design-system/tokens/**`. |
| `login_screen.dart` | The `LoginScreen` widget — all 7 states, keyboard avoidance, a11y, SSO, biometric opt-in. References tokens only. |

Verified on **Flutter 3.41 / Dart 3** (`flutter analyze` clean) and scores
**100/100** on `quality-checks/validators/run_all.py`.

## What it demonstrates

**All 7 states** via an explicit `enum LoginStatus { idle, empty, loading, error,
offline, success, permissionDenied }`:

- **idle / empty** — ready form; `Sign in` enabled only once both fields are
  non-empty. Empty *is* the ready state (labels + placeholder hints, no premature
  error styling).
- **loading** — primary button swaps its label for an inline spinner (stable
  width, no jump), disables, and blocks double-submit; inputs lock.
- **error** — generic inline message ("Email or password is incorrect") that
  **never reveals which field** failed, **preserves all input**, moves focus to
  the message, and announces it via `Semantics(liveRegion: true)`. Icon-paired,
  not color-only.
- **offline** — non-blocking live-region banner; `Sign in` disabled with a spoken
  reason. (Toggle the demo switch to preview; wire real detection to
  `connectivity_plus`.)
- **success** — commits the credential (`TextInput.finishAutofillContext()` so the
  OS can save it / mint a passkey), then offers **biometric opt-in with a password
  fallback**.
- **permissionDenied** — if biometric isn't enrolled/denied, a sheet explains and
  offers **Open Settings** or **Keep using password** — never a dead end.

**Accessible authentication (WCAG 2.2 §3.3.8):**

- Correct autofill content types — email field `AutofillHints.username` +
  `.email`, password field `AutofillHints.password` (current-password). This
  enables **paste, password managers, passkeys, and OS autofill**; wrapped in an
  `AutofillGroup`.
- Show/hide password is a **labeled toggle that exposes its state**
  (`Semantics(button: true, toggled: …)`, "Show password" / "Hide password") with
  a **48 dp hit area**.
- Every field has a programmatic label (`InputDecoration.labelText`).
- Targets ≥ 48 dp; text uses `Theme` text styles (no fixed heights, no sub-12
  fonts) so it scales to 200 %+.
- Contrast-safe token pairings in both light and dark.

**Adaptive & layout:**

- SSO order flips by platform (Apple first on iOS, Google first elsewhere); glyphs
  are decorative (`ExcludeSemantics`) — identity is carried by the text label/role.
- Full-width primary **Sign in** sticky in the bottom arc, kept above the keyboard
  via `MediaQuery.viewInsetsOf` and above the home-indicator inset via `SafeArea`.
- `Forgot password`, `Create account`, and `Continue as guest` are present and
  reachable, visually subordinate to the one primary action.

**Motion:** only opacity/height transitions (error + banner reveal, button
crossfade), all collapsed to `Duration.zero` under
`MediaQuery.disableAnimationsOf` (reduce motion). No shake.

## Drop into an app

`LoginScreen` is self-contained — with no arguments it runs a demo that simulates
the network. Wire the callbacks to make it real:

```dart
import 'login_screen.dart';

MaterialApp(
  themeMode: ThemeMode.system,
  theme: ThemeData(brightness: Brightness.light, useMaterial3: true),
  darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
  home: LoginScreen(
    // Return AuthOutcome.success / .invalidCredentials / .serverError.
    authenticate: (email, password) => api.signIn(email, password),
    // Return false (or throw) to route to the permission-denied fallback.
    enrollBiometric: () => localAuth.enrollBiometric(),
    onAuthenticated: () => context.go('/home'),   // honor your deep link here
    onForgotPassword: () => context.push('/recover'),
    onCreateAccount: () => context.push('/signup'),
    onContinueAsGuest: () => context.go('/home?guest=1'),
    onSignInWithApple: () => sso.apple(),
    onSignInWithGoogle: () => sso.google(),
    onOpenSettings: () => AppSettings.openAppSettings(),
    isOffline: connectivity.isOffline,            // e.g. from connectivity_plus
  ),
);
```

Notes:

- **Try the states** in the demo: any email containing `fail` returns the error
  state; the top **Simulate offline** switch previews the offline state; a
  successful sign-in opens the biometric opt-in sheet.
- **Colors** resolve through `LoginColors.of(context)` off `Theme.brightness`. In
  a production app, promote `login_tokens.dart` onto a `ThemeExtension<T>` (see
  `frameworks/flutter/tokens.md`) and read via `Theme.of(context)`.
- **Localization:** copy lives in the private `_Strings` class as a placeholder —
  route it through your i18n layer. Error strings are whole messages (no
  concatenation) so they translate and mirror correctly in RTL.
- The demo-only **Simulate offline** toggle should be removed in production;
  connectivity should come from the platform.

## Validate

```bash
python3 quality-checks/validators/run_all.py examples/login/flutter
# → Readiness score: 100/100 — PASS — clean
```
