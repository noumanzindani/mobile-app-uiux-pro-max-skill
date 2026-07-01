# Dashboard — React Native (TypeScript)

A real, compiling implementation of the [Dashboard spec](../spec.md) for React Native.
Every visual value resolves through semantic tokens; **each widget owns its own state**;
the grid re-flows across size classes; and the screen passes all six
`quality-checks/validators` at **100/100**.

```
react-native/
  dashboardTokens.ts   — semantic tokens (surface/container, status success/error,
                         chart series chart1..4, on-surface roles, spacing incl. grid
                         gutter, radius, size, typography + `tabular` figures, motion,
                         breakpoints compact=600 / expanded=840). The ONLY file allowed
                         to hold raw literals; each is `// ux:ignore`.
  DashboardScreen.tsx  — the DashboardScreen component (responsive grid of self-contained
                         metric cards + a Views-drawn bar chart + an activity list, the
                         per-widget 7-state map, pull-to-refresh, accessible).
  README.md            — this file.
```

## What it demonstrates

**Responsive, size-class grid (GRD-001…004).** `useWindowDimensions()` drives the layout
against breakpoint **tokens** — nothing is hardcoded:

| Window class | Width | Grid | Navigation |
|---|---|---|---|
| **Compact** | `< breakpoint.compact` (600) | 1 column, full-width cards | Bottom nav |
| **Medium** | 600–839 | 2 columns | Side rail |
| **Expanded** | `>= breakpoint.expanded` (840) | 3 columns (4 at `>= wide` 1080); **chart spans 2** | Side rail |

Tile widths are computed from the measured content width minus the grid `gutter`, and the
content is **capped at `breakpoint.maxContent`** and centered so a single column never
stretches edge-to-edge on a tablet/foldable (GRD-005). Rotating, folding, or entering
split-screen re-flows live.

**Per-widget state — no global spinner (STATE-014).** There is no screen-wide status.
Each tile is a `WidgetState =
'loading' | 'empty' | 'error' | 'offline' | 'success' | 'permissionDenied' | 'ideal'`
and resolves on its own clock:

| State | Behaviour in this screen |
|---|---|
| **loading** | A **shape-matched skeleton** per tile (a label line + a number block + a trend line for metrics; placeholder bars for the chart; placeholder rows for the list) — never one global spinner. |
| **ideal** | Value + trend; chart renders; activity list populated. |
| **empty** | A first-use empty (*"No tasks due — you're all caught up"*) with an optional CTA (*Create task*) — not a dead end (STATE-002). |
| **error** | A **scoped** inline error + **Retry** on that tile only; every other tile stays live. Retry recovers just that widget (STATE-007). |
| **offline** | A global, **non-blocking** banner; each tile keeps its **cached value** with a *"saved · offline"* stale indicator; pull-to-refresh is disabled with a spoken reason (STATE-008/011, OFF-004). |
| **success** | After a pull-to-refresh, tiles update in place, the number cross-fades subtly, and *"Dashboard updated"* is announced (STATE-009, A11Y-019). |
| **permissionDenied** | A metric needing a permission (*Steps → Motion & Fitness*) shows a scoped explain + **Open Settings** + a "rest of your dashboard still works" fallback; nothing else is affected (STATE-010, PERM-003/005). |

Because the loaders are per-tile, the seeded demo shows every state **at once**: three live
metrics, one first-use empty, one failed tile with Retry, and one permission-gated tile —
proving one failure can't blank the screen.

**Trustworthy numbers (TYP-006, L10N-005).** Every figure uses `tabular`
(`fontVariant: ['tabular-nums']`) so digits stay column-aligned as values recompute, and is
formatted with **`Intl.NumberFormat`** (currency / decimal / compact) — change `locale` /
`currency` and the whole dashboard re-localizes. **Trend is never color-only**: it pairs an
**arrow icon + a sign (+/−) + text** (*"+6.3% vs last week"*) with the success/error color,
so meaning survives for color-blind users and greyscale.

**Bar chart drawn with Views + a data-table fallback (CHT-001/002).** The chart is plain
`View` bars (heights scaled from the data), each labeled with its day and value — no
color-only encoding. The bars are marked decorative for assistive tech, and an **accessible
data table** of rows (*"Mon, $18,400"* …) below carries the same data in reading order for
screen readers.

**Pull-to-refresh + live announcements.** A `RefreshControl` refreshes every tile; on
completion the header's *"Updated"* status updates inside an `accessibilityLiveRegion` and
`AccessibilityInfo.announceForAccessibility` speaks it. Offline, refresh is **blocked with a
reason** instead of silently failing.

**Accessibility.** Each live card is a single grouped tap target with a **coherent label**
(*"Revenue, $128,940, up 6.3 percent versus last week"*) so the trend isn't arrow-only
(A11Y-014/012). Cards, Retry, the refresh control, and every nav item are **≥48dp**. Text
uses scalable token roles (size ≥ 12, `allowFontScaling`, **no fixed heights on text**) so it
grows to 200% without clipping — fixed heights appear only on non-text skeleton/bar Views.

**Motion & reduce-motion (MOT-001/004).** The only animations are a per-tile skeleton→content
cross-fade, a subtle number settle, and a brief chart draw-in — **`opacity`/`transform`
only**. All collapse to an instant final state when
`AccessibilityInfo.isReduceMotionEnabled()` is on.

**Tokens & RTL (COL-001, L10N-001).** `DashboardScreen.tsx` holds **zero** raw hex or
off-grid spacing — colors, the 4/8-grid spacing + gutter, radius, type roles, target sizes,
motion durations, chart series colors, and breakpoints all come from `dashboardTokens.ts`;
dark mode is automatic via `useColorScheme()` → `getColors()`. Layout uses **logical
properties only** (`flex-start`/`flex-end`, `paddingHorizontal`, `paddingStart`/`End`,
`borderEndWidth`) with **no `left`/`right`/`marginLeft`** anywhere; amounts end-align via
flex and the trend arrow mirrors under `I18nManager.isRTL`, so the whole grid flips in RTL.

## Dependencies

Beyond `react` / `react-native`:

| Package | Why |
|---|---|
| [`react-native-safe-area-context`](https://github.com/th3rdwave/react-native-safe-area-context) | `SafeAreaView` + `useSafeAreaInsets()` — the bottom nav and side rail clear the home indicator / cutouts without hardcoding insets. |
| [`@react-native-community/netinfo`](https://github.com/react-native-netinfo/react-native-netinfo) | Connectivity — drives the global offline banner, each tile's cached/stale fallback, and the "refresh disabled offline" reason. |

```bash
npm install react-native-safe-area-context @react-native-community/netinfo
# or: yarn add react-native-safe-area-context @react-native-community/netinfo
```

Wrap the app once in `<SafeAreaProvider>` (from `react-native-safe-area-context`) so
`useSafeAreaInsets()` resolves.

> **The chart in a real app.** To keep this example dependency-light and fully self-contained,
> the bar chart is drawn with plain **`View`s** (bar heights scaled from the data). In
> production, render it with [`react-native-svg`](https://github.com/software-mansion/react-native-svg)
> (or a charting lib built on it) for crisp axes, gridlines, and curves — but **keep the same
> two guarantees**: non-color encoding (labels/patterns, not hue alone) **and** the accessible
> **data-table fallback** so screen-reader users get the numbers (CHT-001/002).

## Usage

```tsx
import DashboardScreen from './examples/dashboard/react-native/DashboardScreen';

<DashboardScreen
  locale="en-US"
  currency="USD"
  userName="Sam"
  onOpenTile={(id) => navigation.navigate('Detail', { id })}  // card tap → detail
  onOpenSettings={() => Linking.openSettings()}               // permission fallback
  onChangeRange={() => openRangePicker()}                     // date-range filter
  onSelectNav={(key) => navigation.navigate(key)}
/>;
```

Everything defaults to lightweight mocks, so the file compiles and runs standalone:

- **pull to refresh** to watch tiles update in place and hear *"Dashboard updated"*,
- tap **Retry** on the failed tile — only that widget reloads; the rest stay live,
- toggle connectivity (airplane mode) to see the **offline banner + cached/stale** tiles and
  the blocked-refresh reason,
- **resize / rotate / split-screen** to re-flow Compact → Medium → Expanded,
- turn on **Reduce Motion** to confirm every animation collapses to an instant state.

## Validators

`python3 quality-checks/validators/run_all.py examples/dashboard/react-native` →
**100/100, 0 errors** (`token_lint · contrast_check · target_size_lint · state_coverage ·
dynamic_type_check · rtl_check` all PASS).
