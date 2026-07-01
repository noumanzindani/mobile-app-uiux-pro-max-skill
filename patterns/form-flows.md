# Form Flows

> Purpose: Design data-entry flows — single-screen and multi-step — that validate helpfully, keep inputs above the keyboard, preserve what the user typed through errors, and stay fully accessible. Forms are the highest-friction, highest-abandonment surface in most apps; this pattern makes them fast, forgiving, and compliant.

## Contents
- [When to use](#when-to-use)
- [Single-screen vs multi-step fork](#single-screen-vs-multi-step-fork)
- [Field anatomy](#field-anatomy)
- [Validation timing & messaging](#validation-timing--messaging)
- [Keyboard avoidance & input types](#keyboard-avoidance--input-types)
- [Multi-step flows](#multi-step-flows)
- [Thumb-zone layout](#thumb-zone-layout)
- [The 7 states](#the-7-states)
- [Accessibility](#accessibility)
- [Motion](#motion)
- [Applied rules](#applied-rules)
- [Anti-patterns](#anti-patterns)
- [Acceptance checklist](#acceptance-checklist)

---

## When to use

Sign-up, profile edit, address, payment, job posting, settings forms, filters — anywhere the user types or picks structured data. For auth specifically pair with domain rules ([[AUTH-001]]); for payment forms pair with [checkout-patterns.md](checkout-patterns.md).

## Single-screen vs multi-step fork

```
How many fields / logical groups?
├─ ≤ ~6 fields, one concern      → SINGLE SCREEN form
├─ 7+ fields OR multiple concerns→ GROUP into sections on one long scroll,
│                                   OR split into a MULTI-STEP wizard when
│                                   steps are sequential/dependent           [[FRM-012]]
└─ Long + high-stakes (checkout, KYC) → MULTI-STEP with a review step        [[FRM-013]]
```

Prefer the **fewest fields possible**: ask only what you need now, defer the rest, use platform autofill and sensible defaults ([[FRM-007]]).

## Field anatomy

Each field is a cluster: **label → input → helper/error**, spaced tightly (4–8dp) and separated from the next field by 16dp ([[SPC-013]]).

- **Always-visible label** above the input; do not rely on placeholder-as-label (it vanishes on focus and fails a11y) ([[FRM-004]]).
- **Correct keyboard + content type** per field: email, number pad, phone, one-time-code, etc. ([[FRM-002]], [[FRM-007]]).
- **Required vs optional** marked explicitly and consistently (mark the shorter set) ([[FRM-006]]).
- **Input formatting/masking** applied as the user types where it aids comprehension (card, phone, currency) without blocking paste ([[FRM-014]], [[AUTH-001]]).
- Field height ≥44pt/48dp; tap target includes the label row ([[A11Y-003]]).

## Validation timing & messaging

- **Validate on blur / after a short pause**, not on every keystroke while the user is mid-typing; confirm success quietly ([[FRM-001]]).
- Show the error **adjacent to its field** with an actionable message ("Enter a valid email like name@example.com"), not a generic "Invalid input" ([[FRM-005]], [[A11Y-018]]).
- Never clear the field or the whole form on error — **preserve every value** ([[FRM-009]]).
- Error is **not color-only**: pair red with an icon + text and an accessible error association ([[A11Y-012]], [[COL-003]]).
- Do not aggressively disable submit; if you do gate it, tell the user what's missing rather than a silently dead button ([[FRM-008]]).
- On submit failure, move focus to the first invalid field and announce the error ([[A11Y-018]], [[A11Y-019]]).

## Keyboard avoidance & input types

- The focused field and its Submit/Next control must stay **visible above the keyboard** — scroll/inset the form using the framework's keyboard-avoidance primitive ([[FRM-003]], [[A11Y-020]]).
- Provide a sensible **return-key action** (Next moves to the next field, Done submits) and logical focus order ([[FRM-010]], [[FRM-011]]).
- Respect the safe area + keyboard inset together; the sticky action bar rides above the keyboard, then above the home indicator when dismissed ([[SPC-011]], [[SPC-016]]).
- Auto-advance only where unambiguous (OTP); never trap focus.

## Multi-step flows

- Show **progress**: step N of M, or a stepper, so the user knows the length up front ([[FRM-012]], [[ONB-004]]).
- Each step is independently valid; **Back preserves prior entries** ([[FRM-009]], [[NAV-005]]).
- End with a **review step** that summarizes all entries and lets the user jump back to edit any section before the irreversible action ([[FRM-013]], [[PAY-002]]).
- Persist progress (draft) so an interruption (call, backgrounding) doesn't lose data ([[OFF-001]]).
- Don't gate the whole flow behind one giant validation at the end — validate per step.

## Thumb-zone layout

| Zone | Role |
|---|---|
| Bottom arc | Primary action (Continue / Save / Pay) as a sticky, full-width button riding above the keyboard ([[BTN-007]]) |
| Middle | The focused field (kept in view) and its neighbors |
| Top | Step title / progress; Back/Close |

Keep the primary action reachable and unambiguous; secondary actions (Skip, Back) are visually subordinate ([[BTN-006]]).

## The 7 states

| State | Form behavior |
|---|---|
| Ideal | Empty-but-ready form, labels visible, correct keyboards |
| Empty | The initial state of a form *is* empty-ready; for edit forms, prefill known values |
| Loading | Submitting: disable the primary button, show inline progress, block double-submit ([[BTN-003]], [[PAY-007]]) |
| Error | Field-level errors preserve input ([[FRM-009]]); form-level error (server) shown at top with retry, values intact ([[STATE-007]]) |
| Offline | Allow entry; queue the submit and show "will send when back online," or disable submit with a clear reason ([[OFF-001]], [[STATE-008]]) |
| Success | Confirmation + clear next step (navigate onward, show the created item) ([[STATE-009]]) |
| Permission-denied | If a field needs a permission (camera for scan, contacts for autofill), explain and offer Settings; keep a manual-entry fallback ([[STATE-010]], [[PERM-004]]) |

## Accessibility

- Every input has a **programmatic label** tied to it; helper/error text is associated so screen readers read it with the field ([[A11Y-004]], [[FRM-004]]).
- Errors use **error identification** (3.3.1) and are announced via a status/live region ([[A11Y-018]], [[A11Y-019]]).
- **Accessible authentication** (3.3.8): allow paste, password managers, passkeys; no cognitive-test barriers ([[A11Y-015]], [[AUTH-001]]).
- Logical focus order matches visual order; focus never obscured by keyboard/sticky bar ([[A11Y-008]], [[A11Y-009]]).
- Dynamic Type to 200% without truncating labels or clipping fields ([[A11Y-010]], [[TYP-004]]).
- Required-state, invalid-state, and character counters are exposed to assistive tech, not visual-only ([[A11Y-006]]).

## Motion

- Error reveal: quick, non-jarring — shake is discouraged; prefer a 150–200ms fade/height change on the message ([[MOT-001]], [[MOT-004]]).
- Step transitions: shared-axis (horizontal) small tier; reduce-motion → cut ([[MOT-001]], [[MOT-004]]).
- Field focus: subtle border/label transition ≤150ms ([[MIC-001]]).
- Success: a brief confirmation animation is fine, but never delay the user's next action behind it ([[MOT-005]]).

## Applied rules

| Intent | Rule |
|---|---|
| Validation timing | [[FRM-001]] |
| Keyboard type per field | [[FRM-002]] |
| Keyboard avoidance | [[FRM-003]], [[A11Y-020]] |
| Visible label | [[FRM-004]] |
| Actionable error near field | [[FRM-005]], [[A11Y-018]] |
| Required/optional marking | [[FRM-006]] |
| Autofill/content type | [[FRM-007]] |
| Preserve input on error | [[FRM-009]] |
| Focus order / return key | [[FRM-010]], [[FRM-011]] |
| Progress in multi-step | [[FRM-012]] |
| Review before submit | [[FRM-013]] |
| Input masking (paste-safe) | [[FRM-014]] |
| Field spacing cluster | [[SPC-013]] |
| Accessible auth | [[A11Y-015]] |
| Error not color-only | [[COL-003]], [[A11Y-012]] |

## Anti-patterns

- ❌ Placeholder text used as the only label ([[FRM-004]]).
- ❌ Validating (and erroring) on every keystroke while typing ([[FRM-001]]).
- ❌ Clearing fields / the form after a validation error ([[FRM-009]]).
- ❌ Blocking paste in email/OTP/card fields ([[A11Y-015]], [[FRM-014]]).
- ❌ Submit button hidden behind the keyboard ([[FRM-003]]).
- ❌ Color-only error indication ([[A11Y-012]]).
- ❌ One giant validation dump at the end of a long form ([[FRM-012]]).
- ❌ Generic "Something went wrong" with no field guidance ([[FRM-005]]).

## Acceptance checklist

- [ ] Fewest necessary fields; autofill + content types set ([[FRM-007]]).
- [ ] Visible labels; helper/error associated programmatically ([[FRM-004]], [[A11Y-004]]).
- [ ] Validate on blur/pause; errors are specific, adjacent, non-color-only, and preserve input ([[FRM-001]], [[FRM-005]], [[FRM-009]], [[A11Y-012]]).
- [ ] Focused field + primary action stay above the keyboard; logical focus order ([[FRM-003]], [[FRM-010]]).
- [ ] Multi-step shows progress, preserves entries, ends with an editable review ([[FRM-012]], [[FRM-013]]).
- [ ] Submitting disables the button and blocks double-submit ([[BTN-003]], [[PAY-007]]).
- [ ] Paste / password managers / passkeys allowed (3.3.8) ([[A11Y-015]]).
- [ ] All 7 states designed, including offline queue and permission fallback ([[STATE-001]]).
- [ ] Text scales to 200% without clipping; targets ≥44pt/48dp ([[A11Y-010]], [[A11Y-003]]).
- [ ] Reduce-motion fallback for step/error animations ([[MOT-004]]).
