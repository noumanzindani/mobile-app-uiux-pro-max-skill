# Flutter Framework Pack

**Purpose:** Map the skill's semantic design system to idiomatic Flutter (Material 3 + Cupertino). This `_index.md` is the router for the pack — read the one sub-file your task needs. Rules are *referenced by ID* (e.g. see `A11Y-*`, `STATE-*`, `LST-*`) and never restated here; the rule corpus lives in `rules/`.

> Volatile-fact baseline (date-stamp per §11.2): Flutter 3.24+ / Dart 3.5+, Material 3 default (`useMaterial3: true` is implied since 3.16), `go_router` 14.x. Re-verify on the quarterly standards refresh.

## Table of contents
- [When to reach for Flutter](#when-to-reach-for-flutter)
- [Capability summary](#capability-summary)
- [Adaptive vs single-platform](#adaptive-vs-single-platform-decision)
- [Sub-file map](#sub-file-map)
- [Non-negotiables in this pack](#non-negotiables-in-this-pack)

## When to reach for Flutter
Single Dart codebase rendering its **own** widgets via Skia/Impeller — it does not use OS-native controls, so platform correctness is *authored*, not inherited. Strong when: you want one team shipping iOS + Android (+ web/desktop) with pixel-identical, brand-forward UI and Material 3 as the design substrate. Weaker when the product must feel indistinguishable from a stock native app on both platforms simultaneously — then you owe explicit adaptive work (see `adaptive.md`).

## Capability summary
| Concern | Idiomatic Flutter primitive | Rules |
|---|---|---|
| Tokens / theming | `ThemeData` + `ThemeExtension<T>` for custom tokens; `ColorScheme.fromSeed` for M3 roles; read via `Theme.of(context)` | `COL-*`, `DRK-*`, `SHP-*` |
| Safe area | `SafeArea`; `MediaQuery.paddingOf(context)` / `MediaQuery.viewInsetsOf(context)` for keyboard | `A11Y-*`, `BSH-*` |
| Buttons | `FilledButton` / `.tonal` / `OutlinedButton` / `TextButton` (44pt/48dp targets) | `BTN-*` |
| Lists | `ListView.builder` / `SliverList` — **always virtualized** | `LST-*`, `PERF-*` |
| Sheets | `showModalBottomSheet` + `DraggableScrollableSheet` (detents) | `BSH-*` |
| Navigation | `Navigator` / `go_router` + `NavigationBar` (≤5 tabs) / `NavigationRail` ≥600dp | `NAV-*`, `GRD-*` |
| Dark mode | `ThemeMode.system` + `theme:` / `darkTheme:` on `MaterialApp` | `DRK-*` |
| A11y | `Semantics(label:, button:, …)`, `MergeSemantics`, `ExcludeSemantics` | `A11Y-*` |
| Motion | `AnimationController` + `Tween`; implicit `AnimatedFoo`; `Hero` | `MOT-*`, `MIC-*` |
| Adaptive | explicit Material vs Cupertino libraries; `.adaptive` ctors (`Switch.adaptive`, `Slider.adaptive`) | `PLAT-*` |

## Adaptive vs single-platform decision
Pick **one** paradigm before generating (Pre-Generation Protocol §6, `PLAT-*`):

- **Single-paradigm (Material everywhere)** — default. Brand-led apps where a consistent Material 3 look on both OSes is acceptable/desired. Use Material widgets throughout; still honor safe areas, targets, and a11y. Simplest, fewest branches.
- **Adaptive (feel-native-per-OS)** — when the brief says "feels native on iOS *and* Android." Switch the whole paradigm on `Theme.of(context).platform` (or `defaultTargetPlatform`): Cupertino nav/sheets/switches on iOS, Material on Android. Use `.adaptive` constructors for the cheap wins (`Switch.adaptive`, `Slider.adaptive`, `showAdaptiveDialog`, `CircularProgressIndicator.adaptive`). See `adaptive.md`.
- **Cupertino-only** — iOS-exclusive product: use the `cupertino` library end-to-end (`CupertinoApp`, `CupertinoNavigationBar`, `CupertinoSheetRoute`).

Rule of thumb: divergence is largest for **navigation, sheets, dialogs, switches, and back-gesture** — branch those first; share everything else.

## Sub-file map
| Task | Read |
|---|---|
| Consume DTCG tokens / build `ThemeData` | `tokens.md` |
| Build button / list / sheet / nav / a11y / animation | `components.md` |
| Implement the 7 UI states | `states.md` |
| Make it feel native per OS | `adaptive.md` |
| Copy-paste stubs | `snippets/{button,list,sheet,safe-area,theme}.md` |

## Non-negotiables in this pack
1. **Lists virtualize** — `ListView.builder`/`SliverList`, never a `Column` of N children (`LST-*`, `PERF-*`).
2. **Safe area is primitive-driven** — `SafeArea` + `MediaQuery`, never hardcoded insets (`A11Y-*`).
3. **Tokens, not literals** — every color/space/radius resolves through `Theme.of(context)` or a `ThemeExtension` (`COL-*`, `SPC-*`, `SHP-*`).
4. **Sheets use detents** — `DraggableScrollableSheet` snap sizes; respect the 34pt home-indicator inset (`BSH-*`).
5. **Targets ≥44pt/48dp** — wrap small glyphs in `IconButton`/`InkWell` sized to spec (`BTN-*`, `ICN-*`, `A11Y-*`).
