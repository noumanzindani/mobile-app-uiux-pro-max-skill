# Offline & Sync (OFF)

> Design offline-first: render from local cache, apply optimistic UI with visible rollback, queue mutations with explicit sync states, and reconcile with exponential backoff + plain-language conflict handling.

## Table of contents
- Reading offline — OFF-001, OFF-007, OFF-008, OFF-013
- Writing offline (queue & sync) — OFF-002, OFF-003, OFF-009, OFF-011, OFF-012
- Connectivity & recovery — OFF-004, OFF-005, OFF-010, OFF-014
- Conflicts — OFF-006

---

### OFF-001 — Offline-first: render from local cache
- **Rule:** Screens MUST render from a local cache/store first and treat the network as an update source, not a prerequisite. Cache the last-known data for every core read screen.
- **Why:** Mobile networks are intermittent; users expect the app to open and show content instantly, even on a train or in a lift.
- **Platforms:** all
- **Severity:** error
- **Check:** Manual airplane-mode launch shows cached content; architecture review for a persistence layer.
- **Exceptions:** Inherently live-only surfaces (e.g., a live video stream) that clearly state they need a connection.
- **See also:** [[OFF-007]], [[OFF-008]], [[PERF-012]]

### OFF-002 — Optimistic UI with visible rollback
- **Rule:** For user mutations (like, send, edit, add-to-cart) reflect the change immediately, then reconcile with the server; on failure, visibly roll back the change and tell the user, offering retry.
- **Why:** Optimistic updates feel instant; a silent non-rollback leaves the UI lying about state the server never accepted.
- **Platforms:** all
- **Severity:** error
- **Check:** Manual: perform action offline/with forced server error → UI reverts + message; code review for rollback path.
- **Exceptions:** High-stakes actions (payments, irreversible deletes) that must confirm server success first.
- **See also:** [[OFF-003]], [[OFF-012]], [[STATE-005]]

### OFF-003 — Queue mutations with explicit sync states
- **Rule:** Offline mutations MUST enter a durable queue and carry an explicit, user-visible status through Queued → Syncing → Synced → Failed. Surface per-item status (icon/label) where it matters.
- **Why:** Users need to trust that their offline actions are captured and will send; hidden queues cause "did it save?" anxiety and duplicates.
- **Platforms:** all
- **Severity:** error
- **Check:** Manual offline-action flow through each state; review queue state model.
- **Exceptions:** Trivial ephemeral actions with no server effect.
- **See also:** [[OFF-002]], [[OFF-009]], [[OFF-012]]

### OFF-004 — Non-blocking connectivity banner
- **Rule:** When connectivity is lost, show a lightweight, non-blocking banner ("You're offline — changes will sync when you reconnect") that auto-dismisses on reconnect. Never trap the user behind a full-screen blocking dialog for transient network loss.
- **Why:** Users must be informed without being locked out of offline-capable features.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual toggle airplane mode; verify banner appears/dismisses and does not block interaction.
- **Exceptions:** Flows that genuinely cannot proceed offline may block with a clear explanation + retry.
- **See also:** [[OFF-013]], [[OFF-014]], [[BDG-002]]

### OFF-005 — Exponential backoff with jitter on retries
- **Rule:** Retry failed network/sync attempts with exponential backoff and jitter (≈ 1s, 2s, 4s, 8s … capped, plus random jitter), not tight loops. Cap attempts and hand off to manual retry after the cap.
- **Why:** Fixed/immediate retries hammer the server (thundering herd), waste battery, and rarely recover faster; jitter avoids synchronized retry storms.
- **Platforms:** all
- **Severity:** error
- **Check:** Code review of retry policy; network trace shows increasing intervals + jitter.
- **Exceptions:** A single immediate retry for a known-transient error before backing off.
- **See also:** [[OFF-010]], [[OFF-012]], [[OFF-014]]

### OFF-006 — Plain-language conflict resolution
- **Rule:** When local and server versions diverge, resolve via a defined strategy and, where the user must choose, present the conflict in plain language ("This note was edited on another device. Keep this version, keep the other, or merge?") — never raw diffs, timestamps, or error codes.
- **Why:** Silent last-write-wins destroys user data; technical conflict dumps are unusable for normal users.
- **Platforms:** all
- **Severity:** error
- **Check:** Manual two-device concurrent-edit test; review conflict policy.
- **Exceptions:** Domains where an automatic, well-documented merge (e.g., CRDT) is provably safe and lossless.
- **See also:** [[OFF-002]], [[OFF-011]]

### OFF-007 — Mark stale/cached data with freshness
- **Rule:** Data shown from cache while offline or during refresh MUST be marked as such (subtle "Last updated 2h ago" / stale indicator) so users know it may not be current.
- **Why:** Presenting stale data as live erodes trust and can cause bad decisions (prices, balances, schedules).
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual offline view for freshness indicator; verify timestamp source.
- **Exceptions:** Data that never goes stale within a session.
- **See also:** [[OFF-001]], [[OFF-013]]

### OFF-008 — Never block core reads on the network; degrade gracefully
- **Rule:** Core read flows MUST remain usable offline from cache; features that truly require connectivity degrade with a clear, localized message + retry rather than crashing, spinning forever, or showing a dead-end.
- **Why:** A network blip should never render the app inert; graceful degradation keeps it useful.
- **Platforms:** all
- **Severity:** error
- **Check:** Manual airplane-mode sweep of every core screen for dead-ends/infinite spinners.
- **Exceptions:** Explicitly online-only features, clearly labeled.
- **See also:** [[OFF-001]], [[OFF-013]], [[STATE-004]]

### OFF-009 — Persist the queue across restarts & process death
- **Rule:** The mutation queue and cache MUST survive app restart, backgrounding, and OS process death (durable storage, not in-memory). Pending actions resume on next launch.
- **Why:** Users background and reopen apps constantly; an in-memory queue silently loses their offline work.
- **Platforms:** all
- **Severity:** error
- **Check:** Manual: queue offline action, force-kill app, relaunch → action still pending and syncs.
- **Exceptions:** None for user-visible mutations.
- **See also:** [[OFF-003]], [[PERF-013]]

### OFF-010 — Distinguish retryable from non-retryable failures
- **Rule:** Retry only transient failures (timeouts, 5xx, connection loss). Do NOT auto-retry deterministic client errors (4xx validation/auth); surface those to the user for correction and stop retrying.
- **Why:** Retrying a 400/422 forever wastes resources and hides a real, user-fixable problem.
- **Platforms:** all
- **Severity:** warning
- **Check:** Code review of error classification; trace shows no retry loop on 4xx.
- **Exceptions:** 401 that can be resolved by a single silent token refresh + one retry.
- **See also:** [[OFF-005]], [[OFF-012]]

### OFF-011 — Idempotent mutations (no duplicate writes)
- **Rule:** Queued mutations MUST carry an idempotency key / client-generated ID so retries and reconnect-resends do not create duplicates on the server.
- **Why:** Backoff + reconnect naturally re-send requests; without idempotency the user gets double orders/messages/charges.
- **Platforms:** all
- **Severity:** error
- **Check:** Code review for idempotency keys; test duplicate-send under flaky network.
- **Exceptions:** Endpoints the backend already dedupes server-side.
- **See also:** [[OFF-003]], [[OFF-005]], [[OFF-006]]

### OFF-012 — Manual retry affordance on failed items
- **Rule:** Items that reach the Failed state MUST expose a clear manual retry (and where relevant, cancel/discard) affordance with an explanation of what failed.
- **Why:** After automatic backoff is exhausted, the user needs a way to recover their action rather than losing it silently.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual: force permanent failure → Failed item shows retry/cancel controls.
- **Exceptions:** None for user-visible failed mutations.
- **See also:** [[OFF-003]], [[OFF-005]], [[STATE-005]]

### OFF-013 — Distinguish offline from server error states
- **Rule:** "No connection" and "server/request error" MUST be different, correctly-worded states with appropriate recovery ("Check your connection" vs "Something went wrong, try again"). Do not show a generic error for a pure connectivity loss.
- **Why:** Mis-labeling connectivity as a server error sends users chasing the wrong fix and erodes trust.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual airplane-mode vs forced-500 → verify distinct copy/state.
- **Exceptions:** None.
- **See also:** [[OFF-004]], [[OFF-008]], [[STATE-004]]

### OFF-014 — Auto-sync on reconnect with visible progress
- **Rule:** On regaining connectivity, automatically flush the queue and refresh stale data, surfacing sync progress/result (syncing → synced, or an error summary). Users should not have to manually trigger a sync for normal operation.
- **Why:** Automatic, visible reconciliation closes the offline loop and reassures users their work landed.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual: act offline, restore connection → queue flushes automatically with progress shown.
- **Exceptions:** Metered/data-saver contexts may defer large syncs with user consent.
- **See also:** [[OFF-003]], [[OFF-004]], [[OFF-005]]
