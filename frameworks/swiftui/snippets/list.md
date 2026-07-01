# SwiftUI snippet — Virtualized List

`List`/`ForEach` materialize rows lazily (the virtualization `LST-*`/`PERF-*` require). Includes pull-to-refresh, skeleton loading, combined-a11y rows, and token-bound row background. Rules: `LST-*`, `PERF-*`, `STATE-*`, `A11Y-*`, `OFF-*`.

```swift
import SwiftUI

struct Transaction: Identifiable {
    let id: UUID; let merchant: String; let amount: Decimal; let pending: Bool
    static let placeholder = Transaction(id: UUID(), merchant: "Placeholder Co", amount: 0, pending: false)
}

struct TransactionList: View {
    @Environment(\.space) private var space
    let phase: LoadPhase<[Transaction]>
    let reload: () async -> Void

    var body: some View {
        switch phase {
        case .loading:
            // Skeleton uses real row layout so metrics match (STATE-*, LST-*)
            List(0..<8, id: \.self) { _ in Row(txn: .placeholder) }
                .redacted(reason: .placeholder)
                .accessibilityLabel("Loading transactions")

        case .empty:
            ContentUnavailableView("No transactions yet",
                systemImage: "creditcard",
                description: Text("Your purchases will show up here."))

        case .loaded(let txns):
            List(txns) { txn in
                Row(txn: txn)
                    .listRowBackground(Color.surface)   // token, not literal (COL-*)
            }
            .listStyle(.plain)
            .refreshable { await reload() }             // pull-to-refresh (STATE-*, OFF-*)

        case .failed(let error):
            ContentUnavailableView {
                Label("Couldn't load", systemImage: "exclamationmark.triangle")
            } description: { Text(error.localizedDescription) }
            actions: { Button("Try again") { Task { await reload() } } }
        }
    }
}

private struct Row: View {
    @Environment(\.space) private var space
    let txn: Transaction
    var body: some View {
        HStack {
            Text(txn.merchant)
            Spacer()
            Text(txn.amount, format: .currency(code: "USD"))
                .monospacedDigit()                       // tabular numerals (finance legibility)
        }
        .padding(.vertical, space.s2)
        .accessibilityElement(children: .combine)        // one VoiceOver element (A11Y-*)
    }
}
```
