# Jetpack Compose — Adaptive & Responsive

**Purpose:** Compose is Android-only, but must adapt across **window size classes** (phone ↔ foldable ↔ tablet ↔ desktop windowing) that can change at runtime. This file covers size-class routing, nav bar↔rail, two-pane list-detail, foldable reactivity, and font scaling. Rules referenced, not restated: `GRD-*`, `PLAT-*`, `A11Y-*`, `TYP-*`, `NAV-*`, `BSH-*`.

## Table of contents
- [Window size classes, not device checks](#window-size-classes-not-device-checks)
- [Nav: bar ↔ rail](#nav-bar--rail)
- [List-detail: ListDetailPaneScaffold](#list-detail-listdetailpanescaffold)
- [Sheet ↔ inline pane](#sheet--inline-pane)
- [Foldables change size class at runtime](#foldables-change-size-class-at-runtime)
- [Font scaling is the other axis](#font-scaling-is-the-other-axis)

## Window size classes, not device checks
Branch on `WindowSizeClass`, never on a hardcoded dp or "is tablet" flag (`GRD-*`, `PLAT-*`). The M3 breakpoints:

| Width class | Range | Typical | Layout |
|---|---|---|---|
| Compact | `< 600dp` | phone portrait | single column, `NavigationBar`, bottom sheets |
| Medium | `600–839dp` | foldable open, small tablet, phone landscape | `NavigationRail`, roomier grids |
| Expanded | `≥ 840dp` | tablet, desktop window | two-pane list-detail, `NavigationRail`/`PermanentDrawer` |

```kotlin
val windowSize = currentWindowAdaptiveInfo().windowSizeClass
val expanded = windowSize.isWidthAtLeastBreakpoint(WIDTH_DP_EXPANDED_LOWER_BOUND) // ≥840dp
```

## Nav: bar ↔ rail
Compact uses `NavigationBar` (bottom); medium/expanded promote to `NavigationRail` (side) so the primary thumb zone isn't wasted on wide screens (`NAV-*`, `GRD-*`). `NavigationSuiteScaffold` picks the right container from the size class automatically:

```kotlin
NavigationSuiteScaffold(
    navigationSuiteItems = { destinations.forEach { item(selected = …, onClick = …, icon = …, label = …) } }
) { AppNavHost() }   // NavigationBar on compact, NavigationRail/drawer on wider (GRD-*)
```

## List-detail: ListDetailPaneScaffold
On expanded width, show list + detail side by side; on compact, the same declaration collapses to a single pane with back navigation — the size-class analog of the `GRD-*` "≥840dp two-pane" rule:

```kotlin
val navigator = rememberListDetailPaneScaffoldNavigator<Long>()
NavigableListDetailPaneScaffold(
    navigator = navigator,
    listPane = { ItemList(onSelect = { navigator.navigateTo(ListDetailPaneScaffoldRole.Detail, it) }) },
    detailPane = {
        val id = navigator.currentDestination?.contentKey
        if (id != null) DetailPane(id) else EmptyDetail()   // empty detail (STATE-*)
    }
)
```

## Sheet ↔ inline pane
A `ModalBottomSheet` that works on a phone should become an **inline pane or side sheet** on expanded width, not a tiny sheet on a huge screen (`BSH-*`, `GRD-*`). Keep the same content composable; branch only the container on the size class.

## Foldables change size class at runtime
Unfolding a device switches compact→expanded **without** an Activity recreation, so read the size class **reactively** from `currentWindowAdaptiveInfo()` inside composition (it recomposes on change) — never cache it or read it once in `onCreate` (`GRD-*`, `PLAT-*`). Also honor hinge/posture via `WindowInfoTracker`/`FoldingFeature` for two-pane layouts that should avoid the fold.

## Font scaling is the other axis
Responsive is not only width — Android font size + display size settings scale `sp` text substantially. Because layouts use `MaterialTheme.typography` roles and token spacing, they should reflow rather than clip (`TYP-*`, `A11Y-*`). Test at the largest font scale; prefer `FlowRow`/wrapping and intrinsic sizing over fixed-height rows so large type wraps instead of truncating.

> Volatile-fact note (date-stamp per §11.2): the adaptive scaffolds (`NavigableListDetailPaneScaffold`, `NavigationSuiteScaffold`, `currentWindowAdaptiveInfo`) live in `androidx.compose.material3.adaptive` / `material3-adaptive-navigation-suite`; APIs graduated recently — confirm the artifact versions in the BOM on refresh.
