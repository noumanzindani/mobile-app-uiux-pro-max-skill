# Healthcare — Domain Components

> Domain-specific components with required states/behaviors. Built for legibility,
> error-tolerance, and calm. Token-driven; no magic values. Cross-references use
> `[[ID]]`.

## Table of contents

1. [Vitals card](#1-vitals-card)
2. [Medication row](#2-medication-row)
3. [Dosage input](#3-dosage-input)
4. [Emergency-info card](#4-emergency-info-card)
5. [Reminder / adherence control](#5-reminder--adherence-control)
6. [Consent gate](#6-consent-gate)
7. [Rules](#rules)

---

## 1. Vitals card

Displays a measurement (BP, glucose, HR, SpO₂, weight) with context.

- **Value + unit** in large tabular type, scaling with font size (`[[MED-001]]`).
- **Range & status without color** — "In range / High / Low" as text + icon +
  position on a labeled scale, never red/green alone (`[[MED-006]]`, `[[MED-014]]`,
  core `[[CHT-002]]`).
- **Trend** shown with a sparkline that also has a text/arrow equivalent and an
  accessible data-table fallback.
- **Timestamp** — when measured; flag stale readings.

## 2. Medication row

- Name (generic + brand), strength, and a **shape/color/photo** cue to prevent
  look-alike/sound-alike confusion.
- Next dose time and status (due / taken / skipped / missed) as text + icon, not
  color alone.
- Whole row taps to detail; the "mark taken" action is deliberate and undoable
  (`[[MED-012]]`).

## 3. Dosage input

- **Unit is explicit and unambiguous** — mg vs mcg vs mL vs tablets shown inline and
  never inferred; use a picker for units rather than free text where possible
  (`[[MED-011]]`).
- Validate against plausible ranges; warn (don't silently accept) on outliers
  (core `[[FRM-007]]`).
- Large touch targets and numeric keypad (`[[A11Y-007]]`, core `[[FRM-012]]`).

## 4. Emergency-info card

- One-tap reachable, works **offline** (`[[MED-005]]`), and readable at a glance:
  allergies, active conditions, current meds, blood type, emergency contacts.
- High legibility over decoration; usable by a bystander or first responder.
- Never gated behind a slow load or a login the user can't complete in crisis —
  consider a lock-screen/quick-access surface where the platform supports it
  (`[[MED-008]]`).

## 5. Reminder / adherence control

- Snooze and "mark taken/skipped" with calm, non-guilt language (`[[MED-013]]`).
- Confirmation logs adherence and shows a gentle success state; mis-logs are easily
  undone (`[[MED-012]]`).
- Deep-links from the notification straight to this control (core `[[NOTIF-004]]`).

## 6. Consent gate

- Appears **before** collecting or sharing health data (`[[MED-004]]`).
- Plain-language summary of *what data, why, with whom* + a link to full detail
  (`[[MED-010]]`); granular, unbundled toggles (treatment vs research vs marketing).
- Consent is revocable later from settings; the choice is remembered and honored.

---

## Rules

### MED-008 — Provide fast, offline-capable emergency-info access
- **Rule:** Emergency information (allergies, active conditions, current medications, blood type, emergency contacts) MUST be reachable within one tap, render offline, be highly legible at a glance, and MUST NOT be gated behind a slow load or a login/step the user may be unable to complete in a crisis. Prefer a quick-access/lock-screen surface where the platform supports it.
- **Why:** In emergencies, seconds and connectivity are not guaranteed and the user may be incapacitated; buried or online-only emergency info can cost lives.
- **Platforms:** all (lock-screen/quick-access APIs platform-specific)
- **Severity:** error
- **Check:** Emergency card reachable ≤1 tap; renders offline; legible at large type; not behind a blocking login/load.
- **See also:** [[MED-005]], [[MED-001]], [[MED-006]]

### MED-011 — Make dosage, units, and frequency unambiguous
- **Rule:** Dose entry and display MUST show the unit explicitly and unmistakably (mg / mcg / mL / tablets / puffs), prefer constrained pickers over free-text units, validate against plausible ranges with a visible warning on outliers, and state frequency/route in plain language. Never infer or hide units.
- **Why:** Unit confusion (mg vs mL, mg vs mcg) is a classic, dangerous medication error; explicit, constrained units and range checks prevent thousand-fold and wrong-unit mistakes.
- **Platforms:** all
- **Severity:** error
- **Check:** Unit shown inline everywhere a dose appears; unit entry is constrained; out-of-range doses warn; frequency/route in plain words.
- **See also:** [[MED-003]], [[MED-012]], [[FRM-007]]

### MED-012 — Confirm medication reminders and log adherence undoably
- **Rule:** Marking a medication as taken/skipped MUST be a deliberate action with a clear confirmation and success state, MUST record adherence, and MUST allow easy undo of a mistaken entry. Reminder language is supportive, never guilt-inducing.
- **Why:** Accurate adherence records inform care; accidental one-tap logs corrupt them, and undo prevents corrupted history. Supportive tone sustains engagement.
- **Platforms:** all
- **Severity:** warning
- **Check:** Take/skip requires a deliberate action + shows success; adherence recorded; undo available; copy is supportive.
- **See also:** [[MED-003]], [[MED-011]], [[MED-007]], [[MED-013]]

### MED-014 — Vitals card shows value, range, and trend without color-only encoding
- **Rule:** A vitals/measurement display MUST present the value + unit, its in/out-of-range status via a non-color channel (text + icon + position on a labeled scale), a trend with a text/arrow equivalent, an accessible data-table fallback for any chart, and a measurement timestamp with stale-reading flagging.
- **Why:** Color-blind and low-vision users must still read whether a vital is safe; charts without a data alternative and color-only status are decision-blocking in a clinical context.
- **Platforms:** all
- **Severity:** warning
- **Check:** Status readable in grayscale; chart has a data-table/text fallback; unit + timestamp present; stale readings flagged.
- **See also:** [[MED-006]], [[MED-001]], [[CHT-002]]
