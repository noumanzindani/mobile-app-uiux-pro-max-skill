# Jetpack Compose — Components

**Purpose:** The idiomatic Compose mapping for the core interactive primitives — button, list, sheet, navigation, insets, accessibility, and animation — each bound to tokens and rule IDs. Copy-paste stubs live in `snippets/`. Rules referenced, not restated: `BTN-*`, `LST-*`, `BSH-*`, `NAV-*`, `A11Y-*`, `MOT-*`, `MIC-*`, `PERF-*`.

## Table of contents
- [Buttons — Button + interactionSource](#buttons--button--interactionsource)
- [Lists — LazyColumn (virtualized)](#lists--lazycolumn-virtualized)
- [Sheets — ModalBottomSheet](#sheets--modalbottomsheet)
- [Navigation — NavHost + NavigationBar](#navigation--navhost--navigationbar)
- [Insets & safe drawing](#insets--safe-drawing)
- [Accessibility](#accessibility)
- [Animation — animate*AsState, transitions, MotionScheme](#animation--animateasstate-transitions-motionscheme)

## Buttons — Button + interactionSource
Use M3 `Button` (filled = primary), `FilledTonalButton`, `OutlinedButton`, `TextButton` — they already meet the 48dp target via `minimumInteractiveComponentSize()` and expose `enabled` for the disabled state (`BTN-*`, `A11Y-*`, `STATE-*`). One primary per view (`BTN-*`). Drive the press micro-interaction (scale + haptic) from an `interactionSource` + `MotionScheme` spring (`MIC-*`, `MOT-*`). Loading is an explicit content swap. Full stub: `snippets/button.md`.

Key points:
- Prefer the built-in components' shapes/colors from `MaterialTheme`; don't hand-roll a `Box` button (loses semantics + target size).
- Wrap a bare icon action in `IconButton` (48dp) or `Modifier.minimumInteractiveComponentSize()` — never a 24dp `Icon` clickable (`ICN-*`, `A11Y-*`).
- Destructive: tint with `MaterialTheme.colorScheme.error` **and** confirm via dialog; color is not the only signal (`A11Y-*`, `DLG-*`).

## Lists — LazyColumn (virtualized)
`LazyColumn` / `LazyRow` / `LazyVerticalGrid` compose only visible items — this **is** the virtualization `LST-*` / `PERF-*` require. Never put N items in a `Column` with `verticalScroll`. Always pass a stable `key = { it.id }` so recomposition and item animations are correct and cheap. Loading shows a skeleton with `Modifier.placeholder`/shimmer; pull-to-refresh uses the now-stable `PullToRefreshBox` (`LST-*`, `STATE-*`, `OFF-*`). Full stub: `snippets/list.md`.

```kotlin
LazyColumn(
    contentPadding = padding,                              // insets from Scaffold (A11Y-*)
    verticalArrangement = Arrangement.spacedBy(MaterialTheme.spacing.s2)  // token gap (SPC-*)
) {
    items(txns, key = { it.id }) { txn -> TxnRow(txn) }   // stable key (LST-*, PERF-*)
}
```

## Sheets — ModalBottomSheet
Modal pickers/detail use `ModalBottomSheet` with `rememberModalBottomSheetState`, which snaps to partial/expanded values (the M3 analog of detents) and applies the navigation-bar inset so content clears the gesture bar (`BSH-*`, `A11Y-*`). Full stub: `snippets/sheet.md`.

```kotlin
val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = false)
if (showFilters) {
    ModalBottomSheet(onDismissRequest = { showFilters = false }, sheetState = sheetState) {
        FiltersContent()                                   // drag handle + insets are built in (BSH-*)
    }
}
```
On expanded windows, prefer an inline pane over a sheet — see `adaptive.md`.

## Navigation — NavHost + NavigationBar
Navigation-Compose (`NavHost` + typed routes) drives back-stack and deep links; **predictive back** works when you don't intercept the system back (`NAV-*`, `GES-*`). `NavigationBar` holds ≤5 destinations (`NAV-*`); promote to `NavigationRail` ≥600dp (`GRD-*`, `adaptive.md`).

```kotlin
NavigationBar {                                            // ≤5 tabs (NAV-*)
    destinations.forEach { d ->
        NavigationBarItem(
            selected = current == d.route,
            onClick = { nav.navigate(d.route) },
            icon = { Icon(d.icon, contentDescription = null) },  // label below provides the a11y name
            label = { Text(d.label) }
        )
    }
}
```

## Insets & safe drawing
Call `enableEdgeToEdge()` in the Activity, then let `Scaffold` apply `WindowInsets.safeDrawing` as `contentPadding` — content clears status bar, nav/gesture bar, and the IME (keyboard) without hardcoded heights (`A11Y-*`, `GES-*`). For the keyboard specifically, use `Modifier.imePadding()` / `WindowInsets.ime`. Full stub: `snippets/safe-area.md`.

```kotlin
Scaffold(bottomBar = { NavigationBar { … } }) { padding ->
    LazyColumn(contentPadding = padding) { … }            // insets applied, not hardcoded (A11Y-*)
}
```

## Accessibility
- **contentDescription** on every meaningful non-text element via `Modifier.semantics { contentDescription = … }`, or the component's `contentDescription` param; set decorative icons to `null` (`A11Y-*`).
- **State + role**: `Modifier.semantics { stateDescription = "Selected"; role = Role.Switch }` so TalkBack announces state, not just label (`A11Y-*`).
- **Merge / clear**: `Modifier.semantics(mergeDescendants = true)` to read a row as one node; `clearAndSetSemantics` to override noisy children (`A11Y-*`).
- **Font scaling**: use `MaterialTheme.typography` roles (`sp` scales with the user's font size); never lock text in fixed-height boxes (`TYP-*`, `A11Y-*`).
- **Non-color cues**: pair color-coded status with an icon or text (`A11Y-*`, `CHT-*`).

## Animation — animate*AsState, transitions, MotionScheme
Prefer springs from the M3 **MotionScheme** so motion is consistent and Reduce Motion is honored centrally (`MOT-*`, `A11Y-*`):

```kotlin
val scale by animateFloatAsState(
    targetValue = if (pressed) 0.97f else 1f,
    animationSpec = MaterialTheme.motionScheme.fastSpatialSpec()   // spatial spring (MIC-*, MOT-*)
)
```
- `animate*AsState` for single-value transitions; `updateTransition` for coordinated multi-property changes.
- `AnimatedVisibility` for enter/exit; `AnimatedContent` for content swaps (e.g. state → state).
- M3 Expressive **shape morphing** for expressive press/selection feedback; keep it purposeful, not decorative (`MOT-*`, `MIC-*`).
- Respect Reduce Motion by shortening/disabling the spec at the token level (see `snippets/theme.md`).
