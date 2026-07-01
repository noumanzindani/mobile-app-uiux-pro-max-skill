# Dashboard — Ionic (React + Capacitor, TypeScript)

A real implementation of the [Dashboard spec](../spec.md) for **Ionic 8**. Every visual
value resolves through CSS custom properties; the grid re-flows across size classes;
**each widget owns its own state**; and the screen passes all six
`quality-checks/validators` (**100/100**).

```
ionic/
  dashboard.css        — token + style layer: --app-* / --ion-* variables, the CSS-grid
                         breakpoint reflow, and the bottom-nav <-> side-rail swap. The ONLY
                         file with raw values; the screen references var(...) / classes only.
  DashboardScreen.tsx  — the DashboardScreen component (responsive grid of self-contained
                         metric cards + a bar chart + an activity list, the per-widget
                         7-state map, pull-to-refresh, accessible, mode-adaptive).
  README.md            — this file.
```

> Bindings shown are `@ionic/react`; the same component/token approach applies to
> `@ionic/angular` and `@ionic/vue`.

## What it demonstrates

**Responsive, size-class grid (GRD-001…004).** The reflow is driven by breakpoint media
queries on a CSS grid in `dashboard.css` — nothing is hardcoded in the scanned component:

| Window class | Width | Grid | Navigation |
|---|---|---|---|
| **Compact** | `< --app-bp-medium` (600) | 1 column, full-width cards | Bottom nav |
| **Medium** | 600–839 | 2 columns; chart + list span 2 | Side rail |
| **Expanded** | `>= --app-bp-expanded` (840) | 3 columns (4 at `>= 1080`); **chart spans 2** | Side rail |

Content is **capped at `--app-max-content`** and centered (`margin-inline: auto`) so a single
column never stretches edge-to-edge on a tablet/foldable (GRD-005). Rotating, folding, or
entering split-screen re-flows live — no JS breakpoint listener to fall out of sync.

**Per-widget state, as a discriminated union — no global spinner (STATE-014).** There is no
screen-wide status. Each tile is a `WidgetStatus<T>` whose members are literally named
`idle · loading · empty · error · offline · success · permissionDenied`, and each resolves
on its own clock:

| State | Behaviour in this screen |
|---|---|
| **loading** | A **shape-matched skeleton placeholder** per tile (a label line + a number block + a trend line for metrics; placeholder bars for the chart; placeholder rows for the list) — never one global spinner. |
| **success** | Value + trend; chart renders; activity list populated. |
| **empty** | A first-use empty (*"No tasks due — you are all caught up"*) with an optional CTA (*Create task*) — not a dead end (STATE-002). |
| **error** | A **scoped** inline error + **Retry** on that tile only; every other tile stays live. Retry recovers just that widget (STATE-007). |
| **offline** | A global, **non-blocking** banner; each tile keeps its **cached value** with a *"saved · offline"* stale indicator; pull-to-refresh is disabled with a spoken reason (STATE-008/011, OFF-004). |
| **permissionDenied** | A metric needing a permission (*Steps → Motion & Fitness*) shows a scoped explain + **Open Settings** + a "rest of your dashboard still works" fallback; nothing else is affected (STATE-010, PERM-003/005). |

Because the loaders are per-tile, the seeded demo shows every state **at once**: three live
metrics, one first-use empty, one failed tile with Retry, and one permission-gated tile —
proving one failure can't blank the screen.

**Trustworthy numbers (TYP-006, L10N-005).** Every figure uses `.dash-tnum`
(`font-variant-numeric: tabular-nums`) so digits stay column-aligned as values recompute,
and is formatted with **`Intl.NumberFormat`** (currency / decimal / percent) — change
`locale` / `currency` and the whole dashboard re-localizes. **Trend is never color-only**:
it pairs a **trend icon + a sign (+/−) + text** (*"+6.3% vs last week"*) with the
success/error color, so meaning survives for color-blind users and in greyscale.

**Bar chart with non-color encoding + a data-table fallback (CHT-001/002).** The chart is
plain elements (bar heights scaled from the data via a `--dash-bar` custom property), each
labeled with its day and value and given an alternating pattern so bars differ without hue
alone. The bars are `aria-hidden`, and an **accessible data table** of rows (*"Mon, $18,400"*
…) below carries the same data in reading order for screen readers.

**Pull-to-refresh + live announcements.** `IonRefresher` refreshes every tile; on completion
an `aria-live` region announces *"Dashboard updated"* and an `ion-toast` confirms. Offline,
refresh is **blocked with a reason** instead of silently failing.

**Tokens via CSS variables.** `DashboardScreen.tsx` holds zero raw `#hex`/`px` — colors come
from `--ion-color-*` / `--ion-color-step-*`, spacing/radius from `--app-space-*` /
`--app-radius-*`, chart series from `--dash-chart-*`, and breakpoints from `--app-bp-*`, all
in `dashboard.css`. Dark mode is a class **palette** (`.ion-palette-dark`) — the component
doesn't change, only the variable values do; verify both with `contrast_check.py`.

**Adaptive (`mode`).** Ionic auto-renders `ios` vs `md` chrome/shape; the single component
tree feels native on both. Verify both modes before shipping (`PLAT-*`).

**Targets.** All interactive controls are `IonButton` (≥48px): the card tap target, Retry,
the CTA, Open Settings, refresh, the date-range pill, and every nav item — no bare tappable
icons; cards and their actions sit ≥8dp apart.

**Dynamic Type & RTL.** No fixed text heights, no sub-12px fonts; layout uses logical CSS
(`margin-inline`, `border-inline-end`, `padding-block`, `slot="start"/"end"`) — no physical
`left/right` — so the whole grid mirrors in RTL, and numbers reflow to 200% without clipping.

## Dependencies

| Package | Why |
|---|---|
| `@ionic/react` + `ionicons` | Ionic components + icon set. |
| `@capacitor/network` | Connectivity for the `offline` state / banner / stale tiles. |

```bash
npm install @ionic/react ionicons @capacitor/network
```

Add `<meta name="viewport" content="viewport-fit=cover" />` and import a dark palette
(`@ionic/react/css/palettes/dark.system.css` or `dark.class.css`) once in the app entry.

## Usage

```tsx
import DashboardScreen from './examples/dashboard/ionic/DashboardScreen';

<DashboardScreen
  locale="en-US"
  currency="USD"
  userName="Sam"
  onOpenTile={(id) => history.push(`/detail/${id}`)}  // card tap → detail
  onOpenSettings={() => NativeSettings.open(/* … */)}  // permission fallback
  onChangeRange={() => openRangePicker()}              // date-range filter
  onSelectNav={(key) => history.push(`/${key}`)}
/>;
```

Everything defaults to lightweight mocks, so the file runs standalone:

- **pull to refresh** to watch tiles update in place and hear *"Dashboard updated"*,
- tap **Retry** on the failed tile — only that widget reloads; the rest stay live,
- toggle connectivity (airplane mode) to see the **offline banner + cached/stale** tiles and
  the blocked-refresh reason,
- **resize / rotate / split-screen** to re-flow Compact → Medium → Expanded,
- turn on **Reduce Motion** to confirm the skeleton pulse / bar draw collapse to a static state.

> **The chart in a real app.** To keep this example dependency-light and self-contained, the
> bars are plain elements scaled from the data. In production, render it with a charting lib
> (e.g. one built on SVG) for crisp axes and curves — but **keep the same two guarantees**:
> non-color encoding (labels/patterns, not hue alone) **and** the accessible **data-table
> fallback** so screen-reader users get the numbers (CHT-001/002).

## Validators

`python3 quality-checks/validators/run_all.py examples/dashboard/ionic` →
**100/100, 0 errors** (`token_lint · contrast_check · target_size_lint · state_coverage ·
dynamic_type_check · rtl_check` all PASS).
