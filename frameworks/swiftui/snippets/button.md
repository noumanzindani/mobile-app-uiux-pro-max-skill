# SwiftUI snippet — Button + ButtonStyle

Token-bound roles, ≥44pt target, press micro-interaction + haptic, and explicit loading/disabled. Rules: `BTN-*`, `MIC-*`, `A11Y-*`, `MOT-*`, `STATE-*`.

```swift
import SwiftUI

/// Primary CTA style — one per view (BTN-*). Reads tokens from the environment.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.space) private var space
    @Environment(\.radius) private var radius
    @Environment(\.motion) private var motion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)                              // Dynamic Type (TYP-*)
            .frame(maxWidth: .infinity, minHeight: 44)    // ≥44pt target (A11Y-*)
            .padding(.horizontal, space.s4)
            .background(.actionPrimary, in: .rect(cornerRadius: radius.md))  // token (COL-*, SHP-*)
            .foregroundStyle(.onActionPrimary)
            .opacity(isEnabled ? 1 : 0.4)                 // disabled is visible (STATE-*)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(motion.spatial, value: configuration.isPressed)       // spring (MIC-*, MOT-*)
            .contentShape(.rect)                          // full hit area
    }
}

/// A CTA that models its own loading state and fires a haptic on tap.
struct PrimaryButton: View {
    let title: String
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()  // reinforcement, not sole cue (HAP-*)
            action()
        } label: {
            if isLoading {
                ProgressView().tint(.onActionPrimary)     // loading state (BTN-*, STATE-*)
            } else {
                Text(title)
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(isLoading)
        .accessibilityLabel(title)                        // label (A11Y-*)
        .accessibilityValue(isLoading ? "Loading" : "")
    }
}

// Destructive variant announces its role to VoiceOver and gets system tint:
// Button("Delete account", role: .destructive) { … }.buttonStyle(PrimaryButtonStyle())
```
