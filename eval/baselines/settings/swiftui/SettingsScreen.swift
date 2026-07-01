// BASELINE — intentionally-naive "no-skill" reference for the eval harness (do NOT
// copy). What an assistant typically emits WITHOUT the Mobile UI/UX Pro Max skill:
// hardcoded hex colors, off-grid spacing, a fixed-height caption row, a destructive
// action inline with the rest (not isolated), and only the happy path with none of
// the required UI states. Graded against examples/settings/swiftui/. (Assumes a
// Color(hex:) extension.)
import SwiftUI

struct SettingsScreen: View {
    @State private var notifications = true
    @State private var darkTheme = false

    var body: some View {
        VStack(alignment: .leading) {
            Text("Settings").foregroundColor(Color(hex: "#111827"))
            Toggle("Notifications", isOn: $notifications).padding(15)
            Toggle("Dark theme", isOn: $darkTheme).padding(15)
            Text("Signed in as user@example.com")
                .foregroundColor(Color(hex: "#6B7280"))
                .frame(height: 14)
            Button(action: {}) { Text("Delete account").foregroundColor(Color(hex: "#DC2626")) }
        }
        .padding(18)
    }
}
