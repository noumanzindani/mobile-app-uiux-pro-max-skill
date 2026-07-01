# Feed Patterns

> Purpose: Build a scrolling stream (social feed, timeline, notifications, activity) that loads endlessly without jank, refreshes by pull, and makes actions (like, save, follow, post) feel instant through optimistic UI with visible rollback — all while degrading gracefully offline and covering every state.

## Contents
- [When to use](#when-to-use)
- [Anatomy](#anatomy)
- [Infinite scroll & pagination](#infinite-scroll--pagination)
- [Pull-to-refresh](#pull-to-refresh)
- [Optimistic actions & rollback](#optimistic-actions--rollback)
- [Thumb-zone layout](#thumb-zone-layout)
- [The 7 states](#the-7-states)
- [Accessibility](#accessibility)
- [Motion](#motion)
- [Applied rules](#applied-rules)
- [Anti-patterns](#anti-patterns)
- [Acceptance checklist](#acceptance-checklist)

---

## When to use

Any reverse-chronological or ranked stream the user scrolls through and acts on inline: social timelines, comments, notifications, order/activity history, search results that keep loading. Pairs with [search-patterns.md](search-patterns.md) for filtered feeds and [empty-error-offline.md](empty-error-offline.md) for the state details.

## Anatomy

- **Virtualized list** — render only visible cells + a small buffer; recycle. Never mount the whole feed ([[LST-001]], [[PERF-004]]).
- **Feed item / card** — one primary tap target (open the post) with clearly separated secondary actions (like, comment, share) that do not conflict with the card tap ([[CRD-001]], [[CRD-002]]).
- **Lazy media** — images/video load as they approach the viewport, with fixed aspect-ratio placeholders to prevent layout shift ([[PERF-003]], [[AVT-002]]).
- **Skeleton cells** during initial and paginated loads ([[LST-002]], [[STATE-005]]).
- Stable item identity (keys) so optimistic inserts/removes animate correctly and scroll position holds ([[LST-008]]).

## Infinite scroll & pagination

- Fetch the **next page before** the user hits the bottom (prefetch at ~1 viewport remaining) so scrolling never stalls ([[LST-004]]).
- Show a **footer loading indicator** for the next page (skeleton/spinner), and a distinct **end-of-feed** marker when there's no more ([[STATE-005]]).
- Handle page-fetch **failure inline**: a retry row at the bottom, keeping everything already loaded ([[STATE-007]]).
- Cap unbounded growth: recycle offscreen cells; consider a "back to top" affordance for long sessions.
- Provide a non-infinite escape for accessibility/motor users where relevant (e.g., a manual "Load more" fallback) ([[A11Y-016]]).

## Pull-to-refresh

- Standard gesture at the top of the feed with a visible spinner and haptic tick ([[LST-003]], [[MIC-003]], [[HAP-001]]).
- Because pull-to-refresh is gesture-only, **also expose a non-gesture refresh** (tap active tab to refresh, or a refresh control) ([[GES-005]], [[A11Y-016]]).
- New items load **above** the current position without yanking the user's scroll; consider a "N new posts" pill to jump up rather than auto-scrolling ([[LST-008]]).
- Announce completion to assistive tech ("Feed updated") ([[A11Y-019]]).

## Optimistic actions & rollback

Like / save / follow / vote / post should reflect **immediately**, then reconcile with the server ([[OFF-001]]):

- Apply the UI change instantly (fill the heart, bump the count), fire the request in the background.
- On failure, **roll back visibly** and tell the user ("Couldn't like — tap to retry") via a non-blocking snackbar; never fail silently ([[OFF-001]], [[BDG-001]], [[STATE-007]]).
- Debounce rapid toggles; send the final state, not every intermediate tap.
- **Posting**: show the new post optimistically at the top with a "sending…" status; on failure keep it with a retry affordance, don't discard the user's content ([[CHAT-001]] analog, [[OFF-002]]).
- Provide **Undo** for consequential actions (delete, hide) via a timed snackbar rather than a blocking confirm ([[BDG-001]]).
- Haptic confirms the action but is **never the only feedback** ([[HAP-002]]).

## Thumb-zone layout

| Zone | Feed role |
|---|---|
| Bottom arc | Compose/New FAB; bottom nav; the "N new posts" jump pill |
| Middle | The feed content and inline actions on the focused card |
| Top | Feed title, filter/segment, refresh; overflow/report actions |

Inline card actions sit within reach as the card scrolls through the middle; destructive/report actions live in an overflow menu, not exposed as a bare primary ([[BTN-005]]).

## The 7 states

| State | Feed behavior |
|---|---|
| Ideal | Cards render, media lazy-loads, actions optimistic |
| Empty | First-use: explain the feed + a CTA to populate it (follow people, create first post) ([[STATE-002]]); "all caught up" is a positive empty variant |
| Loading | Skeleton cells initially; footer skeleton for next page ([[STATE-005]], [[LST-002]]) |
| Error | Full-feed error with retry when nothing loaded; **inline** retry row for a failed page while keeping loaded items ([[STATE-007]]) |
| Offline | Non-blocking banner; show cached feed; queue actions; disable/queue posting ([[STATE-008]], [[OFF-004]], [[OFF-002]]) |
| Success | Optimistic action reflected; "Posted" confirmation; "Feed updated" after refresh ([[STATE-009]]) |
| Permission-denied | If posting needs camera/photos and it's denied, explain + Settings link + manual fallback ([[STATE-010]], [[PERM-004]]) |

## Accessibility

- Feed is a `list`; each card is a grouped item with a coherent accessible name summarizing author + content, so screen readers don't read every sub-element in isolation ([[A11Y-014]], [[A11Y-005]]).
- Action buttons (like/save/share) have labels **and** state ("Like, not liked" → "Liked"); counts are announced ([[A11Y-004]], [[A11Y-006]]).
- Optimistic changes and refresh results announce via a live region ([[A11Y-019]]).
- Media has alt text / descriptions; no autoplay audio; respect reduce-motion for autoplaying video ([[AVT-002]], [[MEDIA-001]] where present, [[A11Y-011]]).
- Infinite scroll offers a keyboard/switch-accessible way to load more and reach the end ([[A11Y-016]]).
- Targets ≥44pt/48dp with ≥8dp spacing between adjacent inline actions ([[A11Y-003]], [[SPC-005]]).

## Motion

- Card actions (like): quick bouncy micro-interaction 300–400ms with haptic; reduce-motion → simple state swap ([[MIC-002]], [[MOT-004]], [[HAP-001]]).
- New-item insert / optimistic post: animate the single row in (height/opacity), not a full re-layout ([[MOT-001]], [[PERF-001]]).
- Pull-to-refresh: framework spinner with progressive reveal; don't over-animate ([[MIC-003]]).
- Only animate transform/opacity to hold the 16ms frame budget while scrolling ([[PERF-001]], [[PERF-002]]).

## Applied rules

| Intent | Rule |
|---|---|
| Virtualize | [[LST-001]], [[PERF-004]] |
| Pagination / prefetch | [[LST-004]] |
| Pull-to-refresh + alt | [[LST-003]], [[A11Y-016]] |
| Skeleton loading | [[LST-002]], [[STATE-005]] |
| Optimistic + rollback | [[OFF-001]] |
| Queue offline actions | [[OFF-002]] |
| Undo via snackbar | [[BDG-001]] |
| Lazy media, no layout shift | [[PERF-003]] |
| Card single target | [[CRD-001]], [[CRD-002]] |
| Preserve scroll position | [[LST-008]] |
| Grouped a11y for cards | [[A11Y-014]] |
| Announce updates | [[A11Y-019]] |
| Haptic not sole feedback | [[HAP-002]] |

## Anti-patterns

- ❌ Loading the entire feed into memory / not virtualizing ([[LST-001]]).
- ❌ Layout shift as images load (no aspect-ratio placeholder) ([[PERF-003]]).
- ❌ Optimistic action that fails silently — user thinks it worked ([[OFF-001]]).
- ❌ Auto-scrolling the user to new content and losing their place ([[LST-008]]).
- ❌ Pull-to-refresh as the *only* way to refresh ([[A11Y-016]]).
- ❌ Blocking confirm dialog for a like/delete instead of optimistic + Undo ([[BDG-001]]).
- ❌ Discarding a failed post's content ([[OFF-002]]).
- ❌ Reading every card sub-element separately to screen readers ([[A11Y-014]]).

## Acceptance checklist

- [ ] List virtualized; only transform/opacity animated while scrolling ([[LST-001]], [[PERF-001]]).
- [ ] Next page prefetched; footer loading + distinct end-of-feed marker; inline page-error retry ([[LST-004]], [[STATE-007]]).
- [ ] Pull-to-refresh with a non-gesture alternative; new items don't yank scroll ([[LST-003]], [[LST-008]], [[A11Y-016]]).
- [ ] Like/save/post optimistic with visible rollback + Undo; haptic not sole feedback ([[OFF-001]], [[BDG-001]], [[HAP-002]]).
- [ ] Media lazy-loads with aspect-ratio placeholders; alt text; no autoplay audio ([[PERF-003]], [[AVT-002]]).
- [ ] All 7 states, including cached-offline feed + queued actions ([[STATE-001]], [[OFF-004]]).
- [ ] Cards grouped for screen readers; actions expose label + state; updates announced ([[A11Y-014]], [[A11Y-006]], [[A11Y-019]]).
- [ ] Adjacent inline actions ≥44pt/48dp, ≥8dp apart ([[A11Y-003]], [[SPC-005]]).
- [ ] Reduce-motion fallback for like/insert/refresh animations ([[MOT-004]]).
