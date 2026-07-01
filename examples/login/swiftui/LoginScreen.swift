//  LoginScreen.swift
//  An accessible, paste-friendly, all-states login screen (see ../spec.md).
//
//  Highlights:
//   • 7 explicit states via `LoginStatus` (idle, empty, loading, error, offline,
//     success, permissionDenied) — no boolean soup.
//   • Paste / password-manager / passkey / autofill friendly per WCAG 2.2 3.3.8:
//     .textContentType(.username/.password) + .keyboardType(.emailAddress).
//   • Labeled show/hide password toggle that exposes its state to VoiceOver.
//   • Generic error that never reveals which field failed, preserves all input,
//     and is announced via AccessibilityNotification.Announcement.
//   • Offline banner; success offers Face ID opt-in with a password fallback.
//   • Every design value comes from LoginTokens — no literals in this file.
//   • Keyboard-safe and sticky primary button via .safeAreaInset; RTL-safe
//     (logical leading/trailing only); Dynamic Type via text styles.

import SwiftUI
import AuthenticationServices
import LocalAuthentication
import Network
#if canImport(UIKit)
import UIKit
#endif

// MARK: - State model

/// The mandatory 7-state model for this screen.
enum LoginStatus: Equatable {
    case idle
    case empty
    case loading
    case error
    case offline
    case success
    case permissionDenied
}

// MARK: - Reachability

/// Real connectivity, so the offline state is genuine rather than faked.
final class NetworkMonitor: ObservableObject {
    @Published var isOnline = true
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "login.network.monitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async { self?.isOnline = (path.status == .satisfied) }
        }
        monitor.start(queue: queue)
    }

    deinit { monitor.cancel() }
}

// MARK: - LoginScreen

struct LoginScreen: View {

    // Host-supplied navigation hooks (safe no-op defaults keep the preview live).
    var onAuthenticated: () -> Void = {}   // honor deep-link return after login
    var onSignUp: () -> Void = {}
    var onContinueAsGuest: () -> Void = {}

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @StateObject private var network = NetworkMonitor()

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var status: LoginStatus = .empty
    @State private var errorMessage = ""
    @State private var showRecoverySheet = false
    @State private var showBiometricSheet = false
    @State private var biometricDenied = false

    @FocusState private var focus: Field?
    private enum Field { case email, password }

    // MARK: Derived

    /// Enabled only with non-empty inputs, a connection, and not mid-request —
    /// this is also what blocks double-submit.
    private var canSubmit: Bool {
        status == .idle && network.isOnline
    }

    private var primaryLabel: String {
        switch status {
        case .loading: return "Signing in\u{2026}"
        case .success: return "Signed in"
        default:       return "Sign in"
        }
    }

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LoginTokens.s6) {
                header
                credentialFields
                separator
                ssoButtons
                footerLinks
            }
            .padding(.horizontal, LoginTokens.s4)
            .padding(.top, LoginTokens.s8)
            .padding(.bottom, LoginTokens.s6)
            .frame(maxWidth: LoginTokens.contentMaxWidth)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(LoginTokens.surface)
        .safeAreaInset(edge: .top) { offlineBanner }
        .safeAreaInset(edge: .bottom) { signInBar }
        .animation(LoginTokens.reveal(reduceMotion: reduceMotion), value: status)
        .animation(LoginTokens.reveal(reduceMotion: reduceMotion), value: network.isOnline)
        .sensoryFeedback(trigger: status) { _, new in
            switch new {
            case .success: return .success
            case .error:   return .error
            default:       return nil
            }
        }
        .onAppear(perform: recompute)
        .onChange(of: email) { _, _ in fieldsChanged() }
        .onChange(of: password) { _, _ in fieldsChanged() }
        .onChange(of: network.isOnline) { _, _ in recompute() }
        .sheet(isPresented: $showRecoverySheet) { recoverySheet }
        .sheet(isPresented: $showBiometricSheet) { biometricSheet }
    }

    // MARK: Header (non-interactive)

    private var header: some View {
        VStack(alignment: .leading, spacing: LoginTokens.s2) {
            Image(systemName: "lock.circle.fill")
                .font(LoginTokens.titleFont)
                .foregroundStyle(LoginTokens.actionPrimary)
                .accessibilityHidden(true)
            Text("Welcome back")
                .font(LoginTokens.titleFont)
                .fontWeight(.bold)
                .foregroundStyle(LoginTokens.onSurface)
            Text("Sign in to continue")
                .font(LoginTokens.subtitleFont)
                .foregroundStyle(LoginTokens.onSurfaceMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: Fields

    private var credentialFields: some View {
        VStack(alignment: .leading, spacing: LoginTokens.s4) {
            VStack(alignment: .leading, spacing: LoginTokens.s2) {
                fieldLabel("Email")
                TextField("you@example.com", text: $email)
                    .font(LoginTokens.fieldFont)
                    .textContentType(.username)          // + passkeys / autofill (3.3.8)
                    .keyboardType(.emailAddress)         // paste-friendly email keyboard
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .focused($focus, equals: .email)
                    .onSubmit { focus = .password }
                    .accessibilityLabel("Email address")
                    .modifier(FieldChrome(focused: focus == .email))
            }

            VStack(alignment: .leading, spacing: LoginTokens.s2) {
                fieldLabel("Password")
                HStack(spacing: LoginTokens.s2) {
                    passwordField
                    passwordToggle
                }
                .modifier(FieldChrome(focused: focus == .password))
                forgotButton
            }
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(LoginTokens.labelFont)
            .fontWeight(.medium)
            .foregroundStyle(LoginTokens.onSurface)
            .accessibilityAddTraits(.isStaticText)
    }

    @ViewBuilder private var passwordField: some View {
        Group {
            if showPassword {
                TextField("Your password", text: $password)
            } else {
                SecureField("Your password", text: $password)
            }
        }
        .font(LoginTokens.fieldFont)
        .textContentType(.password)              // current-password autofill (3.3.8)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .submitLabel(.go)
        .focused($focus, equals: .password)
        .onSubmit(submit)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel("Password")
    }

    private var passwordToggle: some View {
        Button {
            showPassword.toggle()
        } label: {
            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                .imageScale(.medium)
                .foregroundStyle(LoginTokens.onSurfaceMuted)
                .frame(width: LoginTokens.toggleHitArea, height: LoginTokens.toggleHitArea)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(showPassword ? "Hide password" : "Show password")
        .accessibilityValue(showPassword ? "Password shown" : "Password hidden")
        .accessibilityAddTraits(.isButton)
    }

    private var forgotButton: some View {
        Button("Forgot password?") { showRecoverySheet = true }
            .font(LoginTokens.footnoteFont)
            .foregroundStyle(LoginTokens.actionPrimary)
            .padding(.vertical, LoginTokens.s1)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .accessibilityHint("Opens password recovery")
    }

    // MARK: SSO

    private var separator: some View {
        HStack(spacing: LoginTokens.s3) {
            hairline
            Text("or")
                .font(LoginTokens.footnoteFont)
                .foregroundStyle(LoginTokens.onSurfaceMuted)
            hairline
        }
        .accessibilityHidden(true)
    }

    private var hairline: some View {
        Rectangle()
            .fill(LoginTokens.outline)
            .frame(height: LoginTokens.hairline)
    }

    private var ssoButtons: some View {
        VStack(spacing: LoginTokens.s3) {
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                handleApple(result)
            }
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(maxWidth: .infinity)
            .frame(minHeight: LoginTokens.buttonMinHeight)
            .clipShape(RoundedRectangle(cornerRadius: LoginTokens.fieldRadius, style: .continuous))
            .disabled(!network.isOnline)
            .accessibilityLabel("Sign in with Apple")

            Button(action: handleGoogle) {
                HStack(spacing: LoginTokens.s2) {
                    Image(systemName: "globe")
                        .accessibilityHidden(true)
                    Text("Continue with Google")
                        .font(LoginTokens.buttonLabelFont)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: LoginTokens.buttonMinHeight)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .tint(LoginTokens.onSurface)
            .disabled(!network.isOnline)
            .accessibilityLabel("Continue with Google")
        }
    }

    // MARK: Footer links

    private var footerLinks: some View {
        VStack(spacing: LoginTokens.s3) {
            HStack(spacing: LoginTokens.s1) {
                Text("New here?")
                    .font(LoginTokens.footnoteFont)
                    .foregroundStyle(LoginTokens.onSurfaceMuted)
                Button("Create account", action: onSignUp)
                    .font(LoginTokens.footnoteFont)
                    .foregroundStyle(LoginTokens.actionPrimary)
            }
            Button("Continue as guest", action: onContinueAsGuest)
                .font(LoginTokens.footnoteFont)
                .foregroundStyle(LoginTokens.onSurfaceMuted)
                .padding(.vertical, LoginTokens.s1)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, LoginTokens.s2)
    }

    // MARK: Sticky bottom bar (rides above the keyboard + home indicator)

    private var signInBar: some View {
        VStack(spacing: LoginTokens.s3) {
            errorRegion
            Button(action: submit) {
                HStack(spacing: LoginTokens.s2) {
                    if status == .loading {
                        ProgressView()
                            .tint(LoginTokens.onActionPrimary)
                    }
                    Text(primaryLabel)
                        .font(LoginTokens.buttonLabelFont)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: LoginTokens.buttonMinHeight)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(LoginTokens.actionPrimary)
            .disabled(!canSubmit)
            .accessibilityLabel(primaryLabel)
            .accessibilityHint(canSubmit ? "Signs you in" : "Enter your email and password")
            .accessibilityAddTraits(status == .loading ? .updatesFrequently : [])
        }
        .padding(.horizontal, LoginTokens.s4)
        .padding(.top, LoginTokens.s3)
        .padding(.bottom, LoginTokens.s4)
        .frame(maxWidth: LoginTokens.contentMaxWidth)
        .frame(maxWidth: .infinity)
        .background(.bar)
    }

    // MARK: Error (generic, announced, input preserved)

    @ViewBuilder private var errorRegion: some View {
        if status == .error {
            HStack(alignment: .top, spacing: LoginTokens.s2) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(LoginTokens.statusError)   // icon + text, never color-only
                    .accessibilityHidden(true)
                Text(errorMessage)
                    .font(LoginTokens.calloutFont)
                    .foregroundStyle(LoginTokens.statusError)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, LoginTokens.s4)
            .padding(.vertical, LoginTokens.s3)
            .background(LoginTokens.surfaceContainer,
                        in: RoundedRectangle(cornerRadius: LoginTokens.bannerRadius, style: .continuous))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Error: \(errorMessage)")
            .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .bottom)))
        }
    }

    // MARK: Offline banner (non-blocking, top safe-area)

    @ViewBuilder private var offlineBanner: some View {
        if !network.isOnline {
            HStack(spacing: LoginTokens.s2) {
                Image(systemName: "wifi.slash")
                    .accessibilityHidden(true)
                Text("You're offline \u{2014} check your connection")
                    .font(LoginTokens.calloutFont)
                Spacer(minLength: LoginTokens.s2)
            }
            .foregroundStyle(LoginTokens.onSurface)
            .padding(.horizontal, LoginTokens.s4)
            .padding(.vertical, LoginTokens.s3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LoginTokens.surfaceContainer)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isStaticText)
            .accessibilityLabel("You're offline. Sign in needs a connection.")
            .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: Recovery sheet (forgot password)

    private var recoverySheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("you@example.com", text: $email)
                        .font(LoginTokens.fieldFont)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityLabel("Email address")
                } header: {
                    Text("Reset your password")
                } footer: {
                    Text("We'll email a secure link to set a new password.")
                }
                Button("Send reset link") { showRecoverySheet = false }
                    .disabled(email.isEmpty)
            }
            .navigationTitle("Forgot password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showRecoverySheet = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: Success → Face ID opt-in, with permission-denied fallback

    private var biometricSheet: some View {
        Group {
            if biometricDenied {
                ContentUnavailableView {
                    Label("Face ID isn't available", systemImage: "faceid")
                } description: {
                    Text("You can still sign in with your password. You can enable Face ID later in Settings.")
                } actions: {
                    Button("Open Settings") { openSettings() }
                        .buttonStyle(.borderedProminent)
                    Button("Continue with password") { finishSuccess() }
                        .buttonStyle(.bordered)
                }
                .accessibilityLabel("Face ID is not available. Continue with your password.")
            } else {
                VStack(spacing: LoginTokens.s6) {
                    Image(systemName: "faceid")
                        .font(LoginTokens.titleFont)
                        .foregroundStyle(LoginTokens.actionPrimary)
                        .accessibilityHidden(true)
                    VStack(spacing: LoginTokens.s2) {
                        Text("Use Face ID next time?")
                            .font(LoginTokens.buttonLabelFont)
                            .multilineTextAlignment(.center)
                        Text("Sign in faster and keep your password as a backup.")
                            .font(LoginTokens.calloutFont)
                            .foregroundStyle(LoginTokens.onSurfaceMuted)
                            .multilineTextAlignment(.center)
                    }
                    VStack(spacing: LoginTokens.s3) {
                        Button {
                            enableBiometrics()
                        } label: {
                            Text("Use Face ID")
                                .font(LoginTokens.buttonLabelFont)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: LoginTokens.buttonMinHeight)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(LoginTokens.actionPrimary)

                        Button("Not now") { finishSuccess() }
                            .font(LoginTokens.buttonLabelFont)
                            .padding(.vertical, LoginTokens.s2)
                    }
                }
                .padding(LoginTokens.s6)
                .frame(maxWidth: LoginTokens.contentMaxWidth)
                .accessibilityElement(children: .contain)
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Behavior

    private func fieldsChanged() {
        if status == .error { errorMessage = "" }   // preserve input, clear stale error
        recompute()
    }

    /// Single place that derives empty / idle / offline from inputs + connectivity.
    private func recompute() {
        if status == .loading || status == .success { return }
        if !network.isOnline { status = .offline; return }
        status = (email.isEmpty || password.isEmpty) ? .empty : .idle
    }

    private func submit() {
        guard canSubmit else { return }   // blocks empty, offline, and double-submit
        focus = nil
        errorMessage = ""
        status = .loading
        Task {
            try? await Task.sleep(for: LoginTokens.simulatedNetworkDelay)
            await MainActor.run { completeSignIn() }
        }
    }

    private func completeSignIn() {
        // Demo outcome: a malformed email stands in for a rejected credential.
        let credentialsAccepted = email.contains("@")
        if credentialsAccepted {
            status = .success
            showBiometricSheet = true
        } else {
            // Generic message — never reveals which field was wrong; input kept.
            status = .error
            errorMessage = "Email or password is incorrect."
            announce(errorMessage)
        }
    }

    private func handleApple(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success:
            status = .success
            showBiometricSheet = true
        case .failure:
            status = .error
            errorMessage = "Couldn't sign in with Apple. Please try again."
            announce(errorMessage)
        }
    }

    private func handleGoogle() {
        guard network.isOnline else { return }
        status = .success
        showBiometricSheet = true
    }

    private func enableBiometrics() {
        let context = LAContext()
        var authError: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
            // Production: persist the opt-in; the system handles enrollment.
            finishSuccess()
        } else {
            biometricDenied = true          // permission-denied → password fallback
            status = .permissionDenied
        }
    }

    private func finishSuccess() {
        showBiometricSheet = false
        biometricDenied = false
        onAuthenticated()                    // return to intended destination / deep link
    }

    private func announce(_ message: String) {
        // VoiceOver reads the error even though focus stays on the inputs.
        AccessibilityNotification.Announcement(message).post()
    }

    private func openSettings() {
        #if canImport(UIKit)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }
}

// MARK: - Field chrome (padding + surface + focus/border)

private struct FieldChrome: ViewModifier {
    let focused: Bool

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, LoginTokens.s4)
            .padding(.vertical, LoginTokens.s3)
            .background(LoginTokens.surfaceContainer,
                        in: RoundedRectangle(cornerRadius: LoginTokens.fieldRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LoginTokens.fieldRadius, style: .continuous)
                    .strokeBorder(focused ? LoginTokens.focusRing : LoginTokens.outline,
                                  lineWidth: focused ? LoginTokens.focusBorderWidth : LoginTokens.borderWidth)
            )
    }
}

// MARK: - Previews

#Preview("Idle") {
    LoginScreen()
}

#Preview("Dark / Accessibility type") {
    LoginScreen()
        .preferredColorScheme(.dark)
        .dynamicTypeSize(.accessibility3)
}
