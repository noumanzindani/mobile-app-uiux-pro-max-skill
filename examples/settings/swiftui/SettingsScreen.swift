//  SettingsScreen.swift
//  A grouped, searchable settings screen with ISOLATED destructive actions and a
//  reachable, multi-step account-deletion path (see ../spec.md).
//
//  Highlights:
//   • GROUPED `Form` + `Section` (iOS grouped inset style) with concern headers —
//     Account · Notifications · Privacy & Security · Appearance · About & Help.
//     Section headers are exposed as accessibility headers.
//   • `.searchable` filters across EVERY setting (title + keywords) and, when
//     nothing matches, shows a distinct zero-results empty via
//     `ContentUnavailableView.search`.
//   • Row types: `Toggle` (announces role + on/off), disclosure `NavigationLink`
//     (chevron auto-mirrors in RTL), value + native `Picker`, and action `Button`.
//   • DESTRUCTIVE actions (Sign out · Delete account) live in their OWN section at
//     the very bottom, out of the accidental-tap arc, drawn in the error color, and
//     each sits behind a confirm. Account deletion is a multi-step confirm
//     (dialog → typed-DELETE alert) so it is reachable in-app (store policy).
//   • A light / dark / system theme `Picker` drives `preferredColorScheme`.
//   • RESPONSIVE: `NavigationSplitView` two-pane (group list + selected group) on a
//     wide, regular window; a single push `NavigationStack` on compact — driven by
//     breakpoint TOKENS (600 / 840), no device checks.
//   • STATES (`SettingsState`): search zero-results (empty), a synced-value skeleton
//     (loading), a failed toggle that REVERTS with a message (error — never a silent
//     false success), a non-blocking offline banner that disables server toggles with
//     a reason, an inline saved-confirmed banner (success), and OS-permission rows
//     that reflect the real system state and deep-link to Settings (permissionDenied).
//   • Motion is opacity/position only and collapses under Reduce Motion. Every design
//     value comes from SettingsTokens — this screen holds zero literals.
//
//  Cross-SDK: the shared `Color` shim lives in SettingsTokens.swift, and every
//  iOS-only API (`.navigationBarTitleDisplayMode`, `UIApplication.openSettingsURLString`)
//  is guarded with `#if os(iOS)`, so this file typechecks under BOTH the iOS and
//  macOS SDKs. Both files belong to ONE Xcode target / module.

import SwiftUI
import Network
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif

// MARK: - The 7 UI states (auditable enum, not boolean soup)

enum SettingsState: Equatable {
    case ideal
    case loading
    case empty
    case error
    case offline
    case success
    case permissionDenied
}

// MARK: - Responsive layout (size-class + breakpoint tokens, no device checks)

enum SettingsLayout: Equatable {
    case compact    // single scrolling list; a group pushes a sub-page
    case expanded   // two-pane: group list (leading) + selected group (detail)

    init(width: CGFloat, sizeClass: UserInterfaceSizeClass?) {
        // Two-pane only on a genuinely wide, regular-width window; otherwise a
        // single push. Below either breakpoint token we stay single-pane.
        if sizeClass == .compact
            || width < SettingsTokens.breakpointCompact
            || width < SettingsTokens.breakpointExpanded {
            self = .compact
        } else {
            self = .expanded
        }
    }

    var isCompact: Bool { self == .compact }
}

// MARK: - Sections (grouped by concern; headers become a11y headings)

enum SettingSection: String, CaseIterable, Identifiable, Hashable {
    case account, notifications, privacy, appearance, about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .account:       return "Account"
        case .notifications: return "Notifications"
        case .privacy:       return "Privacy & Security"
        case .appearance:    return "Appearance"
        case .about:         return "About & Help"
        }
    }

    var systemImage: String {
        switch self {
        case .account:       return "person.crop.circle"
        case .notifications: return "bell.badge"
        case .privacy:       return "lock.shield"
        case .appearance:    return "paintbrush"
        case .about:         return "questionmark.circle"
        }
    }
}

// MARK: - Preference domain

enum ToggleKey: String, CaseIterable, Identifiable {
    case pushAlerts, emailNewsletter, inAppSounds        // Notifications
    case biometricLock, analyticsSharing, crashReports   // Privacy & Security

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pushAlerts:       return "Push alerts"
        case .emailNewsletter:  return "Email newsletter"
        case .inAppSounds:      return "In-app sounds"
        case .biometricLock:    return "Unlock with Face ID"
        case .analyticsSharing: return "Share usage analytics"
        case .crashReports:     return "Send crash reports"
        }
    }

    var subtitle: String? {
        switch self {
        case .pushAlerts:       return "Booking updates and messages"
        case .emailNewsletter:  return "Monthly tips and offers"
        case .inAppSounds:      return nil
        case .biometricLock:    return "Require Face ID to open the app"
        case .analyticsSharing: return "Helps improve the app"
        case .crashReports:     return "Share diagnostics after a crash"
        }
    }

    var systemImage: String {
        switch self {
        case .pushAlerts:       return "bell"
        case .emailNewsletter:  return "envelope"
        case .inAppSounds:      return "speaker.wave.2"
        case .biometricLock:    return "faceid"
        case .analyticsSharing: return "chart.bar.xaxis"
        case .crashReports:     return "ladybug"
        }
    }

    var section: SettingSection {
        switch self {
        case .pushAlerts, .emailNewsletter, .inAppSounds:      return .notifications
        case .biometricLock, .analyticsSharing, .crashReports: return .privacy
        }
    }

    /// Server-synced toggles disable while offline and can fail to save.
    var isServerSynced: Bool { self == .emailNewsletter || self == .analyticsSharing }

    /// One toggle is wired to fail its save, to prove the revert-with-message path.
    var failsToSave: Bool { self == .emailNewsletter }

    var keywords: [String] {
        switch self {
        case .pushAlerts:       return ["push", "notifications", "alerts", "messages"]
        case .emailNewsletter:  return ["email", "newsletter", "marketing", "offers"]
        case .inAppSounds:      return ["sound", "audio", "haptics"]
        case .biometricLock:    return ["face id", "biometric", "lock", "security", "passcode"]
        case .analyticsSharing: return ["analytics", "tracking", "privacy", "usage"]
        case .crashReports:     return ["crash", "diagnostics", "reports", "logs"]
        }
    }
}

enum SyncFrequency: String, CaseIterable, Identifiable, Hashable {
    case realtime, hourly, daily
    var id: String { rawValue }
    var title: String {
        switch self {
        case .realtime: return "Real-time"
        case .hourly:   return "Hourly"
        case .daily:    return "Daily"
        }
    }
}

enum ThemePreference: String, CaseIterable, Identifiable, Hashable {
    case system, light, dark
    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

enum PermissionStatus { case unknown, authorized, denied, notDetermined }

// MARK: - Search index / row descriptor

struct SettingLeaf: Identifiable {
    enum Kind {
        case toggle(ToggleKey)
        case syncFrequency            // value + picker (server-synced)
        case theme                    // value + picker (Appearance)
        case notificationPermission   // OS-permission mirror row
        case navigation(subtitle: String?)
        case action(ActionKind)
    }
    enum ActionKind { case clearCache, contactSupport, signOut, deleteAccount }

    let id: String
    let section: SettingSection
    let title: String
    let systemImage: String
    let keywords: [String]
    let kind: Kind

    var isDestructive: Bool {
        if case let .action(kind) = kind { return kind == .signOut || kind == .deleteAccount }
        return false
    }

    /// Match on title, section name, or any keyword (empty query matches all).
    func matches(_ query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return true }
        if title.lowercased().contains(q) { return true }
        if section.title.lowercased().contains(q) { return true }
        return keywords.contains { $0.lowercased().contains(q) }
    }

    private static func toggleLeaf(_ key: ToggleKey) -> SettingLeaf {
        SettingLeaf(id: key.rawValue, section: key.section, title: key.title,
                    systemImage: key.systemImage, keywords: key.keywords, kind: .toggle(key))
    }

    static let all: [SettingLeaf] = [
        // Account
        SettingLeaf(id: "profile", section: .account, title: "Profile",
                    systemImage: "person.crop.circle",
                    keywords: ["name", "email", "photo", "avatar"],
                    kind: .navigation(subtitle: "Alex Rivera")),
        SettingLeaf(id: "subscription", section: .account, title: "Subscription",
                    systemImage: "creditcard",
                    keywords: ["billing", "plan", "payment", "pro"],
                    kind: .navigation(subtitle: "Pro")),
        SettingLeaf(id: "syncFrequency", section: .account, title: "Sync frequency",
                    systemImage: "arrow.triangle.2.circlepath",
                    keywords: ["sync", "backup", "cloud", "server"],
                    kind: .syncFrequency),
        // Notifications
        SettingLeaf(id: "notifPermission", section: .notifications, title: "System notifications",
                    systemImage: "bell.badge",
                    keywords: ["permission", "allow", "system", "os", "alerts"],
                    kind: .notificationPermission),
        toggleLeaf(.pushAlerts),
        toggleLeaf(.emailNewsletter),
        toggleLeaf(.inAppSounds),
        // Privacy & Security
        toggleLeaf(.biometricLock),
        toggleLeaf(.analyticsSharing),
        toggleLeaf(.crashReports),
        SettingLeaf(id: "blocked", section: .privacy, title: "Blocked accounts",
                    systemImage: "hand.raised",
                    keywords: ["block", "mute", "restrict"],
                    kind: .navigation(subtitle: nil)),
        // Appearance
        SettingLeaf(id: "theme", section: .appearance, title: "Theme",
                    systemImage: "paintbrush",
                    keywords: ["dark", "light", "appearance", "mode", "system"],
                    kind: .theme),
        SettingLeaf(id: "appIcon", section: .appearance, title: "App icon",
                    systemImage: "app.badge",
                    keywords: ["icon", "logo"],
                    kind: .navigation(subtitle: "Default")),
        // About & Help
        SettingLeaf(id: "help", section: .about, title: "Help center",
                    systemImage: "questionmark.circle",
                    keywords: ["faq", "support", "docs"],
                    kind: .navigation(subtitle: nil)),
        SettingLeaf(id: "terms", section: .about, title: "Terms & Privacy",
                    systemImage: "doc.text",
                    keywords: ["legal", "policy", "privacy"],
                    kind: .navigation(subtitle: nil)),
        SettingLeaf(id: "clearCache", section: .about, title: "Clear cache",
                    systemImage: "trash.slash",
                    keywords: ["storage", "cache", "clean"],
                    kind: .action(.clearCache)),
        SettingLeaf(id: "contactSupport", section: .about, title: "Contact support",
                    systemImage: "envelope",
                    keywords: ["email", "help", "support"],
                    kind: .action(.contactSupport)),
        // Destructive — rendered in an ISOLATED section, but kept searchable.
        SettingLeaf(id: "signOut", section: .account, title: "Sign out",
                    systemImage: "rectangle.portrait.and.arrow.forward",
                    keywords: ["logout", "log out", "exit"],
                    kind: .action(.signOut)),
        SettingLeaf(id: "deleteAccount", section: .account, title: "Delete account",
                    systemImage: "trash",
                    keywords: ["remove", "erase", "close account", "delete"],
                    kind: .action(.deleteAccount)),
    ]
}

// MARK: - Reachability (so the offline state is genuine, not faked)

final class SettingsNetworkMonitor: ObservableObject {
    @Published var isOnline = true
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "settings.network.monitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async { self?.isOnline = (path.status == .satisfied) }
        }
        monitor.start(queue: queue)
    }

    deinit { monitor.cancel() }
}

// MARK: - Model (owns preference values + the save / sync / permission logic)

@MainActor
final class SettingsModel: ObservableObject {

    // Local + synced preferences.
    @Published var toggles: [ToggleKey: Bool] = [
        .pushAlerts: true, .emailNewsletter: false, .inAppSounds: true,
        .biometricLock: true, .analyticsSharing: true, .crashReports: false,
    ]
    @Published var syncFrequency: SyncFrequency = .hourly
    @Published var theme: ThemePreference = .system

    /// Phase for server-synced values — drives the synced-value skeleton (loading).
    @Published var syncState: SettingsState = .loading

    /// Cross-cutting confirmations, surfaced as transient banners.
    @Published var saveError: String?       // failed save → revert + message (error)
    @Published var savedMessage: String?    // confirmed save (success)

    /// OS notification permission mirror (permissionDenied path + deep-link).
    @Published var permission: PermissionStatus = .unknown

    private var toastTask: Task<Void, Never>?

    enum SaveError: Error { case failed }

    // MARK: Synced-value load — show the skeleton, then reveal real values.
    func loadSyncedValues() async {
        syncState = .loading
        try? await Task.sleep(for: SettingsTokens.syncDelay)
        // A real app would hydrate syncFrequency / analyticsSharing from the server.
        syncState = .ideal
    }

    // MARK: Toggle write — optimistic, REVERTS on failure (no silent false success).
    func setToggle(_ key: ToggleKey, to newValue: Bool, isOnline: Bool) async {
        let previous = toggles[key] ?? false
        guard previous != newValue else { return }
        toggles[key] = newValue          // optimistic — the switch moves immediately
        saveError = nil
        if key.isServerSynced && !isOnline {
            toggles[key] = previous       // can't reach the server while offline
            flashError("You're offline — reconnect to change \(key.title).")
            return
        }
        do {
            try await persistToggle(key)
            flashSaved("\(key.title) saved")
        } catch {
            toggles[key] = previous       // REVERT — never a silent false success
            flashError("Couldn't save \(key.title). Try again.")
        }
    }

    func setSyncFrequency(_ value: SyncFrequency, isOnline: Bool) async {
        let previous = syncFrequency
        guard previous != value else { return }
        syncFrequency = value
        saveError = nil
        guard isOnline else {
            syncFrequency = previous
            flashError("You're offline — reconnect to change sync frequency.")
            return
        }
        do {
            try await Task.sleep(for: SettingsTokens.saveDelay)
            flashSaved("Sync frequency saved")
        } catch {
            syncFrequency = previous
            flashError("Couldn't save sync frequency. Try again.")
        }
    }

    private func persistToggle(_ key: ToggleKey) async throws {
        try await Task.sleep(for: SettingsTokens.saveDelay)
        if key.failsToSave { throw SaveError.failed }
    }

    // MARK: OS permission mirror + request.
    func refreshPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .denied:                    permission = .denied
        case .notDetermined:             permission = .notDetermined
        case .authorized, .provisional:  permission = .authorized
        default:                         permission = .authorized   // ephemeral etc.
        }
    }

    func requestPermission() async {
        let granted = (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        permission = granted ? .authorized : .denied
    }

    // MARK: Destructive / action outcomes (confirmed inline).
    func signOut()      { flashSaved("Signed out") }
    func deleteAccount(){ flashSaved("Account scheduled for deletion") }
    func clearCache()   { flashSaved("Cache cleared") }

    // MARK: Transient status banner plumbing.
    private func flashSaved(_ message: String) {
        savedMessage = message; saveError = nil
        AccessibilityNotification.Announcement(message).post()
        scheduleClear()
    }
    private func flashError(_ message: String) {
        saveError = message; savedMessage = nil
        AccessibilityNotification.Announcement(message).post()
        scheduleClear()
    }
    private func scheduleClear() {
        toastTask?.cancel()
        toastTask = Task { [weak self] in
            try? await Task.sleep(for: SettingsTokens.toastLinger)
            guard !Task.isCancelled else { return }
            self?.savedMessage = nil
            self?.saveError = nil
        }
    }
}

// MARK: - SettingsScreen

struct SettingsScreen: View {

    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @StateObject private var model = SettingsModel()
    @StateObject private var monitor = SettingsNetworkMonitor()

    @State private var query = ""
    @State private var demoOffline = false
    @State private var selectedSection: SettingSection? = .account
    @State private var path: [String] = []

    // Destructive confirmation state (multi-step for account deletion).
    @State private var confirmSignOut = false
    @State private var confirmDeleteStep1 = false
    @State private var confirmDeleteStep2 = false
    @State private var deleteConfirmText = ""

    private let leaves = SettingLeaf.all

    /// Genuine reachability OR the demo override, so offline is exercisable.
    private var isOnline: Bool { monitor.isOnline && !demoOffline }
    private var isSearching: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: Body — responsive scaffold

    var body: some View {
        GeometryReader { proxy in
            let layout = SettingsLayout(width: proxy.size.width, sizeClass: hSizeClass)
            Group {
                if layout.isCompact { compactScaffold } else { regularScaffold }
            }
            .task { await model.loadSyncedValues() }
            .task { await model.refreshPermission() }
            .preferredColorScheme(model.theme.colorScheme)
            .animation(SettingsTokens.reveal(reduceMotion: reduceMotion), value: layout)
        }
    }

    // MARK: Compact — single scrolling list, sub-pages push (NAV-005)

    private var compactScaffold: some View {
        NavigationStack(path: $path) {
            settingsContent(sections: SettingSection.allCases)
                .navigationTitle("Settings")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .navigationDestination(for: String.self) { id in SettingDetailView(id: id) }
        }
    }

    // MARK: Expanded — two-pane group list + selected group detail (GRD-003)

    private var regularScaffold: some View {
        NavigationSplitView {
            List(selection: $selectedSection) {
                ForEach(SettingSection.allCases) { section in
                    Label(section.title, systemImage: section.systemImage)
                        .frame(minHeight: SettingsTokens.rowMinHeight)
                        .tag(section as SettingSection?)
                }
            }
            .navigationTitle("Settings")
            .frame(minWidth: SettingsTokens.sidebarMinWidth,
                   idealWidth: SettingsTokens.sidebarIdealWidth)
        } detail: {
            NavigationStack(path: $path) {
                settingsContent(sections: detailSections)
                    .navigationTitle(isSearching ? "Search" : (selectedSection?.title ?? "Settings"))
                    .navigationDestination(for: String.self) { id in SettingDetailView(id: id) }
            }
        }
    }

    /// While searching we show matches across ALL sections; otherwise just the
    /// selected group (list-detail).
    private var detailSections: [SettingSection] {
        if isSearching { return SettingSection.allCases }
        if let selectedSection { return [selectedSection] }
        return SettingSection.allCases
    }

    // MARK: Content — search gate + form + banners + confirmations

    @ViewBuilder
    private func settingsContent(sections: [SettingSection]) -> some View {
        let visible = leaves.filter { $0.matches(query) }
        Group {
            if isSearching && visible.isEmpty {
                ContentUnavailableView.search(text: query)   // zero-results (empty)
                    .accessibilityLabel("No results for \(query)")
            } else {
                settingsForm(sections: sections, visible: visible)
            }
        }
        .searchable(text: $query, prompt: "Search settings")
        .background(SettingsTokens.surface)
        .safeAreaInset(edge: .top) { offlineBanner }
        .safeAreaInset(edge: .bottom) { statusBanner }
        .toolbar { demoToolbar }
        .animation(SettingsTokens.reveal(reduceMotion: reduceMotion), value: isOnline)
        .animation(SettingsTokens.reveal(reduceMotion: reduceMotion), value: model.savedMessage)
        .animation(SettingsTokens.reveal(reduceMotion: reduceMotion), value: model.saveError)
        // Sign out — single confirm; label per platform via role: .destructive.
        .confirmationDialog("Sign out of EzHand?", isPresented: $confirmSignOut,
                            titleVisibility: .visible) {
            Button("Sign out", role: .destructive) { model.signOut() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You'll need to sign in again. Your data stays safe.")
        }
        // Delete account — STEP 1 of 2.
        .confirmationDialog("Delete your account?", isPresented: $confirmDeleteStep1,
                            titleVisibility: .visible) {
            Button("Continue", role: .destructive) { confirmDeleteStep2 = true }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This permanently erases your profile, bookings, and history. It can't be undone.")
        }
        // Delete account — STEP 2 of 2 (typed confirmation gate).
        .alert("Confirm account deletion", isPresented: $confirmDeleteStep2) {
            TextField("Type DELETE to confirm", text: $deleteConfirmText)
            Button("Delete account", role: .destructive) {
                model.deleteAccount(); deleteConfirmText = ""
            }
            .disabled(deleteConfirmText != "DELETE")
            Button("Cancel", role: .cancel) { deleteConfirmText = "" }
        } message: {
            Text("Final step. Type DELETE to permanently remove your account.")
        }
    }

    private func settingsForm(sections: [SettingSection], visible: [SettingLeaf]) -> some View {
        Form {
            ForEach(sections) { section in
                let rows = visible.filter { $0.section == section && !$0.isDestructive }
                if !rows.isEmpty {
                    Section {
                        ForEach(rows) { leaf in rowView(leaf) }
                    } header: {
                        sectionHeader(section.title)
                    }
                }
            }
            destructiveSection(visible: visible, sections: sections)
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .frame(maxWidth: SettingsTokens.contentMaxWidth)
        .frame(maxWidth: .infinity)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(SettingsTokens.sectionHeaderFont)
            .foregroundStyle(SettingsTokens.onSurfaceVariant)
            .accessibilityAddTraits(.isHeader)
    }

    // MARK: Isolated destructive zone (bottom, error color, each behind a confirm)

    @ViewBuilder
    private func destructiveSection(visible: [SettingLeaf], sections: [SettingSection]) -> some View {
        let showHere = sections.contains(.account) || isSearching
        let destructive = visible.filter { $0.isDestructive }
        if showHere && !destructive.isEmpty {
            Section {
                if destructive.contains(where: { $0.id == "signOut" }) {
                    Button(role: .destructive) { confirmSignOut = true } label: {
                        destructiveLabel("Sign out", systemImage: "rectangle.portrait.and.arrow.forward")
                    }
                    .frame(minHeight: SettingsTokens.rowMinHeight)
                    .accessibilityHint("Signs you out. Asks for confirmation first.")
                }
                if destructive.contains(where: { $0.id == "deleteAccount" }) {
                    Button(role: .destructive) { confirmDeleteStep1 = true } label: {
                        destructiveLabel("Delete account", systemImage: "trash")
                    }
                    .frame(minHeight: SettingsTokens.rowMinHeight)
                    .accessibilityHint("Permanently deletes your account. Multi-step confirmation.")
                }
            } header: {
                sectionHeader("Account actions")
            } footer: {
                Text("Deleting your account is permanent and can't be undone. Signing out keeps your data.")
                    .font(SettingsTokens.footerFont)
                    .foregroundStyle(SettingsTokens.onSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func destructiveLabel(_ title: String, systemImage: String) -> some View {
        // Red label paired with an icon AND a confirm dialog — never color alone.
        Label(title, systemImage: systemImage)
            .font(SettingsTokens.rowTitleFont)
            .foregroundStyle(SettingsTokens.statusError)
    }

    // MARK: Row rendering (one builder per row type)

    @ViewBuilder
    private func rowView(_ leaf: SettingLeaf) -> some View {
        switch leaf.kind {
        case .toggle(let key):          toggleRow(key)
        case .syncFrequency:            syncFrequencyRow(leaf)
        case .theme:                    themeRow(leaf)
        case .notificationPermission:   permissionRow(leaf)
        case .navigation(let subtitle): navigationRow(leaf, subtitle: subtitle)
        case .action(let kind):         actionRow(leaf, kind: kind)
        }
    }

    // Toggle — announces role (switch) + on/off automatically (A11Y-006).
    private func toggleRow(_ key: ToggleKey) -> some View {
        let disabled = key.isServerSynced && !isOnline
        return Toggle(isOn: toggleBinding(key)) {
            rowLabel(title: key.title, subtitle: key.subtitle, systemImage: key.systemImage)
        }
        .tint(SettingsTokens.actionPrimary)
        .frame(minHeight: SettingsTokens.rowMinHeight)
        .disabled(disabled)
        .accessibilityHint(disabled ? "Unavailable while offline"
                           : (key.isServerSynced ? "Syncs to your account" : ""))
    }

    private func toggleBinding(_ key: ToggleKey) -> Binding<Bool> {
        Binding(
            get: { model.toggles[key] ?? false },
            set: { newValue in Task { await model.setToggle(key, to: newValue, isOnline: isOnline) } }
        )
    }

    // Value + native Picker (server-synced) — skeleton while values sync (loading).
    @ViewBuilder
    private func syncFrequencyRow(_ leaf: SettingLeaf) -> some View {
        if model.syncState == .loading {
            skeletonRow(title: leaf.title, systemImage: leaf.systemImage)
        } else {
            Picker(selection: syncBinding) {
                ForEach(SyncFrequency.allCases) { option in
                    Text(option.title).tag(option)
                }
            } label: {
                rowLabel(title: leaf.title, subtitle: "Keeps devices in sync",
                         systemImage: leaf.systemImage)
            }
            .pickerStyle(.menu)
            .tint(SettingsTokens.onSurfaceVariant)
            .frame(minHeight: SettingsTokens.rowMinHeight)
            .disabled(!isOnline)
            .accessibilityHint(isOnline ? "Server setting" : "Unavailable while offline")
        }
    }

    private var syncBinding: Binding<SyncFrequency> {
        Binding(
            get: { model.syncFrequency },
            set: { value in Task { await model.setSyncFrequency(value, isOnline: isOnline) } }
        )
    }

    // Value + native Picker — light / dark / system theme.
    private func themeRow(_ leaf: SettingLeaf) -> some View {
        Picker(selection: $model.theme) {
            ForEach(ThemePreference.allCases) { pref in
                Text(pref.title).tag(pref)
            }
        } label: {
            rowLabel(title: leaf.title, subtitle: "Light, dark, or match the system",
                     systemImage: leaf.systemImage)
        }
        .pickerStyle(.menu)
        .tint(SettingsTokens.onSurfaceVariant)
        .frame(minHeight: SettingsTokens.rowMinHeight)
        .accessibilityHint("Choose the app appearance")
    }

    // OS-permission mirror — reflects the true state and deep-links to Settings.
    @ViewBuilder
    private func permissionRow(_ leaf: SettingLeaf) -> some View {
        switch model.permission {
        case .authorized:
            statusRow(title: leaf.title, systemImage: leaf.systemImage,
                      valueText: "Allowed", valueColor: SettingsTokens.statusSuccess)
        case .notDetermined, .unknown:
            Button {
                Task { await model.requestPermission() }
            } label: {
                HStack(spacing: SettingsTokens.s2) {
                    rowLabel(title: leaf.title, subtitle: "Turn on to receive alerts",
                             systemImage: leaf.systemImage)
                    Spacer(minLength: SettingsTokens.s2)
                    Text("Turn on").foregroundStyle(SettingsTokens.actionPrimary)
                }
            }
            .frame(minHeight: SettingsTokens.rowMinHeight)
            .accessibilityHint("Requests notification permission")
        case .denied:
            Button { openSystemSettings() } label: {
                HStack(spacing: SettingsTokens.s2) {
                    rowLabel(title: leaf.title, subtitle: "Blocked in system settings",
                             systemImage: leaf.systemImage)
                    Spacer(minLength: SettingsTokens.s2)
                    Text("Open Settings").foregroundStyle(SettingsTokens.actionPrimary)
                }
            }
            .frame(minHeight: SettingsTokens.rowMinHeight)
            .accessibilityHint("Opens system settings to change notification permission")
        }
    }

    // Disclosure — NavigationLink adds a chevron that auto-mirrors in RTL.
    private func navigationRow(_ leaf: SettingLeaf, subtitle: String?) -> some View {
        NavigationLink(value: leaf.id) {
            HStack(spacing: SettingsTokens.s2) {
                rowLabel(title: leaf.title, subtitle: nil, systemImage: leaf.systemImage)
                if let subtitle {
                    Spacer(minLength: SettingsTokens.s2)
                    Text(subtitle)
                        .font(SettingsTokens.rowValueFont)
                        .foregroundStyle(SettingsTokens.onSurfaceVariant)
                }
            }
            .frame(minHeight: SettingsTokens.rowMinHeight)
        }
        .accessibilityHint("Opens \(leaf.title)")
    }

    // Action button (non-destructive).
    private func actionRow(_ leaf: SettingLeaf, kind: SettingLeaf.ActionKind) -> some View {
        Button {
            switch kind {
            case .clearCache:     model.clearCache()
            case .contactSupport: openSupport()
            case .signOut, .deleteAccount: break   // handled in the destructive section
            }
        } label: {
            HStack(spacing: SettingsTokens.s2) {
                rowLabel(title: leaf.title, subtitle: nil, systemImage: leaf.systemImage)
                Spacer(minLength: SettingsTokens.s2)
                Image(systemName: "chevron.forward")
                    .font(SettingsTokens.rowSubtitleFont)
                    .foregroundStyle(SettingsTokens.onSurfaceVariant)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: SettingsTokens.rowMinHeight)
        }
        .tint(SettingsTokens.onSurface)
        .accessibilityHint(kind == .contactSupport ? "Opens support" : "Runs now")
    }

    // MARK: Shared row pieces

    private func rowLabel(title: String, subtitle: String?, systemImage: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: SettingsTokens.s1) {
                Text(title)
                    .font(SettingsTokens.rowTitleFont)
                    .foregroundStyle(SettingsTokens.onSurface)
                    .fixedSize(horizontal: false, vertical: true)   // wrap, don't clip
                if let subtitle {
                    Text(subtitle)
                        .font(SettingsTokens.rowSubtitleFont)
                        .foregroundStyle(SettingsTokens.onSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(SettingsTokens.actionPrimary)
                .accessibilityHidden(true)
        }
    }

    private func statusRow(title: String, systemImage: String,
                           valueText: String, valueColor: Color) -> some View {
        HStack(spacing: SettingsTokens.s2) {
            rowLabel(title: title, subtitle: nil, systemImage: systemImage)
            Spacer(minLength: SettingsTokens.s2)
            Text(valueText)
                .font(SettingsTokens.rowValueFont)
                .foregroundStyle(valueColor)
        }
        .frame(minHeight: SettingsTokens.rowMinHeight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(valueText)")
    }

    // Synced-value loading placeholder (shape-matched skeleton for a picker value).
    private func skeletonRow(title: String, systemImage: String) -> some View {
        HStack(spacing: SettingsTokens.s2) {
            rowLabel(title: title, subtitle: nil, systemImage: systemImage)
            Spacer(minLength: SettingsTokens.s2)
            RoundedRectangle(cornerRadius: SettingsTokens.controlRadius, style: .continuous)
                .fill(SettingsTokens.skeleton)
                .frame(width: SettingsTokens.skeletonValueWidth,
                       height: SettingsTokens.skeletonLineHeight)
        }
        .frame(minHeight: SettingsTokens.rowMinHeight)
        .redacted(reason: .placeholder)
        .accessibilityLabel("\(title), loading")
    }

    // MARK: Banners (non-blocking; opacity/position motion with Reduce-Motion fallback)

    @ViewBuilder private var offlineBanner: some View {
        if !isOnline {
            banner(icon: "wifi.slash",
                   text: "You're offline — local settings still work. Server settings are paused until you reconnect.",
                   tint: SettingsTokens.statusWarning)
                .accessibilityLabel("You're offline. Local settings still work. Server settings are paused until you reconnect.")
                .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
        }
    }

    @ViewBuilder private var statusBanner: some View {
        if let error = model.saveError {
            banner(icon: "exclamationmark.triangle.fill", text: error,
                   tint: SettingsTokens.statusError)
                .accessibilityLabel(error)
                .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
        } else if let saved = model.savedMessage {
            banner(icon: "checkmark.circle.fill", text: saved,
                   tint: SettingsTokens.statusSuccess)
                .accessibilityLabel(saved)
                .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func banner(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: SettingsTokens.s2) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(text)
                .font(SettingsTokens.bannerFont)
                .foregroundStyle(SettingsTokens.onSurface)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: SettingsTokens.s2)
        }
        .padding(.horizontal, SettingsTokens.s4)
        .padding(.vertical, SettingsTokens.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SettingsTokens.surfaceContainer)
        .accessibilityElement(children: .combine)
    }

    // MARK: Demo toolbar (exercise the offline state without leaving the preview)

    @ToolbarContentBuilder private var demoToolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Toggle("Simulate offline", isOn: $demoOffline)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .frame(minWidth: SettingsTokens.targetMin, minHeight: SettingsTokens.targetMin)
                    .contentShape(.rect)
            }
            .accessibilityLabel("Settings demo options")
        }
    }

    // MARK: iOS-only deep link (guarded)

    private func openSupport() {
        #if os(iOS)
        if let url = URL(string: "https://ezhands.co/support") {
            UIApplication.shared.open(url)
        }
        #endif
    }

    private func openSystemSettings() {
        #if os(iOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }
}

// MARK: - Sub-page detail (the disclosure drill-in / two-pane detail)

private struct SettingDetailView: View {
    let id: String

    private var leaf: SettingLeaf? { SettingLeaf.all.first { $0.id == id } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SettingsTokens.s4) {
                Text(leaf?.title ?? "Details")
                    .font(SettingsTokens.screenTitleFont)
                    .fontWeight(.semibold)
                    .foregroundStyle(SettingsTokens.onSurface)
                Text("This sub-page stands in for the detailed \(leaf?.title ?? "settings") screen. On a wide window it fills the detail pane; on a phone it pushes.")
                    .font(SettingsTokens.rowTitleFont)
                    .foregroundStyle(SettingsTokens.onSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: SettingsTokens.s2)
            }
            .padding(.horizontal, SettingsTokens.s4)
            .padding(.top, SettingsTokens.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(SettingsTokens.surface)
        .navigationTitle(leaf?.title ?? "Details")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

// MARK: - Previews

#Preview("Settings") {
    SettingsScreen()
}

#Preview("Dark / Accessibility type") {
    SettingsScreen()
        .preferredColorScheme(.dark)
        .dynamicTypeSize(.accessibility3)
}
