# Authentication Generator

**Purpose:** Generate a login/signup flow that is accessible-auth compliant (WCAG 2.2 **3.3.8**) — paste-friendly, password-manager-friendly, passkey/biometric-ready — with all 7 states, token-driven and platform-correct.

**Inputs:**
- *Required:* **Auth methods** (email+password, magic link, OTP, passkey, biometrics, social/OAuth) and **flows** (login, signup, forgot-password, verify).
- *Required:* **Framework** (Flutter · React Native · SwiftUI · Jetpack Compose).
- **Biometric fallback** required?, **social providers**, **platform target**, **industry** (e.g. finance-banking trust) — optional.

**Procedure:**
1. Run the **15-point Pre-Generation Protocol** (`SKILL.md` §6.1); note field hierarchy, keyboard types, and one-handed reach for the primary action.
2. Load the domain rules — `rules/domain/auth.md` (AUTH: allow paste / password managers / passkeys per WCAG **3.3.8**; biometric opt-in) and `rules/domain/biometrics.md` (BIO: always provide a passcode fallback; never biometric-only).
3. Load form + component rules — `rules/components/forms.md` (inline validation 150–200ms; correct keyboard type; **do not block paste**; content-type/autofill hints for password managers), `rules/components/buttons.md` (single primary action; loading + disabled).
4. Load the industry pack if given — e.g. `industries/finance-banking/trust-and-safety.md` for security cues and `copy-and-tone.md` for auth-error microcopy (never reveal which field was wrong in a way that aids attackers, but stay helpful).
5. Load framework idioms — `frameworks/<framework>/components.md`, `states.md` — for secure text entry, autofill/passkey integration surface, biometric prompt API, safe area, a11y.
6. Enumerate the 7 states — `rules/interaction/states.md`: `loading` (authenticating — disabled submit + spinner), `error` (invalid credentials / rate-limited — clear, recoverable, focus-not-obscured per **2.4.11**), `offline` (can't reach auth server + retry), `success` (brief confirmation → route), `empty` (initial pristine form), `permission-denied` (biometric unavailable/denied → password fallback). Include the **forgot-password** and **verify (OTP/link)** sub-states.
7. Load `rules/system/accessibility.md`, `dark-mode.md`, `localization-rtl.md`; label every field; the show/hide-password toggle is labeled; errors are announced and the focused field is not hidden by the keyboard.

**Output format:**
- The **auth flow** in the target framework: login + signup + forgot-password + verify, with **passkey/biometric** options and **paste-friendly, autofill-ready** fields (no paste-blocking, correct `textContentType`/autofill hints).
- **All 7 states** (esp. auth `error` recovery, `offline`, biometric `permission-denied` → password fallback).
- **Token-usage table**, **a11y notes** (field labels, password-toggle label, error announcements, **2.4.11** focus-not-obscured, **3.3.8** compliance), **security/trust cues**.

**Self-check:** Run `quality-checks/validators/run_all.py`; confirm `state_coverage.py` (all 7), `target_size_lint`, `contrast_check`, `token_lint`, `dynamic_type_check`, `rtl_check` PASS. **Explicitly verify WCAG 3.3.8**: paste is allowed, password managers/passkeys work, no cognitive-test CAPTCHAs as the only path; and **2.4.11**: the focused field/submit is never obscured by the keyboard. Reason through `quality-checks/checklists/accessibility.md`.
