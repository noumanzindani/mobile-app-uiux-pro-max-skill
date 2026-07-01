# Healthcare — Domain Accessibility

> Health-specific accessibility on top of core `[[A11Y-…]]`. The healthcare audience
> skews **older, lower-vision, lower-dexterity, and cognitively varied**, so the
> accessibility bar is the highest in this skill. Focus: large-type legibility,
> color-independent clinical status, reduce-motion, and forgiving forms.

## Focus areas

### Legibility at the largest text sizes
- Design for the **largest** Dynamic Type / system font scale, not just the default.
  Older and low-vision users routinely run 150–200%+. Layouts must reflow, wrap, and
  resize without truncation or overlap (`[[MED-001]]`, core `[[TYP-006]]`).
- Generous default type and line spacing; comfortable, not compact, density.
- Meet contrast minimums (text 4.5:1, large text/icons 3:1) in light and dark
  (`[[A11Y-007]]`).
- Large touch targets (≥44pt/48dp) with generous spacing help users with tremor or
  reduced dexterity (`[[A11Y-007]]`).

### Color-independent clinical status
- In/out-of-range, positive/negative, and alert states must be readable without color
  — text + icon + position (`[[MED-006]]`, `[[MED-014]]`, core `[[CHT-002]]`). Verify
  by grayscale review. This is critical: color-blind users must still know if a vital
  is safe.
- Every chart has a data-table or text-summary fallback for screen readers.

### Reduce-motion (calm is also accessible)
- Honor the OS reduce-motion setting for all animation; provide static equivalents.
  Beyond comfort, this prevents vestibular reactions and respects the low-arousal
  goal (`[[MED-016]]`, `[[MED-002]]`, core `[[MOT-011]]`). Never flash/strobe
  (seizure risk).

### Forgiving forms & inputs
- Symptom/intake forms are long and often filled by unwell users. Make them **short
  where possible, resumable, forgiving, and clearly labeled**, with programmatically
  associated labels and inline, non-color error text (core `[[FRM-007]]`).
- Don't demand precision the user can't give — allow "not sure," ranges, and free-text
  alongside structured input (`[[MED-009]]`).
- Correct input types/keyboards; large targets; no timeouts that penalize slow,
  impaired, or distracted users (or generous, extendable ones).

### Screen-reader clinical semantics
- Vitals, doses, and status expose meaningful labels ("Blood pressure 142 over 90,
  above your target range"), not raw glyphs.
- Announce important state changes (dose logged, result received) via live regions.

---

## Rules

### MED-001 — Remain legible at the largest Dynamic Type / font scale
- **Rule:** Health UIs MUST support the largest system text size (Dynamic Type / font scale, ~200%+) with layouts that reflow, wrap, and resize without truncation, clipping, or overlap; MUST use generous default type, line spacing, and comfortable density; and MUST meet contrast minimums in light and dark. No fixed text-container heights that clip scaled text.
- **Why:** The healthcare audience skews older and low-vision; unreadable or clipped text at large sizes can hide dose, range, or instruction information and cause harm, not just annoyance.
- **Platforms:** all (Dynamic Type / fontScale APIs platform-specific)
- **Severity:** error
- **Check:** At max font scale, no truncated/overlapping/clipped text; containers grow; contrast ≥ minimums; density comfortable.
- **See also:** [[MED-006]], [[MED-008]], [[MED-014]], [[TYP-006]], [[A11Y-007]]

### MED-006 — Never encode clinical status by color alone
- **Rule:** In/out-of-range, positive/negative, alert, and adherence status MUST be conveyed by a non-color channel (text label, icon, shape, position on a labeled scale) in addition to any color, MUST pass a grayscale review, and any chart MUST provide a data-table or text-summary fallback.
- **Why:** WCAG 1.4.1; color-vision-deficient and low-vision users must still read whether a vital is safe or a result is abnormal — color-only clinical status is decision-blocking and potentially dangerous.
- **Platforms:** all
- **Severity:** error
- **Check:** Clinical status readable in grayscale with a text/icon cue; charts have a data alternative; contrast ≥ minimums.
- **See also:** [[MED-001]], [[MED-014]], [[CHT-002]], [[A11Y-007]]

### MED-009 — Make symptom and intake forms accessible and forgiving
- **Rule:** Symptom/intake forms MUST use clear, programmatically-associated labels, correct input types, large targets, and inline non-color error text; MUST be resumable and avoid punishing timeouts; and MUST allow imprecision ("not sure," ranges, free text) rather than forcing false precision from unwell users.
- **Why:** These forms are completed by people who feel bad and vary widely in literacy and dexterity; rigid, timed, precision-demanding forms cause errors, abandonment, and inaccurate clinical data.
- **Platforms:** all
- **Severity:** warning
- **Check:** Labels associated; input types correct; targets ≥44pt/48dp; errors inline + non-color; form resumable; no harsh timeouts; imprecise answers allowed.
- **See also:** [[MED-001]], [[MED-011]], [[FRM-007]]

### MED-016 — Respect reduce-motion for all health animation
- **Rule:** All animation MUST honor the OS reduce-motion setting with a static or minimal equivalent, and MUST NOT flash or strobe. This is both an accessibility requirement and part of the calm, low-arousal mandate.
- **Why:** Motion can trigger vestibular disorders and photosensitive seizures; anxious/impaired users are especially affected. Reduce-motion support is a WCAG-aligned baseline, doubly important in a health context.
- **Platforms:** all (reduce-motion APIs platform-specific)
- **Severity:** error
- **Check:** Reduce-motion setting removes/replaces animation with a static path; no flashing/strobing content.
- **See also:** [[MED-002]], [[MED-001]], [[MOT-011]]
