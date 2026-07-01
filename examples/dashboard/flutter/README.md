# Dashboard — Flutter reference implementation

A real, compiling Flutter build of the dashboard spec in [`../spec.md`](../spec.md).
A glanceable, **responsive** grid of self-contained tiles where **every widget
owns its own state** — one failed metric never blanks the screen. Fully **token
driven**, so a rebrand or a dark-mode swap is a token change, not a refactor.

| File | Role |
|---|---|
| `dashboard_tokens.dart` | The semantic token layer — color / spacing / radius / size / elevation / motion / typography **plus the responsive breakpoints and chart-series colors**. The **only** file allowed raw values (each raw line ends with `// ux:ignore`). Value + amount roles use **tabular figures** (`FontFeature.tabularFigures`) so a number that recounts on refresh never jitters and columns align to the decimal. |
| `dashboard_screen.dart` | The `DashboardScreen` widget — the responsive grid, the per-tile 7-state machine, the CustomPaint chart with a data-table fallback, the global offline banner, pull-to-refresh, RTL-safety, and a11y. References tokens only. Numbers are formatted with `intl` (locale-aware). |

Verified on **Flutter 3.x / Dart 3** (`flutter analyze` clean, widget smoke tests
green) and scores **100/100** on `quality-checks/validators/run_all.py`.

> **One dependency:** `intl` (locale-aware `NumberFormat`). Add it with
> `flutter pub add intl` — a first-party Dart package. Everything else is pure
> `flutter/material` + `flutter/services`.

## What it demonstrates

**Responsive, re-flowing grid** (`GRD-001..004`, `GRD-008`) driven by
`LayoutBuilder` + `MediaQuery.sizeOf` against named breakpoint tokens:

| Window class | Width | Grid | Navigation |
|---|---|---|---|
| Compact | `< 600dp` | 1 column | **Bottom navigation bar** |
| Medium | `600–839dp` | 2 columns | **NavigationRail** |
| Expanded | `≥ 840dp` (4 cols `≥ 1240dp`) | 3–4 columns; **chart spans 2** | NavigationRail |

- Column count is derived from the **live available width** inside the grid, and
  tiles carry a **span** (chart + activity span 2) clamped to the live count, so
  the grid re-flows cleanly on rotate / fold / split — no fixed layouts.
- On very wide windows the content keeps a **max measure** (`DashSize.maxContent`)
  so a single column never stretches edge-to-edge (`GRD-005`, `SPC-018`).

**Per-widget state** — an explicit `enum WidgetState { loading, empty, error,
offline, success, permissionDenied, ideal }`, owned by **each tile** (`STATE-014`).
The demo lays out one tile per state so you can see them coexist:

- **success / ideal** — value + trend, one tap to detail (Balance).
- **loading** — a **skeleton matching the tile's shape** (title / value / trend
  blocks), gentle cross-fade to content as it resolves — not one global spinner
  (Active now).
- **error** — an **inline, compact** message + **Retry scoped to that tile**;
  every other tile stays live (Open tasks).
- **empty** — a first-use prompt + CTA, never a dead end (New customers).
- **offline** — the tile keeps its **cached value** with a **"last updated /
  stale" indicator** (Spending); a **global, non-blocking offline banner** shows
  above the grid, announced via a live region.
- **permission-denied** — a **scoped** explain + Settings deep-link + fallback;
  the rest of the dashboard is unaffected (Steps).

**Trustworthy numbers & a real chart:**

- **Tabular figures + locale formatting** — values, amounts, and the chart axis
  use `FontFeature.tabularFigures` + `intl`'s `NumberFormat`
  (`simpleCurrency` / `decimalPattern` / `compactSimpleCurrency`), so digits align
  and never conveyed by color/weight alone (`TYP-006`, `L10N-005`).
- **Trend is icon + sign + text**, never color-only — an up/down arrow (vertical,
  mirror-safe) + a signed `+4%` + a period label; color is a redundant cue
  (`A11Y-012`, `COL-003`).
- **CustomPaint bar chart** (`_BarChartPainter`) encodes value by **height**, cycles
  **distinguishable series colors**, and marks the **peak with an outline cap** so
  it reads in grayscale (`CHT-001`). Every bar is **labeled** (value above, day
  below). A **screen-reader data-table fallback** is provided both as a spoken
  summary and as an on-demand real `Table` (`CHT-002`).

**Accessible & motion-safe:**

- **Each card is a grouped Semantics node** with a coherent name — e.g.
  *"Balance, \$2,430, up 4% this week"* / *"Spending, \$1,180, Updated 2h ago,
  offline"* (`A11Y-014`). Interactive states keep their **Retry / CTA / Settings**
  reachable as their own nodes.
- **Pull-to-refresh** with a haptic tick updates live tiles **in place** (numbers
  cross-fade ≤ 300ms) and announces **"Updated"** via a `Semantics(liveRegion:true)`
  live region (`A11Y-019`, `MOT-005`).
- Targets ≥ 48dp (cards, Retry, nav items, refresh); text uses `Theme` text styles
  (no fixed heights, no sub-12 fonts) so it scales past 200%.
- **RTL-safe** throughout — `EdgeInsetsDirectional`, `AlignmentDirectional`,
  `TextAlign.start/end`; amounts are **end-aligned** so they mirror and
  column-align in any locale.
- **Motion** is transform/opacity only (skeleton pulse, value cross-fade, chart
  draw-in ≤ 400ms, banner reveal, grid re-flow), all collapsed to `Duration.zero`
  under `MediaQuery.disableAnimationsOf` (reduce motion → final frame instantly,
  `MOT-004`).

## Drop into an app

`DashboardScreen` is self-contained — with no arguments it runs a demo that
simulates a fetch, an offline toggle, a failing tile, and a denied permission.
Wire the callbacks to make it real:

```dart
import 'dashboard_screen.dart';

DashboardScreen(
  // Drill into a metric's detail (one tap per card — CRD-001).
  onOpenMetric: (id) => context.go('/metric/$id'),
  // Real refresh — return when the new data is ready; tiles update in place.
  onRefresh: () => repository.reloadDashboard(),
  // Deep-link to OS settings for a permission-denied tile.
  onOpenSettings: () => AppSettings.openAppSettings(),
  // Start in the offline treatment (e.g. from connectivity_plus).
  initialOffline: connectivity.isOffline,
);
```

Notes:

- **Try the states** in the demo: the **cloud** button in the app bar toggles the
  global offline banner; the *Open tasks* tile shows the inline **Retry** (tap it
  to watch that tile — and only that tile — reload); the *Active now* tile starts
  as a **skeleton** and resolves on its own; *New customers* is **empty**; *Steps*
  is **permission-denied**; pull down to **refresh** and hear "Updated".
- **Wiring per-tile data:** each `_MetricCard` takes an `initialState`, a
  `baseValue`, an optional `trend`, and state-specific copy (`cachedNote`,
  `emptyMessage` + `emptyCta`, `permissionMessage`). In production, drive
  `initialState` from that tile's own async result — a fetch failure flips **one**
  tile to `error`, not the screen.
- **Colors** resolve through `DashColors.of(context)` off `Theme.brightness`. In
  production, promote `dashboard_tokens.dart` onto a `ThemeExtension<T>` (see
  `frameworks/flutter/tokens.md`) and read via `Theme.of(context)`.
- **Localization & currency:** copy lives in the private `_Strings` class as a
  placeholder — route it through your i18n layer (whole messages, no
  concatenation). Numbers follow `Localizations.localeOf(context)` via `intl`.
- The demo-only `_toggleOffline` / `SnackBar` fallbacks should be removed in
  production — connectivity and navigation come from the platform/router.

## Validate

```bash
python3 quality-checks/validators/run_all.py examples/dashboard/flutter
# → Readiness score: 100/100 — PASS — clean
```
