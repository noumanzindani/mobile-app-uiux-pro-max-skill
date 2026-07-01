# SwiftUI snippet — Sheet with detents

`.sheet` + `.presentationDetents` snaps to system heights and keeps context visible; automatic safe area keeps content clear of the home indicator. Rules: `BSH-*`, `A11Y-*`, `GRD-*`, `BTN-*`.

```swift
import SwiftUI

struct ProductScreen: View {
    @State private var showFilters = false
    @Environment(\.horizontalSizeClass) private var hSize

    var body: some View {
        ProductGrid()
            .toolbar {
                Button("Filters", systemImage: "line.3.horizontal.decrease") { showFilters = true }
            }
            .sheet(isPresented: $showFilters) {
                FiltersView(onApply: { showFilters = false })
                    // Detents, not a hardcoded height (BSH-*). On regular width the
                    // system can render this as a popover-sized sheet.
                    .presentationDetents(hSize == .regular ? [.large] : [.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationContentInteraction(.scrolls)
                    .presentationBackground(.regularMaterial)   // Liquid Glass surface (PLAT-*)
            }
    }
}

struct FiltersView: View {
    let onApply: () -> Void
    @Environment(\.space) private var space

    var body: some View {
        NavigationStack {
            Form { /* filter controls — each ≥44pt (A11Y-*) */ }
                .safeAreaInset(edge: .bottom) {
                    PrimaryButton(title: "Apply") { onApply() }   // pinned above home indicator (BSH-*)
                        .padding(space.s4)
                }
                .navigationTitle("Filters")
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: onApply) } }
        }
        .accessibilityAddTraits(.isModal)                  // trap focus in the sheet (A11Y-*)
    }
}
```
