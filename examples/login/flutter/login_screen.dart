// login_screen.dart
//
// An accessible, paste-friendly, all-states sign-in surface built to the spec in
// examples/login/spec.md. Adaptive (Material base, Cupertino accents on iOS),
// keyboard-avoiding, RTL-safe, Dynamic-Type-safe, reduce-motion aware.
//
// Every color / spacing / radius / size / duration / text style comes from
// login_tokens.dart — this file holds no raw design values (token_lint).
//
// Drop-in: `LoginScreen(authenticate: myAuthFn, onAuthenticated: goHome)`.
// See README.md.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'login_tokens.dart';

/// The seven UI states of the sign-in flow (spec "States map (all 7)").
/// Modeled as an explicit enum so the switchboard is exhaustive.
enum LoginStatus {
  /// Ready with input present — primary action enabled.
  idle,

  /// Fresh, ready form — the empty state: both fields empty, labels and
  /// placeholder hints shown, primary action disabled.
  empty,

  /// Sign in tapped — spinner, inputs locked, double-submit blocked.
  loading,

  /// Wrong credentials or server fault — generic message, input preserved.
  error,

  /// No connectivity — non-blocking banner, primary action disabled.
  offline,

  /// Authenticated — offers biometric opt-in with a password fallback.
  success,

  /// Biometric unavailable / denied — clean fall back to password.
  permissionDenied,
}

/// Result of an authentication attempt. Errors are intentionally coarse so the
/// UI can never reveal *which* field was wrong (AUTH-004).
enum AuthOutcome { success, invalidCredentials, serverError }

/// Copy. Kept as constants here so the layout code stays about layout; in a real
/// app these resolve through your localization layer (no string concatenation in
/// errors — L10N-002).
class _Strings {
  const _Strings._();

  static const String title = 'Sign in';
  static const String emailLabel = 'Email';
  static const String emailHint = 'you@example.com';
  static const String passwordLabel = 'Password';
  static const String passwordHint = 'Your password';
  static const String showPassword = 'Show password';
  static const String hidePassword = 'Hide password';
  static const String signIn = 'Sign in';
  static const String signingIn = 'Signing in…';
  static const String forgot = 'Forgot password?';
  static const String createAccount = 'New here? Create account';
  static const String guest = 'Continue as guest';
  static const String appleSso = 'Sign in with Apple';
  static const String googleSso = 'Sign in with Google';
  static const String errorGeneric = 'Email or password is incorrect';
  static const String errorServer = 'Something went wrong. Please try again.';
  static const String offlineBanner = "You're offline — check your connection";
  static const String offlineReason = 'Signing in needs a network connection';
  static const String fillFields = 'Enter your email and password';
  static const String offlineToggle = 'Simulate offline (demo)';
  static const String signedIn = 'Signed in';
  static const String biometricPrompt = 'Sign in faster next time?';
  static const String biometricBody =
      'Use %s to sign in without typing your password. You can always use your '
      'password instead.';
  static const String enable = 'Enable';
  static const String notNow = 'Not now';
  static const String faceId = 'Face ID';
  static const String biometricUnlock = 'biometric unlock';
  static const String permissionTitle = 'Biometric unlock is off';
  static const String permissionBody =
      "Your device hasn't enrolled a biometric, or it's turned off for this app. "
      'You can turn it on in Settings, or just keep using your password.';
  static const String openSettings = 'Open Settings';
  static const String keepPassword = 'Keep using password';
}

/// Sign-in surface. All handlers are optional so it drops into any app; the demo
/// defaults simulate the network so it runs stand-alone.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.authenticate,
    this.enrollBiometric,
    this.onAuthenticated,
    this.onForgotPassword,
    this.onCreateAccount,
    this.onContinueAsGuest,
    this.onSignInWithApple,
    this.onSignInWithGoogle,
    this.onOpenSettings,
    this.isOffline = false,
  });

  /// Verify credentials. Returns an [AuthOutcome]. Defaults to a demo that
  /// "fails" for any email containing `fail`, else succeeds.
  final Future<AuthOutcome> Function(String email, String password)?
      authenticate;

  /// Enroll a platform biometric. Return `false` (or throw) to route to the
  /// permission-denied fallback. Defaults to a demo that grants.
  final Future<bool> Function()? enrollBiometric;

  /// Called once the user is authenticated and any biometric prompt resolved —
  /// navigate to the intended destination / deep link here (NAV-008).
  final VoidCallback? onAuthenticated;

  final VoidCallback? onForgotPassword;
  final VoidCallback? onCreateAccount;
  final VoidCallback? onContinueAsGuest;
  final VoidCallback? onSignInWithApple;
  final VoidCallback? onSignInWithGoogle;
  final VoidCallback? onOpenSettings;

  /// Initial connectivity. In a real app, drive this from `connectivity_plus`.
  final bool isOffline;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _errorFocus = FocusNode(debugLabel: 'loginError');

  LoginStatus _status = LoginStatus.empty;
  String? _errorMessage;
  bool _obscure = true;
  bool _manualOffline = false;

  bool get _offline => widget.isOffline || _manualOffline;
  bool get _loading => _status == LoginStatus.loading;
  bool get _bothFilled =>
      _email.text.trim().isNotEmpty && _password.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _email.addListener(_onInputChanged);
    _password.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _errorFocus.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    // Editing clears a stale error but preserves the text (FRM-009).
    final next = _bothFilled ? LoginStatus.idle : LoginStatus.empty;
    if (_status == LoginStatus.error ||
        _status == LoginStatus.idle ||
        _status == LoginStatus.empty) {
      if (_status != next || _errorMessage != null) {
        setState(() {
          _status = next;
          _errorMessage = null;
        });
      }
    }
  }

  void _toggleObscure() => setState(() => _obscure = !_obscure);

  Future<void> _submit() async {
    if (_loading || !_bothFilled || _offline) return; // double-submit blocked
    _emailFocus.unfocus();
    _passwordFocus.unfocus();
    setState(() {
      _status = LoginStatus.loading;
      _errorMessage = null;
    });

    final auth = widget.authenticate ?? _demoAuthenticate;
    final outcome = await auth(_email.text.trim(), _password.text);
    if (!mounted) return;

    switch (outcome) {
      case AuthOutcome.success:
        // Commit the credential so the OS can save it / mint a passkey.
        TextInput.finishAutofillContext();
        setState(() => _status = LoginStatus.success);
        await _offerBiometric();
      case AuthOutcome.invalidCredentials:
        _showError(_Strings.errorGeneric);
      case AuthOutcome.serverError:
        _showError(_Strings.errorServer);
    }
  }

  void _showError(String message) {
    setState(() {
      _status = LoginStatus.error;
      _errorMessage = message; // input is never cleared (FRM-009)
    });
    // Move focus to the message; the error's Semantics(liveRegion: true) speaks
    // it to assistive tech on reveal (A11Y-018 / A11Y-019).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _errorFocus.requestFocus();
    });
  }

  Future<void> _offerBiometric() async {
    final label = _biometricLabel(context);
    final enable = await _showSheet<bool>(
      builder: (sheetContext) => _BiometricOptInSheet(
        colors: LoginColors.of(sheetContext),
        biometricLabel: label,
      ),
    );
    if (!mounted) return;

    if (enable == true) {
      final enroll = widget.enrollBiometric ?? _demoEnroll;
      final granted = await enroll();
      if (!mounted) return;
      if (!granted) {
        setState(() => _status = LoginStatus.permissionDenied);
        await _showPermissionDenied();
        if (!mounted) return;
      }
    }
    _finishAuthenticated();
  }

  Future<void> _showPermissionDenied() async {
    await _showSheet<void>(
      builder: (sheetContext) => _PermissionDeniedSheet(
        colors: LoginColors.of(sheetContext),
        onOpenSettings: () {
          Navigator.of(sheetContext).pop();
          widget.onOpenSettings?.call();
        },
        onKeepPassword: () => Navigator.of(sheetContext).pop(),
      ),
    );
  }

  void _finishAuthenticated() {
    widget.onAuthenticated?.call();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(_Strings.signedIn),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<T?> _showSheet<T>({required WidgetBuilder builder}) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: LoginColors.of(context).surface,
      builder: (sheetContext) => SafeArea(top: false, child: builder(sheetContext)),
    );
  }

  String _biometricLabel(BuildContext context) =>
      Theme.of(context).platform == TargetPlatform.iOS
          ? _Strings.faceId
          : _Strings.biometricUnlock;

  Future<AuthOutcome> _demoAuthenticate(String email, String password) async {
    await Future<void>.delayed(LoginMotion.demoLatency);
    if (email.toLowerCase().contains('fail')) {
      return AuthOutcome.invalidCredentials;
    }
    return AuthOutcome.success;
  }

  Future<bool> _demoEnroll() async {
    await Future<void>.delayed(LoginMotion.fast);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final colors = LoginColors.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    // Keyboard avoidance: lift the whole column above the IME (FRM-003).
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final canSubmit = _bothFilled && !_loading && !_offline;

    return Scaffold(
      backgroundColor: colors.surface,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _OfflineBanner(
                visible: _offline,
                colors: colors,
                reduceMotion: reduceMotion,
              ),
              Expanded(
                child: AutofillGroup(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      LoginSpace.edge,
                      LoginSpace.xl,
                      LoginSpace.edge,
                      LoginSpace.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Header(colors: colors),
                        const SizedBox(height: LoginSpace.lg),
                        _OfflineDemoToggle(
                          value: _manualOffline,
                          onChanged: (v) => setState(() => _manualOffline = v),
                          colors: colors,
                        ),
                        const SizedBox(height: LoginSpace.lg),
                        _emailField(colors),
                        const SizedBox(height: LoginSpace.fieldGap),
                        _passwordField(colors),
                        const SizedBox(height: LoginSpace.labelGap),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton(
                            onPressed: widget.onForgotPassword,
                            style: _linkStyle(),
                            child: const Text(_Strings.forgot),
                          ),
                        ),
                        const SizedBox(height: LoginSpace.md),
                        _ErrorRegion(
                          message: _errorMessage,
                          visible: _status == LoginStatus.error,
                          colors: colors,
                          reduceMotion: reduceMotion,
                          focusNode: _errorFocus,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _ActionBar(
                colors: colors,
                reduceMotion: reduceMotion,
                isIOS: isIOS,
                loading: _loading,
                canSubmit: canSubmit,
                offline: _offline,
                bothFilled: _bothFilled,
                onSubmit: _submit,
                onApple: widget.onSignInWithApple,
                onGoogle: widget.onSignInWithGoogle,
                onCreateAccount: widget.onCreateAccount,
                onGuest: widget.onContinueAsGuest,
                linkStyle: _linkStyle(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ButtonStyle _linkStyle() => TextButton.styleFrom(
        minimumSize: const Size(LoginSize.targetMin, LoginSize.targetMin),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: LoginSpace.sm),
        tapTargetSize: MaterialTapTargetSize.padded,
      );

  Widget _emailField(LoginColors colors) {
    return TextField(
      controller: _email,
      focusNode: _emailFocus,
      enabled: !_loading,
      autofillHints: const [AutofillHints.username, AutofillHints.email],
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      textCapitalization: TextCapitalization.none,
      onSubmitted: (_) => _passwordFocus.requestFocus(),
      style: LoginType.field(context)?.copyWith(color: colors.onSurface),
      decoration: _fieldDecoration(
        colors,
        label: _Strings.emailLabel,
        hint: _Strings.emailHint,
        prefix: Icons.mail_outline,
      ),
    );
  }

  Widget _passwordField(LoginColors colors) {
    return TextField(
      controller: _password,
      focusNode: _passwordFocus,
      enabled: !_loading,
      autofillHints: const [AutofillHints.password],
      obscureText: _obscure,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      autocorrect: false,
      enableSuggestions: false,
      onSubmitted: (_) => _submit(),
      style: LoginType.field(context)?.copyWith(color: colors.onSurface),
      decoration: _fieldDecoration(
        colors,
        label: _Strings.passwordLabel,
        hint: _Strings.passwordHint,
        prefix: Icons.lock_outline,
        suffix: _ObscureToggle(
          obscure: _obscure,
          onToggle: _toggleObscure,
          colors: colors,
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(
    LoginColors colors, {
    required String label,
    required String hint,
    required IconData prefix,
    Widget? suffix,
  }) {
    final radius =
        const BorderRadius.all(Radius.circular(LoginRadius.control));
    final base = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: colors.outline),
    );
    return InputDecoration(
      labelText: label, // programmatic label (A11Y-004)
      hintText: hint,
      filled: true,
      fillColor: colors.surfaceContainer,
      labelStyle: LoginType.label(context)?.copyWith(color: colors.onSurfaceMuted),
      hintStyle: LoginType.body(context)?.copyWith(color: colors.onSurfaceMuted),
      contentPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: LoginSpace.md,
        vertical: LoginSpace.md,
      ),
      prefixIcon: ExcludeSemantics(
        child: Icon(prefix, size: LoginSize.icon, color: colors.onSurfaceMuted),
      ),
      suffixIcon: suffix,
      border: base,
      enabledBorder: base,
      focusedBorder: base.copyWith(
        borderSide: BorderSide(color: colors.focus, width: LoginSize.stroke),
      ),
    );
  }
}

/// Brand mark + title. Non-interactive top zone (spec "Top").
class _Header extends StatelessWidget {
  const _Header({required this.colors});
  final LoginColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline,
            size: LoginSize.icon, color: colors.primary),
        const SizedBox(height: LoginSpace.sm),
        Semantics(
          header: true,
          child: Text(
            _Strings.title,
            style: LoginType.title(context)?.copyWith(color: colors.onSurface),
          ),
        ),
      ],
    );
  }
}

/// Demo-only affordance to preview the offline state without a real network
/// change. Remove in production — connectivity should come from the platform.
class _OfflineDemoToggle extends StatelessWidget {
  const _OfflineDemoToggle({
    required this.value,
    required this.onChanged,
    required this.colors,
  });
  final bool value;
  final ValueChanged<bool> onChanged;
  final LoginColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            _Strings.offlineToggle,
            style: LoginType.caption(context)
                ?.copyWith(color: colors.onSurfaceMuted),
          ),
        ),
        const SizedBox(width: LoginSpace.sm),
        Switch.adaptive(value: value, onChanged: onChanged),
      ],
    );
  }
}

/// Labeled show/hide toggle with a 48dp hit area that exposes its on/off state
/// to assistive tech (AUTH-003, A11Y-006).
class _ObscureToggle extends StatelessWidget {
  const _ObscureToggle({
    required this.obscure,
    required this.onToggle,
    required this.colors,
  });
  final bool obscure;
  final VoidCallback onToggle;
  final LoginColors colors;

  @override
  Widget build(BuildContext context) {
    final label = obscure ? _Strings.showPassword : _Strings.hidePassword;
    return Semantics(
      button: true,
      toggled: !obscure, // exposes "showing" vs "hidden"
      label: label,
      child: IconButton(
        onPressed: onToggle,
        tooltip: label,
        padding: const EdgeInsets.all(LoginSpace.sm),
        constraints: const BoxConstraints(
          minWidth: LoginSize.targetMin,
          minHeight: LoginSize.targetMin,
        ),
        iconSize: LoginSize.icon,
        color: colors.onSurfaceMuted,
        icon: Icon(
          obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
      ),
    );
  }
}

/// Non-blocking offline banner, announced as a live region (STATE-008, BDG-002).
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({
    required this.visible,
    required this.colors,
    required this.reduceMotion,
  });
  final bool visible;
  final LoginColors colors;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: reduceMotion ? Duration.zero : LoginMotion.standard,
      alignment: AlignmentDirectional.topStart,
      child: !visible
          ? const SizedBox.shrink()
          : Semantics(
              liveRegion: true,
              container: true,
              child: Container(
                color: colors.surfaceContainer,
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: LoginSpace.edge,
                  vertical: LoginSpace.sm,
                ),
                child: Row(
                  children: [
                    Icon(Icons.cloud_off_outlined,
                        size: LoginSize.icon, color: colors.onSurfaceMuted),
                    const SizedBox(width: LoginSpace.sm),
                    Expanded(
                      child: Text(
                        _Strings.offlineBanner,
                        style: LoginType.body(context)
                            ?.copyWith(color: colors.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Inline error above the primary button. Generic copy (never reveals the field),
/// icon-paired (not color-only), focus-receiving, and announced (AUTH-004,
/// A11Y-018). Reveal animates opacity/height only, collapsing under reduce-motion.
class _ErrorRegion extends StatelessWidget {
  const _ErrorRegion({
    required this.message,
    required this.visible,
    required this.colors,
    required this.reduceMotion,
    required this.focusNode,
  });
  final String? message;
  final bool visible;
  final LoginColors colors;
  final bool reduceMotion;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final duration = reduceMotion ? Duration.zero : LoginMotion.standard;
    return AnimatedSize(
      duration: duration,
      alignment: AlignmentDirectional.topStart,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: duration,
        child: !visible || message == null
            ? const SizedBox.shrink()
            : Focus(
                focusNode: focusNode,
                canRequestFocus: true,
                child: Semantics(
                  liveRegion: true,
                  container: true,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline,
                          size: LoginSize.icon, color: colors.error),
                      const SizedBox(width: LoginSpace.sm),
                      Expanded(
                        child: Text(
                          message!,
                          textAlign: TextAlign.start,
                          style: LoginType.body(context)
                              ?.copyWith(color: colors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// Sticky bottom action zone: full-width primary, SSO, and sub-links — the whole
/// bottom arc (BTN-006/007). Rides above the keyboard (parent lifts it) and above
/// the home-indicator inset when the keyboard is down (SafeArea).
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.colors,
    required this.reduceMotion,
    required this.isIOS,
    required this.loading,
    required this.canSubmit,
    required this.offline,
    required this.bothFilled,
    required this.onSubmit,
    required this.onApple,
    required this.onGoogle,
    required this.onCreateAccount,
    required this.onGuest,
    required this.linkStyle,
  });

  final LoginColors colors;
  final bool reduceMotion;
  final bool isIOS;
  final bool loading;
  final bool canSubmit;
  final bool offline;
  final bool bothFilled;
  final VoidCallback onSubmit;
  final VoidCallback? onApple;
  final VoidCallback? onGoogle;
  final VoidCallback? onCreateAccount;
  final VoidCallback? onGuest;
  final ButtonStyle linkStyle;

  @override
  Widget build(BuildContext context) {
    final sso = <Widget>[
      _SsoButton(
        label: _Strings.appleSso,
        icon: Icons.apple,
        onPressed: onApple,
        colors: colors,
      ),
      const SizedBox(height: LoginSpace.actionGap),
      _SsoButton(
        label: _Strings.googleSso,
        icon: Icons.g_mobiledata,
        onPressed: onGoogle,
        colors: colors,
      ),
    ];
    // Platform-order SSO: Apple first on iOS, Google first elsewhere (AUTH-005).
    final orderedSso = isIOS ? sso : sso.reversed.toList();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.divider)),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          LoginSpace.edge,
          LoginSpace.md,
          LoginSpace.edge,
          LoginSpace.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PrimaryButton(
              colors: colors,
              reduceMotion: reduceMotion,
              loading: loading,
              canSubmit: canSubmit,
              offline: offline,
              bothFilled: bothFilled,
              onSubmit: onSubmit,
            ),
            const SizedBox(height: LoginSpace.actionGap),
            ...orderedSso,
            const SizedBox(height: LoginSpace.md),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton(
                  onPressed: onCreateAccount,
                  style: linkStyle,
                  child: const Text(_Strings.createAccount),
                ),
                TextButton(
                  onPressed: onGuest,
                  style: linkStyle,
                  child: const Text(_Strings.guest),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width primary "Sign in". minHeight 48; loading swaps the label for a
/// spinner with a stable width; disabled with a spoken reason when it can't run
/// (BTN-003/007). No shake, no width jump — reduce-motion aware crossfade.
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.colors,
    required this.reduceMotion,
    required this.loading,
    required this.canSubmit,
    required this.offline,
    required this.bothFilled,
    required this.onSubmit,
  });
  final LoginColors colors;
  final bool reduceMotion;
  final bool loading;
  final bool canSubmit;
  final bool offline;
  final bool bothFilled;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    // Keep the primary look while loading (disabled bg == primary); muted only
    // when genuinely blocked (empty / offline).
    final disabledBg = loading ? colors.primary : colors.surfaceContainer;
    final disabledFg = loading ? colors.onPrimary : colors.onSurfaceMuted;
    final hint = offline
        ? _Strings.offlineReason
        : (bothFilled ? '' : _Strings.fillFields);

    return Semantics(
      button: true,
      enabled: canSubmit,
      hint: hint,
      child: FilledButton(
        onPressed: canSubmit ? onSubmit : null,
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          disabledBackgroundColor: disabledBg,
          disabledForegroundColor: disabledFg,
          minimumSize: const Size(double.infinity, LoginSize.targetMin),
          textStyle: LoginType.button(context),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(LoginRadius.control)),
          ),
        ),
        child: AnimatedSwitcher(
          duration: reduceMotion ? Duration.zero : LoginMotion.standard,
          child: loading
              ? Row(
                  key: const ValueKey<String>('loading'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox.square(
                      dimension: LoginSize.spinner,
                      child: CircularProgressIndicator(
                        strokeWidth: LoginSize.stroke,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(colors.onPrimary),
                      ),
                    ),
                    const SizedBox(width: LoginSpace.sm),
                    const Text(_Strings.signingIn),
                  ],
                )
              : const Text(
                  _Strings.signIn,
                  key: ValueKey<String>('label'),
                ),
        ),
      ),
    );
  }
}

/// One SSO button. Role + text label carry the meaning; the glyph is decorative
/// so identity is never conveyed by logo color alone (A11Y-005, A11Y-012).
class _SsoButton extends StatelessWidget {
  const _SsoButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.colors,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final LoginColors colors;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, LoginSize.targetMin),
        foregroundColor: colors.onSurface,
        textStyle: LoginType.button(context),
        side: BorderSide(color: colors.outline),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(LoginRadius.control)),
        ),
      ),
      icon: ExcludeSemantics(child: Icon(icon, size: LoginSize.icon)),
      label: Text(label),
    );
  }
}

/// Success overlay content — biometric opt-in with an explicit password fallback
/// (AUTH-002, STATE-009). `%s` is filled with the platform biometric name.
class _BiometricOptInSheet extends StatelessWidget {
  const _BiometricOptInSheet({
    required this.colors,
    required this.biometricLabel,
  });
  final LoginColors colors;
  final String biometricLabel;

  @override
  Widget build(BuildContext context) {
    final body = _Strings.biometricBody.replaceFirst('%s', biometricLabel);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        LoginSpace.lg,
        LoginSpace.sm,
        LoginSpace.lg,
        LoginSpace.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.verified_user_outlined,
              size: LoginSize.icon, color: colors.success),
          const SizedBox(height: LoginSpace.sm),
          Text(
            _Strings.biometricPrompt,
            style: LoginType.title(context)?.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: LoginSpace.sm),
          Text(
            body,
            style: LoginType.body(context)?.copyWith(color: colors.onSurfaceMuted),
          ),
          const SizedBox(height: LoginSpace.lg),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              minimumSize: const Size(double.infinity, LoginSize.targetMin),
              textStyle: LoginType.button(context),
              shape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.all(Radius.circular(LoginRadius.control)),
              ),
            ),
            child: const Text(_Strings.enable),
          ),
          const SizedBox(height: LoginSpace.sm),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, LoginSize.targetMin),
              foregroundColor: colors.onSurface,
              textStyle: LoginType.button(context),
            ),
            child: const Text(_Strings.notNow),
          ),
        ],
      ),
    );
  }
}

/// Permission-denied fallback: explain, offer Settings, never dead-end — the
/// password path always remains (AUTH-002, PERM-003, STATE-010).
class _PermissionDeniedSheet extends StatelessWidget {
  const _PermissionDeniedSheet({
    required this.colors,
    required this.onOpenSettings,
    required this.onKeepPassword,
  });
  final LoginColors colors;
  final VoidCallback onOpenSettings;
  final VoidCallback onKeepPassword;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        LoginSpace.lg,
        LoginSpace.sm,
        LoginSpace.lg,
        LoginSpace.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.fingerprint,
              size: LoginSize.icon, color: colors.onSurfaceMuted),
          const SizedBox(height: LoginSpace.sm),
          Text(
            _Strings.permissionTitle,
            style: LoginType.title(context)?.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: LoginSpace.sm),
          Text(
            _Strings.permissionBody,
            style: LoginType.body(context)?.copyWith(color: colors.onSurfaceMuted),
          ),
          const SizedBox(height: LoginSpace.lg),
          FilledButton(
            onPressed: onOpenSettings,
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              minimumSize: const Size(double.infinity, LoginSize.targetMin),
              textStyle: LoginType.button(context),
              shape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.all(Radius.circular(LoginRadius.control)),
              ),
            ),
            child: const Text(_Strings.openSettings),
          ),
          const SizedBox(height: LoginSpace.sm),
          TextButton(
            onPressed: onKeepPassword,
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, LoginSize.targetMin),
              foregroundColor: colors.onSurface,
              textStyle: LoginType.button(context),
            ),
            child: const Text(_Strings.keepPassword),
          ),
        ],
      ),
    );
  }
}
