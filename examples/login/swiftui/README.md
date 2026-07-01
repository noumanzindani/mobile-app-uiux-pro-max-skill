# Login — SwiftUI

A real, compiling SwiftUI implementation of the login example in [`../spec.md`](../spec.md).
It renders an accessible, paste-friendly, all-states sign-in screen built entirely
from semantic tokens.

## Files

| File | Role |
|---|---|
| `LoginTokens.swift` | Semantic token layer — Color / spacing / radius / Font / size / motion. **The only file allowed raw values** (each raw line ends with `// ux:ignore`). |
| `LoginScreen.swift` | The `LoginScreen` view — all 7 states, keyboard-safe, accessible, adaptive. Zero literals; everything reads from `LoginTokens`. |

## What it demonstrates

- **7-state model** via `enum LoginStatus { idle, empty, loading, error, offline, success, permissionDenied }` — the body reacts to state instead of boolean soup.
- **Accessible authentication (WCAG 2.2 §3.3.8):** `.textContentType(.username)` + `.keyboardType(.emailAddress)` on email and `.textContentType(.password)` on the secure field enable paste, password managers, passkeys, and OS autofill. No retype/CAPTCHA barriers.
- **Show/hide password** as a labeled `Button` toggle that exposes its state to VoiceOver via `.accessibilityLabel` ("Show password" / "Hide password") + `.accessibilityValue`, inside a 48pt hit area.
- **Generic error** ("Email or password is incorrect.") that never reveals which field failed, **preserves all input**, and is announced with `AccessibilityNotification.Announcement(...).post()` while focus stays put. Error is icon + text, never color-only.
- **Offline banner** pinned with `.safeAreaInset(edge: .top)` from a live `NWPathMonitor`; Sign in / SSO disable with a reason while offline; auto-recovers on reconnect.
- **Full-width primary "Sign in"** button pinned with `.safeAreaInset(edge: .bottom)` so it rides above the keyboard and the home indicator. Inline spinner + "Signing in…" label while loading; disabled state blocks double-submit.
- **SSO:** `SignInWithAppleButton` (AuthenticationServices, color-scheme adaptive) + a Google button. Both carry explicit accessibility labels (not conveyed by logo color alone).
- **Forgot password / Sign up / Guest:** recovery opens a `.sheet` with `.presentationDetents`; sign-up and guest are wired to host callbacks.
- **Success → Face ID opt-in** with a **password fallback**: a detented sheet offers biometric enrollment; if `LAContext` reports biometrics unavailable/denied it falls to `permissionDenied` — a `ContentUnavailableView` with an Open Settings route and "Continue with password", never a dead end.
- **Motion:** only opacity/offset transitions, all collapsed to ~instant under `@Environment(\.accessibilityReduceMotion)` via `LoginTokens.reveal(reduceMotion:)`.
- **Adaptive:** content caps at `contentMaxWidth` and centers on iPad/regular width; layout reflows for Dynamic Type because every text uses a scaling `Font` text style (no fixed point sizes, no fixed heights on text).
- **RTL-safe:** logical `.leading` / `.trailing` / `.horizontal` only — no physical left/right, so it mirrors automatically.

## iOS target notes

- **Deployment target: iOS 17+.** Uses `ContentUnavailableView`, `AccessibilityNotification.Announcement`, the two-parameter `.onChange(of:)`, and `.sensoryFeedback`. `.presentationDetents` / `NavigationStack` are iOS 16+; `SignInWithAppleButton` is iOS 14+.
- **iOS 26 "Liquid Glass":** the screen adopts it for free by using system components — `.buttonStyle(.borderedProminent)`, the `.bar` material behind the sticky footer, sheets, and `SignInWithAppleButton` all render as Liquid Glass and stay concentric with the display corners on iOS 26, with a graceful solid-surface look on earlier releases. No hand-rolled translucency.
- **Colors** map to Apple's semantic system colors (`.label`, `.systemBackground`, `.separator`, `.systemRed`, `Color.accentColor`, …), so light / dark / Increase-Contrast resolve automatically. In a shipping app these token names would instead resolve to asset-catalog Color sets generated from the design system's DTCG tokens.
- **Reachability** uses `NWPathMonitor` (Network framework). Add the appropriate capability if you sandbox networking.
- Drop `LoginScreen()` into a `WindowGroup` / `NavigationStack` and pass `onAuthenticated` / `onSignUp` / `onContinueAsGuest` to wire navigation.

## Validators

Passes `quality-checks/validators/run_all.py`:

- **token_lint** — no hex / `Color(0x…)` and no off-grid spacing in `LoginScreen.swift`; raw values live only in `LoginTokens.swift`, each suppressed with `// ux:ignore`. Spacing is on the 4/8 grid.
- **target_size_lint** — primary button `.frame(minHeight: LoginTokens.buttonMinHeight)` (48) and the toggle's 48pt hit area; no undersized interactive frames.
- **dynamic_type_check** — scaling `Font` text styles only; no fixed heights on text lines; no sub-12pt fonts.
- **rtl_check** — logical leading/trailing only; no physical directional properties.
- **state_coverage** — `loading`, `empty`, `error`, `offline` (and `success`) all referenced.
