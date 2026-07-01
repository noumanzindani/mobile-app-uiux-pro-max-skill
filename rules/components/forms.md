# Forms & Inputs (FRM)

> Rules for text fields, pickers, toggles, validation, keyboard handling, and submission. Grounded in WCAG 2.2 (3.3.8 accessible auth, 2.4.11 focus, 1.3.5 input purpose) and platform input conventions.

## Contents
- [FRM-001 — Every field has a persistent visible label](#frm-001--every-field-has-a-persistent-visible-label)
- [FRM-002 — Fields meet target, contrast, and token minimums](#frm-002--fields-meet-target-contrast-and-token-minimums)
- [FRM-003 — Logical grouping and reading/focus order](#frm-003--logical-grouping-and-readingfocus-order)
- [FRM-004 — Use the correct keyboard type per field](#frm-004--use-the-correct-keyboard-type-per-field)
- [FRM-005 — Set autofill / content-type hints](#frm-005--set-autofill--content-type-hints)
- [FRM-006 — Allow paste, password managers, and passkeys](#frm-006--allow-paste-password-managers-and-passkeys)
- [FRM-007 — Provide a password reveal toggle](#frm-007--provide-a-password-reveal-toggle)
- [FRM-008 — Keyboard avoidance: never trap the field or submit](#frm-008--keyboard-avoidance-never-trap-the-field-or-submit)
- [FRM-009 — Return key advances or submits](#frm-009--return-key-advances-or-submits)
- [FRM-010 — Debounce inline validation 150–200ms](#frm-010--debounce-inline-validation-150200ms)
- [FRM-011 — Validate on blur/submit, then live once errored](#frm-011--validate-on-blursubmit-then-live-once-errored)
- [FRM-012 — Error messages are specific and actionable](#frm-012--error-messages-are-specific-and-actionable)
- [FRM-013 — Errors are not color-only and are programmatically tied to the field](#frm-013--errors-are-not-color-only-and-are-programmatically-tied-to-the-field)
- [FRM-014 — Don't silently disable submit; focus the first error](#frm-014--dont-silently-disable-submit-focus-the-first-error)
- [FRM-015 — Mark required vs optional fields](#frm-015--mark-required-vs-optional-fields)
- [FRM-016 — Show format, constraints, and examples](#frm-016--show-format-constraints-and-examples)
- [FRM-017 — Preserve input across rotation, navigation, and errors](#frm-017--preserve-input-across-rotation-navigation-and-errors)
- [FRM-018 — Multi-step forms show progress and safe back](#frm-018--multi-step-forms-show-progress-and-safe-back)
- [FRM-019 — Ask for the minimum number of fields](#frm-019--ask-for-the-minimum-number-of-fields)
- [FRM-020 — Use the right control for the data type](#frm-020--use-the-right-control-for-the-data-type)
- [FRM-021 — Native date/time/number pickers, locale-aware](#frm-021--native-datetimenumber-pickers-locale-aware)
- [FRM-022 — Accessible selects; searchable when long](#frm-022--accessible-selects-searchable-when-long)
- [FRM-023 — Checkbox/radio/switch labels are tappable and sized](#frm-023--checkboxradioswitch-labels-are-tappable-and-sized)
- [FRM-024 — Toggles reflect state instantly and not color-only](#frm-024--toggles-reflect-state-instantly-and-not-color-only)
- [FRM-025 — Character limits: counter, announcement, no silent truncation](#frm-025--character-limits-counter-announcement-no-silent-truncation)
- [FRM-026 — Visible focus indicator; focused field not obscured](#frm-026--visible-focus-indicator-focused-field-not-obscured)
- [FRM-027 — Placeholder is supplementary and legible](#frm-027--placeholder-is-supplementary-and-legible)
- [FRM-028 — Submit shows loading and guards double submit](#frm-028--submit-shows-loading-and-guards-double-submit)
- [FRM-029 — Confirm success clearly](#frm-029--confirm-success-clearly)
- [FRM-030 — Confirm before discarding unsaved changes](#frm-030--confirm-before-discarding-unsaved-changes)

---

### FRM-001 — Every field has a persistent visible label
- **Rule:** Each input MUST have a visible label that persists while typing; a placeholder MUST NOT be the only label. The label MUST be programmatically associated with the field.
- **Why:** Placeholder-as-label disappears on input, causing users to forget the field's purpose; associated labels are required for screen readers (WCAG 3.3.2/4.1.2).
- **Platforms:** all
- **Severity:** error
- **Check:** a11y audit — every field has an accessible name; manual — label stays visible while typing.
- **Exceptions:** A search field with an adjacent icon may use a placeholder if it exposes an accessible name.
- **See also:** [[FRM-027]], [[A11Y-004]]

### FRM-002 — Fields meet target, contrast, and token minimums
- **Rule:** Input fields MUST be ≥44pt/48dp tall, draw their colors/border/radius from tokens (no hardcoded values), and render entered text and labels at ≥4.5:1 contrast in every theme.
- **Why:** Adequately sized, theme-aware, legible inputs are baseline usability and WCAG 1.4.3.
- **Platforms:** all
- **Severity:** error
- **Check:** `target_size_lint.py` + `contrast_check.py` + `token_lint.py`.
- **Exceptions:** None.
- **See also:** [[A11Y-001]], [[BTN-016]]

### FRM-003 — Logical grouping and reading/focus order
- **Rule:** Related fields MUST be grouped (with group labels for radio/checkbox sets) and the visual, reading, and focus/tab order MUST match a logical top-to-bottom sequence.
- **Why:** Mismatched order disorients keyboard and screen-reader users (WCAG 1.3.2/2.4.3).
- **Platforms:** all
- **Severity:** warning
- **Check:** a11y audit — traverse with the keyboard/screen reader.
- **Exceptions:** None.
- **See also:** [[A11Y-007]], [[FRM-023]]

### FRM-004 — Use the correct keyboard type per field
- **Rule:** Each field MUST request the appropriate keyboard: email → email keyboard, numbers → numeric/decimal pad, phone → phone pad, URL → URL keyboard, OTP → one-time-code numeric.
- **Why:** The right keyboard reduces input errors and effort.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — focus each field and inspect the keyboard.
- **Exceptions:** None.
- **See also:** [[SRCH-004]], [[FRM-005]]

### FRM-005 — Set autofill / content-type hints
- **Rule:** Fields MUST declare their input purpose/content type (name, email, tel, street-address, postal-code, one-time-code, new/current-password) so the OS can autofill and suggest correctly.
- **Why:** WCAG 2.2 SC 1.3.5 (identify input purpose); autofill dramatically speeds forms and cuts errors.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — confirm OS autofill/QuickType offers the right value.
- **Exceptions:** Genuinely novel fields with no matching content type.
- **See also:** [[FRM-006]], [[A11Y-013]]

### FRM-006 — Allow paste, password managers, and passkeys
- **Rule:** Authentication and sensitive fields MUST allow pasting, MUST work with password managers/OS autofill, and SHOULD support passkeys; never block paste or disable autofill on password/OTP fields.
- **Why:** WCAG 2.2 SC 3.3.8 (accessible authentication); blocking paste forces error-prone manual entry and defeats password managers.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — paste into password/OTP; verify manager autofill.
- **Exceptions:** None (SC 3.3.8 has no cognitive-test exception that justifies blocking paste).
- **See also:** [[A11Y-013]], [[FRM-005]]

### FRM-007 — Provide a password reveal toggle
- **Rule:** Password fields MUST offer a show/hide toggle with a ≥44pt/48dp target and an accessible label that reflects state ("Show password"/"Hide password").
- **Why:** Revealing the password reduces entry errors and lockouts, especially on mobile keyboards.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual + a11y audit.
- **Exceptions:** None.
- **See also:** [[FRM-006]], [[BTN-010]]

### FRM-008 — Keyboard avoidance: never trap the field or submit
- **Rule:** When the keyboard appears, the focused field AND the submit/primary action MUST remain visible above it; the form scrolls or resizes so nothing the user needs is trapped behind the keyboard.
- **Why:** A submit button hidden under the keyboard is the classic mobile-form dead end.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — focus the last field and look for the submit.
- **Exceptions:** None.
- **See also:** [[BSH-006]], [[SRCH-006]]

### FRM-009 — Return key advances or submits
- **Rule:** The keyboard return/action key MUST be set per field — "Next" moves focus to the following field, "Done"/"Go" submits on the last field — enabling keyboard-only completion.
- **Why:** Correct input-action keys make forms fast and are expected mobile behavior.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Multiline text areas where Return inserts a newline.
- **See also:** [[FRM-008]], [[SRCH-012]]

### FRM-010 — Debounce inline validation 150–200ms
- **Rule:** Inline (as-you-type) validation feedback MUST be debounced ~150–200ms so it doesn't fire on every keystroke mid-typing, and MUST NOT show an error for a field the user hasn't finished/left yet on first entry.
- **Why:** Premature, per-keystroke errors punish users while they're still typing and feel hostile.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — type and watch validation timing.
- **Exceptions:** Positive real-time hints (e.g., password-strength meter) that don't show errors.
- **See also:** [[FRM-011]], [[SRCH-001]]

### FRM-011 — Validate on blur/submit, then live once errored
- **Rule:** First-pass validation of a field SHOULD occur on blur or submit; once a field has shown an error, it MUST re-validate live so the error clears as soon as the input becomes valid.
- **Why:** This "reward early, punish late" pattern minimizes friction while confirming fixes immediately.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** None.
- **See also:** [[FRM-010]], [[FRM-012]]

### FRM-012 — Error messages are specific and actionable
- **Rule:** Validation errors MUST state what's wrong and how to fix it in plain language ("Password must be at least 8 characters"), placed adjacent to the field — not a generic "Invalid input" or a top-only summary.
- **Why:** Specific, located guidance lets users recover quickly (WCAG 3.3.1/3.3.3).
- **Platforms:** all
- **Severity:** error
- **Check:** manual — trigger each validation.
- **Exceptions:** Security-sensitive cases (e.g., login) may use a deliberately generic message.
- **See also:** [[BDG-012]], [[FRM-013]]

### FRM-013 — Errors are not color-only and are programmatically tied to the field
- **Rule:** Field errors MUST use text and an icon (not red border/color alone) and MUST be associated with the field for assistive tech (error described-by / invalid state) so screen readers announce the error.
- **Why:** WCAG 1.4.1 (not color-only) and 3.3.1/4.1.3; color-only errors are invisible to color-blind and non-visual users.
- **Platforms:** all
- **Severity:** error
- **Check:** a11y audit + desaturate check.
- **Exceptions:** None.
- **See also:** [[A11Y-010]], [[A11Y-006]]

### FRM-014 — Don't silently disable submit; focus the first error
- **Rule:** If the submit button is disabled pending valid input, the form MUST make clear what's missing; on a failed submit attempt it MUST move focus to and scroll to the first invalid field and announce the error count.
- **Why:** A silently disabled button with no explanation is a dead end; focusing the first error speeds recovery.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual + a11y audit.
- **Exceptions:** None.
- **See also:** [[BTN-007]], [[FRM-012]]

### FRM-015 — Mark required vs optional fields
- **Rule:** The form MUST clearly indicate which fields are required vs optional (label the less-common case consistently) using text — not an unexplained asterisk alone — and expose required state to assistive tech.
- **Why:** Ambiguous requiredness causes failed submits and abandonment (WCAG 3.3.2).
- **Platforms:** all
- **Severity:** warning
- **Check:** a11y audit + manual.
- **Exceptions:** None.
- **See also:** [[FRM-012]], [[A11Y-005]]

### FRM-016 — Show format, constraints, and examples
- **Rule:** Fields with specific formats MUST show the expected format/constraints up front (helper text or example), and SHOULD auto-format where helpful (card number grouping, phone) without blocking valid variants.
- **Why:** Showing format before submission prevents guess-and-fail cycles.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Self-evident fields.
- **See also:** [[FRM-012]], [[CHT-010]]

### FRM-017 — Preserve input across rotation, navigation, and errors
- **Rule:** Entered data MUST survive rotation, backgrounding, transient navigation, and validation errors; a failed submit MUST NOT clear the form (especially not passwords the user must retype).
- **Why:** Data loss on rotation or error is a top cause of form rage and abandonment.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — rotate, background, and fail-submit the form.
- **Exceptions:** Sensitive fields intentionally cleared for security, with the user informed.
- **See also:** [[FRM-028]], [[OFF-001]]

### FRM-018 — Multi-step forms show progress and safe back
- **Rule:** Multi-step forms/wizards MUST show step progress (step N of M or a progress bar), allow going back without losing entered data, and let users review before final submit.
- **Why:** Progress reduces abandonment; safe back and review prevent errors on long flows.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Single-step forms.
- **See also:** [[PRG-001]], [[NAV-006]]

### FRM-019 — Ask for the minimum number of fields
- **Rule:** Forms MUST request only the data actually needed now; defer or infer the rest (derive city/state from postal code, use device location, single full-name field where possible).
- **Why:** Every extra field lowers completion; brevity is the highest-leverage form improvement.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual — justify each field.
- **Exceptions:** Regulatory/KYC fields that are genuinely required.
- **See also:** [[FRM-018]], [[FRM-005]]

### FRM-020 — Use the right control for the data type
- **Rule:** Choose the control that fits the data: segmented control / radios for few exclusive options, switch for on/off, stepper for small counts, picker/select for many options, free text only when open-ended — don't force free text where a constrained control fits.
- **Why:** Constrained controls reduce errors and typing versus free text.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** None.
- **See also:** [[FRM-021]], [[CHP-001]]

### FRM-021 — Native date/time/number pickers, locale-aware
- **Rule:** Dates, times, and constrained numbers MUST use native pickers (not free-text parsing), display and accept locale-aware formats, and respect the user's calendar/time-zone settings.
- **Why:** Native pickers eliminate ambiguous formats (MM/DD vs DD/MM) and parsing errors.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — switch locale.
- **Exceptions:** Power-user fields where typed entry is faster and format is unambiguous.
- **See also:** [[L10N-001]], [[FRM-020]]

### FRM-022 — Accessible selects; searchable when long
- **Rule:** Dropdowns/selects MUST be operable by assistive tech with proper listbox/option semantics; lists longer than ~8–10 options SHOULD be searchable/type-ahead.
- **Why:** Long, un-searchable pickers are tedious; inaccessible ones exclude screen-reader users.
- **Platforms:** all
- **Severity:** warning
- **Check:** a11y audit + manual.
- **Exceptions:** Short option lists.
- **See also:** [[SRCH-001]], [[A11Y-005]]

### FRM-023 — Checkbox/radio/switch labels are tappable and sized
- **Rule:** The label of a checkbox/radio/switch MUST be part of its tap target, the control MUST expose its role and checked/selected state, and the combined target MUST be ≥44pt/48dp.
- **Why:** Tiny toggle-only targets and non-tappable labels cause mis-taps and fail screen readers (WCAG 4.1.2/2.5.8).
- **Platforms:** all
- **Severity:** error
- **Check:** `target_size_lint.py` + a11y audit.
- **Exceptions:** None.
- **See also:** [[FRM-024]], [[A11Y-003]]

### FRM-024 — Toggles reflect state instantly and not color-only
- **Rule:** Switches/toggles MUST reflect the new state immediately (optimistic, with rollback on failure), indicate on/off with more than color (knob position/label/icon), and announce the state change.
- **Why:** WCAG 1.4.1; a green-vs-gray-only switch is ambiguous, and laggy toggles feel broken.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual + desaturate + a11y audit.
- **Exceptions:** None.
- **See also:** [[A11Y-010]], [[OFF-001]]

### FRM-025 — Character limits: counter, announcement, no silent truncation
- **Rule:** Length-limited fields MUST show a character counter as the limit nears, announce the limit to assistive tech, and MUST NOT silently truncate or drop typed characters without feedback.
- **Why:** Silent limits confuse users who lose text without knowing why.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — type past the limit.
- **Exceptions:** None.
- **See also:** [[FRM-016]], [[A11Y-006]]

### FRM-026 — Visible focus indicator; focused field not obscured
- **Rule:** The focused field MUST show a clear focus indicator (≥3:1 against its surroundings) and MUST NOT be hidden behind the keyboard, sticky headers, or overlays when focused.
- **Why:** WCAG 2.2 SC 2.4.11 (focus not obscured) and 2.4.7 (focus visible); a hidden focus point strands keyboard users.
- **Platforms:** all
- **Severity:** error
- **Check:** a11y audit + manual with keyboard/switch control.
- **Exceptions:** None.
- **See also:** [[A11Y-011]], [[FRM-008]]

### FRM-027 — Placeholder is supplementary and legible
- **Rule:** Placeholder text, if used, MUST only supplement the label (example/hint), MUST meet ≥4.5:1 contrast, and MUST NOT carry essential instructions that vanish on input.
- **Why:** Low-contrast placeholders are unreadable and placeholder-only guidance disappears when typing (WCAG 1.4.3).
- **Platforms:** all
- **Severity:** warning
- **Check:** `contrast_check.py` + manual.
- **Exceptions:** None.
- **See also:** [[FRM-001]], [[A11Y-001]]

### FRM-028 — Submit shows loading and guards double submit
- **Rule:** On submit, the primary button MUST enter a loading state, block re-taps/double submission, keep entered data, and remain until the request resolves — then route to success or surface the error inline.
- **Why:** Prevents duplicate submissions (double charges/accounts) and communicates progress.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — rapid double-submit.
- **Exceptions:** None.
- **See also:** [[BTN-006]], [[BTN-018]]

### FRM-029 — Confirm success clearly
- **Rule:** A successful submission MUST give clear confirmation (success screen, inline confirmation, or announced snackbar) and a clear next step — never leave the user unsure whether it worked.
- **Why:** Ambiguous outcomes cause re-submission and anxiety; the success state completes the 7-state model.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual + a11y audit (announcement).
- **Exceptions:** None.
- **See also:** [[STATE-005]], [[BDG-007]]

### FRM-030 — Confirm before discarding unsaved changes
- **Rule:** Navigating away, backing out, or dismissing a form with unsaved edits MUST prompt to save or discard rather than silently losing the input.
- **Why:** Accidental loss of a partially filled form is a severe, avoidable frustration.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — enter data, then attempt to leave.
- **Exceptions:** Trivial or auto-saved forms.
- **See also:** [[BSH-009]], [[NAV-006]]
