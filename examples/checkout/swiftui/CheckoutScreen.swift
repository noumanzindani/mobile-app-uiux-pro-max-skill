//  CheckoutScreen.swift
//  A trustworthy, all-states checkout with an idempotent, un-double-chargeable
//  payment (see ../spec.md).
//
//  Highlights:
//   • 8 explicit states via `CheckoutStatus` (ideal, empty, loading, processing,
//     error, offline, success, permissionDenied) — no boolean soup. Payment
//     processing is the safety-critical one.
//   • ALWAYS-VISIBLE, itemized order summary (subtotal / shipping / tax /
//     discount / total) with tabular figures and locale currency via
//     `.formatted(.currency(code:))` — no surprise total at the end.
//   • Prominent guest checkout; a native Apple Pay shortcut surfaced early
//     (`PayWithApplePayButton`, guarded `#if os(iOS)` with a macOS fallback).
//   • Address + payment forms that allow paste / autofill / password managers
//     (`.textContentType`, number-pad keyboards guarded `#if os(iOS)`); the card
//     field is paste-safe and never blocks a paste.
//   • Idempotent submit: a client idempotency key + the button disabling and
//     spinning the instant it's tapped make a second tap — and a double charge —
//     impossible. Every attempt resolves to a definitive success or a recoverable
//     failure; offline BLOCKS the charge with a reason and preserves all entries.
//   • A STICKY, full-width primary button shows the amount, pinned with
//     `.safeAreaInset(edge: .bottom)` so it rides above the keyboard.
//   • Totals changes, "Processing payment", and the result are announced via
//     `AccessibilityNotification.Announcement`. Motion is opacity/number only and
//     collapses under Reduce Motion. Every design value comes from CheckoutTokens.

import SwiftUI
import Network
#if canImport(UIKit)
import UIKit
#endif
#if os(iOS)
import PassKit
#endif

// MARK: - State model (the mandatory, safety-critical state map)

/// The explicit checkout states. `processing` is the safety-critical one: while
/// in it the Pay button is disabled and spinning, so no second charge is possible.
enum CheckoutStatus: Equatable {
    case ideal
    case empty
    case loading
    case processing
    case error
    case offline
    case success
    case permissionDenied
}

/// Which payment instrument the shopper has chosen.
enum PaymentMethod: Equatable {
    case applePay
    case savedCard
    case newCard
}

// MARK: - Domain models

struct LineItem: Identifiable, Equatable {
    let id: UUID
    var name: String
    var detail: String
    var quantity: Int
    var unitPrice: Decimal

    var lineTotal: Decimal { unitPrice * Decimal(quantity) }
}

/// A confirmed order — everything the success screen needs to be a real receipt.
struct PlacedOrder: Equatable {
    let number: String
    let total: Decimal
    let email: String
    let etaText: String
}

// MARK: - Reachability

/// Real connectivity, so the offline state is genuine rather than faked.
final class CheckoutNetworkMonitor: ObservableObject {
    @Published var isOnline = true
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "checkout.network.monitor")

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
final class CheckoutViewModel: ObservableObject {
    @Published var status: CheckoutStatus = .loading
    @Published var items: [LineItem]
    @Published var method: PaymentMethod = .applePay
    @Published var isOnline = true
    @Published var errorMessage = ""
    @Published var placedOrder: PlacedOrder?

    // Guest by default — the account ask is deferred to after purchase.
    @Published var isGuest = true

    // Address (all paste / autofill friendly in the view).
    @Published var email = ""
    @Published var fullName = ""
    @Published var addressLine = ""
    @Published var city = ""
    @Published var region = ""
    @Published var postalCode = ""

    // New-card entry (paste-safe; never blocks a paste).
    @Published var cardNumber = ""
    @Published var cardExpiry = ""
    @Published var cardCVV = ""

    // Demo levers so every state is reachable from the toolbar.
    @Published var simulateDecline = false
    @Published var applePayAvailable = true

    /// Client-side idempotency key. Stable across retries of THIS order attempt so
    /// a retry or a network hiccup reconciles instead of creating a second charge;
    /// it only rotates once an order is definitively placed.
    private(set) var idempotencyKey = UUID()

    private let savedCardLast4 = "4242"
    private let promoCode = "WELCOME10"

    init(items: [LineItem]) {
        self.items = items
    }

    // MARK: Money — locale currency + honest, itemized totals

    var currencyCode: String { Locale.current.currency?.identifier ?? "USD" }

    func money(_ amount: Decimal) -> String {
        amount.formatted(.currency(code: currencyCode))
    }

    var subtotal: Decimal { items.reduce(Decimal(0)) { $0 + $1.lineTotal } }

    /// Free shipping over a threshold, otherwise a flat rate. Honest and shown.
    var shipping: Decimal {
        if items.isEmpty { return Decimal(0) }
        return subtotal >= freeShippingThreshold ? Decimal(0) : flatShipping
    }

    var discount: Decimal {
        // A single applied promo, surfaced as its own line so nothing is hidden.
        items.isEmpty ? Decimal(0) : (subtotal * promoRate)
    }

    var tax: Decimal { (subtotal - discount) * taxRate }

    var total: Decimal { subtotal + shipping + tax - discount }

    var formattedTotal: String { money(total) }

    var itemCount: Int { items.reduce(0) { $0 + $1.quantity } }

    // Business rates (data, not design tokens).
    private var freeShippingThreshold: Decimal { 75 }
    private var flatShipping: Decimal { Decimal(string: "6.95") ?? 0 }
    private var taxRate: Decimal { Decimal(string: "0.0825") ?? 0 }
    private var promoRate: Decimal { Decimal(string: "0.10") ?? 0 }

    var savedCardLabel: String { "Visa ending in \(savedCardLast4)" }
    var appliedPromoLabel: String { "Promo \(promoCode)" }

    // MARK: Derived

    /// The single source of truth for whether a charge may be started. Being false
    /// while `.processing` is exactly what makes a second tap impossible.
    var canPay: Bool {
        status != .processing
            && status != .success
            && status != .loading
            && !items.isEmpty
            && isOnline
    }

    var payButtonTitle: String {
        switch status {
        case .processing: return "Processing\u{2026}"
        case .success:    return "Paid"
        default:          return "Pay \(formattedTotal)"
        }
    }

    /// Spoken label always carries the amount, even while the visible label reads
    /// "Processing…", so VoiceOver users always know what they are paying.
    var payAccessibilityLabel: String {
        switch status {
        case .processing: return "Processing payment of \(formattedTotal)"
        case .success:    return "Paid \(formattedTotal)"
        default:          return "Pay \(formattedTotal)"
        }
    }

    // MARK: Lifecycle

    func start() {
        status = .loading
        Task {
            try? await Task.sleep(for: CheckoutTokens.loadDelay)
            await MainActor.run { self.recompute() }
        }
    }

    /// Derives ideal / empty / offline. Never disturbs an in-flight or completed charge.
    func recompute() {
        if status == .processing || status == .success { return }
        if items.isEmpty { status = .empty; return }
        if !isOnline { status = .offline; return }
        status = .ideal
    }

    func setOnline(_ online: Bool) {
        isOnline = online
        recompute()
    }

    // MARK: Editable review

    func setQuantity(_ id: UUID, to quantity: Int) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].quantity = max(1, quantity)
        announceTotal()
    }

    func remove(_ id: UUID) {
        items.removeAll { $0.id == id }
        if items.isEmpty { status = .empty }
        announceTotal()
    }

    // MARK: Payment method selection

    func select(_ method: PaymentMethod) {
        if method == .applePay && !applePayAvailable {
            // Biometric/NFC path unavailable → never a dead end: explain + fall
            // back to manual card entry. (Never blocks checkout.)
            self.method = .newCard
            status = .permissionDenied
            errorMessage = "Apple Pay isn't available on this device. Enter a card to continue."
            announce(errorMessage)
            return
        }
        self.method = method
        if status == .permissionDenied || status == .error { recompute() }
    }

    // MARK: The safety-critical charge

    /// Starts a charge. Idempotent: a second tap while `.processing` is ignored,
    /// and offline is blocked with a reason rather than firing silently.
    func pay() {
        guard status != .processing, status != .success else { return }  // no double-fire
        guard isOnline else {
            status = .offline
            errorMessage = "You're offline — your order wasn't placed. Your details are saved; try again when you reconnect."
            announce("You're offline. Your order was not placed and you were not charged.")
            return
        }
        errorMessage = ""
        status = .processing
        announce("Processing payment")
        let key = idempotencyKey                      // stable key travels with the request
        Task {
            try? await Task.sleep(for: CheckoutTokens.processingDelay)
            await MainActor.run { self.resolve(idempotencyKey: key) }
        }
    }

    /// Resolves the in-flight charge to a definitive outcome — never a limbo.
    private func resolve(idempotencyKey key: UUID) {
        guard status == .processing, key == idempotencyKey else { return }

        // Reconcile a mid-charge connection drop: show the true state, don't re-charge.
        guard isOnline else {
            status = .offline
            errorMessage = "Connection lost while placing your order. Reconnect to see the result — you won't be charged twice."
            announce("Connection lost. Your payment will be confirmed without charging twice.")
            return
        }

        if simulateDecline {
            // Recoverable failure: specific reason, ALL input preserved, retry ready.
            status = .error
            errorMessage = "Card declined — try another payment method. Your details are saved."
            announce(errorMessage)
            return
        }

        // Definitive success — build the receipt, then rotate the key for any next order.
        let order = PlacedOrder(
            number: Self.makeOrderNumber(),
            total: total,
            email: email.isEmpty ? "your email" : email,
            etaText: etaText()
        )
        placedOrder = order
        status = .success
        idempotencyKey = UUID()
        announce("Payment successful. Order \(order.number) placed. Total \(formattedTotal). Estimated delivery \(order.etaText).")
    }

    func retry() {
        errorMessage = ""
        recompute()   // back to ideal so the shopper can adjust and pay again
    }

    // MARK: Helpers

    private func etaText() -> String {
        let start = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        let end = Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()
        let a = start.formatted(.dateTime.month(.abbreviated).day())
        let b = end.formatted(.dateTime.month(.abbreviated).day())
        return "\(a) \u{2013} \(b)"
    }

    private func announceTotal() {
        announce("New order total \(formattedTotal)")
    }

    private func announce(_ message: String) {
        AccessibilityNotification.Announcement(message).post()
    }

    private static func makeOrderNumber() -> String {
        let n = Int.random(in: 10_000...99_999)
        return "EZH-\(n)"
    }

    static func sampleCart() -> [LineItem] {
        [
            LineItem(id: UUID(), name: "Acoustic Wall Panel",
                     detail: "Walnut · 60×60cm", quantity: 2,
                     unitPrice: Decimal(string: "24.00") ?? 0),
            LineItem(id: UUID(), name: "Mounting Kit",
                     detail: "Concealed cleat", quantity: 1,
                     unitPrice: Decimal(string: "12.50") ?? 0),
        ]
    }
}

// MARK: - CheckoutScreen

struct CheckoutScreen: View {

    // Host-supplied navigation hooks (safe no-op defaults keep the preview live).
    var onBrowse: () -> Void = {}
    var onDone: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @StateObject private var vm = CheckoutViewModel(items: CheckoutViewModel.sampleCart())
    @StateObject private var monitor = CheckoutNetworkMonitor()

    @State private var demoOffline = false

    @FocusState private var focus: Field?
    private enum Field { case email, name, address, city, region, postal, card, expiry, cvv }

    /// The genuine monitor OR the demo override, so the offline flow is exercisable.
    private var effectiveOnline: Bool { monitor.isOnline && !demoOffline }

    // MARK: Body

    var body: some View {
        NavigationStack {
            Group {
                switch vm.status {
                case .empty:   emptyCart
                case .success: confirmation
                case .loading: loadingState
                default:       checkoutForm
                }
            }
            .navigationTitle("Checkout")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { demoMenu }
            .background(CheckoutTokens.surface)
        }
        .task {
            vm.setOnline(effectiveOnline)
            vm.start()
        }
        .onChange(of: effectiveOnline) { _, online in vm.setOnline(online) }
        .animation(CheckoutTokens.reveal(reduceMotion: reduceMotion), value: vm.status)
        .animation(CheckoutTokens.reveal(reduceMotion: reduceMotion), value: vm.isOnline)
    }

    // MARK: Loading (computing totals / placing order)

    private var loadingState: some View {
        VStack(spacing: CheckoutTokens.s4) {
            ProgressView()
            Text("Getting your order ready\u{2026}")
                .font(CheckoutTokens.bodyFont)
                .foregroundStyle(CheckoutTokens.onSurfaceMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading your order")
    }

    // MARK: Checkout form (single scroll, sticky Pay bar, always-visible summary)

    private var checkoutForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CheckoutTokens.s6) {
                orderSummaryCard          // ALWAYS visible — no surprise at the end
                identitySection           // prominent guest checkout
                applePaySection           // native Pay, surfaced early
                addressSection            // paste / autofill friendly
                paymentSection            // Apple Pay / saved / new masked card
                reviewSection             // editable line items + itemized total
                trustFootnote
            }
            .padding(.horizontal, CheckoutTokens.s4)
            .padding(.top, CheckoutTokens.s4)
            .padding(.bottom, CheckoutTokens.s6)
            .frame(maxWidth: CheckoutTokens.contentMaxWidth)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .top) { offlineBanner }
        .safeAreaInset(edge: .bottom) { payBar }
    }

    // MARK: Order summary (subtotal / shipping / tax / discount / total)

    private var orderSummaryCard: some View {
        VStack(alignment: .leading, spacing: CheckoutTokens.s3) {
            Text("Order summary")
                .font(CheckoutTokens.sectionFont)
                .foregroundStyle(CheckoutTokens.onSurface)

            summaryRow("Subtotal", vm.money(vm.subtotal))
            summaryRow("Shipping",
                       vm.shipping == 0 ? "Free" : vm.money(vm.shipping))
            summaryRow("Tax", vm.money(vm.tax))
            summaryRow(vm.appliedPromoLabel, "\u{2212}\(vm.money(vm.discount))",
                       tint: CheckoutTokens.statusSuccess)

            Divider()

            HStack(alignment: .firstTextBaseline) {
                Text("Total")
                    .font(CheckoutTokens.sectionFont)
                    .foregroundStyle(CheckoutTokens.onSurfaceStrong)
                Spacer(minLength: CheckoutTokens.s2)
                Text(vm.formattedTotal)
                    .font(CheckoutTokens.totalAmountFont)
                    .fontWeight(.semibold)
                    .foregroundStyle(CheckoutTokens.onSurfaceStrong)
                    .contentTransition(.numericText())
                    .animation(CheckoutTokens.totalChange(reduceMotion: reduceMotion), value: vm.total)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Total \(vm.formattedTotal), \(vm.itemCount) items")
        }
        .padding(CheckoutTokens.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CheckoutTokens.surfaceContainer,
                    in: RoundedRectangle(cornerRadius: CheckoutTokens.cardRadius, style: .continuous))
    }

    private func summaryRow(_ label: String, _ value: String,
                            tint: Color = CheckoutTokens.onSurface) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(CheckoutTokens.bodyFont)
                .foregroundStyle(CheckoutTokens.onSurfaceMuted)
            Spacer(minLength: CheckoutTokens.s2)
            Text(value)
                .font(CheckoutTokens.amountFont)
                .foregroundStyle(tint)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value)")
    }

    // MARK: Identity (guest prominent, sign-in deferred/secondary)

    private var identitySection: some View {
        sectionCard(title: "Contact") {
            VStack(alignment: .leading, spacing: CheckoutTokens.s3) {
                HStack(spacing: CheckoutTokens.s2) {
                    Image(systemName: "person.crop.circle")
                        .foregroundStyle(CheckoutTokens.actionPrimary)
                        .accessibilityHidden(true)
                    Text("Checking out as guest")
                        .font(CheckoutTokens.bodyFont)
                        .foregroundStyle(CheckoutTokens.onSurface)
                    Spacer(minLength: CheckoutTokens.s2)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Checking out as guest. No account required.")

                fieldLabel("Email for receipt")
                TextField("you@example.com", text: $vm.email)
                    .font(CheckoutTokens.fieldFont)
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    #endif
                    .submitLabel(.next)
                    .focused($focus, equals: .email)
                    .onSubmit { focus = .name }
                    .modifier(FieldChrome(focused: focus == .email))
                    .accessibilityLabel("Email for receipt")

                Button("Have an account? Sign in for faster checkout") {
                    vm.isGuest = false
                }
                .font(CheckoutTokens.footnoteFont)
                .foregroundStyle(CheckoutTokens.actionPrimary)
                .padding(.vertical, CheckoutTokens.s1)
                .frame(minHeight: CheckoutTokens.targetMin)
                .accessibilityHint("Optional — you can also check out as a guest")
            }
        }
    }

    // MARK: Apple Pay shortcut (native, surfaced early)

    private var applePaySection: some View {
        VStack(alignment: .leading, spacing: CheckoutTokens.s2) {
            applePayButton
            Text("Fastest checkout — carries your address and card.")
                .font(CheckoutTokens.footnoteFont)
                .foregroundStyle(CheckoutTokens.onSurfaceMuted)
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder private var applePayButton: some View {
        #if os(iOS)
        PayWithApplePayButton(.buy) {
            vm.select(.applePay)
            vm.pay()
        }
        .payWithApplePayButtonStyle(.automatic)
        .frame(maxWidth: .infinity)
        .frame(minHeight: CheckoutTokens.buttonMinHeight)
        .clipShape(RoundedRectangle(cornerRadius: CheckoutTokens.fieldRadius, style: .continuous))
        .disabled(!vm.canPay)
        .accessibilityLabel("Pay with Apple Pay, \(vm.formattedTotal)")
        #else
        // macOS SDK has no PayWithApplePayButton — provide an equivalent action.
        Button {
            vm.select(.applePay)
            vm.pay()
        } label: {
            Label("Pay with Apple Pay", systemImage: "apple.logo")
                .font(CheckoutTokens.buttonLabelFont)
                .frame(maxWidth: .infinity)
                .frame(minHeight: CheckoutTokens.buttonMinHeight)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(CheckoutTokens.onSurface)
        .disabled(!vm.canPay)
        .accessibilityLabel("Pay with Apple Pay, \(vm.formattedTotal)")
        #endif
    }

    // MARK: Address (autofill, paste-friendly)

    private var addressSection: some View {
        sectionCard(title: "Shipping address") {
            VStack(alignment: .leading, spacing: CheckoutTokens.s4) {
                addressField("Full name", text: $vm.fullName, field: .name,
                             content: .name, next: .address)
                addressField("Address", text: $vm.addressLine, field: .address,
                             content: .fullStreetAddress, next: .city)
                addressField("City", text: $vm.city, field: .city,
                             content: .addressCity, next: .region)
                HStack(alignment: .top, spacing: CheckoutTokens.s3) {
                    addressField("State / Region", text: $vm.region, field: .region,
                                 content: .addressState, next: .postal)
                    postalField
                }
            }
        }
    }

    private func addressField(_ label: String, text: Binding<String>,
                              field: Field, content: TextContentKind,
                              next: Field) -> some View {
        VStack(alignment: .leading, spacing: CheckoutTokens.s2) {
            fieldLabel(label)
            TextField(label, text: text)
                .font(CheckoutTokens.fieldFont)
                .modifier(AddressContentType(kind: content))
                .submitLabel(.next)
                .focused($focus, equals: field)
                .onSubmit { focus = next }
                .modifier(FieldChrome(focused: focus == field))
                .accessibilityLabel(label)
        }
    }

    private var postalField: some View {
        VStack(alignment: .leading, spacing: CheckoutTokens.s2) {
            fieldLabel("ZIP / Postal")
            TextField("ZIP / Postal", text: $vm.postalCode)
                .font(CheckoutTokens.fieldFont)
                .modifier(AddressContentType(kind: .postalCode))
                #if os(iOS)
                .keyboardType(.numbersAndPunctuation)
                #endif
                .submitLabel(.next)
                .focused($focus, equals: .postal)
                .onSubmit { focus = .card }
                .modifier(FieldChrome(focused: focus == .postal))
                .accessibilityLabel("ZIP or postal code")
        }
    }

    // MARK: Payment (Apple Pay / saved / new masked, paste-safe card)

    private var paymentSection: some View {
        sectionCard(title: "Payment") {
            VStack(alignment: .leading, spacing: CheckoutTokens.s3) {
                methodRow(.applePay, title: "Apple Pay",
                          subtitle: "Touch ID / Face ID", systemImage: "applelogo")
                methodRow(.savedCard, title: vm.savedCardLabel,
                          subtitle: "Saved · one tap", systemImage: "creditcard")
                methodRow(.newCard, title: "New card",
                          subtitle: "Paste or autofill supported", systemImage: "plus.rectangle")

                if vm.method == .newCard {
                    newCardFields
                        .transition(reduceMotion ? .opacity
                                    : .opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(CheckoutTokens.reveal(reduceMotion: reduceMotion), value: vm.method)
        }
    }

    private func methodRow(_ method: PaymentMethod, title: String,
                           subtitle: String, systemImage: String) -> some View {
        let selected = vm.method == method
        return Button {
            vm.select(method)
        } label: {
            HStack(spacing: CheckoutTokens.s3) {
                Image(systemName: systemImage)
                    .foregroundStyle(CheckoutTokens.onSurface)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: CheckoutTokens.s1) {
                    Text(title)
                        .font(CheckoutTokens.bodyFont)
                        .foregroundStyle(CheckoutTokens.onSurface)
                    Text(subtitle)
                        .font(CheckoutTokens.footnoteFont)
                        .foregroundStyle(CheckoutTokens.onSurfaceMuted)
                }
                Spacer(minLength: CheckoutTokens.s2)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? CheckoutTokens.actionPrimary : CheckoutTokens.outline)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, CheckoutTokens.s1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: CheckoutTokens.targetMin)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title). \(subtitle)")
        .accessibilityValue(selected ? "Selected" : "Not selected")
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    private var newCardFields: some View {
        VStack(alignment: .leading, spacing: CheckoutTokens.s3) {
            fieldLabel("Card number")
            // Paste-safe: no input restriction blocks a paste; autofill + password
            // managers work via `.textContentType(.creditCardNumber)`.
            TextField("1234 5678 9012 3456", text: $vm.cardNumber)
                .font(CheckoutTokens.fieldFont.monospacedDigit())
                .modifier(CardContentType())
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif
                .focused($focus, equals: .card)
                .modifier(FieldChrome(focused: focus == .card))
                .accessibilityLabel("Card number")
                .accessibilityHint("Paste or autofill is supported")

            HStack(alignment: .top, spacing: CheckoutTokens.s3) {
                VStack(alignment: .leading, spacing: CheckoutTokens.s2) {
                    fieldLabel("Expiry")
                    TextField("MM/YY", text: $vm.cardExpiry)
                        .font(CheckoutTokens.fieldFont.monospacedDigit())
                        #if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
                        #endif
                        .focused($focus, equals: .expiry)
                        .modifier(FieldChrome(focused: focus == .expiry))
                        .accessibilityLabel("Card expiry date")
                }
                VStack(alignment: .leading, spacing: CheckoutTokens.s2) {
                    fieldLabel("CVV")
                    SecureField("123", text: $vm.cardCVV)
                        .font(CheckoutTokens.fieldFont.monospacedDigit())
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                        .focused($focus, equals: .cvv)
                        .modifier(FieldChrome(focused: focus == .cvv))
                        .accessibilityLabel("Card security code")
                }
            }
        }
    }

    // MARK: Editable review (line items + itemized total)

    private var reviewSection: some View {
        sectionCard(title: "Review \(vm.itemCount) items") {
            VStack(alignment: .leading, spacing: CheckoutTokens.s4) {
                ForEach(vm.items) { item in
                    reviewRow(item)
                    if item.id != vm.items.last?.id { Divider() }
                }
            }
        }
    }

    private func reviewRow(_ item: LineItem) -> some View {
        HStack(alignment: .top, spacing: CheckoutTokens.s3) {
            VStack(alignment: .leading, spacing: CheckoutTokens.s1) {
                Text(item.name)
                    .font(CheckoutTokens.bodyFont)
                    .foregroundStyle(CheckoutTokens.onSurface)
                Text(item.detail)
                    .font(CheckoutTokens.footnoteFont)
                    .foregroundStyle(CheckoutTokens.onSurfaceMuted)
                quantityStepper(item)
            }
            Spacer(minLength: CheckoutTokens.s2)
            VStack(alignment: .trailing, spacing: CheckoutTokens.s1) {
                Text(vm.money(item.lineTotal))
                    .font(CheckoutTokens.amountFont)
                    .foregroundStyle(CheckoutTokens.onSurface)
                removeButton(item)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func quantityStepper(_ item: LineItem) -> some View {
        Stepper(value: Binding(
            get: { item.quantity },
            set: { vm.setQuantity(item.id, to: $0) }
        ), in: 1...99) {
            Text("Qty \(item.quantity)")
                .font(CheckoutTokens.footnoteFont)
                .foregroundStyle(CheckoutTokens.onSurface)
        }
        .frame(minHeight: CheckoutTokens.targetMin)
        .accessibilityLabel("Quantity of \(item.name)")
        .accessibilityValue("\(item.quantity)")
    }

    private func removeButton(_ item: LineItem) -> some View {
        Button(role: .destructive) {
            vm.remove(item.id)
        } label: {
            Text("Remove")
                .font(CheckoutTokens.footnoteFont)
                .padding(.horizontal, CheckoutTokens.s2)
                .frame(minHeight: CheckoutTokens.targetMin)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel("Remove \(item.name)")
    }

    // MARK: Trust footnote (security cue — icon + text, honest)

    private var trustFootnote: some View {
        HStack(spacing: CheckoutTokens.s2) {
            Image(systemName: "lock.fill")
                .foregroundStyle(CheckoutTokens.statusSuccess)
                .accessibilityHidden(true)
            Text("Encrypted checkout. You won't be charged until you confirm.")
                .font(CheckoutTokens.footnoteFont)
                .foregroundStyle(CheckoutTokens.onSurfaceMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Encrypted checkout. You won't be charged until you confirm.")
    }

    // MARK: Sticky Pay bar (full-width, shows the amount, rides the keyboard)

    private var payBar: some View {
        VStack(spacing: CheckoutTokens.s3) {
            if vm.status == .error || vm.status == .permissionDenied { errorRegion }
            Button(action: vm.pay) {
                HStack(spacing: CheckoutTokens.s2) {
                    if vm.status == .processing {
                        ProgressView()
                            .tint(CheckoutTokens.onActionPrimary)
                    }
                    Text(vm.payButtonTitle)
                        .font(CheckoutTokens.buttonLabelFont)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: CheckoutTokens.buttonMinHeight)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(CheckoutTokens.actionPrimary)
            .disabled(!vm.canPay)
            .accessibilityLabel(vm.payAccessibilityLabel)
            .accessibilityHint(vm.canPay ? "Places your order" : payDisabledHint)
            .accessibilityAddTraits(vm.status == .processing ? .updatesFrequently : [])
        }
        .padding(.horizontal, CheckoutTokens.s4)
        .padding(.top, CheckoutTokens.s3)
        .padding(.bottom, CheckoutTokens.s4)
        .frame(maxWidth: CheckoutTokens.contentMaxWidth)
        .frame(maxWidth: .infinity)
        .background(.bar)
    }

    private var payDisabledHint: String {
        if vm.status == .processing { return "Processing your payment" }
        if !vm.isOnline { return "You're offline — reconnect to pay" }
        return "Add an item to continue"
    }

    // MARK: Error region (recoverable, announced, input preserved)

    @ViewBuilder private var errorRegion: some View {
        if !vm.errorMessage.isEmpty {
            HStack(alignment: .top, spacing: CheckoutTokens.s2) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(CheckoutTokens.statusError)   // icon + text, never color-only
                    .accessibilityHidden(true)
                Text(vm.errorMessage)
                    .font(CheckoutTokens.calloutFont)
                    .foregroundStyle(CheckoutTokens.onSurface)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: CheckoutTokens.s2)
                Button("Try again") { vm.retry() }
                    .font(CheckoutTokens.footnoteFont)
                    .foregroundStyle(CheckoutTokens.actionPrimary)
                    .frame(minHeight: CheckoutTokens.targetMin)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, CheckoutTokens.s3)
            .padding(.vertical, CheckoutTokens.s2)
            .background(CheckoutTokens.surfaceContainer,
                        in: RoundedRectangle(cornerRadius: CheckoutTokens.bannerRadius, style: .continuous))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Error: \(vm.errorMessage). Try again available. Your details are saved.")
            .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .bottom)))
        }
    }

    // MARK: Offline banner (blocks the charge with a reason, entries preserved)

    @ViewBuilder private var offlineBanner: some View {
        if !vm.isOnline {
            HStack(spacing: CheckoutTokens.s2) {
                Image(systemName: "wifi.slash")
                    .accessibilityHidden(true)
                Text("You're offline — we won't place your order or charge you until you reconnect.")
                    .font(CheckoutTokens.footnoteFont)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: CheckoutTokens.s2)
            }
            .foregroundStyle(CheckoutTokens.onSurface)
            .padding(.horizontal, CheckoutTokens.s4)
            .padding(.vertical, CheckoutTokens.s3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CheckoutTokens.surfaceContainer)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("You're offline. Your order won't be placed or charged until you reconnect. Your details are saved.")
            .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: Empty cart (a Browse CTA, never a dead end)

    private var emptyCart: some View {
        VStack(spacing: CheckoutTokens.s4) {
            Image(systemName: "cart")
                .font(CheckoutTokens.screenTitleFont)
                .foregroundStyle(CheckoutTokens.actionPrimary)
                .accessibilityHidden(true)
            Text("Your cart is empty")
                .font(CheckoutTokens.screenTitleFont)
                .foregroundStyle(CheckoutTokens.onSurface)
            Text("Add something you love and it'll show up here.")
                .font(CheckoutTokens.bodyFont)
                .foregroundStyle(CheckoutTokens.onSurfaceMuted)
                .multilineTextAlignment(.center)
            Button(action: onBrowse) {
                Text("Browse products")
                    .font(CheckoutTokens.buttonLabelFont)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: CheckoutTokens.buttonMinHeight)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(CheckoutTokens.actionPrimary)
            .padding(.top, CheckoutTokens.s2)
            .accessibilityLabel("Browse products")
        }
        .padding(CheckoutTokens.s6)
        .frame(maxWidth: CheckoutTokens.contentMaxWidth)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
    }

    // MARK: Confirmation (order number + receipt + ETA + next steps)

    private var confirmation: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CheckoutTokens.s6) {
                VStack(alignment: .leading, spacing: CheckoutTokens.s2) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(CheckoutTokens.screenTitleFont)
                        .foregroundStyle(CheckoutTokens.statusSuccess)
                        .accessibilityHidden(true)
                    Text("Order confirmed")
                        .font(CheckoutTokens.screenTitleFont)
                        .foregroundStyle(CheckoutTokens.onSurfaceStrong)
                    Text("We emailed a receipt to \(vm.placedOrder?.email ?? "your email").")
                        .font(CheckoutTokens.bodyFont)
                        .foregroundStyle(CheckoutTokens.onSurfaceMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)

                receiptCard
                nextStepsCard
                saveDetailsCard

                Button(action: onDone) {
                    Text("Done")
                        .font(CheckoutTokens.buttonLabelFont)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: CheckoutTokens.buttonMinHeight)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(CheckoutTokens.actionPrimary)
                .accessibilityLabel("Done")
            }
            .padding(.horizontal, CheckoutTokens.s4)
            .padding(.vertical, CheckoutTokens.s6)
            .frame(maxWidth: CheckoutTokens.contentMaxWidth)
            .frame(maxWidth: .infinity)
        }
    }

    private var receiptCard: some View {
        VStack(alignment: .leading, spacing: CheckoutTokens.s3) {
            receiptRow("Order number", vm.placedOrder?.number ?? "")
            receiptRow("Total charged", vm.money(vm.placedOrder?.total ?? 0), mono: true)
            receiptRow("Estimated delivery", vm.placedOrder?.etaText ?? "")
        }
        .padding(CheckoutTokens.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CheckoutTokens.surfaceContainer,
                    in: RoundedRectangle(cornerRadius: CheckoutTokens.cardRadius, style: .continuous))
    }

    private func receiptRow(_ label: String, _ value: String, mono: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(CheckoutTokens.bodyFont)
                .foregroundStyle(CheckoutTokens.onSurfaceMuted)
            Spacer(minLength: CheckoutTokens.s2)
            Text(value)
                .font(mono ? CheckoutTokens.amountFont : CheckoutTokens.bodyFont)
                .foregroundStyle(CheckoutTokens.onSurface)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value)")
    }

    private var nextStepsCard: some View {
        VStack(alignment: .leading, spacing: CheckoutTokens.s3) {
            Text("What's next")
                .font(CheckoutTokens.sectionFont)
                .foregroundStyle(CheckoutTokens.onSurface)
            Button {
                onDone()
            } label: {
                Label("Track your order", systemImage: "shippingbox")
                    .font(CheckoutTokens.bodyFont)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: CheckoutTokens.targetMin)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Track your order")

            Button {
                onDone()
            } label: {
                Label("View order details", systemImage: "doc.text")
                    .font(CheckoutTokens.bodyFont)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: CheckoutTokens.targetMin)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("View order details")
        }
        .padding(CheckoutTokens.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CheckoutTokens.surfaceContainer,
                    in: RoundedRectangle(cornerRadius: CheckoutTokens.cardRadius, style: .continuous))
    }

    // Post-purchase account ask — offered, never forced (deferred from checkout).
    private var saveDetailsCard: some View {
        HStack(spacing: CheckoutTokens.s3) {
            Image(systemName: "person.badge.plus")
                .foregroundStyle(CheckoutTokens.actionPrimary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: CheckoutTokens.s1) {
                Text("Save your details?")
                    .font(CheckoutTokens.bodyFont)
                    .foregroundStyle(CheckoutTokens.onSurface)
                Text("Create an account to reorder in one tap.")
                    .font(CheckoutTokens.footnoteFont)
                    .foregroundStyle(CheckoutTokens.onSurfaceMuted)
            }
            Spacer(minLength: CheckoutTokens.s2)
            Button("Create") { onDone() }
                .font(CheckoutTokens.footnoteFont)
                .frame(minHeight: CheckoutTokens.targetMin)
                .accessibilityLabel("Create an account")
        }
        .padding(CheckoutTokens.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CheckoutTokens.surfaceContainer,
                    in: RoundedRectangle(cornerRadius: CheckoutTokens.cardRadius, style: .continuous))
    }

    // MARK: Demo menu (exercise every state without leaving the preview)

    @ToolbarContentBuilder private var demoMenu: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Toggle("Offline (demo)", isOn: $demoOffline)
                Toggle("Simulate decline", isOn: $vm.simulateDecline)
                Toggle("Apple Pay available", isOn: $vm.applePayAvailable)
                Button("Empty the cart") { vm.items.removeAll(); vm.recompute() }
                Button("Reset order") {
                    vm.items = CheckoutViewModel.sampleCart()
                    vm.placedOrder = nil
                    vm.simulateDecline = false
                    vm.recompute()
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .frame(minWidth: CheckoutTokens.targetMin, minHeight: CheckoutTokens.targetMin)
                    .contentShape(.rect)
            }
            .accessibilityLabel("Demo options")
        }
    }

    // MARK: Small builders

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(CheckoutTokens.labelFont)
            .fontWeight(.medium)
            .foregroundStyle(CheckoutTokens.onSurface)
    }

    private func sectionCard<Content: View>(title: String,
                                            @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: CheckoutTokens.s3) {
            Text(title)
                .font(CheckoutTokens.sectionFont)
                .foregroundStyle(CheckoutTokens.onSurface)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Content-type helpers (iOS-only autofill types, guarded for macOS)

/// The address autofill kinds we use. Mapped to `UITextContentType` only on iOS,
/// where those cases exist; a no-op on macOS so the file compiles on both SDKs.
enum TextContentKind {
    case name, fullStreetAddress, addressCity, addressState, postalCode
}

private struct AddressContentType: ViewModifier {
    let kind: TextContentKind
    func body(content: Content) -> some View {
        #if os(iOS)
        switch kind {
        case .name:              content.textContentType(.name)
        case .fullStreetAddress: content.textContentType(.fullStreetAddress)
        case .addressCity:       content.textContentType(.addressCity)
        case .addressState:      content.textContentType(.addressState)
        case .postalCode:        content.textContentType(.postalCode)
        }
        #else
        content
        #endif
    }
}

/// Credit-card autofill — iOS-only content type, guarded so macOS still compiles.
private struct CardContentType: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        content.textContentType(.creditCardNumber)
        #else
        content
        #endif
    }
}

// MARK: - Field chrome (padding + surface + focus/border)

private struct FieldChrome: ViewModifier {
    let focused: Bool

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, CheckoutTokens.s4)
            .padding(.vertical, CheckoutTokens.s3)
            .frame(minHeight: CheckoutTokens.targetMin)
            .background(CheckoutTokens.surfaceContainer,
                        in: RoundedRectangle(cornerRadius: CheckoutTokens.fieldRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CheckoutTokens.fieldRadius, style: .continuous)
                    .strokeBorder(focused ? CheckoutTokens.focusRing : CheckoutTokens.outline,
                                  lineWidth: focused ? CheckoutTokens.focusBorderWidth : CheckoutTokens.borderWidth)
            )
    }
}

// MARK: - Previews

#Preview("Checkout") {
    CheckoutScreen()
}

#Preview("Dark / Accessibility type") {
    CheckoutScreen()
        .preferredColorScheme(.dark)
        .dynamicTypeSize(.accessibility3)
}
