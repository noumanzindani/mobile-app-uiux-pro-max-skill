# Example Spec — Dashboard

> Purpose: Reference specification for a glanceable, responsive dashboard where **each widget owns its own state**. This is a spec, not code — it defines intent, the per-widget 7-state map, the responsive layout across size classes, thumb-zone, accessibility, tokens, motion, and the validator-backed acceptance gate. Implementations live in `dashboard/<framework>/`.

## Contents
- [Intent / user goal](#intent--user-goal)
- [Platforms & frameworks](#platforms--frameworks)
- [Patterns & rules used](#patterns--rules-used)
- [Layout & thumb-zone (responsive)](#layout--thumb-zone-responsive)
- [States map (per widget)](#states-map-per-widget)
- [Accessibility](#accessibility)
- [Token usage](#token-usage)
- [Motion](#motion)
- [Acceptance checklist](#acceptance-checklist)

---

## Intent / user goal

"Show me the state of my world at a glance, and let me jump to what needs attention." The user scans key metrics/cards (balances, tasks due, activity, charts), notices what changed, and drills into detail. Speed of comprehension and trustworthiness of the numbers matter most.

**Success = the user understands their status in seconds and can act on any tile in one tap.**

## Platforms & frameworks

- **Paradigm:** Adaptive, responsive-first. This example's whole point is size-class adaptation ([[GRD-001]]–[[GRD-003]]). iOS HIG / Android M3 for chrome; content grid is shared.
- **Frameworks (v1, flagship = all four):** Flutter, React Native, SwiftUI, Jetpack Compose — each using its window-size-class API (`MediaQuery` / dimensions / size classes / `WindowSizeClass`).

## Patterns & rules used

- Patterns: [`navigation-patterns.md`](../../patterns/navigation-patterns.md), [`list-detail.md`](../../patterns/list-detail.md), [`empty-error-offline.md`](../../patterns/empty-error-offline.md).
- Rules: [[GRD-001]]/[[GRD-002]]/[[GRD-003]] (size classes), [[GRD-004]] (breakpoint tokens), [[GRD-008]] (foldable/resize), [[CRD-001]] (card single target), [[CHT-001]] (no color-only encoding), [[CHT-002]] (data-table fallback), [[STATE-005]] (skeletons), [[STATE-011]] (stale indicator), [[TYP-006]] (tabular numerals), [[DEN-003]] (compact density for data).

## Layout & thumb-zone (responsive)

A grid of self-contained **metric/summary cards** + a chart + an activity list, re-flowing by width ([[GRD-004]]):

| Window class | Width | Grid | Navigation |
|---|---|---|---|
| Compact | < 600dp | 1 column (cards full-width, vertical scroll) | Bottom nav ([[NAV-001]]) |
| Medium | 600–839dp | 2 columns | Navigation rail ([[NAV-003]]) |
| Expanded | ≥ 840dp | 3–4 columns; chart spans 2; optional list-detail side pane | Rail / permanent drawer ([[NAV-009]], [[GRD-003]]) |

- Re-flows live on rotate / fold-unfold / split-screen; selected drill-down survives the resize ([[GRD-008]]).
- Content max-measure preserved on very wide screens (don't stretch a single column edge-to-edge) ([[GRD-005]], [[SPC-018]]).

| Zone | Contents |
|---|---|
| Bottom arc | Bottom nav (compact); primary FAB (e.g., "New" / "Add") if present; refresh trigger |
| Middle | Metric cards, chart, activity feed |
| Top | Greeting/title, date range / filter, notifications, account avatar |

Each card is one tap target to its detail; secondary actions don't conflict with the card tap ([[CRD-001]], [[CRD-002]]). Filters/date-range live top; the most-tapped drill-ins sit in the scrollable middle within reach.

## States map (per widget)

The dashboard's defining rule: **there is no single global state — each tile loads, errors, and empties independently** ([[STATE-014]]). One failed metric must not blank the whole screen.

| State | Per-widget behavior |
|---|---|
| **Ideal** | Metric shows value + trend; chart renders; activity list populated. |
| **Empty** | A metric with no data yet shows a first-use empty ("No transactions this month") with an optional CTA ([[STATE-002]]); "all clear" tiles read positively ([[STATE-003]]). |
| **Loading** | Each tile shows a **skeleton matching its shape** (number block, chart placeholder, list rows), not one global spinner ([[STATE-005]], [[LST-002]]). |
| **Error** | A failed tile shows an **inline** compact error + Retry, scoped to that tile; other tiles stay live ([[STATE-007]], [[STATE-014]]). |
| **Offline** | Global non-blocking offline banner; tiles show **cached values with a "last updated / stale" indicator**; refresh disabled with reason ([[STATE-008]], [[STATE-011]], [[OFF-004]]). |
| **Success** | After a pull-to-refresh or an action, tiles update in place; "Updated" announced; number changes animate subtly ([[STATE-009]], [[A11Y-019]]). |
| **Permission-denied** | A tile needing a permission (e.g., health/location metric) shows a scoped explain + Settings link + fallback; the rest of the dashboard is unaffected ([[STATE-010]], [[PERM-003]], [[PERM-005]]). |

## Accessibility

- Each card is a grouped, focusable element with a **coherent accessible name** ("Balance, $2,430, up 4% this week") so the trend isn't color/arrow-only ([[A11Y-014]], [[A11Y-005]], [[A11Y-012]]).
- **Charts are never color-only**: include labels/patterns and a **data-table fallback** reachable by screen readers ([[CHT-001]], [[CHT-002]]).
- Trend direction conveyed by icon + text/sign, not just red/green ([[A11Y-012]], [[COL-003]]).
- **Numbers use tabular figures** and locale formatting for alignment and readability ([[TYP-006]], [[L10N-005]]).
- Refresh completion and tile updates announce via a live region ([[A11Y-019]]).
- Contrast ≥4.5:1 for values/labels, ≥3:1 for chart strokes/UI, both themes ([[A11Y-001]], [[A11Y-002]], [[DRK-004]]).
- Targets ≥44pt/48dp; cards + their actions ≥8dp apart; text scales to 200% (numbers may reflow, never clip) ([[A11Y-003]], [[A11Y-010]]).
- Reading/focus order is logical across the grid and mirrors in RTL ([[A11Y-008]], [[L10N-001]]).

## Token usage

| Element | Token |
|---|---|
| Screen / card background | `color.surface` / `color.surface.container` |
| Card elevation | `elevation.level1` (M3) / material in SwiftUI ([[ELV-001]]) |
| Positive / negative trend | `color.status.success` / `color.status.error` (+ icon, non-color) |
| Chart series | `color.chart.1…n` (semantic, distinguishable, pattern-backed) |
| Metric value / label | `type.display.sm` / `type.label.md`, tabular numerals |
| Grid gutter / card padding | `space.4` gutter, `space.4` card padding ([[SPC-007]]) |
| Card radius | `radius.lg` ([[SHP-001]]) |
| Breakpoints | `breakpoint.compact/medium/expanded` ([[GRD-004]]) |

Zero literals; resolves in light/dark ([[COL-001]], [[DRK-001]]); `token_lint.py` clean.

## Motion

- Skeleton → content: gentle cross-fade per tile as each resolves independently ([[MOT-001]]).
- Number/metric change: count-up or subtle transition ≤300ms so a change is noticed, not distracting ([[MOT-001]], [[MOT-005]]).
- Chart draw-in: brief, ≤400ms; reduce-motion → render final state instantly ([[MOT-004]]).
- Pull-to-refresh: standard spinner + haptic tick ([[MIC-003]], [[HAP-001]]).
- Grid re-flow on resize: animate layout gently or cut; never a jarring reshuffle ([[MOT-001]]).
- Only transform/opacity; hold the frame budget while scrolling a dense grid ([[PERF-001]], [[PERF-002]]).

## Acceptance checklist

Validators (`run_all.py`):

- [ ] `token_lint.py` PASS — tokens only, incl. breakpoints + chart colors ([[COL-001]], [[GRD-004]]).
- [ ] `contrast_check.py` PASS — values/labels ≥4.5:1, chart/UI ≥3:1, both themes ([[A11Y-001]]).
- [ ] `target_size_lint.py` PASS — cards/actions ≥44pt/48dp, ≥8dp apart ([[A11Y-003]]).
- [ ] `state_coverage.py` PASS — per-widget empty/loading/error/offline present ([[STATE-001]], [[STATE-014]]).
- [ ] `dynamic_type_check.py` PASS — numbers/labels reflow, no fixed heights ([[A11Y-010]]).
- [ ] `rtl_check.py` PASS — grid + trends mirror correctly ([[L10N-001]]).

Manual / prose:

- [ ] Re-flows Compact→Medium→Expanded via breakpoint tokens; survives fold/rotate/split ([[GRD-001]]–[[GRD-003]], [[GRD-008]]).
- [ ] No global spinner — each tile has independent skeleton/error/empty ([[STATE-014]]).
- [ ] Offline shows cached data with a stale indicator; refresh disabled with reason ([[STATE-011]]).
- [ ] Charts have non-color encoding + data-table a11y fallback ([[CHT-001]], [[CHT-002]]).
- [ ] Trends not color-only; numbers tabular + locale-formatted ([[A11Y-012]], [[TYP-006]]).
- [ ] Updates announced to assistive tech ([[A11Y-019]]).
- [ ] Reduce-motion fallback for chart/number/reflow animations ([[MOT-004]]).
