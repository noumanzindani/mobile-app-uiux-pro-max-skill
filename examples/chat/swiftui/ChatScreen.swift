//  ChatScreen.swift
//  An accessible, all-states 1:1 chat screen with optimistic send (see ../spec.md).
//
//  Highlights:
//   • 7 explicit screen states via `ChatStatus` (idle, empty, loading, error,
//     offline, success, permissionDenied) — no boolean soup.
//   • Optimistic send: an outgoing bubble appears instantly, then transitions
//     sending → sent → delivered → read; a failure shows a badge + tap-to-retry
//     (content preserved); offline sends are queued and auto-flush on reconnect.
//   • Delivery status is icon + TEXT (never color-only); each bubble is one
//     accessibility element read as "sender, message, time, status".
//   • Virtualized LazyVStack list, newest at the bottom, scroll-to-latest, a
//     "N new messages" pill, and per-day date separators.
//   • Composer (attach · growing field · send) rides above the keyboard via
//     .safeAreaInset(edge: .bottom); a non-blocking offline banner rides the top.
//   • Own vs other bubbles align to opposite sides using logical leading/trailing
//     so they mirror automatically in RTL — never physical/absolute directions.
//   • Typing dots pause under Reduce Motion and are exposed as status text;
//     incoming messages announce via AccessibilityNotification.Announcement.
//   • Every design value comes from ChatTokens — no literals in this file.

import SwiftUI
import Network
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Domain models

/// The optimistic-send lifecycle. Conveyed as icon + text, never color alone.
enum MessageStatus: Equatable {
    case sending, sent, delivered, read, failed, queued

    var iconName: String {
        switch self {
        case .sending:   return "clock"
        case .sent:      return "checkmark"
        case .delivered: return "checkmark.circle"
        case .read:      return "checkmark.circle.fill"
        case .failed:    return "exclamationmark.circle"
        case .queued:    return "arrow.up.circle.dotted"
        }
    }

    /// The redundant text equivalent so status never depends on color/shape alone.
    var label: String {
        switch self {
        case .sending:   return "Sending"
        case .sent:      return "Sent"
        case .delivered: return "Delivered"
        case .read:      return "Read"
        case .failed:    return "Failed"
        case .queued:    return "Queued"
        }
    }

    /// Applied to the *icon* only (a graphical object, WCAG ≥ 3:1). The label text
    /// stays on the high-contrast muted role so small text keeps ≥ 4.5:1.
    var iconTint: Color {
        switch self {
        case .failed: return ChatTokens.statusError
        case .read:   return ChatTokens.statusInfo
        default:      return ChatTokens.onSurfaceMuted
        }
    }
}

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let text: String
    let isOwn: Bool
    let senderName: String
    let timestamp: Date
    var status: MessageStatus
}

// MARK: - Screen state (the mandatory 7-state model)

enum ChatStatus: Equatable {
    case idle
    case empty
    case loading
    case error
    case offline
    case success
    case permissionDenied
}

// MARK: - Reachability

/// Real connectivity so the offline state is genuine rather than faked.
final class NetworkMonitor: ObservableObject {
    @Published var isOnline = true
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "chat.network.monitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async { self?.isOnline = (path.status == .satisfied) }
        }
        monitor.start(queue: queue)
    }

    deinit { monitor.cancel() }
}

// MARK: - View model

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var status: ChatStatus = .loading
    @Published var draft: String = ""
    @Published var isOnline: Bool = true
    @Published var isPeerTyping: Bool = false

    let peerName: String
    private let selfName = "You"

    init(peerName: String) { self.peerName = peerName }

    var peerInitials: String {
        peerName.split(separator: " ").compactMap { $0.first }.map(String.init).joined()
    }

    var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: History

    func load() async {
        status = .loading
        try? await Task.sleep(for: ChatTokens.loadDelay)
        messages = ChatViewModel.seed(peerName: peerName)
        status = deriveIdleStatus()
        // Bring the peer to life so typing + announcements are demonstrable.
        Task { await self.simulateIncoming() }
    }

    /// History-load failure that keeps any cached messages on screen.
    func failLoadDemo() {
        status = .error
    }

    private func deriveIdleStatus() -> ChatStatus {
        if !isOnline { return .offline }
        return messages.isEmpty ? .empty : .idle
    }

    // MARK: Optimistic send

    func send() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        draft = ""
        let online = isOnline
        let message = ChatMessage(
            id: UUID(), text: text, isOwn: true, senderName: selfName,
            timestamp: Date(), status: online ? .sending : .queued
        )
        messages.append(message)               // optimistic: appears instantly
        status = .success
        if online {
            Task { await deliver(message.id, text: text) }
        }
    }

    func retry(_ id: UUID) {
        guard let message = messages.first(where: { $0.id == id }) else { return }
        guard isOnline else { update(id) { $0.status = .queued }; return }
        update(id) { $0.status = .sending }
        Task { await deliver(id, text: message.text) }
    }

    private func deliver(_ id: UUID, text: String) async {
        try? await Task.sleep(for: ChatTokens.sendStep)
        // Demo failure trigger: any message containing "fail" is rejected once.
        if text.lowercased().contains("fail") {
            update(id) { $0.status = .failed }
            announce("Message failed to send. Double-tap to retry.")
            return
        }
        update(id) { $0.status = .sent }
        try? await Task.sleep(for: ChatTokens.sendStep)
        update(id) { $0.status = .delivered }
        try? await Task.sleep(for: ChatTokens.sendStep)
        update(id) { $0.status = .read }
    }

    // MARK: Offline queue + flush

    func setOnline(_ online: Bool) {
        let wasOnline = isOnline
        isOnline = online
        if online {
            if !wasOnline { flushQueue() }
            if status == .offline { status = deriveIdleStatus() }
        } else {
            status = .offline
        }
    }

    private func flushQueue() {
        for message in messages where message.status == .queued {
            update(message.id) { $0.status = .sending }
            Task { await deliver(message.id, text: message.text) }
        }
    }

    // MARK: Incoming (typing indicator + live-region announcement)

    func simulateIncoming() async {
        isPeerTyping = true
        announce("\(peerName) is typing")
        try? await Task.sleep(for: ChatTokens.typingDuration)
        isPeerTyping = false
        let message = ChatMessage(
            id: UUID(), text: "Sounds good — see you then!",
            isOwn: false, senderName: peerName, timestamp: Date(), status: .delivered
        )
        messages.append(message)
        if status == .empty { status = .idle }
        announce("New message from \(peerName): \(message.text)")
    }

    // MARK: Helpers

    private func update(_ id: UUID, _ transform: (inout ChatMessage) -> Void) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        var copy = messages[index]
        transform(&copy)
        messages[index] = copy
    }

    private func announce(_ message: String) {
        AccessibilityNotification.Announcement(message).post()
    }

    static func seed(peerName: String) -> [ChatMessage] {
        let now = Date()
        return [
            ChatMessage(id: UUID(), text: "Hey! Are we still on for tomorrow?",
                        isOwn: false, senderName: peerName,
                        timestamp: now.addingTimeInterval(-3_600), status: .delivered),
            ChatMessage(id: UUID(), text: "Absolutely. 10am at the studio works for me.",
                        isOwn: true, senderName: "You",
                        timestamp: now.addingTimeInterval(-3_300), status: .read),
            ChatMessage(id: UUID(), text: "Perfect, I'll bring the prints.",
                        isOwn: false, senderName: peerName,
                        timestamp: now.addingTimeInterval(-3_000), status: .delivered),
        ]
    }
}

// MARK: - ChatScreen

struct ChatScreen: View {

    var onBack: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @StateObject private var vm = ChatViewModel(peerName: "Alex Morgan")
    @StateObject private var monitor = NetworkMonitor()

    @State private var isAtBottom = true
    @State private var unreadCount = 0
    @State private var showAttachSheet = false
    @State private var attachDenied = false
    @State private var demoOffline = false

    @FocusState private var composerFocused: Bool

    private let bottomAnchor = "chat.bottom.anchor"

    /// The genuine monitor OR the demo override, so the offline flow is exercisable.
    private var effectiveOnline: Bool { monitor.isOnline && !demoOffline }

    private var presenceText: String {
        if !vm.isOnline { return "Offline" }
        return vm.isPeerTyping ? "typing\u{2026}" : "Active now"
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            chatSurface
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar { toolbarContent }
        }
        .task {
            vm.setOnline(effectiveOnline)
            await vm.load()
        }
        .onChange(of: effectiveOnline) { _, online in vm.setOnline(online) }
        .sheet(isPresented: $showAttachSheet) { attachSheet }
    }

    // MARK: Chat surface (list + pill + banner + composer)

    private var chatSurface: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .bottom) {
                content
                newMessagesPill(proxy: proxy)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ChatTokens.surface)
            .safeAreaInset(edge: .top) { offlineBanner }
            .safeAreaInset(edge: .bottom) { composer }
            .onChange(of: vm.messages.count) { old, new in
                onMessageCountChange(old: old, new: new, proxy: proxy)
            }
            .onAppear { scrollToBottom(proxy, animated: false) }
        }
    }

    // MARK: State-driven content

    @ViewBuilder private var content: some View {
        switch vm.status {
        case .loading:
            loadingSkeleton
        case .empty:
            emptyPrompt
        default:
            VStack(spacing: 0) {
                if vm.status == .error { errorBanner }
                if vm.messages.isEmpty {
                    emptyPrompt
                } else {
                    messageScroll
                }
            }
        }
    }

    // MARK: Virtualized, newest-at-bottom message list

    private var messageScroll: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: ChatTokens.s2) {
                ForEach(rows) { row in
                    switch row.kind {
                    case .date(let date):
                        DateSeparator(date: date)
                            .frame(maxWidth: .infinity)
                    case .message(let message):
                        MessageBubble(message: message, reduceMotion: reduceMotion) {
                            vm.retry(message.id)
                        }
                        .id(message.id)
                        .transition(bubbleTransition)
                    }
                }
                if vm.isPeerTyping {
                    TypingIndicator(name: vm.peerName)
                        .transition(bubbleTransition)
                }
                // Bottom sentinel: tracks whether the newest message is on screen.
                Color.clear
                    .frame(height: ChatTokens.hairline)
                    .id(bottomAnchor)
                    .onAppear { isAtBottom = true; unreadCount = 0 }
                    .onDisappear { isAtBottom = false }
            }
            .padding(.horizontal, ChatTokens.s4)
            .padding(.vertical, ChatTokens.s3)
            .animation(ChatTokens.reveal(reduceMotion: reduceMotion), value: vm.messages)
            .animation(ChatTokens.reveal(reduceMotion: reduceMotion), value: vm.isPeerTyping)
        }
        .scrollDismissesKeyboard(.interactively)
        .defaultScrollAnchor(.bottom)
    }

    /// Interleaves per-day separators with messages, keyed for stable identity.
    private var rows: [ChatRow] {
        var out: [ChatRow] = []
        var lastDay: DateComponents?
        let calendar = Calendar.current
        for message in vm.messages {
            let day = calendar.dateComponents([.year, .month, .day], from: message.timestamp)
            if day != lastDay {
                out.append(ChatRow(id: "date-\(message.timestamp.timeIntervalSince1970)",
                                   kind: .date(message.timestamp)))
                lastDay = day
            }
            out.append(ChatRow(id: message.id.uuidString, kind: .message(message)))
        }
        return out
    }

    // MARK: "N new messages" pill

    @ViewBuilder private func newMessagesPill(proxy: ScrollViewProxy) -> some View {
        if unreadCount > 0 {
            Button {
                scrollToBottom(proxy)
                unreadCount = 0
            } label: {
                Label("\(unreadCount) new messages", systemImage: "arrow.down")
                    .font(ChatTokens.pillFont)
                    .foregroundStyle(ChatTokens.onChatSelf)
                    .padding(.horizontal, ChatTokens.s4)
                    .padding(.vertical, ChatTokens.s2)
                    .frame(minHeight: ChatTokens.targetMin)
                    .background(ChatTokens.chatSelfBg, in: Capsule())
            }
            .padding(.bottom, ChatTokens.s3)
            .accessibilityLabel("\(unreadCount) new messages, scroll to latest")
            .transition(reduceMotion ? .opacity
                        : .opacity.combined(with: .move(edge: .bottom)))
        }
    }

    // MARK: Loading skeleton

    private var loadingSkeleton: some View {
        VStack(alignment: .leading, spacing: ChatTokens.s3) {
            ForEach(0..<6, id: \.self) { index in
                SkeletonBubble(isOwn: index.isMultiple(of: 2))
            }
        }
        .padding(.horizontal, ChatTokens.s4)
        .padding(.vertical, ChatTokens.s3)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .accessibilityElement()
        .accessibilityLabel("Loading conversation")
    }

    // MARK: Empty (first-message prompt)

    private var emptyPrompt: some View {
        VStack(spacing: ChatTokens.s4) {
            Image(systemName: "hand.wave.fill")
                .font(ChatTokens.emptyIconFont)
                .foregroundStyle(ChatTokens.actionPrimary)
                .accessibilityHidden(true)
            Text("Say hi \u{1F44B}")
                .font(ChatTokens.emptyTitleFont)
                .foregroundStyle(ChatTokens.onSurface)
            Text("This is the start of your conversation with \(vm.peerName). Send the first message.")
                .font(ChatTokens.emptyBodyFont)
                .foregroundStyle(ChatTokens.onSurfaceMuted)
                .multilineTextAlignment(.center)
        }
        .padding(ChatTokens.s6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }

    // MARK: Error banner (history load failed, cached messages kept)

    private var errorBanner: some View {
        HStack(spacing: ChatTokens.s2) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(ChatTokens.statusError)
                .accessibilityHidden(true)
            Text("Couldn't load messages.")
                .font(ChatTokens.bannerFont)
                .foregroundStyle(ChatTokens.onSurface)
            Spacer(minLength: ChatTokens.s2)
            Button("Retry") { Task { await vm.load() } }
                .font(ChatTokens.bannerFont)
                .foregroundStyle(ChatTokens.actionPrimary)
                .padding(.horizontal, ChatTokens.s3)
                .frame(minHeight: ChatTokens.targetMin)
        }
        .padding(.horizontal, ChatTokens.s4)
        .padding(.vertical, ChatTokens.s2)
        .background(ChatTokens.surfaceContainer)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Couldn't load messages. Retry available.")
    }

    // MARK: Offline banner (non-blocking, top safe-area)

    @ViewBuilder private var offlineBanner: some View {
        if !vm.isOnline {
            HStack(spacing: ChatTokens.s2) {
                Image(systemName: "wifi.slash")
                    .accessibilityHidden(true)
                Text("You're offline \u{2014} messages send when you reconnect.")
                    .font(ChatTokens.bannerFont)
                Spacer(minLength: ChatTokens.s2)
            }
            .foregroundStyle(ChatTokens.onSurface)
            .padding(.horizontal, ChatTokens.s4)
            .padding(.vertical, ChatTokens.s2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ChatTokens.surfaceContainer)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("You're offline. Messages will send when you reconnect.")
            .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: Composer (attach · growing field · send) — rides above the keyboard

    private var composer: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(alignment: .bottom, spacing: ChatTokens.s2) {
                attachButton
                TextField("Message", text: $vm.draft, axis: .vertical)
                    .font(ChatTokens.bubbleFont)
                    .lineLimit(ChatTokens.composerMinLines...ChatTokens.composerMaxLines)
                    .focused($composerFocused)
                    .padding(.horizontal, ChatTokens.s3)
                    .padding(.vertical, ChatTokens.s2)
                    .frame(minHeight: ChatTokens.targetMin)
                    .background(ChatTokens.surfaceContainer, in: Capsule())
                    .accessibilityLabel("Message")
                sendButton
            }
            .padding(.horizontal, ChatTokens.s3)
            .padding(.vertical, ChatTokens.s2)
        }
        .background(.bar)
    }

    private var attachButton: some View {
        Button { showAttachSheet = true } label: {
            Image(systemName: "plus")
                .font(ChatTokens.composerIconFont)
                .foregroundStyle(ChatTokens.actionPrimary)
                .frame(minWidth: ChatTokens.targetMin, minHeight: ChatTokens.targetMin)
                .contentShape(.rect)
        }
        .accessibilityLabel("Add attachment")
        .accessibilityHint("Photo library or files")
    }

    private var sendButton: some View {
        Button {
            vm.send()
            composerFocused = true
        } label: {
            Image(systemName: "arrow.up.circle.fill")
                .font(ChatTokens.composerIconFont)
                .foregroundStyle(vm.canSend ? ChatTokens.actionPrimary : ChatTokens.onSurfaceMuted)
                .frame(minWidth: ChatTokens.targetMin, minHeight: ChatTokens.targetMin)
                .contentShape(.rect)
        }
        .disabled(!vm.canSend)
        .accessibilityLabel("Send message")
        .accessibilityHint(vm.canSend ? "Sends your message" : "Type a message first")
    }

    // MARK: Nav bar

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: onBack) {
                Image(systemName: "chevron.backward")   // mirrors in RTL
                    .frame(minWidth: ChatTokens.targetMin, minHeight: ChatTokens.targetMin)
                    .contentShape(.rect)
            }
            .accessibilityLabel("Back")
        }
        ToolbarItem(placement: .principal) {
            HStack(spacing: ChatTokens.s2) {
                Circle()
                    .fill(ChatTokens.chatOtherBg)
                    .frame(width: ChatTokens.avatarSize, height: ChatTokens.avatarSize)
                    .overlay(
                        Text(vm.peerInitials)
                            .font(ChatTokens.statusFont)
                            .foregroundStyle(ChatTokens.onChatOther)
                    )
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: ChatTokens.s1) {
                    Text(vm.peerName)
                        .font(ChatTokens.navTitleFont)
                        .foregroundStyle(ChatTokens.onSurface)
                    Text(presenceText)
                        .font(ChatTokens.navSubtitleFont)
                        .foregroundStyle(ChatTokens.onSurfaceMuted)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(vm.peerName), \(presenceText)")
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button { Task { await vm.simulateIncoming() } } label: {
                    Label("Simulate incoming", systemImage: "tray.and.arrow.down")
                }
                Button { vm.failLoadDemo() } label: {
                    Label("Simulate load error", systemImage: "exclamationmark.triangle")
                }
                Button { demoOffline.toggle() } label: {
                    Label(demoOffline ? "Go online (demo)" : "Go offline (demo)",
                          systemImage: demoOffline ? "wifi" : "wifi.slash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .frame(minWidth: ChatTokens.targetMin, minHeight: ChatTokens.targetMin)
                    .contentShape(.rect)
            }
            .accessibilityLabel("More options")
        }
    }

    // MARK: Attachment sheet (with permission-denied fallback)

    private var attachSheet: some View {
        Group {
            if attachDenied {
                ContentUnavailableView {
                    Label("Photo access is off", systemImage: "photo.on.rectangle")
                } description: {
                    Text("Enable photo access in Settings, or attach a file instead. Your chat keeps working.")
                } actions: {
                    Button("Open Settings") { openSettings() }
                        .buttonStyle(.borderedProminent)
                    Button("Choose a file instead") { dismissAttach() }
                        .buttonStyle(.bordered)
                }
                .accessibilityLabel("Photo access is off. Open Settings or choose a file instead.")
            } else {
                VStack(spacing: ChatTokens.s4) {
                    Text("Add to conversation")
                        .font(ChatTokens.navTitleFont)
                        .foregroundStyle(ChatTokens.onSurface)
                    Button { requestPhotos() } label: {
                        Label("Photo Library", systemImage: "photo")
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: ChatTokens.targetMin)
                    }
                    .buttonStyle(.bordered)
                    Button { dismissAttach() } label: {
                        Label("Files", systemImage: "folder")
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: ChatTokens.targetMin)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(ChatTokens.s6)
                .frame(maxWidth: .infinity)
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: Scroll + change handling

    private func onMessageCountChange(old: Int, new: Int, proxy: ScrollViewProxy) {
        guard new > old, let last = vm.messages.last else { return }
        if last.isOwn || isAtBottom {
            scrollToBottom(proxy)
            unreadCount = 0
        } else {
            unreadCount += 1   // an incoming arrived while scrolled up → surface the pill
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy, animated: Bool = true) {
        if animated && !reduceMotion {
            withAnimation(ChatTokens.reveal(reduceMotion: reduceMotion)) {
                proxy.scrollTo(bottomAnchor, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(bottomAnchor, anchor: .bottom)
        }
        isAtBottom = true
    }

    // MARK: Attachment behavior

    private func requestPhotos() {
        // Demo: simulate a denied authorization to exercise the permission-denied
        // path. Production would call PHPhotoLibrary.requestAuthorization(...).
        attachDenied = true
        vm.status = .permissionDenied
    }

    private func dismissAttach() {
        showAttachSheet = false
        attachDenied = false
        if vm.status == .permissionDenied {
            vm.status = vm.messages.isEmpty ? .empty : .idle
        }
    }

    private var bubbleTransition: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .bottom))
    }

    private func openSettings() {
        #if canImport(UIKit)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }
}

// MARK: - Row model

private struct ChatRow: Identifiable {
    enum Kind { case date(Date); case message(ChatMessage) }
    let id: String
    let kind: Kind
}

// MARK: - Message bubble

struct MessageBubble: View {
    let message: ChatMessage
    let reduceMotion: Bool
    var onRetry: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            if message.isOwn { Spacer(minLength: ChatTokens.bubbleGutter) }
            VStack(alignment: message.isOwn ? .trailing : .leading, spacing: ChatTokens.s1) {
                if !message.isOwn {
                    Text(message.senderName)
                        .font(ChatTokens.statusFont)
                        .foregroundStyle(ChatTokens.onSurfaceMuted)
                }
                bubbleText
                metaRow
                if message.status == .failed && message.isOwn {
                    retryButton
                }
            }
            if !message.isOwn { Spacer(minLength: ChatTokens.bubbleGutter) }
        }
        .frame(maxWidth: .infinity, alignment: message.isOwn ? .trailing : .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(message.status == .failed ? .isButton : [])
        .accessibilityAction(named: "Retry") { if message.status == .failed { onRetry() } }
    }

    private var bubbleText: some View {
        Text(message.text)
            .font(ChatTokens.bubbleFont)
            .foregroundStyle(message.isOwn ? ChatTokens.onChatSelf : ChatTokens.onChatOther)
            .padding(.horizontal, ChatTokens.s3)
            .padding(.vertical, ChatTokens.s2)
            .background(
                message.isOwn ? ChatTokens.chatSelfBg : ChatTokens.chatOtherBg,
                in: RoundedRectangle(cornerRadius: ChatTokens.bubbleRadius, style: .continuous)
            )
            .frame(maxWidth: ChatTokens.bubbleMaxWidth,
                   alignment: message.isOwn ? .trailing : .leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var metaRow: some View {
        HStack(spacing: ChatTokens.s1) {
            Text(message.timestamp, style: .time)
                .font(ChatTokens.timestampFont)
                .foregroundStyle(ChatTokens.onSurfaceMuted)
            if message.isOwn {
                Image(systemName: message.status.iconName)
                    .imageScale(.small)
                    .foregroundStyle(message.status.iconTint)   // icon = graphical ≥ 3:1
                    .contentTransition(.symbolEffect(.replace))
                Text(message.status.label)                      // + text ≥ 4.5:1, not color-only
                    .font(ChatTokens.statusFont)
                    .foregroundStyle(ChatTokens.onSurfaceMuted)
            }
        }
        .animation(ChatTokens.statusChange(reduceMotion: reduceMotion), value: message.status)
        .accessibilityHidden(true)   // folded into the bubble's combined label
    }

    private var retryButton: some View {
        Button(action: onRetry) {
            HStack(spacing: ChatTokens.s1) {
                Image(systemName: "arrow.clockwise")
                Text("Tap to retry")
                    .font(ChatTokens.statusFont)
            }
            .foregroundStyle(ChatTokens.onSurface)
            .padding(.horizontal, ChatTokens.s2)
            .frame(minHeight: ChatTokens.targetMin)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Retry sending message")
    }

    /// Read by VoiceOver as one coherent element: sender, message, time, status.
    private var accessibilityText: String {
        let sender = message.isOwn ? "You" : message.senderName
        let time = message.timestamp.formatted(date: .omitted, time: .shortened)
        var text = "\(sender), \(message.text), \(time)"
        if message.isOwn { text += ", \(message.status.label)" }
        return text
    }
}

// MARK: - Date separator

struct DateSeparator: View {
    let date: Date

    var body: some View {
        Text(date, format: .dateTime.weekday(.wide).month().day())
            .font(ChatTokens.sectionDateFont)
            .foregroundStyle(ChatTokens.onSurfaceMuted)
            .padding(.horizontal, ChatTokens.s3)
            .padding(.vertical, ChatTokens.s1)
            .frame(maxWidth: .infinity, alignment: .center)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Typing indicator (paused under Reduce Motion, exposed as status text)

struct TypingIndicator: View {
    let name: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animating = false

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: ChatTokens.s1) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(ChatTokens.onSurfaceMuted)
                        .frame(width: ChatTokens.typingDotSize, height: ChatTokens.typingDotSize)
                        .opacity(reduceMotion ? 1 : (animating ? 1 : ChatTokens.dotDimOpacity))
                        .animation(
                            ChatTokens.typingLoop(reduceMotion: reduceMotion)?
                                .delay(Double(index) * ChatTokens.typingStagger),
                            value: animating
                        )
                }
            }
            .padding(.horizontal, ChatTokens.s3)
            .padding(.vertical, ChatTokens.s2)
            .background(ChatTokens.chatOtherBg,
                        in: RoundedRectangle(cornerRadius: ChatTokens.bubbleRadius, style: .continuous))
            Spacer(minLength: ChatTokens.bubbleGutter)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { if !reduceMotion { animating = true } }
        .accessibilityElement()
        .accessibilityLabel("\(name) is typing")
    }
}

// MARK: - Skeleton bubble (loading)

struct SkeletonBubble: View {
    let isOwn: Bool

    var body: some View {
        HStack(spacing: 0) {
            if isOwn { Spacer(minLength: ChatTokens.bubbleGutter) }
            RoundedRectangle(cornerRadius: ChatTokens.bubbleRadius, style: .continuous)
                .fill(ChatTokens.surfaceContainer)
                .frame(width: ChatTokens.skeletonWidth, height: ChatTokens.skeletonHeight)
            if !isOwn { Spacer(minLength: ChatTokens.bubbleGutter) }
        }
        .frame(maxWidth: .infinity, alignment: isOwn ? .trailing : .leading)
        .accessibilityHidden(true)
    }
}

// MARK: - Previews

#Preview("Chat") {
    ChatScreen()
}

#Preview("Dark / Accessibility type") {
    ChatScreen()
        .preferredColorScheme(.dark)
        .dynamicTypeSize(.accessibility3)
}
