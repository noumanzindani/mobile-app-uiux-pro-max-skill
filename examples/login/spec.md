# Example Spec — Login

> Purpose: Reference specification for an accessible, paste-friendly, all-states login screen. This is a **spec, not code** — it defines intent, the 7-state map, layout/thumb-zone, accessibility, token usage, motion, and the validator-backed acceptance gate. Implementations live in `login/<framework>/`.

## Contents
- [Intent / user goal](#intent--user-goal)
- [Platforms & frameworks](#platforms--frameworks)
- [Patterns & rules used](#patterns--rules-used)
- [Layout & thumb-zone](#layout--thumb-zone)
- [States map (all 7)](#states-map-all-7)
- [Accessibility](#accessibility)
- [Token usage](#token-usage)
- [Motion](#motion)
- [Acceptance checklist](#acceptance-checklist)

---

## Intent / user goal

"Let me get into my account as fast and painlessly as possible." The user wants to authenticate — ideally with a passkey, saved password, or platform SSO — with minimal typing and clear recovery if something is wrong. Secondary goals: switch to sign-up, recover a forgotten password, or continue as a guest where allowed.

**Success = authenticated and returned to the intended destination** (respecting any deep link) with the fewest possible taps.

## Platforms & frameworks

- **Paradigm:** Adaptive. iOS uses HIG (native fields, Sign in with Apple, `.sheet` for recovery); Android uses Material 3 Expressive (filled/outlined text fields, Google sign-in). Route via [[PLAT-001]].
- **Frameworks (v1, flagship = all four):** Flutter, React Native, SwiftUI, Jetpack Compose.
- **Framework primitives:** safe-area (`SafeArea` / `safe-area-context` / `.safeAreaInset` / `WindowInsets`); keyboard avoidance is mandatory here.

## Patterns & rules used

- Pattern: [`form-flows.md`](../../patterns/form-flows.md), [`empty-error-offline.md`](../../patterns/empty-error-offline.md).
- Rules: [[AUTH-001]] (paste/passkeys/managers), [[AUTH-002]] (biometric opt-in + fallback), [[AUTH-003]] (show-password toggle), [[AUTH-004]] (don't reveal which field failed), [[AUTH-005]] (SSO), [[AUTH-006]] (forgot password), [[AUTH-007]] (email keyboard/autofill), [[AUTH-008]] (lockout UX), [[AUTH-010]] (guest), [[A11Y-015]] (accessible auth 3.3.8), [[FRM-003]] (keyboard avoidance), [[FRM-009]] (preserve input).

## Layout & thumb-zone

Single screen, vertical stack, single content column ([[GRD-001]], [[SPC-003]]):

```
Top:     Brand mark / title (low interaction)
Middle:  Email field → Password field (+ show/hide) → Forgot password link
Bottom:  [ Primary: Sign in ]  (full-width, sticky above keyboard)
         [ Sign in with Apple / Google ]  (platform SSO)
         "New here? Create account"  ·  "Continue as guest"
```

| Zone | Contents |
|---|---|
| Bottom arc (easy reach) | Primary **Sign in** button (full-width, [[BTN-007]]), SSO buttons, sign-up / guest links — all the actions ([[BTN-006]]) |
| Middle | Email + password fields, kept above the keyboard ([[FRM-003]]) |
| Top | Brand/title, non-interactive |

- Fields are a tight cluster (label → input → error at 4–8dp), 16dp between fields ([[SPC-013]]).
- Primary button and focused field always visible above the keyboard; button rides above the home-indicator inset when keyboard dismisses ([[FRM-003]], [[SPC-016]]).
- One primary action only; SSO/guest are visually subordinate ([[BTN-001]], [[BTN-006]]).

## States map (all 7)

| State | When | How it looks |
|---|---|---|
| **Ideal** | Screen ready | Email + password fields, visible labels, correct keyboards; passkey/autofill suggestions surface from the OS; Sign in enabled once inputs are non-empty. |
| **Empty** | Fresh screen | The ready-empty form *is* the empty state: labels shown, placeholders describe format, no premature error styling. |
| **Loading** | Sign in tapped | Primary button shows inline spinner + disabled, label → "Signing in…"; inputs locked; **double-submit blocked** ([[BTN-003]], [[PAY-007]] analog). |
| **Error** | Wrong credentials / server error | Inline message above the button in plain language ("Email or password is incorrect") — **does not reveal which field** was wrong ([[AUTH-004]]); **all input preserved** ([[FRM-009]]); focus + announce the error ([[A11Y-018]]). Rate-limit/lockout shows a wait message ([[AUTH-008]]). |
| **Offline** | No connectivity | Non-blocking banner "You're offline — check your connection"; Sign in disabled with a reason (auth needs network), inputs preserved; auto-retry affordance when back online ([[STATE-008]], [[BDG-002]]). |
| **Success** | Authenticated | Brief confirmation, then navigate to the intended destination / deep link; offer biometric enrollment ("Use Face ID next time?") — opt-in, with a password fallback ([[AUTH-002]], [[STATE-009]]). |
| **Permission-denied** | Biometric unavailable/denied | If biometric login is offered and the OS denies/does not enroll it, fall back cleanly to password; explain + optional Settings link — never dead-end ([[AUTH-002]], [[STATE-010]], [[PERM-003]]). |

## Accessibility

- **Accessible authentication (WCAG 2.2 3.3.8):** allow **paste**, password managers, passkeys, and OS autofill; no "retype your password" or CAPTCHA cognitive barriers ([[A11Y-015]], [[AUTH-001]]).
- Every field has a programmatic **label** and correct **content type** (username/email, current-password) so autofill works ([[A11Y-004]], [[AUTH-007]]).
- **Show/hide password** is a labeled toggle exposing its state ("Show password" / "Hide password") ([[AUTH-003]], [[A11Y-006]]).
- Errors use **error identification** and announce via a status region; focus moves to the error/first invalid field ([[A11Y-018]], [[A11Y-019]], [[A11Y-008]]).
- **Contrast** ≥4.5:1 for text, ≥3:1 for field borders/focus ring, in both themes ([[A11Y-001]], [[A11Y-002]], [[DRK-004]]).
- **Target size** ≥44pt/48dp for button, links, and toggle with ≥8dp spacing ([[A11Y-003]], [[SPC-005]]).
- **Dynamic Type** to 200% without clipping labels or truncating the button label; layout reflows vertically ([[A11Y-010]], [[TYP-004]]).
- SSO buttons expose correct role/label; not conveyed by logo color alone ([[A11Y-005]], [[A11Y-012]]).
- RTL: layout mirrors; no string concatenation in errors ([[L10N-001]], [[L10N-002]]).

## Token usage

Bind everything to semantic tokens — zero literals ([[COL-001]], [[SPC-004]], [[TYP-002]]):

| Element | Token (semantic) |
|---|---|
| Screen background | `color.surface` / `color.surface.dim` (dark) |
| Field background / border | `color.surface.container` / `color.outline` |
| Field focus ring | `color.action.focus` (≥3:1) |
| Primary button bg / label | `color.action.primary` / `color.on.action.primary` |
| Error text / icon | `color.status.error` (paired with icon, not color-only) |
| Title / body / label text | `type.title.lg` / `type.body.md` / `type.label.md` |
| Edge margins / field gap | `space.4` (16) edge, `space.4` between fields, `space.2`–`space.1` label/error |
| Field radius / button radius | `radius.md` / `radius.md` (or `pill` per brand) |
| Button min height | `size.target.min` (44/48) |

Tokens resolve in light + dark via the semantic layer ([[DRK-001]]); `token_lint.py` must find no hardcoded color/spacing/radius.

## Motion

- Field focus: border/label transition ≤150ms ([[MIC-001]]).
- Error reveal: 150–200ms fade/height on the message — **no shake** ([[MOT-001]], [[MOT-004]]).
- Button loading: spinner cross-fades in as the label changes; ≤200ms ([[BTN-003]]).
- Success: brief check/confirmation, then a shared-axis transition into the app ([[MIC-002]], [[MOT-001]]).
- **Reduce-motion:** all transitions collapse to instant state changes ([[MOT-004]], [[A11Y-011]]).
- Only transform/opacity animated ([[PERF-001]]).

## Acceptance checklist

Validators (run `quality-checks/validators/run_all.py`):

- [ ] `token_lint.py` PASS — no hardcoded color/spacing/radius ([[COL-001]], [[SPC-004]]).
- [ ] `contrast_check.py` PASS — text ≥4.5:1, borders/focus ≥3:1, both themes ([[A11Y-001]], [[A11Y-002]]).
- [ ] `target_size_lint.py` PASS — button/links/toggle ≥44pt/48dp, ≥8dp apart ([[A11Y-003]], [[SPC-005]]).
- [ ] `state_coverage.py` PASS — empty/loading/error/offline all present (+ success, permission handled) ([[STATE-001]]).
- [ ] `dynamic_type_check.py` PASS — no fixed text heights; scales to 200% ([[A11Y-010]]).
- [ ] `rtl_check.py` PASS — no hardcoded left/right; mirrors in RTL ([[L10N-001]]).

Manual / prose:

- [ ] Paste, password managers, passkeys, and autofill all work (3.3.8) ([[A11Y-015]]).
- [ ] Error never reveals which field was wrong; input preserved ([[AUTH-004]], [[FRM-009]]).
- [ ] Double-submit blocked during sign-in ([[BTN-003]]).
- [ ] Biometric is opt-in with a password fallback ([[AUTH-002]]).
- [ ] SSO + forgot-password + guest paths present and reachable ([[AUTH-005]], [[AUTH-006]], [[AUTH-010]]).
- [ ] Deep-link return honored after login ([[NAV-008]]).
- [ ] Reduce-motion fallback verified ([[MOT-004]]).
