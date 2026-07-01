# Productivity — Domain Accessibility

> Productivity-specific accessibility on top of core `[[A11Y-…]]` rules. The risks
> concentrate around **selection and sync state (often color-only), drag-to-reorder
> and swipe gestures (motor/keyboard exclusion), and keyboard operability of
> list-detail** on large screens.

## Focus areas

### Non-color state (selection & sync)
- **Selected items** must be distinguishable without color — a checkbox, checkmark, or
  border in addition to any tint — and the selected/unselected condition must be exposed as
  an accessible *state*, not inferred from a color swap (`[[PRO-019]]`, core `[[A11Y-014]]`,
  `[[A11Y-007]]`).
- **Sync state** (Queued/Syncing/Synced/Failed) must carry an icon/shape and a text label so
  it reads in grayscale and to assistive tech (`[[PRO-007]]`, `[[PRO-019]]`). Verify with a
  grayscale review.
- Meet contrast minimums for text (4.5:1) and meaningful icons/affordances (3:1) in both
  light and dark themes (core `[[A11Y-007]]`).

### Screen-reader announcements
- **Announce selection changes and counts** — entering multi-select, "3 selected," and the
  result of a bulk action — via a live region (`[[PRO-019]]`, core `[[A11Y-011]]`).
- **Announce sync transitions** for the item and globally ("Syncing," "Saved," "Couldn't
  sync — 2 items") so a blind user knows their work is safe (`[[PRO-007]]`, `[[PRO-019]]`).
- **Announce reorder results** — after a move, the new position is spoken, not silent
  (`[[PRO-008]]`, `[[PRO-020]]`).
- Every row exposes a meaningful accessible name including its state ("Buy milk, completed,
  synced"), not just visual glyphs (core `[[A11Y-007]]`).

### Keyboard & pointer operability
- **Drag-to-reorder has a keyboard and single-pointer path** (WCAG 2.5.7) — move up/down,
  move-to, or arrow-key movement — so it is not drag-only (`[[PRO-008]]`, `[[PRO-020]]`, core
  `[[GES-007]]`, `[[A11Y-025]]`).
- **Swipe actions have visible/menu equivalents** so gesture-only actions never exclude
  keyboard, switch, or screen-reader users (`[[PRO-010]]`, core `[[GES-001]]`).
- **List-detail is fully keyboard-operable** with a logical focus order: Tab/arrow to move
  in the list, Enter to open, focus lands sensibly in the detail pane, and Escape/back
  returns focus to the originating item — with visible focus never suppressed (`[[PRO-020]]`,
  core `[[PLAT-004]]`).

### Targets & motion
- Interactive targets (rows, checkboxes, drag handles, swipe buttons) meet minimum size
  (core `[[A11Y-005]]`).
- Respect reduced-motion for reorder/collapse/undo animations, providing a non-animated path
  (core `[[MOT-010]]`).

### Forms & capture
- Quick-add and editors use correct keyboard types, clear labels, keyboard-avoidance, and
  inline, programmatically-associated validation (core `[[FRM-005]]`, `[[FRM-002]]`).

---

## Rules

### PRO-019 — Convey selection and sync state without relying on color, and announce changes
- **Rule:** Selection state and sync state (Queued/Syncing/Synced/Failed) MUST be conveyed by at least one non-color channel (checkbox/checkmark/border/icon + text) in addition to any color, MUST be exposed to assistive technology as an accessible state, and MUST pass a grayscale review. Changes to selection (including the selected count) and sync state MUST be announced via a live region.
- **Why:** WCAG 1.4.1 — color-only selection/status excludes color-blind and low-vision users, and silent state changes leave screen-reader users unable to tell what's selected or whether their edits synced; both are decision-blocking in a content-management app.
- **Platforms:** all
- **Severity:** error
- **Check:** Grayscale review: selected vs unselected and each sync state remain distinguishable. With a screen reader, entering selection, the count, and sync transitions are announced; rows expose state in their accessible name.
- **See also:** [[PRO-007]], [[PRO-009]], [[PRO-016]], [[A11Y-014]], [[A11Y-011]], [[A11Y-007]]

### PRO-020 — Ensure full keyboard operability and logical focus order for list-detail and reorder
- **Rule:** List-detail and reorder interactions MUST be fully operable with a hardware keyboard: navigate the list (Tab/arrow), open an item (Enter) with focus moving predictably into the detail pane, return focus to the originating item on back/Escape, and reorder via keyboard (move up/down or arrow-key movement) with the result announced. Visible focus indication MUST NOT be suppressed, and focus order MUST follow reading/interaction order.
- **Why:** On tablets, foldables, and web, keyboard and switch users depend on operable focus; a mouse/touch-only list-detail or drag-only reorder locks them out and fails WCAG 2.1.1 and 2.4.3/2.4.7.
- **Platforms:** tablet, foldable, web
- **Severity:** error
- **Check:** With only a keyboard, traverse the list, open an item (focus enters the detail), return (focus restores to the item), and reorder an item — all with visible focus and an announced reorder result.
- **See also:** [[PRO-001]], [[PRO-008]], [[PRO-011]], [[PLAT-004]], [[A11Y-025]], [[GES-007]]
