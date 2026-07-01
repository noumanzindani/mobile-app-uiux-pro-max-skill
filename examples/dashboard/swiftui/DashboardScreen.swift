//  DashboardScreen.swift
//  A glanceable, responsive dashboard where EACH WIDGET OWNS ITS STATE
//  (see ../spec.md).
//
//  Highlights:
//   • RESPONSIVE reflow with zero device checks: `@Environment(\.horizontalSizeClass)`
//     + a `GeometryReader` width drive a `DashboardLayout` (compact / medium /
//     expanded) built from breakpoint TOKENS (600 / 840). Compact renders a single
//     column inside a bottom `TabView`; medium/expanded promote to a
//     `NavigationSplitView` with a side rail and a `LazyVGrid` of ADAPTIVE columns
//     (2–4) that also reflows on rotate / fold / split. Content measure is capped.
//   • PER-WIDGET STATE: every tile is self-contained and owns a `WidgetState`
//     (loading / empty / error / offline / success / permissionDenied / ideal).
//     One failed tile shows a scoped inline error + Retry while the others stay
//     live — there is NO global spinner. Loading shows a SHAPE-MATCHED skeleton;
//     offline shows the cached value with a "Cached" stale indicator.
//   • Numbers use `.monospacedDigit()` + `.formatted(...)`; trend is conveyed by
//     ICON + SIGN + TEXT, never color alone.
//   • The bar chart is drawn with shapes, each bar is labeled, and it carries a
//     DATA-TABLE FALLBACK reachable by VoiceOver (a real `Grid` table + a full
//     spoken series read-out on the chart element).
//   • Pull-to-refresh reloads every tile independently and announces "Updated" via
//     `AccessibilityNotification.Announcement`; a global offline banner rides
//     `.safeAreaInset(edge: .top)` and disables refresh with a reason.
//   • Motion is opacity/offset only and collapses under Reduce Motion. Every
//     design value comes from DashboardTokens — the screen holds zero literals.
//
//  Cross-SDK: the shared `Color` shim lives in DashboardTokens.swift, and every
//  iOS-only modifier is guarded with `#if os(iOS)`, so this file typechecks under
//  BOTH the iOS and macOS SDKs. Both files belong to ONE Xcode target/module.

import SwiftUI
import Network
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Per-widget state model (the dashboard's defining rule)

/// Each tile owns one of these — there is no single global screen state.
enum WidgetState: Equatable {
    case loading
    case empty
    case error
    case offline
    case success
    case permissionDenied
    case ideal
}

// MARK: - Responsive layout (size-class + breakpoint tokens, no device checks)

enum DashboardLayout: Equatable {
    case compact   // < 600 — 1 column + bottom tabs
    case medium    // 600–839 — 2 columns + rail
    case expanded  // ≥ 840 — 3–4 columns + rail / split

    init(width: CGFloat, sizeClass: UserInterfaceSizeClass?) {
        if sizeClass == .compact || width < DashboardTokens.breakpointCompact {
            self = .compact
        } else if width < DashboardTokens.breakpointExpanded {
            self = .medium
        } else {
            self = .expanded
        }
    }

    var isCompact: Bool { self == .compact }
}

// MARK: - Domain models

struct MetricSeed: Identifiable, Equatable {
    enum Format { case currency, number, percent }

    let id: String
    let title: String
    let systemImage: String
    let value: Double
    let format: Format
    let deltaFraction: Double
    let periodLabel: String
    let emptyHint: String
    let permissionHint: String
    /// Demo lever: pin a tile to a state so per-widget independence is visible.
    /// `nil` resolves to `.success` after its own load.
    let forced: WidgetState?

    var currencyCode: String { Locale.current.currency?.identifier ?? "USD" }

    var displayValue: String {
        switch format {
        case .currency: return value.formatted(.currency(code: currencyCode))
        case .number:   return value.formatted(.number.precision(.fractionLength(0)))
        case .percent:  return value.formatted(.percent.precision(.fractionLength(0)))
        }
    }

    /// Signed percent for the trend badge (carries the +/- sign, not color-only).
    var signedDelta: String {
        deltaFraction.formatted(
            .percent.precision(.fractionLength(1)).sign(strategy: .always()))
    }

    var isUp: Bool { deltaFraction >= 0 }

    /// Spoken trend: direction word + magnitude + period — never color/arrow-only.
    var spokenTrend: String {
        let direction = isUp ? "up" : "down"
        let magnitude = abs(deltaFraction)
            .formatted(.percent.precision(.fractionLength(1)))
        return "\(direction) \(magnitude) \(periodLabel)"
    }

    static let all: [MetricSeed] = [
        MetricSeed(id: "balance", title: "Balance", systemImage: "creditcard",
                   value: 2430, format: .currency, deltaFraction: 0.042,
                   periodLabel: "vs last week", emptyHint: "", permissionHint: "",
                   forced: nil),
        MetricSeed(id: "tasks", title: "Open tasks", systemImage: "checklist",
                   value: 8, format: .number, deltaFraction: -0.15,
                   periodLabel: "vs yesterday", emptyHint: "", permissionHint: "",
                   forced: nil),
        MetricSeed(id: "response", title: "Response rate", systemImage: "bolt.fill",
                   value: 0.94, format: .percent, deltaFraction: 0.03,
                   periodLabel: "this month", emptyHint: "", permissionHint: "",
                   forced: nil),
        MetricSeed(id: "payouts", title: "Pending payouts", systemImage: "banknote",
                   value: 540, format: .currency, deltaFraction: 0.0,
                   periodLabel: "vs last week", emptyHint: "", permissionHint: "",
                   forced: .error),
        MetricSeed(id: "reviews", title: "New reviews", systemImage: "star",
                   value: 0, format: .number, deltaFraction: 0.0,
                   periodLabel: "this week",
                   emptyHint: "Reviews from customers will show up here.",
                   permissionHint: "", forced: .empty),
        MetricSeed(id: "steps", title: "Activity", systemImage: "figure.walk",
                   value: 0, format: .number, deltaFraction: 0.0,
                   periodLabel: "today", emptyHint: "",
                   permissionHint: "Allow Health access in Settings to see your daily activity.",
                   forced: .permissionDenied),
    ]
}

struct ChartBar: Identifiable, Equatable {
    let id = UUID()
    let shortLabel: String
    let fullLabel: String
    let value: Double
    let color: Color

    static func week() -> [ChartBar] {
        let raw: [(String, String, Double)] = [
            ("Mon", "Monday", 12), ("Tue", "Tuesday", 18), ("Wed", "Wednesday", 9),
            ("Thu", "Thursday", 22), ("Fri", "Friday", 27), ("Sat", "Saturday", 16),
            ("Sun", "Sunday", 11),
        ]
        let colors = DashboardTokens.chartSeries
        return raw.enumerated().map { index, item in
            ChartBar(shortLabel: item.0, fullLabel: item.1, value: item.2,
                     color: colors[index % colors.count])
        }
    }
}

struct ActivityItem: Identifiable, Equatable {
    let id = UUID()
    let systemImage: String
    let title: String
    let time: String

    static let all: [ActivityItem] = [
        ActivityItem(systemImage: "checkmark.seal.fill",
                     title: "Booking #4821 completed", time: "2m ago"),
        ActivityItem(systemImage: "person.crop.circle.badge.plus",
                     title: "New customer Priya joined", time: "18m ago"),
        ActivityItem(systemImage: "arrow.down.circle.fill",
                     title: "Payout of $540 scheduled", time: "1h ago"),
        ActivityItem(systemImage: "star.fill",
                     title: "5-star review from Marco", time: "3h ago"),
    ]
}

// MARK: - Reachability (so the offline state is genuine, not faked)

final class DashboardNetworkMonitor: ObservableObject {
    @Published var isOnline = true
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "dashboard.network.monitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async { self?.isOnline = (path.status == .satisfied) }
        }
        monitor.start(queue: queue)
    }

    deinit { monitor.cancel() }
}

// MARK: - DashboardScreen

struct DashboardScreen: View {

    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @StateObject private var monitor = DashboardNetworkMonitor()

    /// Bumping this re-runs every tile's `.task(id:)` — each reloads independently.
    @State private var refreshTick = 0
    @State private var demoOffline = false
    @State private var openedMetric: MetricSeed?

    private let metrics = MetricSeed.all

    /// Genuine reachability OR the demo override, so offline is exercisable.
    private var isOnline: Bool { monitor.isOnline && !demoOffline }

    // MARK: Body — responsive scaffold

    var body: some View {
        GeometryReader { proxy in
            let layout = DashboardLayout(width: proxy.size.width, sizeClass: hSizeClass)
            Group {
                if layout.isCompact {
                    compactScaffold(layout: layout)
                } else {
                    regularScaffold(layout: layout)
                }
            }
            .animation(DashboardTokens.reveal(reduceMotion: reduceMotion), value: layout)
        }
    }

    // MARK: Compact — single column + bottom TabView (NAV-001)

    private func compactScaffold(layout: DashboardLayout) -> some View {
        TabView {
            NavigationStack {
                dashboardContent(layout: layout)
                    .navigationTitle("Dashboard")
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.large)
                    #endif
                    .toolbar { demoToolbar }
            }
            .tabItem { Label("Overview", systemImage: "square.grid.2x2") }

            NavigationStack { placeholderTab("Activity", systemImage: "bell") }
                .tabItem { Label("Activity", systemImage: "bell") }

            NavigationStack { placeholderTab("Settings", systemImage: "gearshape") }
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }

    // MARK: Medium / expanded — side rail + LazyVGrid (NAV-003 / NAV-009 / GRD-003)

    private func regularScaffold(layout: DashboardLayout) -> some View {
        NavigationSplitView {
            railSidebar
        } detail: {
            NavigationStack {
                dashboardContent(layout: layout)
                    .navigationTitle("Dashboard")
                    .toolbar { demoToolbar }
            }
        }
    }

    private var railSidebar: some View {
        List {
            Label("Overview", systemImage: "square.grid.2x2")
            Label("Activity", systemImage: "bell")
            Label("Reports", systemImage: "chart.bar")
            Label("Settings", systemImage: "gearshape")
        }
        .navigationTitle("EzHand")
    }

    // MARK: Shared dashboard content (grid + chart + activity)

    private func dashboardContent(layout: DashboardLayout) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DashboardTokens.s6) {
                header
                LazyVGrid(columns: gridColumns(for: layout),
                          spacing: DashboardTokens.gridGutter) {
                    ForEach(metrics) { seed in
                        MetricTile(seed: seed, isOnline: isOnline,
                                   refreshTick: refreshTick, reduceMotion: reduceMotion,
                                   onOpen: { openedMetric = seed })
                    }
                }
                ChartTile(isOnline: isOnline, refreshTick: refreshTick,
                          reduceMotion: reduceMotion)
                ActivityTile(isOnline: isOnline, refreshTick: refreshTick,
                             reduceMotion: reduceMotion)
            }
            .padding(.horizontal, DashboardTokens.s4)
            .padding(.top, DashboardTokens.s4)
            .padding(.bottom, DashboardTokens.s8)
            .frame(maxWidth: DashboardTokens.contentMaxWidth)   // cap the measure
            .frame(maxWidth: .infinity)
        }
        .background(DashboardTokens.surface)
        .refreshable { await refreshAll() }
        .safeAreaInset(edge: .top) { offlineBanner }
        .animation(DashboardTokens.reveal(reduceMotion: reduceMotion), value: isOnline)
        .sheet(item: $openedMetric) { seed in MetricDetailSheet(seed: seed) }
    }

    private func gridColumns(for layout: DashboardLayout) -> [GridItem] {
        switch layout {
        case .compact:
            return [GridItem(.flexible(), spacing: DashboardTokens.gridGutter)]
        case .medium, .expanded:
            // Adaptive → 2–4 columns depending on the pane width, no hardcoded count.
            return [GridItem(.adaptive(minimum: DashboardTokens.gridItemMin,
                                       maximum: DashboardTokens.gridItemMax),
                             spacing: DashboardTokens.gridGutter)]
        }
    }

    // MARK: Header (greeting + range + refresh)

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: DashboardTokens.s3) {
            VStack(alignment: .leading, spacing: DashboardTokens.s1) {
                Text("Good \(dayPart)")
                    .font(DashboardTokens.screenTitleFont)
                    .fontWeight(.semibold)
                    .foregroundStyle(DashboardTokens.onSurfaceStrong)
                Text(todayRange)
                    .font(DashboardTokens.footnoteFont)
                    .foregroundStyle(DashboardTokens.onSurfaceMuted)
            }
            Spacer(minLength: DashboardTokens.s2)
            refreshButton
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Good \(dayPart). \(todayRange)")
    }

    private var refreshButton: some View {
        Button {
            Task { await refreshAll() }
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(DashboardTokens.bodyFont)
                .frame(minWidth: DashboardTokens.targetMin,
                       minHeight: DashboardTokens.targetMin)
                .contentShape(.rect)
        }
        .buttonStyle(.bordered)
        .disabled(!isOnline)
        .accessibilityLabel("Refresh dashboard")
        .accessibilityHint(isOnline ? "Reloads every tile"
                                    : "Unavailable while offline")
    }

    // MARK: Global offline banner (non-blocking, disables refresh with a reason)

    @ViewBuilder private var offlineBanner: some View {
        if !isOnline {
            HStack(spacing: DashboardTokens.s2) {
                Image(systemName: "wifi.slash")
                    .accessibilityHidden(true)
                Text("You're offline — showing cached data. Pull to refresh once you reconnect.")
                    .font(DashboardTokens.footnoteFont)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: DashboardTokens.s2)
            }
            .foregroundStyle(DashboardTokens.onSurface)
            .padding(.horizontal, DashboardTokens.s4)
            .padding(.vertical, DashboardTokens.s3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DashboardTokens.surfaceContainer)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("You're offline. Showing cached data. Reconnect to refresh.")
            .transition(reduceMotion ? .opacity
                        : .move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: Demo toolbar (reach every state without leaving the preview)

    @ToolbarContentBuilder private var demoToolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Toggle("Offline (demo)", isOn: $demoOffline)
                Button("Refresh now") { Task { await refreshAll() } }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .frame(minWidth: DashboardTokens.targetMin,
                           minHeight: DashboardTokens.targetMin)
                    .contentShape(.rect)
            }
            .accessibilityLabel("Dashboard options")
        }
    }

    private func placeholderTab(_ title: String, systemImage: String) -> some View {
        ContentUnavailableView(title, systemImage: systemImage,
                               description: Text("This tab is a stand-in for the example."))
            .navigationTitle(title)
    }

    // MARK: Refresh — reloads every tile, then announces the result

    private func refreshAll() async {
        guard isOnline else {
            announce("You're offline. Showing cached data. Reconnect to refresh.")
            return
        }
        refreshTick &+= 1   // each tile's `.task(id:)` re-runs its own load
        try? await Task.sleep(for: DashboardTokens.refreshDelay)
        announce("Updated. Dashboard refreshed.")
    }

    private func announce(_ message: String) {
        AccessibilityNotification.Announcement(message).post()
    }

    // MARK: Derived copy

    private var dayPart: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:  return "morning"
        case 12..<17: return "afternoon"
        default:      return "evening"
        }
    }

    private var todayRange: String {
        Date().formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }
}

// MARK: - Tile chrome (padding + surface + radius + min hit height)

private struct TileChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(DashboardTokens.s4)
            .frame(maxWidth: .infinity, minHeight: DashboardTokens.cardMinHeight,
                   alignment: .leading)
            .background(DashboardTokens.surfaceContainer,
                        in: RoundedRectangle(cornerRadius: DashboardTokens.cardRadius,
                                             style: .continuous))
    }
}

// MARK: - MetricTile (self-contained, owns its WidgetState)

struct MetricTile: View {
    let seed: MetricSeed
    let isOnline: Bool
    let refreshTick: Int
    let reduceMotion: Bool
    var onOpen: () -> Void = {}

    @State private var state: WidgetState = .loading
    @State private var recovered = false

    /// A live tile with data becomes "offline/cached" when connectivity drops.
    private var effectiveState: WidgetState {
        switch state {
        case .success, .ideal: return isOnline ? .success : .offline
        default:               return state
        }
    }

    var body: some View {
        let base = content
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(TileChrome())
            .contentShape(.rect)
            .onTapGesture { onOpen() }
            .task(id: refreshTick) { await load() }
            .animation(DashboardTokens.reveal(reduceMotion: reduceMotion), value: state)
            .animation(DashboardTokens.reveal(reduceMotion: reduceMotion), value: isOnline)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { onOpen() }

        return Group {
            switch effectiveState {
            case .error:
                base.accessibilityAction(named: "Retry") { Task { await retry() } }
            case .permissionDenied:
                base.accessibilityAction(named: "Open Settings") { openSettings() }
            default:
                base
            }
        }
    }

    // MARK: State-matched content

    @ViewBuilder private var content: some View {
        switch effectiveState {
        case .loading:          MetricSkeleton()
        case .empty:            emptyBody
        case .error:            errorBody
        case .permissionDenied: permissionBody
        case .offline:          valueBody(stale: true)
        case .success, .ideal:  valueBody(stale: false)
        }
    }

    private var titleRow: some View {
        HStack(spacing: DashboardTokens.s2) {
            Image(systemName: seed.systemImage)
                .foregroundStyle(DashboardTokens.actionPrimary)
                .accessibilityHidden(true)
            Text(seed.title)
                .font(DashboardTokens.cardTitleFont)
                .foregroundStyle(DashboardTokens.onSurfaceMuted)
            Spacer(minLength: DashboardTokens.s2)
        }
    }

    private func valueBody(stale: Bool) -> some View {
        VStack(alignment: .leading, spacing: DashboardTokens.s2) {
            titleRow
            Text(seed.displayValue)
                .font(DashboardTokens.metricValueFont)   // .monospacedDigit() role
                .foregroundStyle(DashboardTokens.onSurfaceStrong)
                .contentTransition(.numericText())
                .animation(DashboardTokens.numberChange(reduceMotion: reduceMotion),
                           value: seed.value)
            HStack(spacing: DashboardTokens.s2) {
                TrendBadge(isUp: seed.isUp, text: seed.signedDelta)
                Text(seed.periodLabel)
                    .font(DashboardTokens.footnoteFont)
                    .foregroundStyle(DashboardTokens.onSurfaceMuted)
                Spacer(minLength: DashboardTokens.s2)
                if stale { StaleChip() }
            }
        }
    }

    private var emptyBody: some View {
        VStack(alignment: .leading, spacing: DashboardTokens.s2) {
            titleRow
            Text("No data yet")
                .font(DashboardTokens.bodyFont)
                .foregroundStyle(DashboardTokens.onSurface)
            Text(seed.emptyHint)
                .font(DashboardTokens.footnoteFont)
                .foregroundStyle(DashboardTokens.onSurfaceMuted)
                .fixedSize(horizontal: false, vertical: true)
            Button { onOpen() } label: {
                Label("Add \(seed.title)", systemImage: "plus")
                    .font(DashboardTokens.footnoteFont)
                    .frame(minHeight: DashboardTokens.targetMin)
            }
            .buttonStyle(.bordered)
            .accessibilityHidden(true)   // exposed via the combined card + activate
        }
    }

    private var errorBody: some View {
        VStack(alignment: .leading, spacing: DashboardTokens.s2) {
            titleRow
            HStack(alignment: .top, spacing: DashboardTokens.s2) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(DashboardTokens.statusError)   // icon + text
                    .accessibilityHidden(true)
                Text("Couldn't load")
                    .font(DashboardTokens.bodyFont)
                    .foregroundStyle(DashboardTokens.onSurface)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button { Task { await retry() } } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(DashboardTokens.footnoteFont)
                    .frame(minHeight: DashboardTokens.targetMin)
            }
            .buttonStyle(.bordered)
            .accessibilityHidden(true)   // exposed via the "Retry" a11y action
        }
    }

    private var permissionBody: some View {
        VStack(alignment: .leading, spacing: DashboardTokens.s2) {
            titleRow
            Text("Permission needed")
                .font(DashboardTokens.bodyFont)
                .foregroundStyle(DashboardTokens.onSurface)
            Text(seed.permissionHint)
                .font(DashboardTokens.footnoteFont)
                .foregroundStyle(DashboardTokens.onSurfaceMuted)
                .fixedSize(horizontal: false, vertical: true)
            Button { openSettings() } label: {
                Label("Open Settings", systemImage: "gear")
                    .font(DashboardTokens.footnoteFont)
                    .frame(minHeight: DashboardTokens.targetMin)
            }
            .buttonStyle(.bordered)
            .accessibilityHidden(true)   // exposed via the "Open Settings" a11y action
        }
    }

    // MARK: Coherent accessible name (trend not color/arrow-only)

    private var accessibilityLabel: String {
        switch effectiveState {
        case .loading:
            return "\(seed.title), loading"
        case .empty:
            return "\(seed.title), no data yet. \(seed.emptyHint)"
        case .error:
            return "\(seed.title), couldn't load. Use the Retry action."
        case .permissionDenied:
            return "\(seed.title), permission needed. \(seed.permissionHint)"
        case .offline:
            return "\(seed.title), \(seed.displayValue), \(seed.spokenTrend). Cached, offline."
        case .success, .ideal:
            return "\(seed.title), \(seed.displayValue), \(seed.spokenTrend)."
        }
    }

    // MARK: Lifecycle (each tile loads on its own)

    private func load() async {
        state = .loading
        try? await Task.sleep(for: DashboardTokens.loadDelay)
        state = resolvedState
    }

    private var resolvedState: WidgetState {
        guard let forced = seed.forced else { return .success }
        if forced == .error && recovered { return .success }
        return forced
    }

    private func retry() async {
        recovered = true
        await load()   // shows the skeleton again, then resolves live
    }

    private func openSettings() {
        #if os(iOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }
}

// MARK: - Trend badge (icon + sign + text — never color-only)

private struct TrendBadge: View {
    let isUp: Bool
    let text: String

    var body: some View {
        HStack(spacing: DashboardTokens.s1) {
            Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
                .accessibilityHidden(true)
            Text(text)
                .font(DashboardTokens.metricDeltaFont)   // .monospacedDigit() role
        }
        .foregroundStyle(isUp ? DashboardTokens.statusSuccess
                              : DashboardTokens.statusError)
    }
}

// MARK: - Stale / cached indicator (offline)

private struct StaleChip: View {
    var body: some View {
        HStack(spacing: DashboardTokens.s1) {
            Image(systemName: "clock.arrow.circlepath")
                .accessibilityHidden(true)
            Text("Cached")
                .font(DashboardTokens.captionFont)
        }
        .foregroundStyle(DashboardTokens.statusWarning)
        .padding(.horizontal, DashboardTokens.s2)
        .padding(.vertical, DashboardTokens.s1)
        .background(DashboardTokens.surface, in: Capsule())
    }
}

// MARK: - Shape-matched metric skeleton (number block + label lines)

private struct MetricSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DashboardTokens.s3) {
            skeletonLine
                .padding(.trailing, DashboardTokens.s8)   // a shorter "title" line
            RoundedRectangle(cornerRadius: DashboardTokens.chipRadius, style: .continuous)
                .fill(DashboardTokens.skeleton)
                .frame(height: DashboardTokens.skeletonNumberHeight)   // shape → fixed ok
                .frame(maxWidth: .infinity, alignment: .leading)
            skeletonLine
        }
        .redacted(reason: .placeholder)
        .accessibilityElement()
        .accessibilityLabel("Loading")
    }

    private var skeletonLine: some View {
        RoundedRectangle(cornerRadius: DashboardTokens.chipRadius, style: .continuous)
            .fill(DashboardTokens.skeleton)
            .frame(height: DashboardTokens.skeletonLineHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - ChartTile (shapes + labeled bars + VoiceOver data-table fallback)

struct ChartTile: View {
    let isOnline: Bool
    let refreshTick: Int
    let reduceMotion: Bool

    @State private var state: WidgetState = .loading
    @State private var showTable = false
    @State private var drawn = false

    private let data = ChartBar.week()

    private var effectiveState: WidgetState {
        switch state {
        case .success, .ideal: return isOnline ? .success : .offline
        default:               return state
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DashboardTokens.s3) {
            headerRow
            switch effectiveState {
            case .loading:
                ChartSkeleton()
            default:
                chart
                if showTable { dataTable }
            }
        }
        .modifier(TileChrome())
        .task(id: refreshTick) { await load() }
        .animation(DashboardTokens.reveal(reduceMotion: reduceMotion), value: state)
        .animation(DashboardTokens.reveal(reduceMotion: reduceMotion), value: showTable)
        .accessibilityElement(children: .contain)
    }

    private var headerRow: some View {
        HStack(spacing: DashboardTokens.s2) {
            Text("Weekly bookings")
                .font(DashboardTokens.sectionFont)
                .foregroundStyle(DashboardTokens.onSurface)
            if effectiveState == .offline { StaleChip() }
            Spacer(minLength: DashboardTokens.s2)
            Button {
                withAnimation(DashboardTokens.reveal(reduceMotion: reduceMotion)) {
                    showTable.toggle()
                }
            } label: {
                Label(showTable ? "Hide table" : "View as table",
                      systemImage: "tablecells")
                    .font(DashboardTokens.footnoteFont)
                    .labelStyle(.iconOnly)
                    .frame(minWidth: DashboardTokens.targetMin,
                           minHeight: DashboardTokens.targetMin)
                    .contentShape(.rect)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(showTable ? "Hide data table" : "Show data table")
        }
    }

    // Bars drawn with shapes; each is labeled. The whole chart reads its full
    // series to VoiceOver (the data-table fallback) and is otherwise decorative.
    private var chart: some View {
        let maxValue = max(data.map(\.value).max() ?? 0, DashboardTokens.chartBarMinHeight)
        return HStack(alignment: .bottom, spacing: DashboardTokens.s2) {
            ForEach(data) { bar in
                VStack(spacing: DashboardTokens.s1) {
                    RoundedRectangle(cornerRadius: DashboardTokens.barCornerRadius,
                                     style: .continuous)
                        .fill(bar.color)
                        .frame(height: barHeight(bar.value, maxValue: maxValue))
                        .frame(maxWidth: .infinity)
                    Text(bar.shortLabel)
                        .font(DashboardTokens.captionFont)
                        .foregroundStyle(DashboardTokens.onSurfaceMuted)
                }
            }
        }
        .frame(height: DashboardTokens.chartHeight, alignment: .bottom)
        .opacity(drawn ? 1 : 0)
        .animation(DashboardTokens.chartDraw(reduceMotion: reduceMotion), value: drawn)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Weekly bookings chart. \(seriesSummary)")
    }

    private var dataTable: some View {
        Grid(alignment: .leading, horizontalSpacing: DashboardTokens.s4,
             verticalSpacing: DashboardTokens.s2) {
            GridRow {
                Text("Day")
                    .font(DashboardTokens.captionFont)
                    .foregroundStyle(DashboardTokens.onSurfaceMuted)
                Text("Bookings")
                    .font(DashboardTokens.captionFont)
                    .foregroundStyle(DashboardTokens.onSurfaceMuted)
            }
            ForEach(data) { bar in
                GridRow {
                    Text(bar.fullLabel)
                        .font(DashboardTokens.footnoteFont)
                        .foregroundStyle(DashboardTokens.onSurface)
                    Text(bar.value.formatted(.number))
                        .font(DashboardTokens.tableValueFont)
                        .foregroundStyle(DashboardTokens.onSurface)
                }
            }
        }
        .accessibilityLabel("Weekly bookings data table")
    }

    private var seriesSummary: String {
        data.map { "\($0.fullLabel) \($0.value.formatted(.number))" }
            .joined(separator: ", ")
    }

    private func barHeight(_ value: Double, maxValue: Double) -> CGFloat {
        let ratio = maxValue > 0 ? value / maxValue : 0
        return max(DashboardTokens.chartBarMinHeight,
                   DashboardTokens.chartHeight * CGFloat(ratio))
    }

    private func load() async {
        state = .loading
        drawn = false
        try? await Task.sleep(for: DashboardTokens.loadDelay)
        state = .success
        drawn = true
    }
}

// MARK: - Chart skeleton (bar-shaped placeholders)

private struct ChartSkeleton: View {
    private let slots = ChartBar.week()

    var body: some View {
        HStack(alignment: .bottom, spacing: DashboardTokens.s2) {
            ForEach(slots) { _ in
                RoundedRectangle(cornerRadius: DashboardTokens.barCornerRadius,
                                 style: .continuous)
                    .fill(DashboardTokens.skeleton)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: DashboardTokens.chartHeight, alignment: .bottom)
        .redacted(reason: .placeholder)
        .accessibilityElement()
        .accessibilityLabel("Loading chart")
    }
}

// MARK: - ActivityTile (recent activity list, owns its state)

struct ActivityTile: View {
    let isOnline: Bool
    let refreshTick: Int
    let reduceMotion: Bool

    @State private var state: WidgetState = .loading

    private let items = ActivityItem.all

    private var effectiveState: WidgetState {
        switch state {
        case .success, .ideal: return isOnline ? .success : .offline
        default:               return state
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DashboardTokens.s3) {
            HStack(spacing: DashboardTokens.s2) {
                Text("Recent activity")
                    .font(DashboardTokens.sectionFont)
                    .foregroundStyle(DashboardTokens.onSurface)
                if effectiveState == .offline { StaleChip() }
                Spacer(minLength: DashboardTokens.s2)
            }
            switch effectiveState {
            case .loading:
                ForEach(items) { _ in ActivityRowSkeleton() }
            default:
                ForEach(items) { item in
                    activityRow(item)
                    if item.id != items.last?.id { Divider() }
                }
            }
        }
        .modifier(TileChrome())
        .task(id: refreshTick) { await load() }
        .animation(DashboardTokens.reveal(reduceMotion: reduceMotion), value: state)
        .accessibilityElement(children: .contain)
    }

    private func activityRow(_ item: ActivityItem) -> some View {
        HStack(spacing: DashboardTokens.s3) {
            Image(systemName: item.systemImage)
                .foregroundStyle(DashboardTokens.actionPrimary)
                .accessibilityHidden(true)
            Text(item.title)
                .font(DashboardTokens.bodyFont)
                .foregroundStyle(DashboardTokens.onSurface)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: DashboardTokens.s2)
            Text(item.time)
                .font(DashboardTokens.footnoteFont)
                .foregroundStyle(DashboardTokens.onSurfaceMuted)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title), \(item.time)")
    }

    private func load() async {
        state = .loading
        try? await Task.sleep(for: DashboardTokens.loadDelay)
        state = .success
    }
}

private struct ActivityRowSkeleton: View {
    var body: some View {
        HStack(spacing: DashboardTokens.s3) {
            Circle()
                .fill(DashboardTokens.skeleton)
                .frame(width: DashboardTokens.targetMin,
                       height: DashboardTokens.sparkDotSize)
            VStack(alignment: .leading, spacing: DashboardTokens.s2) {
                RoundedRectangle(cornerRadius: DashboardTokens.chipRadius, style: .continuous)
                    .fill(DashboardTokens.skeleton)
                    .frame(height: DashboardTokens.skeletonLineHeight)
                RoundedRectangle(cornerRadius: DashboardTokens.chipRadius, style: .continuous)
                    .fill(DashboardTokens.skeleton)
                    .frame(height: DashboardTokens.skeletonLineHeight)
                    .padding(.trailing, DashboardTokens.s8)
            }
        }
        .redacted(reason: .placeholder)
        .accessibilityElement()
        .accessibilityLabel("Loading activity")
    }
}

// MARK: - Metric detail (the one-tap drill-in)

private struct MetricDetailSheet: View {
    let seed: MetricSeed
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DashboardTokens.s4) {
                    Text(seed.displayValue)
                        .font(DashboardTokens.metricValueFont)
                        .foregroundStyle(DashboardTokens.onSurfaceStrong)
                    HStack(spacing: DashboardTokens.s2) {
                        TrendBadge(isUp: seed.isUp, text: seed.signedDelta)
                        Text(seed.periodLabel)
                            .font(DashboardTokens.footnoteFont)
                            .foregroundStyle(DashboardTokens.onSurfaceMuted)
                    }
                    Text("Detailed breakdown for \(seed.title) would live here.")
                        .font(DashboardTokens.bodyFont)
                        .foregroundStyle(DashboardTokens.onSurfaceMuted)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: DashboardTokens.s2)
                }
                .padding(.horizontal, DashboardTokens.s4)
                .padding(.top, DashboardTokens.s4)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(DashboardTokens.surface)
            .navigationTitle(seed.title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") { dismiss() }
                        .frame(minHeight: DashboardTokens.targetMin)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Dashboard") {
    DashboardScreen()
}

#Preview("Dark / Accessibility type") {
    DashboardScreen()
        .preferredColorScheme(.dark)
        .dynamicTypeSize(.accessibility3)
}
