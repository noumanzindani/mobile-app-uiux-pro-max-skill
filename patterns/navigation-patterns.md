# Navigation Patterns

> Purpose: Choose and compose the app's navigation shell correctly for the platform, screen size, and number of destinations — bottom navigation vs navigation rail vs drawer, tab+stack back-stack management, deep links, and the ≥840dp adaptive fork — so navigation is predictable, thumb-reachable, and never fights the OS.

## Contents
- [Decision fork — which navigator?](#decision-fork--which-navigator)
- [Bottom navigation](#bottom-navigation)
- [Navigation rail (≥600dp)](#navigation-rail-600dp)
- [Navigation drawer](#navigation-drawer)
- [Tab + stack: per-tab back stacks](#tab--stack-per-tab-back-stacks)
- [Adaptive shell across size classes](#adaptive-shell-across-size-classes)
- [Deep links](#deep-links)
- [Platform back behavior](#platform-back-behavior)
- [The 7 states in a navigation shell](#the-7-states-in-a-navigation-shell)
- [Accessibility](#accessibility)
- [Motion](#motion)
- [Applied rules](#applied-rules)
- [Anti-patterns](#anti-patterns)
- [Acceptance checklist](#acceptance-checklist)

---

## Decision fork — which navigator?

Pick by **number of top-level destinations** and **width**, in this order:

```
How many primary (top-level) destinations?
├─ 2–5 destinations of equal importance
│    ├─ width < 600dp  → BOTTOM NAVIGATION BAR            [[NAV-001]]
│    ├─ 600–839dp      → NAVIGATION RAIL                  [[NAV-003]] [[GRD-002]]
│    └─ ≥ 840dp        → NAV RAIL or PERMANENT DRAWER + two-pane content [[NAV-009]] [[GRD-003]]
├─ 6+ destinations, or a mix of primary + secondary
│    → keep the top 3–5 in a bottom bar/rail, move the rest behind a
│      "More" tab or a DRAWER. Never exceed 5 visible bottom items.   [[NAV-004]]
└─ Deep hierarchy inside one destination
     → PUSH/STACK navigation within that tab (not a new tab).         [[NAV-005]]
```

iOS convention leans to a **tab bar** (bottom) for 2–5 peers; Android Material 3 uses a **navigation bar** for 3–5 and a **navigation rail/drawer** as it widens. Do not invent a hybrid — pick the paradigm ([[PLAT-001]], [[PLAT-002]]).

## Bottom navigation

**Use when:** 3–5 co-equal top-level destinations on a compact screen. This is the most thumb-friendly navigator and the default for phone apps.

**Anatomy**
- 3–5 items, each with icon + **always-visible label** ([[NAV-011]]) — icon-only bars fail recognition and localization.
- Selected item shows a non-color cue (filled icon, indicator pill, weight change), not color alone ([[NAV-010]], [[A11Y-012]]).
- Bar sits above the home-indicator / gesture inset, read from the safe area ([[SPC-016]], [[SPC-011]]).
- Each item is a ≥44pt/48dp target with ≥8dp between items ([[NAV-001]], [[A11Y-003]]).
- A badge on an item announces its count to assistive tech ([[BDG-003]]).

**Thumb-zone map**

| Zone | Bottom nav role |
|---|---|
| Bottom arc (easy reach) | The entire bar — this is why primary destinations live here |
| Middle | Scrollable content |
| Top | Screen title, contextual actions, low-frequency/destructive items |

**Rules:** never put a destructive or rarely-used action in the bottom bar; never hide the bar on scroll for a primary destination without a way to bring it back.

## Navigation rail (≥600dp)

**Use when:** width reaches the medium window class (600–839dp) — tablets in portrait, foldables unfolded, large phones landscape.

- Convert the bottom bar to a **left/leading vertical rail** with the same destinations ([[NAV-003]], [[GRD-002]]). Preserve selection and order — do not reshuffle destinations across breakpoints.
- Rail items keep icon + label and the ≥48dp target.
- Free the bottom edge for content; keep any single primary action (FAB-style) reachable but out of the rail.

## Navigation drawer

**Use when:** there are more destinations than fit a bar/rail, or you have a clear split of frequent vs occasional destinations.

- **Modal drawer** on compact screens (slides over content, scrim behind, dismiss by tap/scrim/swipe) ([[NAV-004]]).
- **Permanent/standard drawer** at ≥840dp (persistent alongside content) ([[NAV-009]], [[GRD-003]]).
- Group destinations with headers; keep the 3–5 most-used also present in the bottom bar/rail so the drawer is not the only path.
- The menu affordance is a labeled button with an accessible name ("Open navigation menu"), not a bare glyph ([[A11Y-004]]).

## Tab + stack: per-tab back stacks

Each tab owns an **independent navigation stack** so switching tabs and returning restores the prior screen and scroll position ([[NAV-005]], [[NAV-012]]).

- Tapping the **active** tab pops its stack to root (and, on a second tap, scrolls to top) — a learned iOS/Material behavior.
- Tapping an **inactive** tab switches without resetting the target tab's stack.
- Modals and full-screen flows (compose, checkout) present **above** the tab shell, not inside a tab, so the bar does not distract from a focused task ([[NAV-014]]).
- Preserve scroll offset and selection when leaving and re-entering a tab ([[LST-008]]).

## Adaptive shell across size classes

One logical navigation, three presentations — driven by breakpoint tokens ([[GRD-004]]), never by device model:

| Window class | Width | Navigator | Content |
|---|---|---|---|
| Compact | < 600dp | Bottom navigation | Single pane |
| Medium | 600–839dp | Navigation rail | Single pane (or list-detail if content suits) |
| Expanded | ≥ 840dp | Rail or permanent drawer | **Two-pane list-detail** ([[GRD-003]], see [list-detail.md](list-detail.md)) |

- Re-flow on resize (rotation, fold/unfold, split-screen, desktop window) — not just at launch ([[GRD-008]]).
- Keep the selected destination stable across a resize; a fold event must not drop the user to the home tab.
- On foldables, respect the hinge/occlusion region ([[GRD-008]]).

## Deep links

A deep link (URL, notification tap, widget, share) must resolve to a **coherent synthetic back stack**, not a dangling leaf screen ([[NAV-008]], [[NOTIF-003]]):

- Reconstruct: select the correct tab → push the parent(s) → land on the target. Back then walks up the hierarchy naturally, not out of the app.
- If the target requires auth, route through login and **return to the original destination** after success ([[AUTH-010]] where guest is allowed).
- If the linked resource is missing/deleted, show a scoped error state with a path back, never a blank screen ([[STATE-007]], [[STATE-012]]).
- Handle cold start (app not running) and warm start (already running) identically.

## Platform back behavior

- **Never override the Android system Back / predictive-back gesture** ([[NAV-006]], [[NAV-007]]); it must pop the stack or exit, and predictive-back should preview the destination.
- iOS: provide an on-screen back/close in the leading nav position and honor the edge-swipe-to-go-back gesture ([[NAV-013]], [[GES-004]]).
- Distinguish **push** (hierarchical, back arrow) from **modal/present** (close/X, downward dismiss) semantics ([[NAV-014]], [[PLAT-005]]).
- Do not trap the user: every screen has an obvious way back.

## The 7 states in a navigation shell

The shell itself is mostly stateless, but it must **host and coordinate** the states of its destinations:

| State | Shell behavior |
|---|---|
| Ideal | All tabs reachable; badges reflect live counts |
| Empty | A destination with no data shows its own empty state ([[STATE-002]]); the bar stays available |
| Loading | Switching tabs shows the target's skeleton, never a blank shell ([[STATE-005]]) |
| Error | A failed destination shows a scoped, retryable error inside its pane; other tabs stay usable ([[STATE-007]]) |
| Offline | Global non-blocking offline banner above content; navigation stays fully usable on cached data ([[STATE-008]], [[OFF-004]]) |
| Success | Post-action confirmation (snackbar) appears above the bar, not hidden behind it ([[STATE-009]], [[BDG-001]]) |
| Permission-denied | A destination needing a denied permission explains and offers a Settings deep-link, without breaking the rest of the app ([[STATE-010]], [[PERM-003]]) |

## Accessibility

- Nav items expose **role=tab/button**, an accessible **label**, and **selected state** to screen readers ([[A11Y-004]], [[A11Y-005]], [[A11Y-006]]).
- The nav bar is a single grouped landmark; reading order is left-to-right (mirrored in RTL, [[L10N-001]]).
- Selected ≠ color-only: pair color with icon-fill/indicator/weight ([[A11Y-012]]).
- All items meet target size and spacing; labels scale with Dynamic Type without clipping (allow the bar to grow or truncate gracefully at large sizes) ([[A11Y-010]], [[TYP-004]]).
- Focus is not obscured by the bar when the keyboard or a sheet is up ([[A11Y-009]]).

## Motion

- Tab switch: cross-fade or shared-axis transition, small tier (200–250ms), respecting reduce-motion by falling back to an instant cut ([[MOT-001]], [[MOT-004]]).
- Selected-item change: quick icon-fill / indicator slide, ≤200ms ([[MIC-001]]).
- Drawer: slide-in with scrim fade; never a long or bouncy entry for a utilitarian panel ([[MOT-005]]).
- Predictive back (Android): the framework's shared transition previews the destination — do not animate manually over it ([[NAV-007]]).

## Applied rules

| Intent | Rule |
|---|---|
| ≤5 bottom destinations | [[NAV-001]] |
| Rail at medium width | [[NAV-003]] |
| Drawer for overflow/secondary | [[NAV-004]] |
| Per-tab back stacks | [[NAV-005]] |
| Don't override system back | [[NAV-006]] |
| Predictive back | [[NAV-007]] |
| Deep link → full back stack | [[NAV-008]] |
| Adapt at ≥840dp | [[NAV-009]] |
| Selected not color-only | [[NAV-010]], [[A11Y-012]] |
| Labels visible | [[NAV-011]] |
| Preserve state across tabs | [[NAV-012]], [[LST-008]] |
| Modal vs push semantics | [[NAV-014]] |
| Two-pane at expanded | [[GRD-003]] |
| Bar above home indicator | [[SPC-016]] |
| Target size + spacing | [[A11Y-003]] |
| Pick the platform paradigm | [[PLAT-001]], [[PLAT-002]] |

## Anti-patterns

- ❌ 6+ items crammed into a bottom bar → mis-taps; use "More"/drawer for the overflow.
- ❌ Icon-only bottom bar with no labels → fails recognition and localization ([[NAV-011]]).
- ❌ Resetting a tab's stack every time the user leaves and returns ([[NAV-012]]).
- ❌ Custom back button that swallows the OS gesture ([[NAV-006]]).
- ❌ Notification opens a leaf screen with no back stack ([[NAV-008]]).
- ❌ Hiding navigation behind a hamburger when 3–5 items would fit a bar (buries primary destinations).
- ❌ Same layout at 320dp and 1024dp — no rail/two-pane adaptation ([[NAV-009]]).

## Acceptance checklist

- [ ] Navigator chosen by destination count + width via the decision fork; matches platform paradigm ([[PLAT-001]]).
- [ ] ≤5 visible bottom/rail items, each labeled, ≥44pt/48dp, ≥8dp apart ([[NAV-001]], [[NAV-011]], [[A11Y-003]]).
- [ ] Selected state uses a non-color cue and announces `selected` ([[NAV-010]], [[A11Y-006]]).
- [ ] Each tab keeps an independent back stack + scroll position ([[NAV-005]], [[NAV-012]]).
- [ ] Bar/rail respects safe-area + home-indicator inset ([[SPC-011]], [[SPC-016]]).
- [ ] Adapts to rail/two-pane at ≥600/≥840dp and re-flows on resize/fold ([[NAV-003]], [[NAV-009]], [[GRD-003]]).
- [ ] Deep links + notifications build a full synthetic back stack ([[NAV-008]]).
- [ ] System back / predictive back untouched ([[NAV-006]], [[NAV-007]]).
- [ ] Offline banner + scoped error/empty states hosted without breaking navigation ([[STATE-007]], [[STATE-008]]).
- [ ] Reduce-motion fallback for tab/drawer transitions ([[MOT-004]]).
