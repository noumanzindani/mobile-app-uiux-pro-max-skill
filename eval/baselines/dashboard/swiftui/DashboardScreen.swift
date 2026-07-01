// BASELINE — intentionally-naive "no-skill" reference for the eval harness (do NOT
// copy). What an assistant typically emits WITHOUT the Mobile UI/UX Pro Max skill:
// hardcoded hex colors, off-grid spacing, a fixed-height metric row, a fixed
// 2-column grid (no size classes), and only the happy path with none of the
// required UI states. Graded against examples/dashboard/swiftui/. (Assumes a
// Color(hex:) extension.)
import SwiftUI

struct DashboardScreen: View {
    private let tiles = ["Revenue", "Orders", "Visitors", "Refunds"]
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Dashboard").foregroundColor(Color(hex: "#111827"))
            LazyVGrid(columns: columns) {
                ForEach(tiles, id: \.self) { t in
                    VStack(alignment: .leading) {
                        Text(t).foregroundColor(Color(hex: "#111827")).frame(height: 22)
                        Text("+12%").foregroundColor(Color(hex: "#16A34A"))
                    }
                    .padding(10)
                    .background(Color(hex: "#FFFFFF"))
                }
            }
        }
        .padding(18)
    }
}
