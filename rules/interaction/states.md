# UI States (STATE)

> The 7-state model every data-backed screen must ship — ideal, empty, loading, error, offline, success, permission-denied — with layout-stable skeletons, response-time-appropriate loading, and visibly reversible optimistic UI.

## Contents
- [STATE-001 — Ship all 7 states](#state-001--ship-all-7-states)
- [STATE-002 — Three empty-state variants](#state-002--three-empty-state-variants)
- [STATE-003 — Empty state is not a blank screen](#state-003--empty-state-is-not-a-blank-screen)
- [STATE-004 — No-results differs from first-use](#state-004--no-results-differs-from-first-use)
- [STATE-005 — Loading under 100ms: nothing](#state-005--loading-under-100ms-nothing)
- [STATE-006 — Loading 100ms–1s: keep it stable](#state-006--loading-100ms1s-keep-it-stable)
- [STATE-007 — Loading 1–10s: show progress](#state-007--loading-110s-show-progress)
- [STATE-008 — Loading over 10s: background & notify](#state-008--loading-over-10s-background--notify)
- [STATE-009 — Prefer skeletons over spinners](#state-009--prefer-skeletons-over-spinners)
- [STATE-010 — Skeletons reserve exact dimensions](#state-010--skeletons-reserve-exact-dimensions)
- [STATE-011 — Shimmer 1.5–2s, reduce-motion safe](#state-011--shimmer-152s-reduce-motion-safe)
- [STATE-012 — Progressive loading](#state-012--progressive-loading)
- [STATE-013 — Pick the error surface by scope](#state-013--pick-the-error-surface-by-scope)
- [STATE-014 — Every error offers recovery](#state-014--every-error-offers-recovery)
- [STATE-015 — Human error copy](#state-015--human-error-copy)
- [STATE-016 — Offline: banner + stale data](#state-016--offline-banner--stale-data)
- [STATE-017 — Offline: queue or disable network actions](#state-017--offline-queue-or-disable-network-actions)
- [STATE-018 — Success confirmation](#state-018--success-confirmation)
- [STATE-019 — Permission-denied recovery](#state-019--permission-denied-recovery)
- [STATE-020 — Optimistic UI with visible rollback](#state-020--optimistic-ui-with-visible-rollback)
- [STATE-021 — Cross-fade state transitions](#state-021--cross-fade-state-transitions)
- [STATE-022 — One clear state at a time](#state-022--one-clear-state-at-a-time)
- [STATE-023 — Preserve context on silent refresh](#state-023--preserve-context-on-silent-refresh)
- [STATE-024 — States are tokenized, themed & announced](#state-024--states-are-tokenized-themed--announced)

---

### STATE-001 — Ship all 7 states
- **Rule:** Every data-backed screen must design and implement all 7 states: ideal (populated), empty, loading, error, offline, success, and permission-denied. Shipping a "loaded-only" screen is a defect.
- **Why:** Real networks fail, lists start empty, and permissions get denied; skipping invisible states is the single most common way AI-generated UI breaks in production.
- **Platforms:** all
- **Severity:** error
- **Check:** `state_coverage.py` detects missing empty/loading/error/offline handling per data-backed screen.
- **Exceptions:** Purely static screens with no data source, no network, and no permissions.
- **See also:** [[STATE-002]], [[STATE-013]], [[STATE-019]]

### STATE-002 — Three empty-state variants
- **Rule:** Distinguish the three empty causes and design each: **first-use** (nothing created yet), **no-results** (search/filter returned nothing), and **user-cleared** (all items done/deleted). Do not reuse one generic "No data" screen for all three.
- **Why:** Each cause needs a different message and CTA — onboard vs broaden-search vs celebrate-done; a generic empty screen misguides the user.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — verify the screen branches empty by cause.
- **Exceptions:** Screens where only one empty cause is possible.
- **See also:** [[STATE-003]], [[STATE-004]]

### STATE-003 — Empty state is not a blank screen
- **Rule:** An empty state must include an illustration/icon, a one-line explanation, and a primary CTA that moves the user forward (create, import, invite, adjust filters). Never render a bare blank area.
- **Why:** A blank screen reads as broken; a guided empty state turns a dead end into the fastest path to first value.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — verify empty states contain copy + CTA, not just whitespace.
- **Exceptions:** Deliberately minimal "inbox zero"-style celebratory empties may drop the CTA.
- **See also:** [[STATE-002]], [[STATE-018]]

### STATE-004 — No-results differs from first-use
- **Rule:** A no-results (search/filter) empty state must reflect the query ("No results for '…'"), keep the search/filter controls visible, and offer a clear-filters / broaden-search action — never the first-use onboarding CTA.
- **Why:** After a search the user has intent and context; showing them a "get started" onboarding message ignores what they just did and offers no recovery.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — verify search/filter empties echo the query and offer clear/broaden.
- **Exceptions:** none
- **See also:** [[STATE-002]], [[SRCH-008]]

### STATE-005 — Loading under 100ms: nothing
- **Rule:** For work expected to finish in under ~100ms, show no loading indicator; let the result appear directly.
- **Why:** Under 100ms feels instantaneous (Nielsen response-time limits); a flashed spinner in that window reads as a flicker and makes the UI feel slower.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — verify sub-100ms operations don't flash a loader.
- **Exceptions:** none
- **See also:** [[STATE-006]], [[MIC-005]]

### STATE-006 — Loading 100ms–1s: keep it stable
- **Rule:** For work of ~100ms–1s, keep the user in the flow with a lightweight, in-place indicator (subtle skeleton, inline spinner, disabled button state); do not throw up a full-screen blocking loader or shift layout.
- **Why:** In this window the user's flow of thought is intact; a heavy interstitial breaks it and feels like more work than the wait actually is.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — verify short waits use lightweight, non-blocking indicators.
- **Exceptions:** none
- **See also:** [[STATE-005]], [[STATE-009]]

### STATE-007 — Loading 1–10s: show progress
- **Rule:** For work of ~1–10s, show a determinate progress indicator when the duration/percentage is knowable, otherwise an indeterminate indicator; keep the user informed that work is ongoing.
- **Why:** Beyond ~1s users need reassurance the app is working; determinate progress sets expectations and reduces perceived wait.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — verify medium waits show progress; determinate where measurable.
- **Exceptions:** none
- **See also:** [[STATE-008]], [[PRG-002]]

### STATE-008 — Loading over 10s: background & notify
- **Rule:** For work expected to exceed ~10s, move it to the background so the user can keep using the app, and notify (in-app or push) on completion or failure. Do not hold a blocking spinner for double-digit seconds.
- **Why:** Past ~10s attention wanders; blocking the UI wastes the user's time, whereas backgrounding respects it and a notification reliably brings them back.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — verify long operations background and report completion.
- **Exceptions:** none
- **See also:** [[STATE-007]], [[NOTIF-004]]

### STATE-009 — Prefer skeletons over spinners
- **Rule:** For content-shaped screens (lists, cards, profiles, feeds), use skeleton placeholders that mirror the final layout rather than a centered spinner.
- **Why:** Skeletons preview the structure, reduce perceived wait, and prevent the disorienting empty-then-full pop that a spinner produces.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual — verify content screens load with skeletons matching layout.
- **Exceptions:** Small/indeterminate operations (submit, refresh spinner) where there's no layout to preview.
- **See also:** [[STATE-010]], [[STATE-012]]

### STATE-010 — Skeletons reserve exact dimensions
- **Rule:** Skeleton placeholders must reserve the exact final dimensions of the content they replace so that swapping in real content causes zero layout shift (CLS = 0). No jump/reflow when data arrives.
- **Why:** Layout shift after load is disorienting and causes mis-taps; matching dimensions keeps the page stable from skeleton to content.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — verify no layout shift between skeleton and loaded content.
- **Exceptions:** Content whose size is genuinely unknown until loaded (rare) — reserve a sensible minimum and animate the change.
- **See also:** [[STATE-009]], [[STATE-021]]

### STATE-011 — Shimmer 1.5–2s, reduce-motion safe
- **Rule:** Skeleton shimmer/pulse loops should run at ~1.5–2s per cycle and be subtle; under reduce-motion, replace the moving shimmer with a static neutral placeholder (no animation).
- **Why:** A calm shimmer signals "loading" without distraction; motion-sensitive users need the animation removed while keeping the placeholder.
- **Platforms:** all
- **Severity:** warning
- **Check:** `animation_lint` — verify shimmer duration and a reduce-motion static fallback.
- **Exceptions:** none
- **See also:** [[MOT-010]], [[MOT-020]]

### STATE-012 — Progressive loading
- **Rule:** When parts of a screen are ready before others, render available content immediately and skeleton only the pending regions, rather than blocking the whole screen on the slowest request.
- **Why:** Progressive rendering gets useful content in front of the user sooner and makes the app feel dramatically faster than an all-or-nothing load.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual — verify independent regions load independently.
- **Exceptions:** Screens where partial content would be misleading (e.g. a total before its line items).
- **See also:** [[STATE-009]], [[MOT-017]]

### STATE-013 — Pick the error surface by scope
- **Rule:** Match the error surface to its scope: **inline** next to the field/section for localized/validation errors; **toast/snackbar + retry** for transient, recoverable failures; **full-screen** only when the whole view can't render. Don't full-screen a single failed field.
- **Why:** Right-sizing the error keeps the user oriented and preserves the work still on screen; a full-screen error for a minor failure is disproportionate and destroys context.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — verify error surface matches failure scope.
- **Exceptions:** none
- **See also:** [[STATE-014]], [[BDG-002]], [[FRM-006]]

### STATE-014 — Every error offers recovery
- **Rule:** Every error state must offer a clear recovery action — Retry, Go back, Edit input, or Contact support — and never leave the user at a dead end with no forward path.
- **Why:** An error without a next step traps the user; a recovery action turns failure into a solvable step.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — verify each error state exposes at least one recovery action.
- **Exceptions:** none
- **See also:** [[STATE-013]], [[STATE-020]]

### STATE-015 — Human error copy
- **Rule:** Error copy must be plain-language: say what happened and what to do next. Never surface raw error codes, stack traces, or backend messages to the user (log those instead); optionally include a support/reference code as secondary text.
- **Why:** Jargon and stack traces confuse and alarm users and can leak implementation details; actionable plain language builds trust and guides recovery.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — review error strings for plain language and no raw technical output.
- **Exceptions:** Developer/debug builds may show technical detail behind a flag.
- **See also:** [[STATE-014]], [[L10N-009]]

### STATE-016 — Offline: banner + stale data
- **Rule:** When offline, show a persistent but non-blocking banner ("You're offline") and continue serving last-known cached data, clearly marked as stale (e.g. "Last updated 2h ago"); do not wipe the screen to an error.
- **Why:** Stale-but-visible data is far more useful than a blank error, and the banner sets honest expectations about freshness without blocking the user.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — verify offline serves cached data with an offline banner and freshness marker.
- **Exceptions:** Screens where stale data is unsafe to show (e.g. live balances mid-transaction) must state why it's unavailable.
- **See also:** [[STATE-017]], [[OFF-004]], [[BDG-005]]

### STATE-017 — Offline: queue or disable network actions
- **Rule:** While offline, either queue mutating actions for later sync (with a visible "will send when online" affordance) or clearly disable them; never let a network action appear to succeed and silently vanish.
- **Why:** Silent loss of user actions destroys trust; queuing or honest disabling keeps the user's mental model of what will and won't happen accurate.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — verify offline actions are queued (with status) or disabled, never silently dropped.
- **Exceptions:** none
- **See also:** [[STATE-016]], [[STATE-020]], [[OFF-006]]

### STATE-018 — Success confirmation
- **Rule:** Confirm successful completion explicitly (checkmark, success toast, or state change); transient success confirmations should auto-dismiss after ~2–4s, while success that changes what the user should do next should persist until acknowledged.
- **Why:** Users need positive closure that an action worked; an appropriately-timed confirmation prevents doubt and duplicate submissions.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — verify successful actions produce a confirmation with sensible dismissal.
- **Exceptions:** Obvious inline results where the changed UI is itself the confirmation.
- **See also:** [[MIC-010]], [[HAP-005]], [[BDG-001]]

### STATE-019 — Permission-denied recovery
- **Rule:** For a denied OS permission, show a state that (1) explains what the feature needs and why, (2) deep-links to the system Settings to re-enable it, and (3) offers a degraded fallback where possible (e.g. manual entry instead of camera). Never leave a blank or broken feature.
- **Why:** Once a permission is denied the app can't re-prompt; a clear explanation + Settings deep-link + fallback is the only path back to the feature.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — verify denied-permission screens explain, deep-link to Settings, and offer a fallback.
- **Exceptions:** Permissions with no possible fallback must still explain and link to Settings.
- **See also:** [[STATE-001]], [[PERM-007]]

### STATE-020 — Optimistic UI with visible rollback
- **Rule:** For low-risk actions (like, send, add-to-cart, toggle), apply the change to the UI optimistically with a subtle pending affordance; if the request fails, roll the UI back to the prior state visibly and explain the failure — never leave the UI showing a success that didn't happen.
- **Why:** Optimistic updates make the app feel instant, but a silent failure that leaves a false success is worse than a slow honest one; visible rollback keeps the UI truthful.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — verify optimistic actions show pending state and roll back visibly on failure.
- **Exceptions:** High-stakes/irreversible actions (payments, deletes) should confirm server-side before showing success.
- **See also:** [[STATE-014]], [[STATE-017]], [[MIC-005]]

### STATE-021 — Cross-fade state transitions
- **Rule:** Transition between states (skeleton → content, content → error, empty → populated) with a short cross-fade or shared-axis motion; never hard-cut, which reads as a flash or flicker.
- **Why:** A smooth state transition preserves continuity and softens the swap; a hard cut is visually jarring and can look like a bug.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual — verify state changes animate rather than snap.
- **Exceptions:** Reduce-motion may shorten to a minimal fade (see [[MOT-010]]).
- **See also:** [[MOT-001]], [[STATE-010]]

### STATE-022 — One clear state at a time
- **Rule:** Show exactly one primary state at a time; do not stack contradictory indicators (e.g. a full-screen spinner over stale content with no offline banner, or an empty state plus a loading skeleton). Layered indicators must have a clear meaning (e.g. refresh spinner over existing content is fine).
- **Why:** Overlapping states confuse the user about what's actually happening and whether the data on screen is real.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — verify only one coherent state renders per view.
- **Exceptions:** Background-refresh indicators intentionally layered over valid content (see [[STATE-023]]).
- **See also:** [[STATE-016]], [[STATE-023]]

### STATE-023 — Preserve context on silent refresh
- **Rule:** On a background/silent refresh (pull-to-refresh, focus refetch, polling), keep existing content, scroll position, and in-progress input visible; show a small non-blocking refresh indicator instead of collapsing back to a full loading/skeleton state.
- **Why:** Resetting to a loading screen on every refetch throws away the user's place and any typed input, which feels like the app restarted.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — verify silent refresh preserves content/scroll/input and doesn't full-reload.
- **Exceptions:** First load (no prior content) legitimately shows the full loading state.
- **See also:** [[STATE-006]], [[MIC-006]]

### STATE-024 — States are tokenized, themed & announced
- **Rule:** All state UIs (empty, loading, error, offline, success, permission-denied) must be token-driven, resolve correctly in light and dark themes, and announce their change to assistive tech via a live region / accessibility announcement (e.g. "Loading", "3 results", "Error: retry available").
- **Why:** States are as much a part of the design system as the ideal view; screen-reader users must be told when the screen changes state, not left on a silently-updated page.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — verify each state uses tokens, passes contrast in both themes, and posts an a11y announcement.
- **Exceptions:** none
- **See also:** [[STATE-001]], [[A11Y-022]], [[DRK-003]]
