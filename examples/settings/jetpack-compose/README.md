# Settings — Jetpack Compose (Material 3 Expressive)

A real, compiling reference implementation of the [settings spec](../spec.md) for **Jetpack
Compose** on Android, using **Material 3 Expressive**. It is the flagship "find and change a
setting quickly, and trust I won't destroy anything by accident" screen: a **grouped, searchable**
preference list with **isolated, confirmed destructive actions**, a **reachable multi-step account
deletion**, a **light / dark / system** theme selector — accessible, RTL- and Dynamic-Type-safe,
responsive, and edge-to-edge.

## Files

| File | Role |
|---|---|
| [`SettingsTokens.kt`](SettingsTokens.kt) | Semantic token layer — the **only** file with raw values (`Color`, `Dp` spacing/size/radius, the **breakpoint** dp values, millis). Colors/typography/shape resolve through `MaterialExpressiveTheme`; spacing/size/radius/breakpoints are carried as `Space` / `Size` / `Radius` / `Breakpoints` token objects. Every role the list needs (`surface`/`surfaceContainer`, `outlineVariant` divider, `onSurface`/`onSurfaceVariant`, `primary`/`onPrimary` switch, `error`/`onError` destructive) maps onto an M3 `ColorScheme` slot, so no `CompositionLocal` is needed. `Space.rowInset` (16dp keyline) and `Space.group` (24dp) come straight from the spec token table. Every literal line is marked `// ux:ignore`. |
| [`SettingsScreen.kt`](SettingsScreen.kt) | The `SettingsScreen` composable + a stateless `SettingsScreenContent`, the sealed `SettingsState`, the `SettingItem` row model + `SettingsGroup` data, the responsive `BoxWithConstraints` routing, the row composables, the theme-picker `ModalBottomSheet`, the sign-out / delete-account `AlertDialog`s, `SettingsActivity` (edge-to-edge host), and one `@Preview` per state / layout. Consumes **only** tokens + `MaterialTheme` roles. |

## What it demonstrates

- **Grouped preference list with category headers** — **Account · Notifications · Privacy &
  Security · Appearance · About & Help** — each header exposed as a `heading()` so TalkBack can jump
  between groups (`SET-001`, `A11Y-017`). Each group is an inset `surfaceContainer` card with
  `outlineVariant` dividers inset to the 16dp `Space.rowInset` keyline.
- **Search across ALL settings** — an `OutlinedTextField` filters every group's items by label **and**
  keyword; a match-less query resolves to a **distinct zero-results Empty** ("No settings match
  …"), announced via a polite `liveRegion` (`SET-002`, `STATE-004`). The list itself is never empty.
- **Four row types**, each with correct semantics:
  - **Toggle** (`Switch`) — the whole row is `Modifier.toggleable(role = Role.Switch)` with
    `stateDescription` "On"/"Off" and a coherent `contentDescription`; the switch conveys state by
    **shape/position, not color** (`A11Y-006`, `A11Y-012`).
  - **Disclosure** — a `clickable` row with a trailing **auto-mirrored** chevron
    (`Icons.AutoMirrored.Filled.KeyboardArrowRight`) that announces it navigates.
  - **Value + chevron** — shows the current value and opens a **picker / bottom sheet** on tap
    (the theme selector); others push a sub-page (`PLAT-006`).
  - **Action** — a button-styled row with a **primary-tinted** label ("Send feedback").
- **Isolated destructive zone** at the **very bottom**, out of the accidental-tap arc: **Sign out**
  and **Delete account** in their own card with **error-colored** labels + icons, each behind an
  explicit `AlertDialog` (`SET-003`, `DLG-001`). **Sign out** is a single confirm; **Delete account**
  is a **multi-step** confirm ("Delete account?" → "This is permanent") so the store-policy deletion
  path is reachable and hard to trigger by accident (`SET-004`, `PROF-001`).
- **Light / dark / system theme selector** in a `ModalBottomSheet` with `Role.RadioButton`
  `selectable` rows and `stateDescription` (`DRK-001`). `SettingsTheme` takes an explicit `darkTheme`
  so the app can override the system value.
- **Responsive via `BoxWithConstraints` + the breakpoint tokens** (`GRD-003`):
  - **Compact `< 600dp`** → a **single scrolling list**; a disclosure/value row **pushes a sub-page**
    (a back arrow returns).
  - **Expanded `≥ 840dp`** → a **two-pane list-detail**: a category **rail** (leading) + the selected
    group's rows (detail), with the destructive zone riding the **Account** detail so it stays
    isolated. Search flattens both modes into one results list.
- **All 7 UI states via a sealed `SettingsState`** (`Ideal`, `Loading`, `Empty`, `Error`, `Offline`,
  `Success`, `PermissionDenied`), driven through `when` so coverage is auditable (`STATE-001`):
  - **Loading** → server-synced values fetch behind a **shape-matched skeleton**, not a screen
    spinner (`STATE-005`).
  - **Empty** → the search zero-results above.
  - **Error** → a toggle that fails to save **REVERTS** and shows "Couldn't save — try again" — **never
    a silent false success** (`STATE-007`); the demo wires `push_notifs` to fail so the revert path is
    exercised.
  - **Offline** → a **non-blocking banner** + **server-synced toggles disabled** (local prefs still
    work); an offline change is **queued with a reason** (`OFF-002`).
  - **Success** → a saved change is **confirmed inline** by a transient banner (the toggle reflects
    the **true** saved state) (`STATE-009`).
  - **PermissionDenied** → the **System notifications** row reflects the **true** OS permission
    ("Allowed"/"Blocked", not color-only) and **deep-links** to system notification settings via an
    `Intent` — it never re-prompts in-app (`PERM-003`, `NOTIF-002`).
- **Accessibility** — rows are `semantics(mergeDescendants = true)` single focus stops with role +
  label + value/state; headers are `heading()`s; the search field is labeled and its zero-results are
  announced; destructive dialogs are fully labeled with the destructive action placed per convention
  (`A11Y-004/005/006/012/017`).
- **RTL-safe** — logical `padding(start/end)` / `PaddingValues`, RTL-aware `Arrangement`/`Alignment`,
  and **auto-mirrored** chevrons + back arrow; no physical left/right anywhere (`L10N-001`).
- **Dynamic Type** — every text role comes from `MaterialTheme.typography` (scales to 200%); no fixed
  heights on text; long/localized labels wrap; rows grow via `heightIn(min = Size.rowMinHeight)`
  (`A11Y-010`, `L10N-003`).
- **Edge-to-edge** — `enableEdgeToEdge()` in `SettingsActivity` + `Modifier.windowInsetsPadding(
  WindowInsets.safeDrawing)` so content clears the system bars.
- **Motion** — only **opacity** animates (the offline + save-result banners fade `≤200ms`), each with
  a **reduce-motion** `snap()` fallback via `rememberReduceMotion()` (reads
  `Settings.Global.ANIMATOR_DURATION_SCALE`); destructive dialogs use the standard present/dismiss —
  no playful motion on a serious action (`MOT-004/005`).

> **Demo hooks (reference-only):** flip `SettingsUiState(syncing = true)` for the skeleton,
> `isOffline = true` for the banner + disabled server toggles, `notificationsAllowed = false` for the
> blocked-permission row, `query = "…"` for search / zero-results, and toggle `push_notifs` to see the
> failed-save **revert** (see the `@Preview`s).

## Validators

Passes the five `SettingsScreen.kt`-scoped rules audited by
[`quality-checks/validators/run_all.py`](../../../quality-checks/validators/run_all.py):
`token_lint`, `target_size_lint`, `dynamic_type_check`, `rtl_check`, `state_coverage` (plus the
repo-wide `contrast_check`) — **100/100**.

```bash
python3 quality-checks/validators/run_all.py "examples/settings/jetpack-compose"
```

## Compose BOM note

Pin dependency versions through the **Compose BOM** (verified against **`2025.x`**, which ships
`androidx.compose.material3` with the **Expressive** APIs — `MaterialExpressiveTheme`, `MotionScheme`,
the 10-step corner scale — targeting Android 16 / API 36). `ModalBottomSheet`, `AlertDialog`,
`Switch`, `RadioButton`, `HorizontalDivider` / `VerticalDivider`, and `LazyColumn` are in `material3` /
`foundation`, included in BOM 2025.x.

The row / nav glyphs (`Person`, `Notifications`, `Security`, `Palette`, `Info`, `Search`, `SearchOff`,
`Close`, `CloudOff`, `Check`, `Warning`, `Delete`, `HelpOutline`, `Language`, and the **auto-mirrored**
`KeyboardArrowRight`, `ArrowBack`, `Logout`, `OpenInNew`) come from **`material-icons-extended`** — add
that dependency, or swap in your own icon set.

```kotlin
dependencies {
    implementation(platform("androidx.compose:compose-bom:2025.06.00")) // use the current 2025.x BOM

    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended") // row / nav + auto-mirrored glyphs
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    debugImplementation("androidx.compose.ui:ui-tooling")

    implementation("androidx.activity:activity-compose:1.9.0+") // enableEdgeToEdge, setContent
}
```

## Responsiveness: `WindowSizeClass` vs `BoxWithConstraints`

This example reflows with **`BoxWithConstraints`** measured against the **breakpoint tokens**
(`Breakpoints.compact` = 600dp, `Breakpoints.expanded` = 840dp), which keeps the widget
**self-contained** — it adapts to whatever width it's given (a pane, a split-screen half, or the whole
window), reflows **live** on rotate / fold-unfold / split-screen, and needs no extra dependency. For
**app-level** chrome (routing `NavigationBar` ↔ `NavigationRail`, or a first-class two-pane
`ListDetailPaneScaffold` with predictive-back), promote to the official **window-size-class /
adaptive** artifacts and branch on `currentWindowAdaptiveInfo().windowSizeClass` — the **same** 600 /
840 dp values M3 uses:

```kotlin
dependencies {
    // WindowSizeClass + currentWindowAdaptiveInfo()
    implementation("androidx.compose.material3:material3-window-size-class")
    // ListDetailPaneScaffold (two-pane list-detail) + NavigationSuiteScaffold (bar ↔ rail)
    implementation("androidx.compose.material3.adaptive:adaptive-navigation")
    implementation("androidx.compose.material3.adaptive:adaptive-navigation-suite")
}
```

```kotlin
val widthClass = currentWindowAdaptiveInfo().windowSizeClass
val expanded = widthClass.isWidthAtLeastBreakpoint(WIDTH_DP_EXPANDED_LOWER_BOUND) // ≥ 840dp
```

> Material You dynamic color (Android 12+) can be layered on `SettingsTheme` by sourcing the
> `ColorScheme` from `dynamicLightColorScheme(context)` / `dynamicDarkColorScheme(context)` with the
> brand palette in `SettingsTokens.kt` as the fallback.
