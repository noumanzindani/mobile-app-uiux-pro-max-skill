# Jetpack Compose Framework Pack

**Purpose:** Map the skill's semantic design system to idiomatic Jetpack Compose with **Material 3 Expressive** on Android 16. This `_index.md` is the router for the pack — read the one sub-file your task needs. Rules are *referenced by ID* (e.g. `A11Y-*`, `STATE-*`, `LST-*`, `BSH-*`) and never restated here; the rule corpus lives in `rules/`.

> Volatile-fact baseline (date-stamp per §11.2): Compose BOM 2025.x, `androidx.compose.material3` with the **Expressive** APIs (`MaterialExpressiveTheme`, `MotionScheme` spatial/effects springs, shape morphing, the 10-step corner scale), targeting Android 16 (API 36). `PullToRefreshBox` is stable; window size classes come from `androidx.compose.material3.adaptive` / `WindowSizeClass`; **Material You dynamic color** requires Android 12+ (`dynamicLightColorScheme`/`dynamicDarkColorScheme`). Re-verify on the quarterly standards refresh.

## Table of contents
- [When to reach for Compose](#when-to-reach-for-compose)
- [Capability summary](#capability-summary)
- [Adaptive vs single-form-factor](#adaptive-vs-single-form-factor-decision)
- [Sub-file map](#sub-file-map)
- [Non-negotiables in this pack](#non-negotiables-in-this-pack)

## When to reach for Compose
Android's declarative UI toolkit rendering **Material** components — so Material 3 correctness, Material You dynamic color, dark mode, and TalkBack are largely *inherited* when you use `MaterialTheme` roles + `Modifier.semantics` rather than hardcoding. Strong when: the product is Android-only (phone / foldable / tablet / Wear / TV) and should feel native, adopt Material You theming, and get edge-to-edge + predictive-back for free. It is **Android-only** — no iOS target here, so cross-platform briefs route to Flutter or React Native (see `frameworks/_index.md`).

## Capability summary
| Concern | Idiomatic Compose primitive | Rules |
|---|---|---|
| Tokens / theming | `MaterialExpressiveTheme(colorScheme, typography, shapes, motionScheme)` + **`CompositionLocal`** for custom tokens; Material You via `dynamicLightColorScheme(context)` | `COL-*`, `DRK-*`, `SHP-*`, `SPC-*` |
| Safe area | **`WindowInsets.safeDrawing`** + `enableEdgeToEdge()` + `Scaffold` (applies insets as `contentPadding`) | `A11Y-*`, `BSH-*`, `GES-*` |
| Buttons | `Button` / `FilledTonalButton` / `OutlinedButton` / `TextButton` (≥48dp targets) | `BTN-*` |
| Lists | **`LazyColumn` / `LazyRow` / `LazyVerticalGrid`** — virtualized by construction | `LST-*`, `PERF-*` |
| Sheets | `ModalBottomSheet` + `rememberModalBottomSheetState` (partial/expanded) | `BSH-*` |
| Navigation | Navigation-Compose (`NavHost`) + `NavigationBar` (≤5 tabs) / `NavigationRail` ≥600dp | `NAV-*`, `GRD-*` |
| Dark mode | `isSystemInDarkTheme()` selects the color scheme | `DRK-*` |
| A11y | `Modifier.semantics { contentDescription = … }`, `stateDescription`, `role`, merge/clear | `A11Y-*`, `TYP-*` |
| Motion | `animate*AsState`, `AnimatedVisibility`, `updateTransition`, `spring()` / `MotionScheme` tokens | `MOT-*`, `MIC-*` |
| Adaptive | `WindowSizeClass` (compact/medium/expanded) + `androidx…adaptive` scaffolds | `GRD-*`, `PLAT-*` |

## Adaptive vs single-form-factor decision
Compose is single-**vendor** (Android) but spans phone → foldable → tablet. Decide the axis before generating (Pre-Generation Protocol §6, `PLAT-*`, `GRD-*`):

- **Compact-first (phone) — default.** `NavHost` + `NavigationBar`; single column; `ModalBottomSheet` for pickers. Target ≥48dp; apply `WindowInsets.safeDrawing` so content clears status/nav bars and the IME.
- **Medium / expanded (foldable, tablet, desktop windowing).** Promote to `NavigationRail` (≥600dp) and a two-pane list-detail via `NavigableListDetailPaneScaffold` (≥840dp expanded). Drive it from `WindowSizeClass`, never hardcoded dp. See `adaptive.md`.
- **Material You dynamic color.** On Android 12+, source the color scheme from the wallpaper (`dynamicLightColorScheme`/`dynamicDarkColorScheme`) with a static brand fallback. See `tokens.md`.

Rule of thumb: divergence is largest for **nav container (bar↔rail), single-vs-two-pane, and sheet width** — branch those on `WindowSizeClass` first; share everything else. Foldables can change size class at runtime, so read it reactively.

## Sub-file map
| Task | Read |
|---|---|
| Consume DTCG tokens / build `MaterialExpressiveTheme` + CompositionLocals | `tokens.md` |
| Build button / list / sheet / nav / insets / a11y / animation | `components.md` |
| Implement the 7 UI states | `states.md` |
| Adapt across window size classes / foldables | `adaptive.md` |
| Copy-paste stubs | `snippets/{button,list,sheet,safe-area,theme}.md` |

## Non-negotiables in this pack
1. **Lists virtualize** — `LazyColumn`/`LazyRow`/`LazyVerticalGrid` with stable `key`s, never a `Column` inside `verticalScroll` for N items (`LST-*`, `PERF-*`).
2. **Insets are primitive-driven** — `enableEdgeToEdge()` + `WindowInsets.safeDrawing` (via `Scaffold`), never hardcoded status/nav-bar heights (`A11Y-*`, `GES-*`).
3. **Tokens, not literals** — every color/shape resolves through `MaterialTheme.colorScheme`/`.shapes`; every spacing/motion through a `CompositionLocal`, never a magic dp (`COL-*`, `SPC-*`, `SHP-*`).
4. **Sheets use breakpoints/detents** — `ModalBottomSheet` with partial + expanded values; respect the navigation-bar inset (`BSH-*`).
5. **Targets ≥48dp** — wrap small icons in `IconButton` or `Modifier.minimumInteractiveComponentSize()`; never a bare 24dp `Icon` as the tap target (`BTN-*`, `ICN-*`, `A11Y-*`).
