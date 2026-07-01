# Search Patterns

> Purpose: Design search that feels instant and forgiving — debounced live results, recent/suggested queries before typing, filter chips that combine cleanly, and a genuinely helpful zero-results state — while covering loading, error, offline, and permission edge cases and staying fully accessible.

## Contents
- [When to use](#when-to-use)
- [Search lifecycle](#search-lifecycle)
- [The search field](#the-search-field)
- [Before typing: recent & suggested](#before-typing-recent--suggested)
- [Instant results & debounce](#instant-results--debounce)
- [Filters & facets](#filters--facets)
- [Zero-results state](#zero-results-state)
- [Thumb-zone layout](#thumb-zone-layout)
- [The 7 states](#the-7-states)
- [Accessibility](#accessibility)
- [Motion](#motion)
- [Applied rules](#applied-rules)
- [Anti-patterns](#anti-patterns)
- [Acceptance checklist](#acceptance-checklist)

---

## When to use

Any find-something surface: global app search, in-list filter, catalog/product search, contact/message search, location search. Combines with [feed-patterns.md](feed-patterns.md) (results as a paginated feed) and [list-detail.md](list-detail.md) (result → detail).

## Search lifecycle

```
Field focused, empty  → show RECENT + SUGGESTED                      [[SRCH-002]]
User typing           → debounce, then INSTANT results / suggestions [[SRCH-001]]
Query submitted       → full results (paginated feed)                [[SRCH-006]]
No matches            → distinct ZERO-RESULTS state (not blank/empty)[[SRCH-003]]
Filters applied       → results narrow; filtered-empty is its own copy
Cleared               → back to recent + suggested
```

## The search field

- Persistent search field (or a tap-to-expand that becomes a full search screen) with a **leading search icon**, **clear (✕) button**, and a **Cancel/Back** affordance ([[SRCH-004]]).
- Placeholder describes scope ("Search orders"), never used as the sole label; the field has an accessible name ([[FRM-004]], [[A11Y-004]]).
- Correct keyboard (default/search return key), autocorrect sensible for the domain, paste allowed ([[FRM-002]], [[A11Y-015]]).
- Field + its buttons are ≥44pt/48dp; clear/cancel don't crowd each other ([[A11Y-003]], [[SPC-005]]).
- If search has scopes (All / People / Files), expose them as a segmented control or chips ([[SRCH-007]], [[CHP-001]]).

## Before typing: recent & suggested

When the field is focused but empty, **don't show a blank screen** ([[STATE-012]]):

- **Recent searches** (with a way to remove individual items and clear all) ([[SRCH-002]]).
- **Suggested / popular / trending** or contextual suggestions.
- Tapping a recent/suggested item runs the search immediately.
- Respect privacy: allow clearing recents; don't surface sensitive prior queries inappropriately.

## Instant results & debounce

- **Debounce** input (~200–300ms) so you query after the user pauses, not on every keystroke ([[SRCH-001]]).
- Show a lightweight **loading indicator** in/under the field during the query, not a full-screen spinner that hides prior results ([[SRCH-008]], [[STATE-005]]).
- Keep the previous results visible while the next query resolves (avoid flicker to empty).
- Highlight the matched substring in suggestions where helpful.
- Cancel superseded in-flight requests so a slow early query can't overwrite a newer one.

## Filters & facets

- Filters as **chips** or a filter sheet; selected chips show a non-color selected cue and are individually removable ([[CHP-001]], [[CHP-003]], [[A11Y-012]]).
- Show **active filter count** and a one-tap "Clear all"; keep the result count visible so users see the effect ([[SRCH-005]]).
- Chip row scrolls horizontally, inset from screen edges so edge chips aren't clipped by system gestures ([[GES-002]], [[CHP-002]]).
- A filter sheet uses detents, applies on an explicit "Apply" (or live-updates with a visible result count), and never traps the user ([[BSH-001]]).
- Filtered-to-nothing is a **different message** than never-searched or no-matches ([[STATE-004]]).

## Zero-results state

The most-neglected search state. Design it deliberately ([[SRCH-003]], [[STATE-004]]):

- Say plainly there are no matches for the specific query ("No results for 'headphonez'").
- Offer **recovery**: check spelling, "Did you mean…", remove a filter (with a one-tap remove), broaden the scope, or a clear-filters button.
- Provide a constructive next step (browse categories, contact support, create the missing item).
- Never show the generic empty-first-use illustration here — it misleads.

## Thumb-zone layout

| Zone | Search role |
|---|---|
| Bottom arc | (Field lives top, but) filter/sort trigger and Apply button in a sheet ride the bottom; keyboard sits here while typing |
| Middle | Results / suggestions list |
| Top | Search field, scope segments, clear/cancel |

Because the field is top-anchored (platform norm), keep the **most-tapped follow-ups** (result rows, filter apply) within the lower reach where possible; on tall phones consider a bottom-docked search entry that expands.

## The 7 states

| State | Search behavior |
|---|---|
| Ideal | Results render; filters reflect; matches highlighted |
| Empty | **Pre-search** (recent + suggested) is the "empty" of search ([[SRCH-002]]); distinct from zero-results |
| Loading | In-field/underline progress; keep prior results visible ([[SRCH-008]], [[STATE-005]]) |
| Error | Query failed → inline error with retry, keep the field + query intact ([[STATE-007]], [[FRM-009]]) |
| Offline | Search cached/local data if possible; else explain search needs connection; queue nothing destructive ([[STATE-008]], [[OFF-004]]) |
| Success | Result count announced; selecting a result navigates on ([[STATE-009]], [[A11Y-019]]) |
| Permission-denied | Location/mic search (voice, "near me") denied → explain + Settings link + typed fallback ([[STATE-010]], [[PERM-004]]) |

## Accessibility

- Search field has a role of `searchbox`/search with an accessible name; the clear button is labeled ([[A11Y-004]], [[A11Y-005]]).
- **Result count is announced** on each query via a live region ("12 results") so screen-reader users know results updated ([[A11Y-019]]).
- Suggestions/results are a navigable list; selected filter chips announce `selected` ([[A11Y-006]], [[A11Y-014]]).
- Voice-search entry, if present, is optional — typed search always works ([[A11Y-016]]).
- Highlighted matches don't rely on color alone (bold/weight too) ([[A11Y-012]]).
- Paste allowed; no CAPTCHAs blocking search ([[A11Y-015]]).

## Motion

- Field focus/expand into full search: shared-axis or scale, small tier ≤250ms; reduce-motion → cut ([[MOT-001]], [[MOT-004]]).
- Results update: cross-fade rows in rather than hard-swapping the list; avoid flicker-to-empty ([[MOT-001]]).
- Chip select: quick fill/scale ≤150ms with optional haptic ([[MIC-001]], [[HAP-001]]).
- Keep result-list scroll at 60/120fps by animating only transform/opacity ([[PERF-001]]).

## Applied rules

| Intent | Rule |
|---|---|
| Debounce input | [[SRCH-001]] |
| Recent + suggested | [[SRCH-002]] |
| Zero-results state | [[SRCH-003]], [[STATE-004]] |
| Clear button | [[SRCH-004]] |
| Filter chips + count | [[SRCH-005]] |
| Instant vs submit | [[SRCH-006]] |
| Search scope | [[SRCH-007]] |
| Loading during query | [[SRCH-008]] |
| Chips selected not color-only | [[CHP-001]], [[A11Y-012]] |
| Chip gaps/overflow | [[CHP-002]], [[CHP-003]] |
| Inset chip row from edges | [[GES-002]] |
| Announce result count | [[A11Y-019]] |
| Field accessible name | [[A11Y-004]] |
| Preserve query on error | [[FRM-009]] |

## Anti-patterns

- ❌ Querying on every keystroke with no debounce ([[SRCH-001]]).
- ❌ Blank screen when the field is focused but empty ([[STATE-012]]).
- ❌ Full-screen spinner that hides prior results on each keystroke ([[SRCH-008]]).
- ❌ Zero-results shown with the generic first-use empty illustration ([[SRCH-003]]).
- ❌ Filter chips whose selected state is color-only ([[A11Y-012]]).
- ❌ Filtered-empty and never-searched sharing one message ([[STATE-004]]).
- ❌ Voice/near-me as the only way to search (no typed fallback) ([[A11Y-016]]).
- ❌ Result count changes silently for screen-reader users ([[A11Y-019]]).

## Acceptance checklist

- [ ] Debounced instant search; superseded requests cancelled; prior results kept during load ([[SRCH-001]], [[SRCH-008]]).
- [ ] Focused-empty shows recent + suggested (removable), never blank ([[SRCH-002]], [[STATE-012]]).
- [ ] Clear + cancel present and labeled; field has an accessible name; paste allowed ([[SRCH-004]], [[A11Y-004]], [[A11Y-015]]).
- [ ] Filters as chips with count + clear-all; selected state non-color-only; row inset from edges ([[SRCH-005]], [[CHP-001]], [[GES-002]]).
- [ ] Zero-results is a distinct, recovery-oriented state, separate from filtered-empty and first-use ([[SRCH-003]], [[STATE-004]]).
- [ ] Result count announced via live region on each query ([[A11Y-019]]).
- [ ] All 7 states designed, incl. offline/local search + permission fallback for voice/location ([[STATE-001]]).
- [ ] Targets ≥44pt/48dp; matches not color-only ([[A11Y-003]], [[A11Y-012]]).
- [ ] Reduce-motion fallback for expand/results transitions ([[MOT-004]]).
