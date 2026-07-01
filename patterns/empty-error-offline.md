# Empty / Error / Offline — The State-Design Playbook

> Purpose: The single reference for designing all seven UI states well, on every data-backed screen. AI-generated UI almost always ships only the "ideal, loaded" state; this playbook makes the invisible states — empty (×3), loading, error, offline, success, permission-denied — first-class, so every screen is complete, honest, and recoverable.

## Contents
- [The rule: every screen ships all 7 states](#the-rule-every-screen-ships-all-7-states)
- [State selection matrix](#state-selection-matrix)
- [1. Ideal](#1-ideal)
- [2. Empty — the three flavors](#2-empty--the-three-flavors)
- [3. Loading](#3-loading)
- [4. Error](#4-error)
- [5. Offline](#5-offline)
- [6. Success](#6-success)
- [7. Permission-denied](#7-permission-denied)
- [Anatomy of a good state screen](#anatomy-of-a-good-state-screen)
- [Copywriting the states](#copywriting-the-states)
- [Accessibility of states](#accessibility-of-states)
- [Motion between states](#motion-between-states)
- [Applied rules](#applied-rules)
- [Anti-patterns](#anti-patterns)
- [Acceptance checklist](#acceptance-checklist)

---

## The rule: every screen ships all 7 states

For any view backed by data, permissions, or network, enumerate and design each of the seven states — do not ship "loaded-only" ([[STATE-001]]). The `state_coverage.py` validator fails a screen missing empty/loading/error/offline. The seven:

1. **Ideal** — loaded, everything works.
2. **Empty** — no data (first-use / user-cleared / no-results).
3. **Loading** — fetching.
4. **Error** — the request failed.
5. **Offline** — no connectivity.
6. **Success** — an action completed.
7. **Permission-denied** — a required system permission was refused.

> Not every state applies to every screen — a static "About" page has no loading state. But you must **consciously decide** which apply and design them, rather than forgetting they exist.

## State selection matrix

| Screen type | Empty | Loading | Error | Offline | Success | Perm-denied |
|---|:--:|:--:|:--:|:--:|:--:|:--:|
| Feed / list | ✅ ×3 | ✅ | ✅ | ✅ | ✅ (optimistic) | ⚠️ if needs perm |
| Detail | ⚠️ placeholder | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| Form | ready-empty | ✅ (submit) | ✅ | ✅ (queue) | ✅ | ⚠️ (camera/contacts) |
| Search | ✅ pre-search + zero-results | ✅ | ✅ | ⚠️ local | ✅ | ⚠️ (voice/location) |
| Dashboard | ✅ per widget | ✅ per widget | ✅ per widget | ✅ | — | ⚠️ |
| Map / camera | — | ✅ | ✅ | ✅ | ✅ | ✅ (location/camera) |
| Settings | — | ⚠️ | ✅ | ✅ | ✅ | — |

✅ = design it · ⚠️ = design if the feature involves it · — = usually N/A

## 1. Ideal

The fully-loaded, everything-works state. Design this **last conceptually** but never assume it's the only one. It sets the layout the other states must fit into (a loading skeleton should match the ideal layout's shape so the transition is calm).

## 2. Empty — the three flavors

"Empty" is not one state. Distinguish them; each needs different copy and a different call to action ([[STATE-002]], [[STATE-003]], [[STATE-004]]):

- **First-use empty** — the user has never added data. **Onboarding opportunity:** explain the value and give a primary CTA to create the first item ("No tasks yet — add one to get started"). ([[STATE-002]])
- **User-cleared empty** — the user emptied it themselves (archived all, completed all). **Positive reinforcement:** "All caught up," "Inbox zero" — no error tone. ([[STATE-003]])
- **No-results empty** — a search or filter returned nothing. **Recovery-oriented:** name the query, offer to clear filters / broaden / fix spelling. Never the first-use illustration. ([[STATE-004]], see [search-patterns.md](search-patterns.md))

All three: never a blank screen ([[STATE-012]]); use a friendly visual, one clear sentence, and at most one primary action.

## 3. Loading

- **Skeletons over spinners** for content — mirror the ideal layout so content settles in place without a jarring swap ([[STATE-005]], [[LST-002]], [[PERF-005]]).
- **Determinate progress** when the duration/amount is known (upload, download, multi-step) ([[PRG-001]], [[STATE-006]]).
- Spinner is acceptable for short, indeterminate, in-place actions (button submit).
- **Perceived performance:** respond within ~100ms (press feedback), show progress by ~1s, and for >1s show skeletons; anything over ~10s needs a progress bar and ideally a way to cancel/continue in background.
- Never blank-white-flash between navigation and content ([[STATE-012]]).
- Preserve layout stability — reserve space so content doesn't jump when it arrives ([[PERF-003]]).

## 4. Error

- **Explain plainly** what went wrong in human terms; **offer the fix** (Retry, and any alternative) ([[STATE-007]]).
- **Scope correctly:** a single failed widget/section shows an inline error; a whole-screen failure shows a full-screen error. Don't blank the entire screen for a partial failure ([[STATE-014]]).
- **Preserve user input** across an error — never wipe a form ([[FRM-009]], [[STATE-013]]).
- Distinguish error types: transient/network (Retry), not-found (path back), forbidden (explain), server (try later + support).
- Log details for developers, show empathy to users; **no raw stack traces / codes** as the whole message (a small reference code is fine).
- Error visuals/state are **not color-only**: icon + text + action ([[COL-003]], [[A11Y-012]]).

## 5. Offline

- **Non-blocking banner**, not a full takeover — the app stays usable on cached data ([[STATE-008]], [[BDG-002]], [[OFF-004]]).
- Show **cached content** with a subtle "showing offline / last updated" indicator; mark stale data honestly ([[OFF-004]], [[STATE-011]]).
- **Queue** mutations (send, post, save) and sync with backoff when connectivity returns; show the queued/sending status ([[OFF-002]], [[OFF-003]]).
- **Optimistic + rollback** for actions taken offline, with visible reconciliation ([[OFF-001]]).
- Disable (with a reason) only the actions that truly require the network (e.g., payment charge) ([[PAY-007]]).
- Auto-recover: detect reconnection and refresh/sync without making the user relaunch.

## 6. Success

- **Confirm the outcome** and provide the **next step** — don't leave the user wondering if it worked ([[STATE-009]]).
- Match weight to consequence: a transient **snackbar** for lightweight actions (saved, sent) with **Undo** where reversible ([[BDG-001]]); a **confirmation screen** for high-stakes outcomes (order placed, account created) with receipt/next actions ([[PAY-008]]).
- Haptic success cue is a bonus, never the only signal ([[HAP-003]], [[HAP-002]]).
- Don't trap the user on a success screen or force an upsell before their goal.

## 7. Permission-denied

- Triggered when a needed OS permission is refused (camera, location, mic, photos, notifications, contacts) ([[STATE-010]]).
- **Explain the value** the feature provides, then offer a **deep-link to Settings** to re-enable, plus a **manual fallback** where possible (type the address instead of GPS, pick a file instead of camera) ([[PERM-003]], [[PERM-004]]).
- **Degrade the feature, not the whole app** — never dead-end ([[PERM-005]]).
- Distinguish "not yet asked" (prime + request) from "denied" (Settings path) from "restricted" (explain it's blocked by policy) ([[PERM-001]], [[PERM-002]]).

## Anatomy of a good state screen

Empty / error / permission screens share a template:

```
[ Illustration or icon — friendly, on-brand, not a scary crash graphic ]
[ Headline  — one short line, plain language                          ]
[ Body      — one sentence: what happened + what to do (optional)     ]
[ Primary CTA — the single most useful next action (Retry / Add / Settings) ]
[ Secondary  — optional (Learn more / Contact support)               ]
```

Rules: one primary action ([[BTN-001]]); centered in the content area but keep the CTA within thumb reach; tokenized spacing/type/color ([[SPC-004]], [[TYP-002]], [[COL-001]]); works in dark mode ([[DRK-001]]); illustration is decorative (hidden from screen readers) while the text carries the meaning ([[A11Y-004]]).

## Copywriting the states

- **Human, specific, blameless.** "We couldn't load your orders. Check your connection and try again." — not "Error 500."
- Empty first-use is **inviting**, user-cleared is **congratulatory**, no-results is **corrective**, error is **reassuring + actionable**, offline is **calm**, success is **affirming**, permission-denied is **explanatory**.
- Real, localized strings — no concatenation, room for text expansion, RTL-safe ([[L10N-002]], [[L10N-003]]).
- Match the domain tone (a medical app stays calm and precise; a social app can be playful) — see the industry packs' `copy-and-tone.md`.

## Accessibility of states

- State **changes are announced** via a live/status region — a screen-reader user must know when loading finished, an error appeared, or an action succeeded ([[A11Y-019]], `4.1.3 Status Messages`).
- **Errors are identified** in text and associated with the failing field/section ([[A11Y-018]], `3.3.1`).
- Focus moves sensibly on state change (to the error summary, to the new content), never lost ([[A11Y-008]]).
- No state relies on color alone (error red, success green, offline gray) — always pair with icon + text ([[A11Y-012]]).
- Skeletons/spinners are marked busy and don't spam the screen reader with churn.
- Text in every state scales to 200% and contrasts ≥4.5:1 in both themes ([[A11Y-010]], [[A11Y-001]], [[DRK-004]]).

## Motion between states

- Transition **skeleton → content** with a gentle cross-fade so items don't pop harshly ([[MOT-001]]).
- Offline banner slides in/out non-blocking; don't shove content jarringly ([[MOT-001]], [[BDG-002]]).
- Error/empty illustrations enter subtly; never a long or bouncy animation that delays the fix ([[MOT-005]]).
- Respect reduce-motion: fall back to instant changes ([[MOT-004]], [[A11Y-011]]).
- Only animate transform/opacity to protect the frame budget ([[PERF-001]]).

## Applied rules

| Intent | Rule |
|---|---|
| Ship all 7 states | [[STATE-001]] |
| First-use empty | [[STATE-002]] |
| User-cleared empty | [[STATE-003]] |
| No-results empty | [[STATE-004]] |
| Skeleton loading | [[STATE-005]], [[LST-002]] |
| Determinate progress | [[STATE-006]], [[PRG-001]] |
| Actionable error | [[STATE-007]] |
| Offline banner + cache | [[STATE-008]], [[OFF-004]] |
| Success confirm + next | [[STATE-009]] |
| Permission-denied handling | [[STATE-010]], [[PERM-003]] |
| Stale/partial indicator | [[STATE-011]] |
| Never blank screen | [[STATE-012]] |
| Preserve input on error | [[STATE-013]], [[FRM-009]] |
| Error scoping inline vs full | [[STATE-014]] |
| Queue + backoff offline | [[OFF-002]], [[OFF-003]] |
| Undo via snackbar | [[BDG-001]] |
| Announce state changes | [[A11Y-019]] |
| Not color-only | [[A11Y-012]] |

## Anti-patterns

- ❌ Shipping only the loaded state ([[STATE-001]]).
- ❌ One "empty" for first-use, cleared, and no-results ([[STATE-002]]–[[STATE-004]]).
- ❌ Full-screen spinner that blanks everything and hides prior content ([[STATE-005]]).
- ❌ Raw error codes / stack traces as the user-facing message ([[STATE-007]]).
- ❌ Wiping a form on error ([[FRM-009]]).
- ❌ Full-screen offline takeover that blocks cached content ([[STATE-008]]).
- ❌ Silent success (no confirmation the action worked) ([[STATE-009]]).
- ❌ Permission denial that dead-ends the whole app ([[PERM-005]]).
- ❌ State conveyed by color alone; state changes not announced ([[A11Y-012]], [[A11Y-019]]).

## Acceptance checklist

- [ ] Every data-backed screen consciously designs all applicable states from the matrix ([[STATE-001]]).
- [ ] Three empty flavors distinguished with correct tone + CTA ([[STATE-002]], [[STATE-003]], [[STATE-004]]).
- [ ] Loading uses layout-matching skeletons (or determinate progress); no blank flash ([[STATE-005]], [[STATE-012]]).
- [ ] Errors are plain, scoped correctly, retryable, and preserve input ([[STATE-007]], [[STATE-013]], [[STATE-014]]).
- [ ] Offline is a non-blocking banner with cached content + queued sync ([[STATE-008]], [[OFF-002]]).
- [ ] Success confirms + gives a next step; weight matches consequence ([[STATE-009]]).
- [ ] Permission-denied explains value, deep-links to Settings, and offers a fallback ([[STATE-010]], [[PERM-004]]).
- [ ] All states are tokenized, dark-mode-correct, and not color-only ([[COL-001]], [[DRK-001]], [[A11Y-012]]).
- [ ] State changes announced to assistive tech; focus handled ([[A11Y-019]], [[A11Y-008]]).
- [ ] Reduce-motion fallback for all state transitions ([[MOT-004]]).
