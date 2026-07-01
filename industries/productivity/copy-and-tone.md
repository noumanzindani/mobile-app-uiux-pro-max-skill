# Productivity — Copy & Tone

> Voice, microcopy, sync/status messaging, and empty-state onboarding copy for
> productivity apps. The voice is **clear, calm, action-oriented, and honest about
> data** — it tells the user what happened to their content and what to do next,
> without cuteness at the moment work is at stake.

## Voice principles

- **Action-oriented.** Copy points to the next productive step. An empty list says "Add
  your first task," not "Nothing here yet." (`[[PRO-018]]`)
- **Precise about data state.** Sync and save words are literal and consistent: "Saved,"
  "Syncing," "Offline — changes saved on this device," "Couldn't sync." Pick one term per
  concept and reuse it everywhere (mirrors the `[[PRO-003]]` pipeline).
- **Calm and reassuring under failure.** When a sync fails, lead with the reassurance that
  data is safe locally, then the next step — never a bare error code (`[[PRO-017]]`).
- **Blameless.** Errors describe what happened and what to do, never "you did X wrong."
- **Concise.** Productivity users move fast; short labels and one-line states beat verbose
  explanations.

## Microcopy norms

| Situation | Do | Don't |
|---|---|---|
| Item saved locally, not yet synced | "Saved · Syncing…" | "Saving…" (implies unsafe) |
| Working offline | "Offline — changes saved on this device" | "No connection" (and nothing else) |
| Sync failed | "Couldn't sync 2 items. Your changes are safe here. Retry" | "Sync error 0x8007" |
| Deleted one item | "Task deleted · Undo" | silent removal |
| Bulk delete confirm | "Delete 24 items? You can undo this." | "Are you sure?" |
| Empty task list (first run) | "No tasks yet. Add your first one to get started." | "Empty." |
| No results after filtering | "No tasks match this filter." | reuse the first-run empty copy |
| Conflict detected | "This note changed on another device. Keep this version, the other, or both?" | silently overwrite |
| Read-only shared doc | "You have view access. Ask the owner to edit." | greyed controls with no reason |

- **Distinguish the three empty states in words**, not just art: first-run empty ("Add your
  first…"), zero-results ("No items match…"), and error ("Couldn't load — Retry")
  (`[[PRO-018]]`, core `[[STATE-001]]`).
- **State the count in bulk and destructive copy** ("Delete 24 items?") so scope is
  unambiguous (`[[PRO-014]]`).

## Sync & status messaging

Sync copy is where trust is won or lost. Every sync/error message should answer:

1. **What's the state?** — Saved, Syncing, Offline, or Failed, in the app's consistent
   vocabulary (`[[PRO-003]]`, `[[PRO-017]]`).
2. **Is my data safe?** — the key reassurance when anything goes wrong ("Your changes are
   saved on this device").
3. **What now?** — the next step where one is needed ("Retry," "Resolve conflict"), never a
   raw code alone (`[[PRO-017]]`).

Avoid ambiguous words like "Saving…" that imply data isn't safe yet; if the edit is durably
local, say "Saved" and indicate sync separately.

## Empty-state onboarding copy

The empty state is an onboarding surface, not a decoration (`[[PRO-006]]`).

- **Explain the space and prompt the first action** in one or two lines, wired to quick-add
  (`[[PRO-018]]`, `[[PRO-005]]`, core `[[ONB-001]]`).
- **Value-first**: describe what the user gets, not app internals ("Capture anything you
  need to remember" > "This is the Inbox view").
- **No dead-end blanks.** Every empty primary surface has a next step.

---

## Rules

### PRO-017 — Write clear, reassuring sync-state and error microcopy
- **Rule:** Sync and data-state messages MUST use a consistent, literal vocabulary for each state (Saved / Syncing / Offline / Failed), MUST reassure the user that unsynced edits are safe locally when something goes wrong, MUST offer the next step (e.g., Retry, Resolve) where one exists, and MUST NOT show a bare error code or blame the user. Avoid ambiguous progress words (e.g., "Saving…") for edits that are already durably stored locally.
- **Why:** Productivity users must trust that their work is safe; vague or code-only sync errors create anxiety about data loss and generate support load, while consistent literal state words let users reason about their data.
- **Platforms:** all
- **Severity:** warning
- **Check:** Trigger offline edits and a sync failure: messages use the consistent state vocabulary, reassure that data is safe, offer retry, and contain no bare code or user-blaming phrasing.
- **See also:** [[PRO-003]], [[PRO-007]], [[PRO-013]], [[PRO-018]]

### PRO-018 — Make empty-state copy action-oriented, not decorative
- **Rule:** First-run empty states MUST explain the surface's purpose and prompt a single concrete first action (wired to create/quick-add), and MUST be worded distinctly from zero-results and error states. Empty-state copy MUST NOT be a decorative dead-end (e.g., "Nothing here" with no next step).
- **Why:** New users almost always start on an empty screen; action-oriented copy drives activation and teaches the core loop, whereas decorative or ambiguous emptiness stalls the user and wastes the highest-intent moment.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** Review each primary list's empty state: it names the purpose and offers a create action, and its wording differs from the filtered-empty and error messages.
- **See also:** [[PRO-006]], [[PRO-005]], [[ONB-001]], [[STATE-001]]
