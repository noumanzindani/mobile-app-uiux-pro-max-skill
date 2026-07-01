# Productivity — Common Pitfalls

> The productivity-specific mistakes AI-generated and human-built content apps make
> most often, why they hurt, and the rule that prevents each. Scan this before
> shipping a list, editor, board, or sync surface.

Two categories dominate productivity regressions: **large-screen layout** and
**gesture-only interaction**. Phone-first list-detail code shipped to a tablet tends to
either stay a wasteful single column or, worse, show a detail pane with no list context and
drop the user's selection on rotation (`[[PRO-021]]`). And the signature productivity
gestures — drag-to-reorder and swipe-to-act — are frequently the *only* way to perform an
action, silently excluding keyboard, switch, and screen-reader users and failing WCAG 2.5.7
(`[[PRO-022]]`). The remaining pitfalls cluster around the data-safety promise: silent sync
failures, un-undoable deletes, and color-only state.

| # | Pitfall | Why it's harmful | Fix / rule |
|---|---------|------------------|-----------|
| 1 | **Single-column list-detail on tablets/foldables** | Wastes large-screen space; feels like a blown-up phone app | Two-pane list-detail ≥840dp → [[PRO-001]], [[GRD-004]] |
| 2 | **Detail pane shown with no list context** in two-pane, or a stale item on first load | User is lost, edits the wrong item, or sees ghost data | Placeholder when no selection; two-pane keeps the list → [[PRO-021]], [[PRO-001]] |
| 3 | **Selection / scroll / edit lost on rotate or fold** | Users redo work; feels broken on the exact devices meant to shine | Preserve state across config changes → [[PRO-021]], [[PRO-001]] |
| 4 | **Drag-to-reorder with no non-drag alternative** | Fails WCAG 2.5.7; excludes motor/keyboard/switch users | Move up/down or move-to + keyboard path → [[PRO-022]], [[PRO-008]], [[GES-007]], [[A11Y-025]] |
| 5 | **Swipe-only actions** (complete/delete with no button) | Undiscoverable and inaccessible; actions are invisible | Every swipe has a visible/menu equivalent → [[PRO-022]], [[PRO-010]], [[GES-001]] |
| 6 | **Silent sync failure** — dropped or hidden to look "clean" | Invisible data loss; the worst trust break in the category | Failed state + retry; preserve local edit → [[PRO-003]], [[PRO-007]], [[PRO-013]] |
| 7 | **Last-write-silently-wins conflicts** | One device's edits clobber another's without warning | Merge-with-disclosure or explicit resolution → [[PRO-013]] |
| 8 | **Irreversible delete with no undo** | One mistap wipes work; no recovery | Undo window on destructive actions → [[PRO-004]], [[PRO-014]], [[BDG-001]] |
| 9 | **Bulk delete with no scope confirm or undo** | Mass, unrecoverable loss from one action | Confirm count + undo window → [[PRO-014]], [[PRO-009]] |
| 10 | **Color-only selection or sync state** | Invisible to color-blind and screen-reader users | Non-color cue + announced state → [[PRO-019]], [[A11Y-014]] |
| 11 | **No keyboard shortcuts / non-operable list-detail on tablet** | Power users can't work fast; keyboard users locked out | Shortcuts + full keyboard operability → [[PRO-011]], [[PRO-020]], [[PLAT-004]] |
| 12 | **High-friction capture** (multi-screen add, many required fields) | Users stop capturing; the tool loses its purpose | One-gesture quick-add, essential fields only → [[PRO-005]], [[PRO-012]] |
| 13 | **Quick-add loses drafts / hides behind keyboard** | Half-typed thoughts vanish; capture feels unsafe | Focus + keyboard-avoid + draft preservation → [[PRO-012]], [[FRM-005]] |
| 14 | **Decorative empty states with no next step** | New users stall at activation; nothing is taught | Action-oriented onboarding empty state → [[PRO-006]], [[PRO-018]], [[ONB-001]] |
| 15 | **No export / no in-app account deletion** | Lock-in and store-policy violation | Reachable export + account/data deletion → [[PRO-015]], [[PROF-002]] |
| 16 | **Ambiguous "Saving…" / bare sync error codes** | Implies data isn't safe; creates anxiety and support load | Consistent state words + reassurance + retry → [[PRO-017]] |
| 17 | **Shared items indistinguishable from private ones** | Privacy leaks; edits to "private" notes that are actually shared | Sharing/permission indicators (non-color) → [[PRO-016]] |

## Quick self-audit

Before shipping any list, editor, or sync surface, confirm:

- [ ] Two-pane list-detail at ≥840dp; single-pane below; state survives rotate/fold.
- [ ] Two-pane never shows a detail with no list context; empty pane has a placeholder.
- [ ] Drag-to-reorder has a non-drag alternative and works from the keyboard.
- [ ] Every swipe action has a visible/menu equivalent.
- [ ] Offline edits queue, sync, and failures show a Failed state with retry — never dropped.
- [ ] Sync conflicts are resolved in the open, never silently overwritten.
- [ ] Destructive single and bulk actions are undoable; bulk confirms scope.
- [ ] Selection and sync state read in grayscale and are announced to assistive tech.
- [ ] Keyboard operates list-detail and reorder with visible focus on tablet/foldable.
- [ ] Quick-add is one gesture, focuses the field, and never loses a draft.
- [ ] Empty states teach the first action and differ from no-results/error.
- [ ] Data export and in-app account/data deletion are reachable.

---

## Rules

### PRO-021 — Avoid two-pane list-detail pitfalls (detail without context; lost selection on rotate)
- **Rule:** Two-pane list-detail layouts MUST keep the list visible alongside the detail, MUST show an intentional placeholder (not blank or a stale item) when there is no selection, and MUST preserve the selected item, scroll position, and in-progress edits across rotation, split-screen resize, and fold/unfold. A single-column phone layout MUST NOT be shipped unchanged to ≥840dp widths.
- **Why:** These are the most common large-screen regressions: a detail with no list context disorients users and invites editing the wrong item, while dropping selection/state on a configuration change makes the app feel broken on the very devices two-pane is meant to serve.
- **Platforms:** tablet, foldable, web
- **Severity:** warning
- **Check:** At ≥840dp the list stays visible with the detail; with no selection the detail shows a placeholder. Select an item, start an edit, rotate/fold/resize — selection, scroll, and the edit all persist.
- **See also:** [[PRO-001]], [[GRD-004]], [[GRD-001]], [[NAV-005]]

### PRO-022 — Never ship reorder or actions as gesture-only without a visible alternative
- **Rule:** Drag-to-reorder and swipe (or long-press-only) actions MUST NOT be the sole way to perform their function. Reordering MUST offer a non-drag, keyboard-operable alternative (move up/down, move-to, arrow-key movement) per WCAG 2.5.7, and every swipe action MUST have a visible or menu button equivalent. Gesture-only critical actions are prohibited.
- **Why:** Drag and swipe are undiscoverable and physically impossible for many users (motor, dexterity, switch, keyboard, screen-reader); making them the only path fails WCAG 2.5.7 and 2.1.1 and silently excludes people from core functionality.
- **Platforms:** all
- **Severity:** error
- **Check:** For every reorder and swipe action, verify a non-gesture path exists and is operable by keyboard/screen reader; audit that no critical action is reachable only via drag/swipe/long-press.
- **See also:** [[PRO-008]], [[PRO-010]], [[PRO-020]], [[GES-001]], [[GES-007]], [[A11Y-025]]
