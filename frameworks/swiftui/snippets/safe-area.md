# SwiftUI snippet — Safe area

Safe area is automatic; use `.safeAreaInset` to pin a bar/banner (it pushes scroll content instead of covering it) and `.ignoresSafeArea` only for full-bleed backgrounds. Rules: `A11Y-*`, `BSH-*`, `STATE-*`, `GES-*`.

```swift
import SwiftUI

struct CheckoutScreen: View {
    @Environment(\.space) private var space
    @Environment(NetworkMonitor.self) private var network

    var body: some View {
        ScrollView {
            LazyVStack(spacing: space.s4) { CartItems() }   // virtualized (LST-*)
                .padding(space.s4)
        }
        // Full-bleed background is the ONLY place to ignore safe area (A11Y-*):
        .background(Color.surface.ignoresSafeArea())
        // Offline banner pinned to top safe edge — never covers the Dynamic Island (OFF-*, STATE-*):
        .safeAreaInset(edge: .top) {
            if !network.isOnline {
                OfflineBanner()
                    .accessibilityLabel("You're offline. Changes will sync later.")  // live region (A11Y-*)
            }
        }
        // Persistent CTA pinned to bottom safe edge — sits above the home indicator (BSH-*):
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "Pay") { /* … */ }
                .padding(.horizontal, space.s4)
                .padding(.top, space.s2)
                .background(.thinMaterial)                    // Liquid Glass bar (PLAT-*)
        }
    }
}

// Note: do NOT read `UIApplication...safeAreaInsets` and add manual padding — the
// .safeAreaInset / automatic inset primitives already handle notch, Dynamic Island,
// keyboard, and home indicator, and adapt on rotation and across devices.
```
