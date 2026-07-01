# Biometrics (BIO)

> Purpose: Use Face ID / Touch ID / fingerprint as a convenience layer, never a trap — always a passcode fallback, never the sole factor, clear opt-in enrollment, and graceful lockout handling.

## Contents
- [BIO-001 — Always provide a passcode/password fallback](#bio-001--always-provide-a-passcodepassword-fallback)
- [BIO-002 — Never use biometrics as the sole factor for sensitive actions](#bio-002--never-use-biometrics-as-the-sole-factor-for-sensitive-actions)
- [BIO-003 — Enroll biometrics via a clear opt-in](#bio-003--enroll-biometrics-via-a-clear-opt-in)
- [BIO-004 — Handle biometric lockout gracefully](#bio-004--handle-biometric-lockout-gracefully)
- [BIO-005 — Use the platform biometric prompt API](#bio-005--use-the-platform-biometric-prompt-api)
- [BIO-006 — Match label and icon to the device modality](#bio-006--match-label-and-icon-to-the-device-modality)
- [BIO-007 — Handle not-enrolled and hardware-unavailable states](#bio-007--handle-not-enrolled-and-hardware-unavailable-states)
- [BIO-008 — Never store or transmit raw biometric data](#bio-008--never-store-or-transmit-raw-biometric-data)

---

### BIO-001 — Always provide a passcode/password fallback
- **Rule:** Any biometric gate MUST offer an alternative passcode/password path that is always reachable, not hidden behind repeated failures.
- **Why:** Sensors fail (gloves, masks, wet fingers, injuries); without a visible fallback the user is locked out of their own account.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — cancel/fail the biometric prompt and confirm an accessible fallback.
- **Exceptions:** None.
- **See also:** [[AUTH-011]], [[BIO-004]]

### BIO-002 — Never use biometrics as the sole factor for sensitive actions
- **Rule:** High-value or irreversible actions (payments, transfers, changing credentials, account deletion) MUST NOT rely on biometrics alone; pair with device passcode/password or a second factor.
- **Why:** Biometrics unlock convenience but are spoofable and shared-device risky; sole reliance is inappropriate for high-stakes actions.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — verify sensitive actions require more than a fingerprint/face.
- **Exceptions:** Low-risk conveniences (e.g. unlocking the app view) may use biometrics alone.
- **See also:** [[BIO-001]], [[PAY-015]], [[AUTH-012]]

### BIO-003 — Enroll biometrics via a clear opt-in
- **Rule:** Biometric unlock MUST be an explicit opt-in (a settings/onboarding choice), never silently enabled; explain what it does and let users turn it off later.
- **Why:** Forcing biometrics or enabling it by default violates consent expectations and unsettles privacy-sensitive users.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — confirm biometric unlock is off until the user opts in and is toggleable.
- **Exceptions:** None.
- **See also:** [[BIO-006]], [[ONB-005]]

### BIO-004 — Handle biometric lockout gracefully
- **Rule:** After the OS locks out biometrics (too many failed attempts), the app MUST detect this and route the user to the passcode/password fallback with a clear explanation, not a dead prompt.
- **Why:** A silently failing biometric prompt after lockout looks broken and strands the user.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — fail biometrics past the OS threshold and confirm graceful fallback.
- **Exceptions:** None.
- **See also:** [[BIO-001]], [[AUTH-015]]

### BIO-005 — Use the platform biometric prompt API
- **Rule:** Authenticate via the official APIs (LocalAuthentication / BiometricPrompt) with an accurate reason string and Info.plist usage description (NSFaceIDUsageDescription); do not build a custom sensor UI.
- **Why:** Native prompts are secure, consistent, and required; a missing usage-description string crashes the app or fails review.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — verify native prompt usage and presence of the usage-description string.
- **Exceptions:** None.
- **See also:** [[BIO-006]], [[PERM-001]]

### BIO-006 — Match label and icon to the device modality
- **Rule:** UI copy and icons MUST reflect the actual modality — 'Face ID' + face icon on Face ID devices, 'Touch ID'/'Fingerprint' + fingerprint icon otherwise — detected at runtime, never hardcoded to one.
- **Why:** Prompting for 'Face ID' on a fingerprint device (or vice versa) confuses users and looks broken.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — verify the label/icon match the device's available biometry.
- **Exceptions:** None.
- **See also:** [[BIO-005]], [[L10N-004]]

### BIO-007 — Handle not-enrolled and hardware-unavailable states
- **Rule:** If the device has no biometric hardware or the user has not enrolled, the app MUST hide or disable the biometric option (with explanation) rather than offering a control that always fails.
- **Why:** Offering biometrics where they cannot work produces guaranteed failures and confusion.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — test on a device with no enrolled biometrics and confirm the option is hidden/explained.
- **Exceptions:** None.
- **See also:** [[BIO-004]], [[STATE-007]]

### BIO-008 — Never store or transmit raw biometric data
- **Rule:** The app MUST NOT access, store, or transmit raw biometric templates; rely on the OS secure enclave/keystore, which returns only a success/failure and gates a stored key.
- **Why:** Raw biometric handling is a severe security/privacy violation; the OS is designed to keep templates off-limits.
- **Platforms:** all
- **Severity:** error
- **Check:** grep for any biometric-template access; confirm keystore/enclave-gated pattern.
- **Exceptions:** None.
- **See also:** [[BIO-005]], [[PAY-002]]
