# Finance / Banking — Trust & Safety / Compliance UX

> Trust signals, authentication, session handling, data protection (PCI/PII), fraud
> reporting, and the compliance-driven UX that a money app must ship. These are the
> rules that make users feel — and be — safe.

## Table of contents

1. [Trust cues](#1-trust-cues)
2. [Authentication & re-auth](#2-authentication--re-auth)
3. [Sessions & timeout](#3-sessions--timeout)
4. [Data protection (PCI / PII)](#4-data-protection-pci--pii)
5. [Fraud & error reporting](#5-fraud--error-reporting)
6. [Compliance-driven UX](#6-compliance-driven-ux)
7. [Rules](#rules)

---

## 1. Trust cues

Users decide in seconds whether a money app is legitimate. Persistent, honest cues:

- Institution branding + verified name/logo on auth and dashboard.
- Secure-session indicator; **last login** timestamp and device.
- Clear, reachable support and "report a problem" (`[[FIN-008]]`).
- No dark patterns: no fake urgency, no pre-checked opt-ins for fee-bearing products.

Trust is cumulative and fragile — one hidden fee (`[[FIN-010]]`) or one ambiguous
transaction state (`[[FIN-005]]`) undoes it.

## 2. Authentication & re-auth

- **Biometric unlock** with an always-available passcode/password fallback (core
  `[[BIO-001]]`); biometrics are opt-in, never the sole factor.
- **Paste-friendly & password-manager-friendly** fields — do not block paste, do not
  disable autofill, support passkeys (WCAG 3.3.8, core `[[AUTH-003]]`). Blocking
  paste on a one-time-code or password field is a hard fail.
- **Step-up auth** before high-risk actions: adding a payee, raising limits,
  revealing card details, large/first-time transfers (`[[FIN-006]]`).

## 3. Sessions & timeout

- Idle timeout with a **warning + extend** prompt before logout; on timeout, protect
  the session and re-auth without losing in-progress (non-committed) input where safe
  (`[[FIN-011]]`).
- Re-auth on returning from background for sensitive surfaces; mask PII while
  backgrounded (`[[FIN-016]]`).

## 4. Data protection (PCI / PII)

- **Never render or log raw PAN/CVV** (`[[FIN-009]]`).
- Mask account numbers to last 4 everywhere; reveal is explicit and re-auth-gated.
- **Background/app-switcher masking** — obscure balances, card numbers, and PII in
  the OS app-switcher snapshot and block screenshots on sensitive screens where the
  platform allows (`[[FIN-016]]`).
- Keep secrets out of analytics, crash logs, and clipboards.

## 5. Fraud & error reporting

- A **"report a problem / dispute"** path is reachable from every transaction and
  from the payment result (`[[FIN-008]]`). Disputing a charge must never be buried.
- Distinguish "report fraud" (urgent, card-freezing) from "dispute a charge"
  (merchant issue) with distinct, fast paths.
- Offer an immediate **freeze/lock card** control that is prominent and reversible.

## 6. Compliance-driven UX

- Show required disclosures (APR, fees, FX margin, regulatory notices) **at the point
  of decision**, not only in a distant T&C (`[[FIN-010]]`, see copy-and-tone).
- Consent is explicit and unbundled — separate toggles for marketing vs required
  processing; no pre-checked fee opt-ins.
- Provide account closure/deletion reachable per store policy (core `[[PROF-002]]`).

---

## Rules

### FIN-001 — Keep trust & security cues persistent on money surfaces
- **Rule:** Auth, dashboard, and money-movement screens MUST surface honest trust cues: verified institution identity, secure-session indication, last-login/device info (reachable), and a visible support/report path. No fake urgency, no pre-checked fee opt-ins, no dark patterns.
- **Why:** Financial trust is decided fast and lost faster; legitimacy signals reduce phishing susceptibility and abandonment, and dark patterns invite regulatory action.
- **Platforms:** all
- **Severity:** warning
- **Check:** Dashboard/auth show institution identity + support path; audit for pre-checked fee opt-ins and countdown pressure on money actions.
- **See also:** [[FIN-008]], [[FIN-010]], [[FIN-017]]

### FIN-006 — Biometric + paste-friendly auth, with step-up for high-risk actions
- **Rule:** Money-app auth MUST support biometric unlock with a non-biometric fallback, MUST NOT block paste/password-manager/passkeys on credential or OTP fields (WCAG 3.3.8), and MUST require step-up re-auth before high-risk actions (add payee, raise limit, reveal card, large/first-time transfer).
- **Why:** Biometrics + password managers improve both security and accessibility; blocking paste harms users and provides no real security. Step-up scopes friction to genuinely risky moments.
- **Platforms:** all (biometric APIs platform-specific)
- **Severity:** error
- **Check:** Password/OTP fields allow paste + autofill; biometric path has a fallback; high-risk actions trigger re-auth.
- **See also:** [[FIN-011]], [[FIN-009]], [[AUTH-003]], [[BIO-001]]

### FIN-008 — Make fraud and error reporting always reachable
- **Rule:** A path to report fraud, dispute a charge, and freeze/lock a card MUST be reachable from every transaction detail and from any payment result. "Report fraud" (urgent) and "dispute charge" (merchant) are distinct, fast paths; card freeze is prominent and reversible.
- **Why:** Speed of reporting directly limits fraud loss and is often legally mandated; burying these paths harms users and increases liability.
- **Platforms:** all
- **Severity:** error
- **Check:** Report/dispute action present on transaction detail + payment result; a freeze-card control is reachable within two taps.
- **See also:** [[FIN-001]], [[FIN-007]], [[FIN-017]]

### FIN-011 — Enforce idle session timeout with graceful re-auth
- **Rule:** Authenticated money sessions MUST time out after inactivity, warn before logout with an option to extend, and require re-auth on resume for sensitive surfaces. Re-auth must not silently discard in-progress, non-committed input where preserving it is safe.
- **Why:** Unattended, still-authenticated devices are a top account-takeover vector; a warning + graceful re-auth balances security with not losing user work.
- **Platforms:** all
- **Severity:** error
- **Check:** Idle timeout exists with a pre-logout warning; resume triggers re-auth; committed vs draft state handled explicitly.
- **See also:** [[FIN-006]], [[FIN-016]], [[FIN-009]]

### FIN-016 — Mask PII in app-switcher, screenshots, and background
- **Rule:** Balances, card numbers, and PII MUST be masked in the OS app-switcher/recents snapshot and while backgrounded; screenshot capture SHOULD be blocked on card-detail and full-PAN reveal screens where the platform permits. Revealed sensitive values auto-hide after a short timeout.
- **Why:** App-switcher snapshots and screenshots leak financial data to anyone with the device; masking is a standard, low-cost protection expected by regulators and users.
- **Platforms:** iOS (privacy overlay), Android (`FLAG_SECURE`), others where supported
- **Severity:** warning
- **Check:** Sensitive screens apply a background privacy overlay; reveal screens set secure/no-capture flags; revealed values time out.
- **See also:** [[FIN-009]], [[FIN-003]], [[FIN-011]]
