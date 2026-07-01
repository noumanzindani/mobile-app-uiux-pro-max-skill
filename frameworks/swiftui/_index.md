# SwiftUI Framework Pack

**Purpose:** Map the skill's semantic design system to idiomatic SwiftUI on Apple platforms (iOS 26 "Liquid Glass" era). This `_index.md` is the router for the pack — read the one sub-file your task needs. Rules are *referenced by ID* (e.g. `A11Y-*`, `STATE-*`, `LST-*`, `BSH-*`) and never restated here; the rule corpus lives in `rules/`.

> Volatile-fact baseline (date-stamp per §11.2): Xcode 26 / Swift 6, iOS 26 SDK. **Liquid Glass** is the system material (translucent, reflective, refractive); tab bars and toolbars shrink/condense on scroll; controls render **concentric** with the device/display corner radius; **SF Symbols 7** adds Draw + Magic Replace animations and scales with Dynamic Type. `.presentationDetents` is iOS 16+; `ContentUnavailableView` is iOS 17+; the newer glass material APIs are iOS 26+. Re-verify on the quarterly standards refresh.

## Table of contents
- [When to reach for SwiftUI](#when-to-reach-for-swiftui)
- [Capability summary](#capability-summary)
- [Adaptive vs single-platform](#adaptive-vs-single-platform-decision)
- [Sub-file map](#sub-file-map)
- [Non-negotiables in this pack](#non-negotiables-in-this-pack)

## When to reach for SwiftUI
Apple's declarative UI framework rendering **OS-native** controls — so platform correctness (HIG, Liquid Glass, Dynamic Type, VoiceOver) is largely *inherited*, not authored, as long as you use system components and semantic colors rather than hardcoding. Strong when: the product is iOS / iPadOS / macOS / watchOS / visionOS-only and must feel indistinguishable from a stock Apple app, adopt new OS looks for free, and get accessibility + dark mode by construction. It is **Apple-only** — there is no Android target here, so cross-platform briefs route to Flutter or React Native instead (see `frameworks/_index.md`).

## Capability summary
| Concern | Idiomatic SwiftUI primitive | Rules |
|---|---|---|
| Tokens / theming | Asset-catalog **semantic `Color` sets** (Any/Dark appearances) + custom `EnvironmentValues` / `ViewModifier` for spacing/radius/motion; read via `@Environment` | `COL-*`, `DRK-*`, `SHP-*`, `SPC-*` |
| Safe area | **Automatic** safe area; opt into it with `.safeAreaInset(edge:)`, opt out deliberately with `.ignoresSafeArea()` | `A11Y-*`, `BSH-*`, `GES-*` |
| Buttons | `Button` + `ButtonStyle` / `.buttonStyle(.borderedProminent)` (≥44pt targets) | `BTN-*` |
| Lists | `List` / `ForEach` and `LazyVStack` in `ScrollView` — **lazily materialized (virtualized)** | `LST-*`, `PERF-*` |
| Sheets | `.sheet` + **`.presentationDetents([.medium, .large])`** + `.presentationDragIndicator` | `BSH-*` |
| Navigation | `NavigationStack` (path-driven) + `TabView` (≤5 tabs; condenses on scroll on iOS 26) | `NAV-*`, `GRD-*` |
| Dark mode | Automatic via semantic colors; branch on `@Environment(\.colorScheme)` only when needed | `DRK-*` |
| A11y | `.accessibilityLabel/Value/Hint`, `.accessibilityElement`, traits; Dynamic Type via `.font(.body)` text styles | `A11Y-*`, `TYP-*` |
| Motion | `withAnimation`, named springs (`.smooth` / `.snappy` / `.bouncy`), `matchedGeometryEffect`, `PhaseAnimator` | `MOT-*`, `MIC-*` |
| Adaptive | Apple-only: `@Environment(\.horizontalSizeClass)`, `NavigationSplitView`, `ViewThatFits` | `GRD-*`, `PLAT-*` |

## Adaptive vs single-platform decision
SwiftUI is single-**vendor** (Apple) but multi-**form-factor**. Decide the axis before generating (Pre-Generation Protocol §6, `PLAT-*`, `GRD-*`):

- **iPhone-first (compact) — default.** `NavigationStack` + `TabView`; single column; sheets with `.medium`/`.large` detents. Target ≥44pt, respect the ~34pt home-indicator inset via automatic safe area.
- **iPad / Mac / size-class-adaptive.** Promote to `NavigationSplitView` (list-detail) when `horizontalSizeClass == .regular`; use `ViewThatFits` and size-class branches instead of hardcoded widths. Sheets can become popovers on regular width. See `adaptive.md`.
- **Liquid-Glass surfaces (iOS 26).** Prefer system materials so controls stay concentric with the device corners and glass reacts to scroll automatically; do not fake translucency with opacity literals. See `adaptive.md`.

Rule of thumb: divergence is largest for **navigation container, sheet-vs-popover, and multi-column layout** — branch those on size class first; share everything else.

## Sub-file map
| Task | Read |
|---|---|
| Consume DTCG tokens / build the Color asset catalog + Environment token layer | `tokens.md` |
| Build button / list / sheet / nav / safe-area / a11y / animation | `components.md` |
| Implement the 7 UI states | `states.md` |
| Adapt across size classes / iPad / Liquid Glass | `adaptive.md` |
| Copy-paste stubs | `snippets/{button,list,sheet,safe-area,theme}.md` |

## Non-negotiables in this pack
1. **Lists virtualize** — `List`/`ForEach` or `LazyVStack`, never a plain `VStack` of N rows in a `ScrollView` (`LST-*`, `PERF-*`).
2. **Safe area is primitive-driven** — rely on automatic safe area + `.safeAreaInset`; reach for `.ignoresSafeArea` only for full-bleed backgrounds, never to hardcode insets (`A11Y-*`, `GES-*`).
3. **Tokens, not literals** — every color resolves through a semantic `Color` asset; every spacing/radius/spring resolves through an `@Environment` token, never a magic number (`COL-*`, `SPC-*`, `SHP-*`).
4. **Sheets use detents** — `.presentationDetents(...)` + drag indicator; never a custom full-screen cover masquerading as a sheet (`BSH-*`).
5. **Targets ≥44pt** — wrap small glyphs in a `Button` with `.frame(minWidth: 44, minHeight: 44)` or a `.contentShape`; SF Symbols scale with Dynamic Type (`BTN-*`, `ICN-*`, `A11Y-*`).
