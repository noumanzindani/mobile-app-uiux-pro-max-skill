# SwiftUI — Tokens & Theming

**Purpose:** How SwiftUI consumes the skill's DTCG semantic tokens. Colors flow through **asset-catalog Color sets** (so dark mode + high-contrast resolve automatically); non-color tokens (spacing, radius, motion) flow through **custom `EnvironmentValues`** read with `@Environment`. Rules referenced, not restated: `COL-*`, `DRK-*`, `SPC-*`, `SHP-*`, `MOT-*`.

## Table of contents
- [Layering: DTCG → SwiftUI](#layering-dtcg--swiftui)
- [Color: semantic asset-catalog sets](#color-semantic-asset-catalog-sets)
- [Non-color tokens: EnvironmentValues](#non-color-tokens-environmentvalues)
- [Consuming tokens in a view](#consuming-tokens-in-a-view)
- [Do / Don't](#do--dont)

## Layering: DTCG → SwiftUI
The design system emits three token tiers (primitive → semantic → component). SwiftUI code binds **only to the semantic/component tiers** (`COL-*` forbids referencing primitives directly):

| DTCG token tier | SwiftUI carrier | Resolves |
|---|---|---|
| `color.action.primary`, `color.surface`, `color.on-surface`, `color.error` | Named entry in an **`.xcassets` Color set** with Any + Dark (+ High Contrast) appearances | light / dark / increased-contrast, automatically |
| `space.*`, `radius.*` | `EnvironmentValues` (`\.space`, `\.radius`) | injected once at the app root |
| `motion.spring.*`, `motion.duration.*` | `EnvironmentValues` (`\.motion`) returning `Animation` values | reduce-motion branch in one place |

Style Dictionary can generate the Color set JSON and a Swift `enum` of names, but the **carrier** stays the asset catalog — that is what makes `@Environment(\.colorScheme)` and Increase Contrast work for free (`DRK-*`).

## Color: semantic asset-catalog sets
Define one Color set per **semantic role**, not per raw hue. Each set stores an Any Appearance and a Dark Appearance (add High Contrast variants to satisfy `A11Y-*` contrast under Increase Contrast). Expose them as a namespaced Swift extension so call sites read as intent:

```swift
extension Color {
    // Mirror DTCG semantic role names 1:1 — never expose primitives (COL-*).
    static let surface        = Color("surface")          // color.surface
    static let onSurface      = Color("onSurface")        // color.on-surface
    static let actionPrimary  = Color("actionPrimary")    // color.action.primary
    static let onActionPrimary = Color("onActionPrimary")
    static let danger         = Color("danger")           // color.error
}
```

Views then write `.foregroundStyle(.onSurface)` / `.background(.surface)` — dark mode is resolved by the asset catalog, satisfying `DRK-*` with zero branches.

## Non-color tokens: EnvironmentValues
Spacing, radius, and motion are not appearance-sensitive, so carry them in the environment. This keeps `SPC-*` / `SHP-*` / `MOT-*` centralized and lets a screen swap density or honor Reduce Motion in one place. See `snippets/theme.md` for the full definition; the shape is:

```swift
struct SpaceScale { let s1: CGFloat = 4; let s2: CGFloat = 8; let s3: CGFloat = 12
                    let s4: CGFloat = 16; let s6: CGFloat = 24; let s8: CGFloat = 32 }

private struct SpaceKey: EnvironmentKey { static let defaultValue = SpaceScale() }
extension EnvironmentValues { var space: SpaceScale { self[SpaceKey.self] } }
```

Motion tokens return `Animation` so the Reduce Motion decision lives with the token, not the call site (`MOT-*`, `A11Y-*`):

```swift
struct MotionTokens {
    var reduceMotion = false
    var spatial: Animation { reduceMotion ? .linear(duration: 0.01) : .snappy }   // list/nav movement
    var effects: Animation { reduceMotion ? .linear(duration: 0.01) : .smooth }   // color/opacity
}
```

## Consuming tokens in a view
```swift
struct PriceRow: View {
    @Environment(\.space) private var space
    @Environment(\.radius) private var radius

    var body: some View {
        HStack { /* … */ }
            .padding(.horizontal, space.s4)     // 16 — never a literal (SPC-*)
            .padding(.vertical, space.s3)       // 12
            .background(.surface, in: .rect(cornerRadius: radius.md))  // COL-* + SHP-*
    }
}
```

## Do / Don't
- **Do** name Color sets by semantic role (`surface`, `actionPrimary`) so they mirror DTCG and theme automatically (`COL-*`, `DRK-*`).
- **Do** inject `\.space` / `\.radius` / `\.motion` once at the app root and read via `@Environment` (`SPC-*`, `SHP-*`).
- **Do** put the Reduce-Motion branch inside the motion token (`MOT-*`, `A11Y-*`).
- **Don't** use `Color(red:green:blue:)` / hex literals or raw CGFloat paddings in views — that is exactly what `token_lint` flags.
- **Don't** hardcode `.preferredColorScheme(.dark)` app-wide; let semantic colors + system setting drive it (`DRK-*`).
