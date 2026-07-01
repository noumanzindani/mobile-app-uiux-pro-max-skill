# Productivity — Industry Pack

> **Tier-3 industry pack.** Read this when the app helps people capture, organize,
> and act on their own content: to-do and task managers, notes, docs and outlines,
> kanban/project boards, calendars, email/read-later, file managers, and personal
> knowledge tools. It layers **domain-specific** rules on top of the core corpus
> (`rules/`); it never restates core rules — it references them by ID (`[[OFF-003]]`).

## When to use this pack

Activate when the screen or flow involves any of:

- **Lists of user content** — tasks, notes, docs, cards, files, messages, events —
  that the user creates, edits, reorders, and deletes.
- **List-detail navigation** — a browsable list that opens an item into a detail/editor,
  especially where a tablet or foldable can show both at once.
- **Multi-select & bulk actions** — completing, moving, tagging, archiving, or deleting
  many items at once.
- **Offline-first editing & sync** — local edits that must survive no-connectivity and
  reconcile with a server (queued → syncing → synced → failed).
- **Reordering & organizing** — drag-to-reorder lists/boards, nesting, prioritizing.
- **Fast capture** — quick-add of a task/note with minimal friction, often via FAB,
  inline row, or a bottom sheet.
- **First-run & empty surfaces** — onboarding empty states that must teach the first
  productive action rather than decorate a blank screen.

If the app is primarily about moving money, use the **Finance / Banking** pack; if it's
primarily social feeds or media, reach for those packs. Use this pack when the product's
core job is **helping a person manage their own stuff**.

## The 5 most load-bearing patterns

These five carry the most weight in productivity UX. Get them right first.

1. **Responsive list-detail across size classes** — one pane below 840dp, a persistent
   two-pane list-detail at and above 840dp, with selection and scroll position preserved
   across rotation and fold/unfold. → `[[PRO-001]]`, `[[PRO-021]]`, core `[[GRD-001]]`, `[[GRD-004]]`, `[[NAV-005]]`.
2. **Offline-first with an honest sync pipeline** — edits apply optimistically to local
   state, queue when offline, retry with backoff, and expose an unambiguous per-item and
   global state: Queued → Syncing → Synced → Failed. → `[[PRO-003]]`, `[[PRO-007]]`, core `[[OFF-001]]`, `[[OFF-002]]`, `[[OFF-003]]`.
3. **Multi-select + a contextual bulk action bar** — a clear way to enter selection mode,
   a running count, batch actions, and a way to clear the selection; destructive batch
   actions are confirmed and undoable. → `[[PRO-002]]`, `[[PRO-009]]`, `[[PRO-014]]`, core `[[BDG-001]]`, `[[DLG-005]]`.
4. **Undo everywhere, especially for destructive and bulk edits** — every edit and every
   delete/archive/move offers a visible, time-boxed undo (and redo where the mental model
   supports it) rather than a silent, irreversible change. → `[[PRO-004]]`, `[[PRO-014]]`, core `[[BDG-001]]`, `[[GES-001]]`.
5. **Reorder and swipe actions that never depend on a gesture alone** — drag-to-reorder
   always has a non-drag alternative (move up/down, "move to…"), and swipe actions always
   have a visible button equivalent (WCAG 2.5.7). → `[[PRO-008]]`, `[[PRO-010]]`, `[[PRO-022]]`, core `[[GES-007]]`, `[[A11Y-025]]`.

## Domain rules in this pack (PRO-\*\*\*)

| ID | Title | File | Severity |
|---|---|---|---|
| [[PRO-001]] | List-detail: single-pane <840dp, two-pane ≥840dp | patterns.md | warning |
| [[PRO-002]] | Multi-select mode + contextual bulk action bar | patterns.md | warning |
| [[PRO-003]] | Offline-first with sync-state pipeline (Queued→Syncing→Synced→Failed) | patterns.md | error |
| [[PRO-004]] | Undo/redo for edits and destructive actions | patterns.md | error |
| [[PRO-005]] | Quick-add entry (FAB / inline / sheet) with minimal friction | patterns.md | warning |
| [[PRO-006]] | Onboarding empty states that teach the first action | patterns.md | warning |
| [[PRO-007]] | Sync-status indicator per item and global | components.md | error |
| [[PRO-008]] | Drag-to-reorder with a non-drag alternative (WCAG 2.5.7) | components.md | error |
| [[PRO-009]] | Bulk action bar: count, actions, clear selection | components.md | warning |
| [[PRO-010]] | Item row: selection checkbox + swipe actions with button equivalents | components.md | warning |
| [[PRO-011]] | Keyboard shortcuts on tablet/foldable + discoverability (⌘K, shortcuts sheet) | components.md | warning |
| [[PRO-012]] | Quick-add sheet keyboard & focus management | components.md | warning |
| [[PRO-013]] | No silent data loss: conflict resolution UX on sync failure | trust-and-safety.md | error |
| [[PRO-014]] | Destructive bulk actions require confirmation + undo window | trust-and-safety.md | error |
| [[PRO-015]] | Data export and account/data deletion reachable | trust-and-safety.md | warning |
| [[PRO-016]] | Sharing / permission / ownership indicators (shared docs) | trust-and-safety.md | warning |
| [[PRO-017]] | Sync-state and error microcopy (Queued/Syncing/Synced/Failed, retry) | copy-and-tone.md | warning |
| [[PRO-018]] | Empty-state onboarding copy (action-oriented, not decorative) | copy-and-tone.md | suggestion |
| [[PRO-019]] | Selection & sync state announced, not color-only | accessibility.md | error |
| [[PRO-020]] | Full keyboard operability + focus order for list-detail & reorder | accessibility.md | error |
| [[PRO-021]] | Two-pane pitfalls (detail without list context; lost selection on rotate) | pitfalls.md | warning |
| [[PRO-022]] | Reorder/gesture-only actions without a visible alternative | pitfalls.md | error |

## Table of contents

- [`patterns.md`](./patterns.md) — list-detail across size classes, multi-select + bulk actions, offline-first sync pipeline, undo/redo, quick-add, onboarding empty states.
- [`components.md`](./components.md) — sync-status indicator, drag-to-reorder + non-drag alternative, bulk action bar, item row (checkbox + swipe), keyboard shortcuts, quick-add sheet.
- [`trust-and-safety.md`](./trust-and-safety.md) — no silent data loss, sync conflict resolution, destructive-action confirmation + undo, data export/deletion, sharing & permission indicators.
- [`copy-and-tone.md`](./copy-and-tone.md) — voice, sync-state and error microcopy, empty-state onboarding copy, do/don't tables.
- [`accessibility.md`](./accessibility.md) — non-color selection/sync state, screen-reader announcements, full keyboard operability and focus order.
- [`pitfalls.md`](./pitfalls.md) — the common productivity UX mistakes and how to avoid them.

## Core rules this pack leans on

`[[OFF-001]]` (optimistic UI + visible rollback), `[[OFF-002]]` (offline queue + backoff),
`[[OFF-003]]` (sync states queued/syncing/synced/failed), `[[STATE-001]]` (enumerate the 7
states), `[[STATE-004]]` (offline state), `[[GRD-001]]` (single column <600dp), `[[GRD-004]]`
(two-pane list-detail ≥840dp), `[[NAV-003]]` (never override system back), `[[NAV-005]]`
(rail at ≥600dp), `[[LST-001]]` (virtualize long lists), `[[LST-002]]` (skeleton on load),
`[[BDG-001]]` (snackbar + Undo), `[[GES-001]]` (never gesture-only critical paths),
`[[GES-007]]` / `[[A11Y-025]]` (drag has a tap alternative, WCAG 2.5.7), `[[A11Y-005]]`
(44pt/48dp targets), `[[A11Y-007]]` (labels+roles+state), `[[A11Y-011]]` (live-region
announce), `[[A11Y-014]]` (no color-only meaning), `[[PLAT-004]]` (hardware keyboard),
`[[DLG-005]]` (explicit destructive confirm), `[[PROF-002]]` (account/data deletion
reachable), `[[ONB-001]]` (value-first onboarding).
