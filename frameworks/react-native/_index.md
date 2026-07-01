# React Native Framework Pack

**Purpose:** Map the skill's semantic design system to idiomatic React Native (+ Expo). RN ships **no built-in token/theme system** and renders native platform views, so both theming and platform correctness are authored. This `_index.md` routes the pack; rules are *referenced by ID* (e.g. see `A11Y-*`, `STATE-*`, `LST-*`) — never restated. Corpus lives in `rules/`.

> Volatile-fact baseline (date-stamp per §11.2): RN 0.75+ / React 18, Expo SDK 51+, Reanimated 3.x, react-native-gesture-handler 2.x, react-native-safe-area-context 4.x, @gorhom/bottom-sheet 5.x, React Navigation 6.x / Expo Router 3.x, FlashList 1.x. Re-verify on the quarterly standards refresh.

## Table of contents
- [When to reach for React Native](#when-to-reach-for-react-native)
- [Capability summary](#capability-summary)
- [Adaptive vs single-platform](#adaptive-vs-single-platform-decision)
- [Sub-file map](#sub-file-map)
- [Non-negotiables in this pack](#non-negotiables-in-this-pack)

## When to reach for React Native
JavaScript/TypeScript over **real native views** (`UIView`/`android.view`). Strong when: a React/web team wants to ship iOS + Android, you want native controls' feel by default, or you're on Expo for fast managed builds + OTA updates. Because there's no theme layer, you must **choose a styling system on day one** (below) or values will get hardcoded — exactly the failure this skill exists to prevent.

## Capability summary
| Concern | Idiomatic RN primitive | Rules |
|---|---|---|
| Tokens / theming | **No built-in** → React Context + one of **Restyle** / **NativeWind** / **Unistyles** | `COL-*`, `DRK-*`, `SPC-*` |
| Safe area | `react-native-safe-area-context` → `SafeAreaView`, `useSafeAreaInsets()` | `A11Y-*`, `BSH-*` |
| Buttons | `Pressable` (build your own; `Button` is too limited) | `BTN-*` |
| Lists | `FlatList` / **`FlashList`** (Shopify) — **always virtualized** | `LST-*`, `PERF-*` |
| Sheets | `@gorhom/bottom-sheet` (`snapPoints` = detents) | `BSH-*` |
| Navigation | React Navigation / **Expo Router** + bottom tabs (≤5) | `NAV-*`, `GRD-*` |
| Dark mode | `useColorScheme()` / `Appearance` → pick token set | `DRK-*` |
| A11y | `accessibilityLabel` / `accessibilityRole` / `accessibilityState` | `A11Y-*` |
| Motion | **Reanimated 3** (worklets, `useSharedValue`) + Gesture Handler | `MOT-*`, `MIC-*` |
| Adaptive | manual `Platform.select` / `Platform.OS`; `Component.ios.tsx` / `.android.tsx` | `PLAT-*` |

## Adaptive vs single-platform decision
Pick **one** paradigm before generating (Pre-Generation Protocol §6, `PLAT-*`):

- **Single-paradigm (shared look)** — default. One component tree, tokenized; accept a consistent (often near-Material) look on both OSes. RN native controls already differ subtly per OS for free.
- **Adaptive (feel-native-per-OS)** — RN has **no `.adaptive` widgets**; you branch manually with `Platform.select`, `Platform.OS`, or platform-specific files (`Sheet.ios.tsx` / `Sheet.android.tsx`, resolved automatically by Metro). Branch the divergent surfaces: header/tab-bar chrome, sheets, action menus (`ActionSheetIOS` vs Material menu), switches, back behavior.
- **Expo Router note** — file-based routing gives native stack/tab headers that already adopt platform styling; lean on it before hand-rolling chrome.

Rule of thumb: divergence is largest for **navigation chrome, sheets, action menus, switches, and haptics** — branch those; share tokenized content.

## Sub-file map
| Task | Read |
|---|---|
| Set up tokens / theme provider | `tokens.md` |
| Build button / list / sheet / nav / a11y / animation | `components.md` |
| Implement the 7 UI states | `states.md` |
| Make it feel native per OS | `adaptive.md` |
| Copy-paste stubs | `snippets/{button,list,sheet,safe-area,theme}.md` |

## Non-negotiables in this pack
1. **Lists virtualize** — `FlatList`/`FlashList`, never `.map()` inside a `ScrollView` (`LST-*`, `PERF-*`).
2. **Safe area via the library** — `useSafeAreaInsets()` / `SafeAreaView` from `react-native-safe-area-context`, never `StatusBar.currentHeight` math or hardcoded `44`/`34` (`A11Y-*`).
3. **Tokens, not literals** — every color/space/radius comes from the theme context/styling system (`COL-*`, `SPC-*`).
4. **Sheets use snap points** — `@gorhom/bottom-sheet` `snapPoints` as detents; add the bottom safe-area inset (`BSH-*`).
5. **Targets ≥44×44 / 48×48** — set `minHeight`/`minWidth` or `hitSlop` on every `Pressable` (`BTN-*`, `A11Y-*`).
