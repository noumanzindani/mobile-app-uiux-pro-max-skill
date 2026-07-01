# UI States Checklist (the 7 states)

> Every data-backed screen must handle all seven. `state_coverage.py` heuristically
> checks four (loading/empty/error/offline); the rest need judgment. See
> `rules/interaction/states.md`.

1. **Ideal / loaded** — the happy path with real content and correct hierarchy.
2. **Empty** — design all three that apply:
   - *First-use* — onboard + a primary CTA (not a blank screen).
   - *No-results* — suggest a query/filter change; keep filters visible.
   - *Cleared* — success confirmation after the user emptied it.
3. **Loading** — skeleton (content-shaped, reserve exact dimensions → no layout shift) for
   content; spinner only for short discrete actions; progress bar when duration is known.
   Show within 100ms. Shimmer 1.5–2s cycle.
4. **Error** — inline (field/section), full-screen (page failed) + **Retry**, or toast +
   Undo/Retry. Human, specific, blame-free copy; no raw error codes.
5. **Offline** — stale content + non-blocking connectivity banner; queued actions with a
   sync indicator (Queued → Syncing → Synced → Failed).
6. **Success / confirmation** — confirm consequential actions; optimistic UI with **visible
   rollback** on failure.
7. **Permission-denied** — explain the value, then deep-link to Settings; never dead-end.

**Copy test:** does each empty/error state say *what happened*, *why*, and *the next step*,
without blaming the user or exposing codes?

**Motion test:** does every state transition honor reduce-motion (cross-fade/instant)?
