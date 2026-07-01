# SwiftUI — Adaptive & Responsive

**Purpose:** SwiftUI is Apple-only, but must still adapt across **size classes** (iPhone ↔ iPad ↔ Mac ↔ split view / Stage Manager) and adopt **iOS 26 Liquid Glass** correctly. This file covers size-class routing, list-detail promotion, Dynamic Type, and glass/concentric-corner behavior. Rules referenced, not restated: `GRD-*`, `PLAT-*`, `A11Y-*`, `TYP-*`, `NAV-*`, `BSH-*`.

## Table of contents
- [Size classes, not device checks](#size-classes-not-device-checks)
- [List-detail: NavigationSplitView](#list-detail-navigationsplitview)
- [ViewThatFits & the layout adapters](#viewthatfits--the-layout-adapters)
- [Sheet ↔ popover](#sheet--popover)
- [Dynamic Type is the other axis](#dynamic-type-is-the-other-axis)
- [Liquid Glass & concentric corners](#liquid-glass--concentric-corners)

## Size classes, not device checks
Branch on `@Environment(\.horizontalSizeClass)` / `verticalSizeClass`, never on `UIDevice` model or hardcoded widths (`GRD-*`, `PLAT-*`). Compact ≈ iPhone portrait & many split-view widths; regular ≈ iPad full-screen, landscape, Mac. This automatically covers Split View, Stage Manager, and external displays.

```swift
@Environment(\.horizontalSizeClass) private var hSize

var body: some View {
    if hSize == .regular { splitLayout }   // iPad / Mac / wide
    else { stackLayout }                    // iPhone / narrow
}
```

## List-detail: NavigationSplitView
On regular width, promote a `NavigationStack` master-detail flow to a true two/three-column `NavigationSplitView` — this is the size-class analog of the `GRD-*` "≥840dp two-pane" rule expressed in Apple's model:

```swift
NavigationSplitView {
    List(items, selection: $selected) { ItemRow(item: $0) }   // sidebar
} detail: {
    if let selected { DetailView(id: selected) }
    else { ContentUnavailableView("Select an item", systemImage: "sidebar.left") }  // empty detail (STATE-*)
}
```
Collapses to a stack on compact automatically — one declaration covers both.

## ViewThatFits & the layout adapters
For component-level adaptivity (a control row that wraps when cramped), let the framework choose:

```swift
ViewThatFits(in: .horizontal) {
    HStack { PrimaryButton(); SecondaryButton() }   // preferred
    VStack { PrimaryButton(); SecondaryButton() }   // fallback when narrow / large text
}
```
`Grid`, `AnyLayout` (swap `HStackLayout`/`VStackLayout` in an animation), and `.containerRelativeFrame` cover the rest — none require hardcoded breakpoints (`GRD-*`).

## Sheet ↔ popover
A modal picker that reads well as a bottom sheet on iPhone should present as a **popover** on regular width. `.presentationDetents` are honored in the compact sheet; on regular width prefer `.popover` or let `NavigationSplitView` show it inline (`BSH-*`, `GRD-*`). Keep the same content view; branch only the presentation.

## Dynamic Type is the other axis
Responsive is not only width — text can scale to AX5 (~310%). Because layouts use text styles and token spacing, they should reflow, not clip (`TYP-*`, `A11Y-*`). Validate with `.dynamicTypeSize(...DynamicTypeSize.accessibility5)` in previews; prefer `ViewThatFits`/`Grid` over fixed-height rows so large type wraps instead of truncating.

## Liquid Glass & concentric corners
On iOS 26, system containers (tab bar, toolbars, sheets, sidebars) render in **Liquid Glass** and condense on scroll — you get this for free by using system components, so **do not** reimplement translucency with opacity literals (`PLAT-*`, `COL-*`). For custom floating surfaces, apply the glass material via the system modifier rather than a hand-rolled blur, and let controls inherit the **concentric** corner radius so they nest correctly inside the device/display corners (`SHP-*`). Keep contrast legible over glass by pairing it with semantic foreground colors and testing under Increase Contrast + Reduce Transparency (`A11Y-*`, `DRK-*`).

> Volatile-fact note (date-stamp per §11.2): the named Liquid Glass material + concentric-corner APIs are iOS 26+. Gate with availability checks and provide a solid-surface fallback on earlier OSes.
