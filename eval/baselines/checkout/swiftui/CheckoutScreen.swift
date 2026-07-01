// BASELINE — intentionally-naive "no-skill" reference for the eval harness (do NOT
// copy). What an assistant typically emits WITHOUT the Mobile UI/UX Pro Max skill:
// hardcoded hex colors, off-grid spacing, a fixed-height price row, an undersized
// stepper, and only the happy path — none of the required UI states, so nothing
// guards a double-charge. Graded against examples/checkout/swiftui/. (Assumes a
// Color(hex:) extension, as such code usually does.)
import SwiftUI

struct CheckoutScreen: View {
    @State private var qty = 1

    var body: some View {
        VStack(alignment: .leading) {
            Text("Order summary").foregroundColor(Color(hex: "#111827")).frame(height: 26)
            HStack {
                Text("Wireless Headphones")
                Spacer()
                Text("$129.00")
            }
            .padding(15)
            HStack {
                Button(action: { qty -= 1 }) { Text("-") }.frame(width: 32, height: 32)
                Text("\(qty)")
                Button(action: { qty += 1 }) { Text("+") }.frame(width: 32, height: 32)
            }
            Text("Tax and shipping calculated at charge").foregroundColor(Color(hex: "#9CA3AF"))
            Button(action: {}) { Text("Pay now").frame(maxWidth: .infinity) }
                .padding(15)
                .background(Color(hex: "#16A34A"))
        }
        .padding(18)
    }
}
