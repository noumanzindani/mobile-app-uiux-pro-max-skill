# Productivity — Domain Components

> Domain-specific components and their required states/behaviors. Each maps to core
> component rules (`[[LST-…]]`, `[[GES-…]]`, `[[FRM-…]]`) and adds productivity
> constraints. Build these token-driven; no magic values.

## Table of contents

1. [Sync-status indicator (per-item & global)](#1-sync-status-indicator-per-item--global)
2. [Drag-to-reorder handle + non-drag alternative](#2-drag-to-reorder-handle--non-drag-alternative)
3. [Bulk action bar](#3-bulk-action-bar)
4. [Item row (checkbox + swipe actions)](#4-item-row-checkbox--swipe-actions)
5. [Keyboard shortcuts & command palette](#5-keyboard-shortcuts--command-palette)
6. [Quick-add sheet](#6-quick-add-sheet)
7. [Rules](#rules)

---

## 1. Sync-status indicator (per-item & global)

The component that makes the offline-first contract (`[[PRO-003]]`) visible and trustworthy.

- **Per-item state** maps to the pipeline: Queued (waiting), Syncing (in-flight), Synced
  (settled/absent marker), Failed (needs attention + retry) (`[[PRO-007]]`, core `[[OFF-003]]`).
- **Global state** summarizes the whole set: "All changes saved," "Syncing…," "Sync paused
  — offline," or "Some changes failed" with a path to the failures (`[[PRO-007]]`).
- **Not color-only.** Each state carries an icon/shape and a text/label channel so it reads
  in grayscale and to assistive tech (`[[PRO-019]]`, core `[[A11Y-014]]`).
- **Failed is actionable.** A failed item exposes a retry affordance inline; the local edit
  is preserved until the user resolves it (`[[PRO-013]]`).

## 2. Drag-to-reorder handle + non-drag alternative

Reordering is a signature productivity interaction — and a classic accessibility trap when
it is the *only* way to move an item.

- **Explicit drag handle** with an adequate target (core `[[A11Y-005]]`) and a clear
  pressed/lifted state; long-press-to-lift is fine as an *addition*, not the only trigger.
- **A non-drag alternative is mandatory** (WCAG 2.5.7): a "Move up / Move down" control, a
  "Move to…" picker, or numeric position entry, so reordering works without a sustained
  drag gesture (`[[PRO-008]]`, core `[[GES-007]]`, `[[A11Y-025]]`).
- **Keyboard-operable on tablet/foldable/web** — focus the item, move with arrow/modifier
  keys, commit and announce the new position (`[[PRO-020]]`, core `[[PLAT-004]]`).
- **Announce the result.** After a move, the new position is announced to assistive tech,
  not left silent (`[[PRO-019]]`, core `[[A11Y-011]]`).

## 3. Bulk action bar

The contextual bar that appears in multi-select mode (`[[PRO-002]]`).

- **Shows the running count** of selected items ("3 selected") as the primary label
  (`[[PRO-009]]`).
- **Presents batch actions** relevant to the selection (complete, move, tag, archive,
  delete); destructive actions confirm scope and offer undo (`[[PRO-014]]`, core `[[DLG-005]]`,
  `[[BDG-001]]`).
- **Always offers clear-selection / exit** — a close control that leaves selection mode
  without acting (`[[PRO-009]]`).
- **Reachable and operable by keyboard and AT**, with the count announced on change and
  selected state exposed as a state, not just a tint (`[[PRO-019]]`, `[[PRO-020]]`).

## 4. Item row (checkbox + swipe actions)

The atomic unit of a productivity list.

- **Selection checkbox** appears in multi-select mode with a real checked/unchecked *state*
  exposed to AT (not a color swap) (`[[PRO-010]]`, `[[PRO-019]]`, core `[[A11Y-007]]`).
- **Whole row is the primary tap target** → opens detail; adequate target size (core
  `[[A11Y-005]]`).
- **Swipe actions must have visible button equivalents.** A swipe-to-complete or
  swipe-to-delete is a shortcut layered on top of a discoverable control (an overflow menu,
  a visible action, or long-press menu) so the action is never gesture-only (`[[PRO-010]]`,
  core `[[GES-001]]`, `[[GES-007]]`).
- **Destructive swipe = undoable.** Swipe-delete/archive fires the undo affordance rather
  than an immediate irreversible removal (`[[PRO-004]]`, core `[[BDG-001]]`).
- **Virtualized, with skeletons on load** (core `[[LST-001]]`, `[[LST-002]]`).

## 5. Keyboard shortcuts & command palette

On tablet, foldable, and web, a hardware keyboard turns a productivity app into a power
tool — but only if shortcuts exist and are discoverable.

- **Support hardware-keyboard navigation and common shortcuts** — arrow/tab movement,
  Enter to open, ⌘Z/⌘⇧Z undo/redo, ⌘F find, and a command palette (⌘K) where the app is
  action-rich (`[[PRO-011]]`, core `[[PLAT-004]]`).
- **Discoverability is required.** Provide a shortcuts reference (the platform's key-command
  overlay and/or an in-app shortcuts sheet) so shortcuts aren't invisible tribal knowledge
  (`[[PRO-011]]`).
- **Don't trap or override system chords** — respect platform-reserved keys and the system
  back/escape semantics (core `[[NAV-003]]`).
- **Focus order is logical** and visible focus is never suppressed (`[[PRO-020]]`).

## 6. Quick-add sheet

The fast-capture surface (`[[PRO-005]]`); its keyboard and focus behavior make or break
capture speed.

- **Focus the input and raise the keyboard on open**; the composer field is never covered
  by the keyboard (`[[PRO-012]]`, core `[[FRM-005]]`).
- **Commit-and-continue.** Return/Enter (or an explicit add button) commits and, for rapid
  entry, can keep the sheet open with the field cleared and focused (`[[PRO-012]]`).
- **Preserve drafts** across accidental dismiss, backgrounding, and rotation; validate
  inline rather than discarding input on error (`[[PRO-012]]`, core `[[FRM-002]]`).
- **Reachable dismiss** — a clear close/cancel that doesn't destroy an in-progress draft
  without confirmation.

---

## Rules

### PRO-007 — Show sync status per item and globally
- **Rule:** Any surface backed by syncable data MUST expose a per-item sync state (Queued / Syncing / Synced / Failed) and a global sync summary ("All changes saved" / "Syncing…" / "Offline" / "Some changes failed"). Each state MUST use a non-color channel (icon + text/label) and a Failed state MUST offer an inline retry.
- **Why:** Users need to trust that their edits are safe both for the item on screen and for the whole set; a single hidden or color-only indicator undermines the offline-first promise and hides failures until data is lost.
- **Platforms:** all
- **Severity:** error
- **Check:** Toggle connectivity and force a failure: the item shows the correct state with a non-color cue, and the global indicator reflects Queued/Syncing/Synced/Failed. Verify the Failed retry works and grayscale review passes.
- **See also:** [[PRO-003]], [[PRO-013]], [[PRO-019]], [[OFF-003]], [[A11Y-014]]

### PRO-008 — Give drag-to-reorder a non-drag alternative (WCAG 2.5.7)
- **Rule:** Any drag-to-reorder (lists, boards, outlines) MUST provide an equivalent non-drag method — "Move up/down," a "Move to…" picker, or position entry — and MUST be operable by keyboard on devices with a hardware keyboard. The new position MUST be announced to assistive technology after a move.
- **Why:** WCAG 2.5.7 (Dragging Movements) requires a single-pointer alternative to dragging; users with motor or dexterity limitations, and keyboard/switch users, cannot perform sustained drags. Reordering that is drag-only excludes them and fails the guideline.
- **Platforms:** all
- **Severity:** error
- **Check:** Reorder an item without dragging (move up/down or move-to). With a hardware keyboard, move an item via keys. Confirm the new position is announced by the screen reader.
- **See also:** [[PRO-010]], [[PRO-020]], [[PRO-022]], [[GES-007]], [[A11Y-025]], [[A11Y-005]]

### PRO-009 — Bulk action bar shows count, actions, and clear-selection
- **Rule:** The contextual bar shown in multi-select mode MUST display a running count of selected items, the batch actions applicable to the selection, and an explicit clear-selection/exit control. Destructive batch actions MUST confirm scope and offer undo.
- **Why:** Without a visible count users lose track of scope; without an explicit exit they get stuck in selection mode; without confirmation/undo a mis-scoped bulk delete is unrecoverable.
- **Platforms:** all
- **Severity:** warning
- **Check:** Enter selection mode and select items: the bar shows an accurate count, relevant actions, and a clear/exit control. Trigger bulk delete: scope is confirmed and undo is offered.
- **See also:** [[PRO-002]], [[PRO-014]], [[PRO-019]], [[BDG-001]], [[DLG-005]]

### PRO-010 — Item row: selection checkbox plus swipe actions with button equivalents
- **Rule:** List item rows MUST expose selection as a real checkbox state (checked/unchecked communicated to AT, not color alone), keep the whole row as the primary open-detail target with an adequate hit area, and provide any swipe action ALSO as a visible/menu button so no action is gesture-only. Destructive swipe actions MUST be undoable.
- **Why:** Swipe-only actions are undiscoverable and inaccessible; a color-only checkbox is invisible to color-blind and screen-reader users; an irreversible swipe-delete causes accidental data loss.
- **Platforms:** all
- **Severity:** warning
- **Check:** Every swipe action has a non-swipe equivalent (menu/visible button). The selection checkbox exposes checked state to VoiceOver/TalkBack. Swipe-delete offers undo.
- **See also:** [[PRO-008]], [[PRO-004]], [[GES-001]], [[GES-007]], [[A11Y-007]], [[A11Y-005]]

### PRO-011 — Support keyboard shortcuts on tablet/foldable with discoverability
- **Rule:** On devices with a hardware keyboard (tablet, foldable, web, desktop), the app MUST support keyboard navigation and common shortcuts (open/enter, undo/redo ⌘Z/⌘⇧Z, find ⌘F, and a command palette ⌘K where action-rich) and MUST make them discoverable via the platform key-command overlay and/or an in-app shortcuts reference. Shortcuts MUST NOT override reserved system chords or system back/escape.
- **Why:** Keyboard-driven power use is a defining productivity advantage on large screens; undiscoverable or absent shortcuts leave that value on the table and hurt efficiency and accessibility.
- **Platforms:** tablet, foldable, web
- **Severity:** warning
- **Check:** Attach a keyboard: navigate and invoke undo/redo, find, and (if present) the command palette. Confirm a shortcuts overlay/sheet lists them and system back/escape still work.
- **See also:** [[PRO-004]], [[PRO-020]], [[PLAT-004]], [[NAV-003]]

### PRO-012 — Quick-add sheet: correct keyboard and focus management
- **Rule:** The quick-add surface MUST focus its input and raise the keyboard on open, MUST keep the input unobscured by the keyboard, SHOULD support commit-and-continue for rapid entry, and MUST preserve in-progress drafts across accidental dismiss, backgrounding, and rotation. Validation is inline, not draft-destroying.
- **Why:** Capture speed is the product's value; a composer that requires an extra tap to focus, hides behind the keyboard, or loses a half-typed thought defeats the purpose of quick-add.
- **Platforms:** all
- **Severity:** warning
- **Check:** Open quick-add: the field is focused, the keyboard is up, the field is visible. Type, background/rotate, return: the draft is intact. Confirm rapid consecutive adds work.
- **See also:** [[PRO-005]], [[FRM-005]], [[FRM-002]]
