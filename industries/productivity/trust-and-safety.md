# Productivity — Trust & Safety / Data Integrity UX

> Data-integrity signals, conflict handling, destructive-action safety, data
> portability, and the sharing/permission UX a productivity app must ship. In this
> category "trust" is mostly about one promise: **the user's data is safe, theirs,
> and never silently lost or overwritten.**

## Table of contents

1. [No silent data loss](#1-no-silent-data-loss)
2. [Sync conflict resolution](#2-sync-conflict-resolution)
3. [Destructive-action safety](#3-destructive-action-safety)
4. [Data portability & deletion](#4-data-portability--deletion)
5. [Sharing, permissions & ownership](#5-sharing-permissions--ownership)
6. [Rules](#rules)

---

## 1. No silent data loss

The cardinal sin of a productivity app is losing something the user typed. Guard against it
at every layer.

- **Local edits are durable.** Optimistic changes are persisted locally before any network
  attempt, so a crash or kill doesn't erase work (core `[[OFF-001]]`, `[[OFF-002]]`).
- **Failed syncs are surfaced, not swallowed.** A change that can't reach the server is
  marked Failed with retry; it is never dropped to make the UI look "clean" (`[[PRO-013]]`,
  `[[PRO-007]]`).
- **Drafts survive interruptions.** Backgrounding, rotation, and accidental dismissal keep
  in-progress input (`[[PRO-012]]`).

## 2. Sync conflict resolution

When the same item changes in two places, the app must reconcile honestly.

- **Never last-write-silently-wins on user-visible content.** When a real conflict is
  detected, either merge deterministically (and tell the user) or present a resolution
  choice ("Keep this version / Keep the other / Keep both"), preserving both sides until the
  user decides (`[[PRO-013]]`).
- **Show which version is which** — device, timestamp, and a preview — so the choice is
  informed, not a coin flip.
- **Don't block all editing on an unresolved conflict** where safe; scope the block to the
  conflicted item and keep the rest usable (core `[[STATE-004]]`).

## 3. Destructive-action safety

Deletes, archives, and bulk operations must be hard to do by accident and easy to take back.

- **Single-item destructive actions favor optimistic-apply + undo** over a modal, keeping
  flow fast while reversible (`[[PRO-004]]`, core `[[BDG-001]]`).
- **Bulk and high-consequence destructive actions confirm scope and offer an undo window**
  ("Delete 24 items?" → delete → "24 deleted · Undo"). The confirmation states the count and
  the consequence; the commit is clearly the destructive choice (`[[PRO-014]]`, core
  `[[DLG-005]]`).
- **Permanent deletion is distinguished from archive/trash.** Where a trash/restore exists,
  say whether an action is recoverable and for how long.

## 4. Data portability & deletion

The user owns their content, and stores/regulators now require both export and deletion.

- **Export is reachable.** Users can export their data (per-item share, and a bulk
  account-level export such as JSON/CSV/Markdown) from settings without contacting support
  (`[[PRO-015]]`).
- **Account and data deletion are reachable in-app** per platform policy — a discoverable
  path to delete the account and associated data, with clear consequences (`[[PRO-015]]`,
  core `[[PROF-002]]`).
- **Deletion copy is honest** about what is removed, what is retained (and why), and whether
  it is reversible.

## 5. Sharing, permissions & ownership

Shared docs, boards, and lists introduce a trust surface: users must know who can see and
change what.

- **Show sharing state at a glance.** A shared item is visibly marked (a badge/avatar
  stack), distinct from private items, so a user never edits a "private" note that is
  actually shared (`[[PRO-016]]`, core `[[A11Y-014]]`).
- **Surface the user's own permission level** — can they view, comment, or edit? — and
  reflect it in the UI (read-only affordances when the user can't edit) (`[[PRO-016]]`).
- **Attribute changes and ownership.** Where multiple people edit, show who made a change or
  owns an item; transferring/removing access is explicit and confirmed.
- **Respect least-privilege defaults.** New shares default to the narrowest sensible access;
  making something more public is a deliberate, clearly-labeled step (no dark patterns).

---

## Rules

### PRO-013 — Prevent silent data loss: resolve sync conflicts and failures in the open
- **Rule:** When a change cannot sync or conflicts with the server, the app MUST preserve the user's local edit and surface the situation: a Failed state with retry for failures, and for genuine conflicts either a deterministic merge that is disclosed to the user or an explicit resolution choice that keeps both versions until the user decides. The app MUST NOT silently discard local edits or silently overwrite one version with another.
- **Why:** Silently dropping or clobbering user content is the most damaging failure a productivity app can have; it destroys trust irreparably and is often invisible until important work is already gone.
- **Platforms:** all
- **Severity:** error
- **Check:** Create a conflict (edit the same item on two clients offline, then sync): the app preserves both and offers resolution or a disclosed merge — it does not silently lose one side. Force a sync failure: the local edit persists with retry.
- **See also:** [[PRO-003]], [[PRO-007]], [[OFF-001]], [[OFF-002]], [[STATE-004]]

### PRO-014 — Require confirmation and an undo window for destructive bulk actions
- **Rule:** Bulk destructive actions (delete/archive/move many items) and high-consequence single-item deletions MUST confirm the scope (stating the count and consequence) AND provide a time-boxed undo after execution. Reversible single-item actions may skip the dialog but still MUST offer undo. Permanent deletion MUST be visually and textually distinct from recoverable archive/trash.
- **Why:** A mis-scoped or accidental bulk delete can wipe out large amounts of work at once; confirmation scopes intent and undo provides recovery, together preventing the highest-impact accidents.
- **Platforms:** all
- **Severity:** error
- **Check:** Select many items and delete: a confirmation states the count, and after confirming an Undo restores them within the window. Confirm permanent-delete copy differs from archive.
- **See also:** [[PRO-004]], [[PRO-009]], [[BDG-001]], [[DLG-005]]

### PRO-015 — Make data export and account/data deletion reachable in-app
- **Rule:** Users MUST be able to export their content (per-item share plus a bulk, machine-readable account export) and MUST be able to reach account and data deletion from within the app, without contacting support. Deletion copy MUST state what is removed, what is retained, and whether it is reversible.
- **Why:** Users own their content and expect portability; both Apple and Google require an in-app account-deletion path, and export prevents lock-in and builds trust in a tool people entrust with their work.
- **Platforms:** all
- **Severity:** warning
- **Check:** Settings expose a bulk export in a standard format and an account/data deletion path; the deletion flow explains consequences clearly.
- **See also:** [[PRO-016]], [[PROF-002]], [[SET-002]]

### PRO-016 — Show sharing, permission, and ownership state on shared content
- **Rule:** Shared items MUST be visibly distinguished from private ones (via a non-color-only badge/avatar cue), MUST reflect the current user's permission level (view/comment/edit) in the UI (e.g., read-only affordances when the user cannot edit), and SHOULD attribute changes/ownership where multiple people collaborate. New shares default to least-privilege access; widening access is an explicit, clearly-labeled action.
- **Why:** Without visible sharing and permission state, users leak private content, are surprised by others' edits, or waste effort trying to change something they can't; clear indicators prevent both privacy mistakes and confusion.
- **Platforms:** all
- **Severity:** warning
- **Check:** A shared item shows a sharing indicator distinct from private items (readable in grayscale); a view-only user sees disabled edit affordances; increasing access is a deliberate labeled step.
- **See also:** [[PRO-013]], [[PRO-019]], [[A11Y-014]]
