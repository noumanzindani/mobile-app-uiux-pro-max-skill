# SwiftUI snippet — Token theme layer

Semantic `Color` assets (auto light/dark) + custom `EnvironmentValues` for spacing / radius / motion, injected once at the app root. Rules: `COL-*`, `DRK-*`, `SPC-*`, `SHP-*`, `MOT-*`, `A11Y-*`.

```swift
import SwiftUI

// 1. COLORS — one asset-catalog Color set per semantic role (Any + Dark appearances).
//    Dark mode & Increase Contrast resolve automatically (COL-*, DRK-*).
extension Color {
    static let surface          = Color("surface")
    static let onSurface        = Color("onSurface")
    static let actionPrimary    = Color("actionPrimary")
    static let onActionPrimary  = Color("onActionPrimary")
    static let danger           = Color("danger")
}

// 2. SPACING / RADIUS — not appearance-sensitive, so carry in the environment (SPC-*, SHP-*).
struct SpaceScale  { let s1: CGFloat = 4; let s2: CGFloat = 8;  let s3: CGFloat = 12
                     let s4: CGFloat = 16; let s6: CGFloat = 24; let s8: CGFloat = 32 }
struct RadiusScale { let sm: CGFloat = 8; let md: CGFloat = 12; let lg: CGFloat = 20; let pill: CGFloat = 999 }

// 3. MOTION — the Reduce Motion branch lives with the token, not the call site (MOT-*, A11Y-*).
struct MotionTokens {
    var reduceMotion = false
    var spatial: Animation { reduceMotion ? .linear(duration: 0.01) : .snappy }  // movement
    var effects: Animation { reduceMotion ? .linear(duration: 0.01) : .smooth }  // color/opacity
}

private struct SpaceKey:  EnvironmentKey { static let defaultValue = SpaceScale() }
private struct RadiusKey: EnvironmentKey { static let defaultValue = RadiusScale() }
private struct MotionKey: EnvironmentKey { static let defaultValue = MotionTokens() }

extension EnvironmentValues {
    var space:  SpaceScale   { get { self[SpaceKey.self] }  set { self[SpaceKey.self] = newValue } }
    var radius: RadiusScale  { get { self[RadiusKey.self] } set { self[RadiusKey.self] = newValue } }
    var motion: MotionTokens { get { self[MotionKey.self] } set { self[MotionKey.self] = newValue } }
}

// 4. Inject once at the root; wire Reduce Motion from the accessibility environment.
@main
struct MyApp: App {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.motion, MotionTokens(reduceMotion: reduceMotion))
                // .space / .radius use their defaults; override here for a density variant.
        }
    }
}
```
