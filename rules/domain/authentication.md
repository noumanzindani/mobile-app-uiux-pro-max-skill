# Authentication (AUTH)

> Purpose: Make sign-up and sign-in fast, recoverable, and accessible — paste-friendly, password-manager and passkey ready, with biometric opt-in and clear error recovery (WCAG 2.2 §3.3.8).

## Contents
- [AUTH-001 — Permit paste in every credential field](#auth-001--permit-paste-in-every-credential-field)
- [AUTH-002 — Integrate OS autofill and password managers](#auth-002--integrate-os-autofill-and-password-managers)
- [AUTH-003 — Offer passkeys as a first-class sign-in method](#auth-003--offer-passkeys-as-a-first-class-sign-in-method)
- [AUTH-004 — Never require a cognitive-puzzle CAPTCHA to authenticate](#auth-004--never-require-a-cognitive-puzzle-captcha-to-authenticate)
- [AUTH-005 — Provide a password reveal toggle](#auth-005--provide-a-password-reveal-toggle)
- [AUTH-006 — Forgot-password reachable in one tap from sign-in](#auth-006--forgot-password-reachable-in-one-tap-from-sign-in)
- [AUTH-007 — Offer email plus social, with Sign in with Apple parity](#auth-007--offer-email-plus-social-with-sign-in-with-apple-parity)
- [AUTH-008 — Specific, recoverable inline error messages](#auth-008--specific-recoverable-inline-error-messages)
- [AUTH-009 — Set the correct keyboard and content type per field](#auth-009--set-the-correct-keyboard-and-content-type-per-field)
- [AUTH-010 — Autofill one-time codes with a single field and resend timer](#auth-010--autofill-one-time-codes-with-a-single-field-and-resend-timer)
- [AUTH-011 — Biometric login is opt-in with a mandatory fallback](#auth-011--biometric-login-is-opt-in-with-a-mandatory-fallback)
- [AUTH-012 — Persist sessions and step up only for sensitive actions](#auth-012--persist-sessions-and-step-up-only-for-sensitive-actions)
- [AUTH-013 — Primary submit CTA in the thumb zone with an inline loading state](#auth-013--primary-submit-cta-in-the-thumb-zone-with-an-inline-loading-state)
- [AUTH-014 — Announce validation state to assistive tech, not by color alone](#auth-014--announce-validation-state-to-assistive-tech-not-by-color-alone)
- [AUTH-015 — Lockout and rate-limit states show wait time and recovery](#auth-015--lockout-and-rate-limit-states-show-wait-time-and-recovery)
- [AUTH-016 — Follow NIST 800-63B password rules](#auth-016--follow-nist-800-63b-password-rules)
- [AUTH-017 — Minimize sign-up fields and defer non-essential data](#auth-017--minimize-sign-up-fields-and-defer-non-essential-data)
- [AUTH-018 — Ship all 7 UI states on auth screens](#auth-018--ship-all-7-ui-states-on-auth-screens)

---

### AUTH-001 — Permit paste in every credential field
- **Rule:** Email, username, password, and one-time-code fields MUST accept clipboard paste; never disable paste, `onPaste`, or long-press paste.
- **Why:** Blocking paste breaks password managers and forces error-prone manual entry; it is an explicit WCAG 2.2 §3.3.8 Accessible Authentication failure.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — attempt to paste into each credential field; grep for disabled-paste handlers.
- **Exceptions:** None.
- **See also:** [[AUTH-002]], [[AUTH-003]], [[A11Y-030]]

### AUTH-002 — Integrate OS autofill and password managers
- **Rule:** Credential fields MUST declare autofill content-type hints (`textContentType`/`autofillHints`/`autocomplete`) so the OS and third-party managers can fill username, password, and new-password.
- **Why:** Native autofill removes the memory/transcription burden that §3.3.8 forbids and cuts sign-in abandonment.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — verify each field exposes the correct autofill hint; QuickType/Autofill bar appears.
- **Exceptions:** None for standard username/password; ephemeral throwaway codes may omit hints.
- **See also:** [[AUTH-001]], [[AUTH-010]], [[FRM-014]]

### AUTH-003 — Offer passkeys as a first-class sign-in method
- **Rule:** Where the backend supports WebAuthn, expose passkey creation and sign-in at least as prominently as password entry, using the platform passkey APIs.
- **Why:** Passkeys are phishing-resistant, require no memorization, and are the strongest §3.3.8-compliant method available in 2025–2026.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual — confirm a passkey path exists and uses the native credential API.
- **Exceptions:** Backends without WebAuthn support; regulated flows mandating a specific factor.
- **See also:** [[AUTH-011]], [[BIO-001]]

### AUTH-004 — Never require a cognitive-puzzle CAPTCHA to authenticate
- **Rule:** Do not gate sign-in behind puzzles requiring transcription, calculation, memorization, or object-recognition. Use device attestation, risk-based challenges, or honeypots instead.
- **Why:** Cognitive-function tests are a direct WCAG 2.2 §3.3.8/§3.3.9 failure and disproportionately block users with cognitive or motor disabilities.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — inspect anti-bot step for a cognitive test with no accessible alternative.
- **Exceptions:** Object-recognition CAPTCHAs are tolerated only if a non-cognitive alternative (e.g. device passkey) is offered.
- **See also:** [[AUTH-003]], [[A11Y-031]]

### AUTH-005 — Provide a password reveal toggle
- **Rule:** Password fields MUST offer a show/hide toggle (default hidden) with a ≥44pt/48dp hit area and a labeled, state-announced control.
- **Why:** Letting users verify what they typed reduces failed attempts and supports §3.3.8 without weakening security.
- **Platforms:** all
- **Severity:** warning
- **Check:** target_size_lint.py on the toggle; manual — VoiceOver/TalkBack announces show/hide state.
- **Exceptions:** Fields masked for shoulder-surfing-sensitive contexts may default to a shorter reveal timeout.
- **See also:** [[AUTH-014]], [[A11Y-012]]

### AUTH-006 — Forgot-password reachable in one tap from sign-in
- **Rule:** A visible 'Forgot password?' affordance MUST sit on the sign-in screen itself, reachable without scrolling on a standard phone viewport.
- **Why:** Recovery is the most common auth need; burying it forces account abandonment.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — confirm the reset entry point is on the login screen above the fold.
- **Exceptions:** Passwordless/passkey-only flows that have no password to reset.
- **See also:** [[AUTH-008]], [[AUTH-015]]

### AUTH-007 — Offer email plus social, with Sign in with Apple parity
- **Rule:** Provide at least one email/passwordless option alongside social sign-in. If any third-party social login (Google/Facebook/etc.) is offered on iOS, Sign in with Apple MUST be offered with equivalent prominence.
- **Why:** Choice reduces friction, and App Store Review Guideline 4.8 requires an equivalent private login option when third-party social login is used.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — enumerate providers; verify Sign in with Apple present on iOS builds when other social is present.
- **Exceptions:** 4.8 exemptions (e.g. education/enterprise apps using an org-specific IdP, or apps using only their own account system).
- **See also:** [[AUTH-002]], [[PROF-001]]

### AUTH-008 — Specific, recoverable inline error messages
- **Rule:** Auth errors MUST state what went wrong and how to fix it inline next to the field or action (e.g. 'No account uses this email — create one?'), not a generic 'Something went wrong'.
- **Why:** Actionable recovery text is required by WCAG 2.2 §3.3.1/§3.3.3 and turns dead-ends into completed sign-ins.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — trigger each failure path and read the message.
- **Exceptions:** Deliberately vague messaging for credential mismatches to limit account enumeration (still offer a recovery link).
- **See also:** [[AUTH-015]], [[AUTH-014]], [[STATE-014]]

### AUTH-009 — Set the correct keyboard and content type per field
- **Rule:** Email fields use the email keyboard with autocapitalization and autocorrect off; numeric OTP fields use a number pad; name fields use word-capitalization. Match keyboard type to expected input.
- **Why:** The right keyboard removes taps and prevents autocorrect from corrupting credentials.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — focus each field and verify keyboard type and capitalization/correction flags.
- **Exceptions:** Alphanumeric codes need a default keyboard rather than a number pad.
- **See also:** [[FRM-011]], [[AUTH-010]]

### AUTH-010 — Autofill one-time codes with a single field and resend timer
- **Rule:** SMS/email OTP entry MUST support OS one-time-code autofill (`oneTimeCode`/SMS Retriever), accept paste, use one auto-advancing field or clearly linked boxes, and expose a resend action gated by a visible countdown.
- **Why:** Autofilled codes and paste eliminate transcription errors; a resend timer handles undelivered messages without spamming.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — trigger an OTP and confirm autofill suggestion, paste, and resend countdown.
- **Exceptions:** None for phone/email OTP.
- **See also:** [[AUTH-001]], [[AUTH-002]], [[AUTH-015]]

### AUTH-011 — Biometric login is opt-in with a mandatory fallback
- **Rule:** Biometric sign-in MUST be opt-in (never forced at first launch) and MUST always expose a passcode/password fallback path; biometrics are never the sole way in.
- **Why:** Sensors fail, users wear masks/gloves, and lockouts happen — a fallback keeps people from being locked out of their own account.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — decline biometrics and confirm an alternative sign-in completes.
- **Exceptions:** None.
- **See also:** [[BIO-001]], [[BIO-004]], [[AUTH-012]]

### AUTH-012 — Persist sessions and step up only for sensitive actions
- **Rule:** Keep users signed in with silent token refresh; do not force full re-login on every launch. Require step-up re-auth (biometric/passcode) only for sensitive actions such as payments, changing email/password, or account deletion.
- **Why:** Needless re-login is the top auth friction complaint; scoping re-auth to risky actions balances security and usability.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — relaunch app (stays signed in); attempt a sensitive action (prompts step-up).
- **Exceptions:** High-security/regulated apps (banking, health) may enforce shorter session timeouts.
- **See also:** [[BIO-002]], [[PAY-015]], [[PROF-008]]

### AUTH-013 — Primary submit CTA in the thumb zone with an inline loading state
- **Rule:** The primary sign-in/continue button MUST sit in the lower thumb-reachable third, be ≥44pt/48dp, and show an inline spinner + disabled (non-duplicable) state while the request is in flight.
- **Why:** Bottom placement suits one-handed use, and an explicit pending state prevents double-submits and blind waiting.
- **Platforms:** all
- **Severity:** warning
- **Check:** target_size_lint.py on the CTA; manual — submit and observe the loading state.
- **Exceptions:** Split layouts on large/tablet screens may anchor the CTA within the form column.
- **See also:** [[BTN-007]], [[STATE-005]], [[AUTH-018]]

### AUTH-014 — Announce validation state to assistive tech, not by color alone
- **Rule:** Field validity and error text MUST be exposed programmatically (accessibility state + associated error, live region on submit) and never signaled by color alone.
- **Why:** Screen-reader and colorblind users cannot perceive a red border; WCAG 2.2 §1.4.1 and §3.3.1 require non-color, programmatic cues.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — VoiceOver/TalkBack reads the error; verify a non-color indicator (icon/text).
- **Exceptions:** None.
- **See also:** [[AUTH-008]], [[A11Y-018]], [[FRM-020]]

### AUTH-015 — Lockout and rate-limit states show wait time and recovery
- **Rule:** When sign-in is throttled or locked, the UI MUST state the reason, the time remaining before retry, and an alternate recovery path (reset password, contact support).
- **Why:** Silent failures after repeated attempts read as a broken app; a clear countdown plus recovery prevents support escalations.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — trigger the lockout threshold and read the state.
- **Exceptions:** Security policy may cap how much timing detail is disclosed.
- **See also:** [[AUTH-008]], [[AUTH-006]], [[STATE-014]]

### AUTH-016 — Follow NIST 800-63B password rules
- **Rule:** Accept passwords/passphrases of at least 64 characters and all printable Unicode; do NOT impose composition rules (forced symbols/mixed case) or periodic rotation. Screen new passwords against known-breached lists.
- **Why:** Modern NIST 800-63B guidance shows composition/rotation theater harms usability without improving security; length and breach-screening are what matter.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — verify a long passphrase is accepted and no forced-rotation prompt exists.
- **Exceptions:** Regulatory regimes that still mandate specific composition rules.
- **See also:** [[AUTH-005]], [[AUTH-003]]

### AUTH-017 — Minimize sign-up fields and defer non-essential data
- **Rule:** Request only the fields required to create the account at sign-up; collect profile details, preferences, and optional data progressively after first value is delivered.
- **Why:** Every extra field lowers completion; progressive profiling gets users to the product faster.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual — count required sign-up fields; confirm optional data is deferred.
- **Exceptions:** Compliance-driven KYC/identity flows that legally require upfront data.
- **See also:** [[ONB-007]], [[PROF-002]]

### AUTH-018 — Ship all 7 UI states on auth screens
- **Rule:** Auth screens MUST design ideal, empty (pristine form), loading (submitting), error (invalid/expired), offline (no network), success (signed in / email sent), and permission-denied (biometric/contacts declined) states.
- **Why:** Auth is a network-dependent, permission-touching flow where missing states cause the worst first impressions.
- **Platforms:** all
- **Severity:** error
- **Check:** state_coverage.py on the auth screen set.
- **Exceptions:** Permission-denied is N/A when the flow requests no OS permission.
- **See also:** [[STATE-001]], [[OFF-003]], [[AUTH-013]]
