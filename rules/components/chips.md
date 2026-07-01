# Chips & Filters (CHP)

> Rules for filter/choice/input chips: selected state, spacing, targets, and overflow. Selected state must never rely on color alone.

### CHP-001 — Selected state is not color-only
- **Rule:** A selected chip MUST signal selection with a non-color cue (checkmark/leading icon, fill+border change, or weight) in addition to any color change.
- **Why:** WCAG 2.2 SC 1.4.1; color-blind users and grayscale contexts must perceive selection.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — desaturate and confirm selected chips are still distinguishable.
- **Exceptions:** None.
- **See also:** [[A11Y-010]], [[CHP-003]]

### CHP-002 — Chips meet the touch-target minimum
- **Rule:** Each chip MUST have a hit area ≥44pt (iOS) / 48dp (Android); expand the tap area with padding when the visual height is smaller (M3 chips are 32dp tall visually — pad the hit area).
- **Why:** Chips are small by design; without padded hit areas they are easy to miss.
- **Platforms:** all
- **Severity:** error
- **Check:** `target_size_lint.py`.
- **Exceptions:** None.
- **See also:** [[A11Y-003]], [[BTN-002]]

### CHP-003 — Expose chip role and selected state to assistive tech
- **Rule:** Filter/choice chips MUST expose a toggle/selected trait (or radio semantics for single-select groups) so screen readers announce "selected/not selected".
- **Why:** State must be programmatically determinable, not just visual.
- **Platforms:** all
- **Severity:** error
- **Check:** a11y audit.
- **Exceptions:** Assist/suggestion chips that act as buttons use the button role.
- **See also:** [[A11Y-005]], [[BTN-011]]

### CHP-004 — Space chips ≥8dp apart
- **Rule:** Chips in a row/wrap MUST have ≥8dp gaps horizontally and vertically between hit areas.
- **Why:** Prevents mis-tapping an adjacent filter.
- **Platforms:** all
- **Severity:** error
- **Check:** `target_size_lint.py` gap check.
- **Exceptions:** None.
- **See also:** [[BTN-003]], [[SPC-003]]

### CHP-005 — Wrap or horizontally scroll — never truncate the set
- **Rule:** A chip group MUST either wrap to multiple rows or be a horizontally scrollable row with an edge affordance; it MUST NOT silently clip chips out of reach.
- **Why:** Hidden filters are undiscoverable; users can't select what they can't see.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual at small widths and large font scales.
- **Exceptions:** None.
- **See also:** [[TAB-009]], [[SRCH-006]]

### CHP-006 — Removable (input) chips have a labeled dismiss target
- **Rule:** Input chips with a remove affordance MUST give the ✕ its own ≥44pt/48dp target with an accessible label like "Remove <value>", separate from the chip's main tap action.
- **Why:** Ambiguous or tiny remove targets cause accidental deletion or inability to remove.
- **Platforms:** all
- **Severity:** warning
- **Check:** a11y audit + target size.
- **Exceptions:** None.
- **See also:** [[CRD-002]], [[FRM-020]]

### CHP-007 — Style chips from tokens
- **Rule:** Chip fill, border, radius (typically pill/8dp), and selected colors MUST reference tokens; no hardcoded values, and selected/unselected label contrast MUST meet ≥4.5:1.
- **Why:** Theming and dark mode; readable labels in both states.
- **Platforms:** all
- **Severity:** error
- **Check:** `token_lint.py` + `contrast_check.py`.
- **Exceptions:** None.
- **See also:** [[BTN-016]], [[A11Y-001]]

### CHP-008 — Reflect applied filters and offer a clear-all
- **Rule:** When filter chips are applied, the result set MUST update and the UI MUST show the active-filter count and a single "Clear all" affordance.
- **Why:** Users need to see what's filtering results and to reset quickly.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual.
- **Exceptions:** Single-chip filters where clear-all is redundant.
- **See also:** [[SRCH-008]], [[LST-014]]
