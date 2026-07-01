# Progress & Sliders (PRG)

> Rules for progress indicators (linear/circular), skeletons, and sliders — determinacy, thresholds, and adjustable accessibility semantics.

## Contents
- [PRG-001 — Determinate when the duration is knowable](#prg-001--determinate-when-the-duration-is-knowable)
- [PRG-002 — Match the indicator to the wait length](#prg-002--match-the-indicator-to-the-wait-length)
- [PRG-003 — Prefer skeletons for content loads](#prg-003--prefer-skeletons-for-content-loads)
- [PRG-004 — Announce progress and completion](#prg-004--announce-progress-and-completion)
- [PRG-005 — Progress meets non-text contrast ≥3:1](#prg-005--progress-meets-non-text-contrast-31)
- [PRG-006 — Respect reduce-motion in indeterminate animation](#prg-006--respect-reduce-motion-in-indeterminate-animation)
- [PRG-007 — Sliders expose the adjustable trait](#prg-007--sliders-expose-the-adjustable-trait)
- [PRG-008 — Slider thumb meets the touch-target minimum](#prg-008--slider-thumb-meets-the-touch-target-minimum)
- [PRG-009 — Sliders show the current value and are keyboard/AT steppable](#prg-009--sliders-show-the-current-value-and-are-keyboardat-steppable)
- [PRG-010 — Style progress and sliders from tokens](#prg-010--style-progress-and-sliders-from-tokens)

---

### PRG-001 — Determinate when the duration is knowable
- **Rule:** Use a determinate progress indicator (with real percent/step) whenever total work or time is known (uploads, downloads, multi-step flows); reserve indeterminate spinners for genuinely unknown waits.
- **Why:** Determinate progress sets expectations and lowers perceived wait and abandonment.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — is progress data available but shown as a spinner?
- **Exceptions:** Unknown-length operations (server think-time) legitimately use indeterminate.
- **See also:** [[PRG-002]], [[STATE-001]]

### PRG-002 — Match the indicator to the wait length
- **Rule:** For waits <1s show no spinner (or delay it ~500ms to avoid flicker); 1–10s show an indicator; >10s show determinate progress with the ability to continue working or cancel where possible.
- **Why:** Nielsen response thresholds (0.1s/1s/10s); spinner flicker on fast responses feels broken.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** None.
- **See also:** [[BTN-006]], [[PRG-001]]

### PRG-003 — Prefer skeletons for content loads
- **Rule:** When loading structured content (lists, cards, detail screens), use skeleton placeholders that mirror the final layout rather than a centered spinner or blank screen.
- **Why:** Skeletons communicate structure and reduce perceived latency versus an opaque spinner.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Small inline loads where a spinner is clearer.
- **See also:** [[LST-008]], [[CRD-012]]

### PRG-004 — Announce progress and completion
- **Rule:** Progress indicators MUST expose a progress role/value to assistive tech and announce meaningful milestones and completion via a polite live region (e.g., "Upload complete").
- **Why:** Non-visual users need to know work is happening and when it finishes (WCAG 4.1.3).
- **Platforms:** all
- **Severity:** error
- **Check:** a11y audit.
- **Exceptions:** None.
- **See also:** [[A11Y-006]], [[BDG-007]]

### PRG-005 — Progress meets non-text contrast ≥3:1
- **Rule:** The active (filled) track of a progress bar or slider MUST have ≥3:1 contrast against the inactive track/background in every theme.
- **Why:** WCAG 2.2 SC 1.4.11; the progress value must be perceivable.
- **Platforms:** all
- **Severity:** warning
- **Check:** `contrast_check.py`.
- **Exceptions:** None.
- **See also:** [[A11Y-002]], [[PRG-010]]

### PRG-006 — Respect reduce-motion in indeterminate animation
- **Rule:** Indeterminate spinners/looping progress animations MUST honor reduce-motion by slowing, simplifying, or replacing continuous spin with a subtler cue.
- **Why:** Continuous motion can trigger vestibular discomfort (WCAG 2.3.3).
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — enable reduce-motion.
- **Exceptions:** None.
- **See also:** [[A11Y-009]], [[MOT-002]]

### PRG-007 — Sliders expose the adjustable trait
- **Rule:** Sliders MUST expose the adjustable/slider trait (role) plus current, min, and max values so assistive tech announces "adjustable" and reads the value on change.
- **Why:** Without the trait, screen-reader users cannot operate the control (WCAG 4.1.2).
- **Platforms:** all
- **Severity:** error
- **Check:** a11y audit.
- **Exceptions:** None.
- **See also:** [[A11Y-005]], [[PRG-009]]

### PRG-008 — Slider thumb meets the touch-target minimum
- **Rule:** A slider thumb (and any tick handles) MUST have a hit area ≥44pt/48dp even when the visible thumb is smaller.
- **Why:** Small draggable handles are hard to grab, especially one-handed.
- **Platforms:** all
- **Severity:** error
- **Check:** `target_size_lint.py`.
- **Exceptions:** None.
- **See also:** [[A11Y-003]], [[BTN-002]]

### PRG-009 — Sliders show the current value and are keyboard/AT steppable
- **Rule:** Sliders MUST display the current value (or a live-updating label) and MUST be adjustable in discrete steps via assistive tech / hardware keyboard, not drag-only.
- **Why:** WCAG 2.5.7 dragging alternative and 2.1.1 keyboard; drag-only sliders exclude motor-impaired users.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — operate via VoiceOver/TalkBack increment.
- **Exceptions:** None.
- **See also:** [[A11Y-012]], [[PRG-007]]

### PRG-010 — Style progress and sliders from tokens
- **Rule:** Track colors, thumb size, active/inactive colors, and radii MUST reference tokens; no hardcoded colors or dimensions.
- **Why:** Theming, dark mode, and density consistency.
- **Platforms:** all
- **Severity:** error
- **Check:** `token_lint.py`.
- **Exceptions:** None.
- **See also:** [[COL-001]], [[DRK-001]]
