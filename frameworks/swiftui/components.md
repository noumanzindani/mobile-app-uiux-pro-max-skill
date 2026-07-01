# SwiftUI — Components

**Purpose:** The idiomatic SwiftUI mapping for the core interactive primitives — button, list, sheet, navigation, safe area, accessibility, and animation — each bound to tokens and rule IDs. Copy-paste stubs live in `snippets/`. Rules referenced, not restated: `BTN-*`, `LST-*`, `BSH-*`, `NAV-*`, `A11Y-*`, `MOT-*`, `MIC-*`, `PERF-*`.

## Table of contents
- [Buttons — Button + ButtonStyle](#buttons--button--buttonstyle)
- [Lists — List / LazyVStack (virtualized)](#lists--list--lazyvstack-virtualized)
- [Sheets — .sheet + presentationDetents](#sheets--sheet--presentationdetents)
- [Navigation — NavigationStack + TabView](#navigation--navigationstack--tabview)
- [Safe area](#safe-area)
- [Accessibility](#accessibility)
- [Animation — springs, matchedGeometry, PhaseAnimator](#animation--springs-matchedgeometry-phaseanimator)

## Buttons — Button + ButtonStyle
Encapsulate the primary/secondary/destructive **roles** in a `ButtonStyle` so every button is token-bound and hits the target minimum in one place (`BTN-*`, `A11Y-*`). One primary action per view (`BTN-*`). The press micro-interaction (scale + haptic) lives in the style so it's uniform (`MIC-*`). Loading and disabled are explicit visual states (`BTN-*`, `STATE-*`). Full stub: `snippets/button.md`.

Key points:
- `.frame(minHeight: 44)` + `.contentShape(.rect)` guarantees the ≥44pt hit area even for a short label (`A11Y-*`).
- `configuration.isPressed` drives a `.scaleEffect(0.97)` with a `.snappy` spring (`MIC-*`, `MOT-*`).
- Destructive uses `role: .destructive` so VoiceOver announces it and the system tints it (`A11Y-*`, `DLG-*`).

## Lists — List / LazyVStack (virtualized)
`List` and `ForEach` (and `LazyVStack` inside a `ScrollView`) materialize rows lazily — this **is** the virtualization `LST-*` / `PERF-*` require. Never build a screen-length `VStack` of rows. Use stable `id:` (ideally `Identifiable`) so diffs animate and don't recompute. Loading shows a skeleton via `.redacted(reason: .placeholder)` (`LST-*`, `STATE-*`). Full stub: `snippets/list.md`.

```swift
List(items) { item in
    ItemRow(item: item)
        .listRowBackground(Color.surface)      // token, not literal (COL-*)
}
.listStyle(.plain)
.refreshable { await store.reload() }          // pull-to-refresh (STATE-*, OFF-*)
```

## Sheets — .sheet + presentationDetents
Modal pickers/detail use `.sheet` with **detents** so the sheet snaps to system-standard heights and keeps context visible (`BSH-*`). Add a drag indicator and let automatic safe area keep content clear of the home indicator (`BSH-*`, `A11Y-*`). Full stub: `snippets/sheet.md`.

```swift
.sheet(isPresented: $showFilters) {
    FiltersView()
        .presentationDetents([.medium, .large])     // detents, not a hardcoded height (BSH-*)
        .presentationDragIndicator(.visible)
        .presentationContentInteraction(.scrolls)
}
```
On regular width this can become a popover — see `adaptive.md`.

## Navigation — NavigationStack + TabView
`NavigationStack` is path-driven (`NavigationStack(path:)`) so deep links and programmatic back work, and never override the system back-swipe (`NAV-*`, `GES-*`). `TabView` holds ≤5 tabs (`NAV-*`); on iOS 26 the tab bar/toolbar is Liquid Glass and condenses on scroll automatically — do not reimplement that. Promote to `NavigationSplitView` on regular width (`adaptive.md`, `GRD-*`).

```swift
TabView(selection: $tab) {
    Tab("Home", systemImage: "house", value: .home) { HomeView() }
    Tab("Search", systemImage: "magnifyingglass", value: .search) { SearchView() }
    // ≤5 tabs (NAV-*)
}
```

## Safe area
Safe area is **automatic** — content already insets past the notch, Dynamic Island, and home indicator. Add an overlay pinned to a safe edge with `.safeAreaInset` (e.g. a persistent CTA or offline banner) and it pushes scroll content instead of covering it (`A11Y-*`, `STATE-*`). Use `.ignoresSafeArea()` **only** for full-bleed backgrounds. Full stub: `snippets/safe-area.md`.

```swift
ScrollView { content }
    .safeAreaInset(edge: .bottom) { CheckoutBar() }   // never overlaps home indicator (BSH-*, A11Y-*)
```

## Accessibility
- **Label / value / hint** on every non-text control: `.accessibilityLabel("Add to cart")`, `.accessibilityValue(qty)`, `.accessibilityHint("Adds one item")` (`A11Y-*`).
- **Group** composite rows with `.accessibilityElement(children: .combine)` so VoiceOver reads one element, not five (`A11Y-*`).
- **Dynamic Type**: use text styles (`.font(.body)`, `.title`), never fixed point sizes; verify at AX5 (`TYP-*`, `A11Y-*`). SF Symbols scale with the text automatically.
- **Non-color cues**: pair any color-encoded status with a symbol or text (`A11Y-*`, `CHT-*`).

## Animation — springs, matchedGeometry, PhaseAnimator
Prefer **springs** over fixed curves for interactive motion; pull them from the motion token so Reduce Motion is honored centrally (`MOT-*`, `A11Y-*`):

```swift
@Environment(\.motion) private var motion
withAnimation(motion.spatial) { isExpanded.toggle() }   // .snappy, or ~instant under Reduce Motion
```
- `matchedGeometryEffect(id:in:)` for shared-element / expand transitions (`MOT-*`).
- `PhaseAnimator` for multi-step looping micro-interactions (e.g. attention pulse), and `.symbolEffect` for SF Symbols 7 Draw/Replace (`MIC-*`).
- Named system springs: `.smooth` (no bounce, effects), `.snappy` (slight bounce, UI), `.bouncy` (playful) — choose by intent, not decoration (`MOT-*`).
