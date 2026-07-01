# Productivity — Screen Patterns

> Domain screen recipes: how core rules combine into correct productivity flows.
> Rules here are content-management patterns — list-detail, selection, sync, undo,
> capture, and onboarding. Cross-references use `[[ID]]`; core rules are referenced,
> never restated.

## Table of contents

1. [List-detail across size classes](#1-list-detail-across-size-classes)
2. [Multi-select & the bulk action bar](#2-multi-select--the-bulk-action-bar)
3. [Offline-first & the sync pipeline](#3-offline-first--the-sync-pipeline)
4. [Undo, redo & reversible edits](#4-undo-redo--reversible-edits)
5. [Quick-add / fast capture](#5-quick-add--fast-capture)
6. [Onboarding empty states](#6-onboarding-empty-states)
7. [Rules](#rules)

---

## 1. List-detail across size classes

The backbone of nearly every productivity app: a browsable list on one side, an item
editor/detail on the other. The layout must respond to width, not device type.

- **Below 840dp — single pane.** The list fills the screen; tapping an item pushes the
  detail as a new destination. System back returns to the list with scroll position and
  selection intact (core `[[GRD-001]]`, `[[NAV-003]]`).
- **At and above 840dp — two-pane.** List and detail are visible side by side; selecting
  in the list updates the detail in place without a full navigation (`[[PRO-001]]`, core
  `[[GRD-004]]`). At ≥600dp promote the primary nav to a rail (core `[[NAV-005]]`).
- **Never show a detail with no list context in two-pane.** On first load or after
  clearing selection, the detail pane shows a purposeful placeholder ("Select an item"),
  not a blank or a stale item from a previous session (`[[PRO-021]]`).
- **Preserve state across configuration changes.** Rotation, split-screen resize, and
  fold/unfold must keep the selected item, scroll offset, and any in-progress edit —
  this is the single most common tablet/foldable regression (`[[PRO-021]]`).
- **Virtualize long lists and show skeletons on load** so scrolling stays smooth and the
  first paint isn't an empty void (core `[[LST-001]]`, `[[LST-002]]`).

## 2. Multi-select & the bulk action bar

Managing many items at once is core productivity work; the pattern must be discoverable,
reversible, and keyboard-operable.

- **Entering selection mode is obvious.** Long-press an item, or tap a "Select" affordance,
  to enter multi-select. On tablet/foldable, checkboxes and shift-click ranges are available
  (`[[PRO-002]]`, `[[PRO-011]]`).
- **A contextual action bar replaces or overlays the top bar** showing a running **count**,
  the batch actions (complete, move, tag, archive, delete), and a **clear-selection**
  control (usually a close "X" or "Done") (`[[PRO-002]]`, `[[PRO-009]]`).
- **Destructive batch actions are gated.** Bulk delete/archive confirms scope ("Delete 12
  items?") and offers an undo window afterward (`[[PRO-014]]`, core `[[DLG-005]]`, `[[BDG-001]]`).
- **Selection survives scroll and rotation.** Selecting item 3, scrolling to 90, and
  rotating must not silently drop the selection (`[[PRO-021]]`).
- **Announce state changes to assistive tech.** Entering selection mode, the count, and
  applied bulk actions are announced, and selected state is not color-only (`[[PRO-019]]`).

## 3. Offline-first & the sync pipeline

Productivity apps are used on planes, in basements, and on flaky mobile data. Local-first
editing with an honest sync state is not optional — it is the core reliability contract.

Canonical per-change lifecycle: **Queued → Syncing → Synced → Failed.**

1. **Optimistic local apply.** An edit takes effect immediately in local state and UI; the
   user never waits on the network to see their own change (core `[[OFF-001]]`).
2. **Queued.** If offline or the request hasn't started, the change is durably queued and
   the item shows a "waiting to sync" state (`[[PRO-003]]`, `[[PRO-007]]`, core `[[OFF-002]]`).
3. **Syncing.** In-flight requests show progress; retries use exponential backoff rather
   than a tight failing loop (core `[[OFF-002]]`).
4. **Synced.** The change is confirmed server-side; the indicator resolves to a settled
   state (a check or simply the absence of a pending marker).
5. **Failed.** On unrecoverable failure the item is clearly marked failed with a **retry**
   affordance; the local edit is **not silently discarded** (`[[PRO-003]]`, `[[PRO-013]]`).

Global sync state (an overall "All changes saved" / "Syncing…" / "Sync paused — offline")
sits alongside per-item indicators so the user can trust the whole set, not just what's on
screen (`[[PRO-007]]`, core `[[OFF-003]]`, `[[STATE-004]]`). On a genuine conflict, resolve
it in the open, never by silently overwriting (`[[PRO-013]]`).

## 4. Undo, redo & reversible edits

The confidence to move fast comes from knowing any action can be taken back.

- **Every destructive action offers undo.** Delete, archive, complete, and move surface a
  snackbar/toast with **Undo** for a meaningful window (typically a few seconds, longer for
  bulk) before the change is finalized server-side (`[[PRO-004]]`, core `[[BDG-001]]`).
- **Undo is the primary safety net, not a modal wall.** Prefer optimistic-apply + undo over
  an "Are you sure?" prompt for reversible single-item actions; reserve confirmation dialogs
  for high-consequence or bulk destructive actions (`[[PRO-014]]`, core `[[DLG-005]]`).
- **Provide redo where the editing model supports it** — text editors, outlines, and boards
  benefit from a redo stack; a to-do checkbox may not. Match the affordance to the mental
  model (`[[PRO-004]]`).
- **Expose undo/redo to the keyboard on tablet/foldable** (⌘Z / ⌘⇧Z) and to assistive tech,
  not just as a transient gesture (`[[PRO-011]]`, core `[[PLAT-004]]`).

## 5. Quick-add / fast capture

The value of a productivity app is proportional to how frictionlessly it captures. Capture
must be one gesture away and never lose input.

- **A single, obvious entry point.** A FAB, a persistent inline "Add…" row at the top of a
  list, or a system-level quick-add sheet — pick one primary pattern and keep it consistent
  (`[[PRO-005]]`).
- **Minimal required fields.** Capture the title/body first; defer optional metadata (due
  date, tags, project) to progressive disclosure so a thought can be logged in seconds
  (`[[PRO-005]]`).
- **Keyboard and focus are handled.** Opening quick-add focuses the input and raises the
  keyboard immediately; the input is never obscured by the keyboard; "return/next" adds and
  optionally keeps the composer open for rapid entry (`[[PRO-012]]`, core `[[FRM-005]]`).
- **Never lose a draft.** Dismissing accidentally, backgrounding, or rotating preserves
  in-progress text; validate inline rather than discarding on error (`[[PRO-012]]`, core
  `[[FRM-002]]`).

## 6. Onboarding empty states

The first screen a new user sees is usually empty. Treat that emptiness as the most
important onboarding surface, not a placeholder to fill with a shrug.

- **Teach the first productive action.** An empty list explains what this space is for and
  gives a single, obvious way to create the first item — ideally wired to quick-add
  (`[[PRO-006]]`, `[[PRO-005]]`, core `[[ONB-001]]`).
- **Value-first, not tour-first.** Prefer getting the user to their first real item over a
  multi-slide carousel; deliver help in context (core `[[ONB-001]]`).
- **Distinguish "empty" from "no results" and "error."** A brand-new empty list, a
  filtered/searched list with zero matches, and a failed load are three different states
  with three different messages (`[[PRO-006]]`, core `[[STATE-001]]`).
- **Copy is action-oriented, not decorative.** "Add your first task" beats a cute
  illustration with no next step (`[[PRO-018]]`).

---

## Rules

### PRO-001 — Use a responsive list-detail layout: single-pane <840dp, two-pane ≥840dp
- **Rule:** List-detail screens MUST render a single pane below 840dp (list pushes detail as a navigation destination) and a persistent two-pane list-detail at and above 840dp (selecting in the list updates the detail in place). Selection, scroll position, and in-progress edits MUST survive rotation, split-screen resize, and fold/unfold. In two-pane mode with no selection, the detail pane shows an intentional placeholder, never a blank or stale item.
- **Why:** Width, not device class, determines the right layout; a phone-only stack wastes tablet/foldable space, while a detail that loses list context or drops state on rotation is the most common large-screen regression.
- **Platforms:** all (primarily tablet, foldable, web)
- **Severity:** warning
- **Check:** Resize the window/emulator across the 840dp boundary: below is single-pane with working system back; at/above is two-pane with in-place selection. Rotate and fold with an item selected and an edit in progress — both persist. Empty two-pane shows a placeholder.
- **See also:** [[PRO-021]], [[GRD-001]], [[GRD-004]], [[NAV-003]], [[NAV-005]]

### PRO-002 — Provide a multi-select mode with a contextual bulk action bar
- **Rule:** Lists of user content MUST offer a discoverable way to enter multi-select (long-press and/or a "Select" affordance; checkboxes and range-select on pointer devices), and while in selection mode MUST show a contextual action bar with a running selected-count, the available batch actions, and an explicit clear-selection/exit control. Selection MUST survive scroll and rotation.
- **Why:** Batch operations are core productivity work; without a clear selection mode and a persistent action bar, users can't manage many items efficiently and lose selections to scroll/rotation.
- **Platforms:** all
- **Severity:** warning
- **Check:** Enter selection mode, select several items across a scroll, rotate: the count and selection persist; the action bar shows count + actions + a clear/exit control.
- **See also:** [[PRO-009]], [[PRO-014]], [[PRO-019]], [[BDG-001]], [[DLG-005]]

### PRO-003 — Implement offline-first editing with an explicit sync-state pipeline
- **Rule:** User edits MUST apply optimistically to local state and MUST be durably queued when offline or in-flight, progressing through explicit, user-visible states: Queued → Syncing → Synced → Failed. Retries use exponential backoff. A failed change MUST be marked as failed with a retry path and MUST NOT be silently discarded or silently overwrite server data.
- **Why:** Productivity apps are used with unreliable or no connectivity; hiding sync state or dropping queued edits destroys the user's trust that their data is safe — the core promise of the category.
- **Platforms:** all
- **Severity:** error
- **Check:** Go offline, make edits (they apply locally and show Queued), reconnect (Syncing → Synced). Force a server failure: the item shows Failed with retry and the local edit is preserved.
- **See also:** [[PRO-007]], [[PRO-013]], [[OFF-001]], [[OFF-002]], [[OFF-003]], [[STATE-004]]

### PRO-004 — Provide undo (and redo where appropriate) for edits and destructive actions
- **Rule:** Every destructive or hard-to-reverse action (delete, archive, complete, move, bulk edits) MUST offer a visible, time-boxed undo before it is finalized. Editors that support a change history MUST provide redo alongside undo. Undo/redo MUST be reachable by pointer, keyboard (⌘Z / ⌘⇧Z on hardware keyboards), and assistive tech — not only via a transient gesture.
- **Why:** Reversibility is what lets users act quickly without fear; a silent, unrecoverable delete or an undo available only as a vanishing gesture causes real data loss and hesitation.
- **Platforms:** all
- **Severity:** error
- **Check:** Delete/complete/move an item — an Undo affordance appears and restores state. In a supporting editor, undo then redo round-trips. Verify ⌘Z/⌘⇧Z on an attached keyboard.
- **See also:** [[PRO-014]], [[PRO-011]], [[BDG-001]], [[GES-001]]

### PRO-005 — Make quick-add a one-gesture, low-friction entry point
- **Rule:** Creating a new item MUST be reachable in a single obvious action (FAB, persistent inline add-row, or a quick-add sheet), MUST require only the essential field(s) to commit, and MUST defer optional metadata to progressive disclosure. The chosen primary capture pattern MUST be consistent across the app.
- **Why:** A productivity tool's value depends on capture friction; if logging a thought takes multiple screens or many required fields, users stop capturing and the tool loses its purpose.
- **Platforms:** all
- **Severity:** warning
- **Check:** From the main list, count the actions to create an item and commit it: one entry gesture, one required field. Optional metadata is not required to save.
- **See also:** [[PRO-006]], [[PRO-012]], [[FRM-005]]

### PRO-006 — Design onboarding empty states that teach the first action
- **Rule:** The first-run empty state of any primary list MUST explain the space's purpose and present a single, obvious way to create the first item (wired to quick-add). It MUST be visually and textually distinct from a "no results" (filtered/searched) state and from an error state.
- **Why:** New users almost always land on an empty screen; a decorative or ambiguous blank teaches nothing and stalls activation, whereas an action-oriented empty state drives the user to their first real success.
- **Platforms:** all
- **Severity:** warning
- **Check:** Fresh account/empty list shows purpose + a create affordance. Apply a filter with no matches and force a load error — each shows a distinct, appropriate message.
- **See also:** [[PRO-005]], [[PRO-018]], [[ONB-001]], [[STATE-001]]
