# Dashboard — Jetpack Compose (Material 3 Expressive)

A real, compiling reference implementation of the [dashboard spec](../spec.md) for **Jetpack
Compose** on Android, using **Material 3 Expressive**. It is the flagship "show me the state of my
world at a glance, and let me jump to what needs attention" screen: a **responsive** grid of
**self-contained metric cards** + a small **bar chart** + an **activity list**, where **every widget
owns its own state** — accessible, RTL- and Dynamic-Type-safe, and edge-to-edge.

## Files

| File | Role |
|---|---|
| [`DashboardTokens.kt`](DashboardTokens.kt) | Semantic token layer — the **only** file with raw values (`Color`, `Dp` spacing/size/radius, millis, the **breakpoint** dp values, and the **chart-series** colors). Colors/typography/shape resolve through `MaterialExpressiveTheme`; spacing/size/radius/breakpoints are carried as `Space` / `Size` / `Radius` / `Breakpoint` token objects; the `onSurfaceStrong`, `status.success` / `status.error`, and `chart.1…n` roles ride a `CompositionLocal` (`LocalDashboardColors`) read as `MaterialTheme.dashboardColors`. The `value` / `amount` text styles enable **tabular figures** (`fontFeatureSettings = "tnum"`). Every literal line is marked `// ux:ignore`. |
| [`DashboardScreen.kt`](DashboardScreen.kt) | The `DashboardScreen` composable + a stateless `DashboardScreenContent`, the per-widget `WidgetState` model, the `MetricTile` / `ChartData` / `ActivityFeed` data, the responsive `BoxWithConstraints` reflow, the Canvas bar chart + data-table fallback, `DashboardActivity` (edge-to-edge host), and one `@Preview` per width class / state. Consumes **only** tokens + `MaterialTheme` roles. |

## What it demonstrates

- **Responsive reflow across the M3 window size classes** — `BoxWithConstraints` reads the available
  width and branches on the **breakpoint tokens** (`Breakpoint.compact` = 600dp,
  `Breakpoint.expanded` = 840dp) so it re-flows **live** on rotate / fold-unfold / split-screen
  (`GRD-008`), never on a hardcoded device check:
  - **Compact `< 600dp`** → **1 column** + bottom **`NavigationBar`** (`NAV-001`),
  - **Medium `600–839dp`** → **2 columns** + **`NavigationRail`** (`NAV-003`),
  - **Expanded `≥ 840dp`** → **3 columns** (4 at `≥ 1240dp`) with the **chart spanning 2**, laid out
    in a `LazyVerticalGrid`, + rail (`GRD-003`).
  - A **capped max content measure** (`Size.maxContentWidth`) keeps tiles from stretching
    edge-to-edge on very wide screens (`GRD-005`, `SPC-018`).
- **Per-widget state — no single global spinner (`STATE-014`).** Each tile carries its own sealed
  `WidgetState` (`Loading`, `Empty`, `Error`, `Offline`, `Success`, `PermissionDenied`, `Ideal`) and
  renders it inline through a `when`:
  - **Loading** → a **shape-matched skeleton** (a value block + a trend line; the chart and the list
    get their own skeletons), not one screen-wide spinner (`STATE-005`).
  - **Error** → a **scoped inline** message + **Retry** that cycles only that tile; every other tile
    stays live (`STATE-007`).
  - **Empty** → a first-use, positively-framed message + a CTA, never a dead end (`STATE-002/003`).
  - **Offline** → the tile shows its **cached value with a "stale / Updated 2h ago" indicator**
    (`STATE-011`), under a **global, non-blocking offline banner**; pull-to-refresh is **disabled
    with a reason** (`OFF-004`).
  - **PermissionDenied** → a scoped explain + **Settings** link + a graceful fallback line; the rest
    of the dashboard is unaffected (`STATE-010`, `PERM-003`).
- **Honest, accessible numbers.** Every value uses **tabular figures** (`fontFeatureSettings =
  "tnum"`) and **locale formatting** via `NumberFormat` (`getCurrencyInstance` / `getIntegerInstance`)
  so columns align and never jitter (`TYP-006`, `L10N-005`).
- **Trend by icon + sign + text, never color-only.** An up/down/flat **arrow** + a `+ / −` **sign** +
  the change **text**, tinted with `status.success` / `status.error` as a *fourth*, redundant cue
  (`A11Y-012`, `CHT-001`).
- **A Canvas bar chart with a screen-reader data-table fallback.** The bars are drawn with
  `Canvas` from the semantic **chart-series tokens**, each bar is **labeled**, and a real, focusable
  **data table** (`day, amount` rows) sits below it so the numbers are never trapped in pixels
  (`CHT-001`, `CHT-002`).
- **Grouped cards.** Each metric card is `Modifier.semantics(mergeDescendants = true)` with a
  **coherent accessible name** that folds in the value + trend ("Balance, $2,430, up 4% this week")
  so it's one focus stop and the trend isn't arrow-only (`A11Y-014`, `CRD-001`).
- **Pull-to-refresh + an announced result.** `PullToRefreshBox` drives the refresh; the **"Updated
  just now"** result is exposed through a **polite `liveRegion`** (`A11Y-019`).
- **RTL-safe:** logical `padding(start/end)` / `PaddingValues(start, end)`, RTL-aware
  `Arrangement`/`Alignment`, and **amounts end-aligned** (`TextAlign.End`) so number columns mirror
  correctly — no physical left/right anywhere (`L10N-001`).
- **Dynamic Type:** every text role comes from `MaterialTheme.typography` (scales to 200%); no fixed
  heights on text; the grid and tiles reflow (`A11Y-010`).
- **Edge-to-edge:** `enableEdgeToEdge()` in `DashboardActivity` + `Modifier.windowInsetsPadding(
  WindowInsets.safeDrawing)` so content clears the system bars.
- **Motion:** only **opacity + offset/height** animate — the offline-banner fade, the "Updated"
  reveal, the chart draw-in (`≤400ms`), and the skeleton pulse — each with a **reduce-motion**
  `snap()` fallback via `rememberReduceMotion()` (reads `Settings.Global.ANIMATOR_DURATION_SCALE`).

> **Demo hooks (reference-only):** the seven metric tiles are seeded across all seven states so the
> whole matrix renders at once. Toggle `DashboardUiState(isOffline = true)` for the cached/stale +
> banner path, and `justUpdated = true` for the announced-refresh path (see the `@Preview`s).

## Validators

Passes the five `DashboardScreen.kt`-scoped rules audited by
[`quality-checks/validators/run_all.py`](../../../quality-checks/validators/run_all.py):
`token_lint`, `target_size_lint`, `dynamic_type_check`, `rtl_check`, `state_coverage` (plus the
repo-wide `contrast_check`) — **100/100**.

```bash
python3 quality-checks/validators/run_all.py "examples/dashboard/jetpack-compose"
```

## Compose BOM note

Pin dependency versions through the **Compose BOM** (verified against **`2025.x`**, which ships
`androidx.compose.material3` with the **Expressive** APIs — `MaterialExpressiveTheme`,
`MotionScheme`, the 10-step corner scale, and `surfaceContainerHigh(est)` — targeting Android 16 /
API 36). `PullToRefreshBox` and `LazyVerticalGrid` item spans are in `material3` / `foundation`,
included in BOM 2025.x.

The metric / nav / trend glyphs (`AccountBalanceWallet`, `ShoppingCart`, `Insights`, `Groups`,
`DirectionsWalk`, `ReceiptLong`, `Refresh`, `CloudOff`, `ErrorOutline`, `ArrowUpward`,
`ArrowDownward`, `TrendingFlat`, `Inbox`, `GridView`, `Notifications`, `Person`, `AccountCircle`,
`Lock`) come from **`material-icons-extended`** — add that dependency, or swap in your own icon set.

```kotlin
dependencies {
    implementation(platform("androidx.compose:compose-bom:2025.06.00")) // use the current 2025.x BOM

    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended") // metric / trend / nav glyphs
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    debugImplementation("androidx.compose.ui:ui-tooling")

    implementation("androidx.activity:activity-compose:1.9.0+") // enableEdgeToEdge, setContent
}
```

## Responsiveness: `WindowSizeClass` vs `BoxWithConstraints`

This example reflows with **`BoxWithConstraints`** measured against the **breakpoint tokens**, which
keeps the widget **self-contained** (it adapts to whatever width it's given — a pane, a split-screen
half, or the whole window) and needs no extra dependency. For **app-level** chrome (routing the
`NavigationBar` ↔ `NavigationRail` ↔ `PermanentDrawer`, or a two-pane `ListDetailPaneScaffold`),
promote to the official **window-size-class / adaptive** artifacts and branch on
`currentWindowAdaptiveInfo().windowSizeClass` — the **same** `Breakpoint.compact` (600dp) /
`Breakpoint.expanded` (840dp) values M3 uses:

```kotlin
dependencies {
    // WindowSizeClass + currentWindowAdaptiveInfo()
    implementation("androidx.compose.material3:material3-window-size-class")
    // NavigationSuiteScaffold (bar ↔ rail ↔ drawer) + ListDetailPaneScaffold (two-pane)
    implementation("androidx.compose.material3.adaptive:adaptive-navigation-suite")
    implementation("androidx.compose.material3.adaptive:adaptive-navigation")
}
```

```kotlin
val widthClass = currentWindowAdaptiveInfo().windowSizeClass
val expanded = widthClass.isWidthAtLeastBreakpoint(WIDTH_DP_EXPANDED_LOWER_BOUND) // ≥ 840dp
```

> Material You dynamic color (Android 12+) can be layered on `DashboardTheme` by sourcing the
> `ColorScheme` from `dynamicLightColorScheme(context)` / `dynamicDarkColorScheme(context)` with the
> brand palette in `DashboardTokens.kt` as the fallback. The `DashboardColors` strong / status /
> chart roles stay on `LocalDashboardColors` so they swap with the theme regardless of the source.
