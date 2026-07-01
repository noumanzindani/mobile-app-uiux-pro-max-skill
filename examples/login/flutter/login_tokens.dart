// login_tokens.dart
//
// The semantic token layer for the Login example (the sign-in flow). This is the
// ONLY file in the example allowed to hold raw values (hex colors, grid numbers,
// milliseconds). The widget references these constants exclusively, so a rebrand
// or a dark-mode swap becomes a token change, not a refactor (COL-*, SPC-*, DRK-*).
//
// Values are faithful to the skill design system:
//   design-system/tokens/primitives/{color,dimension}.json
//   design-system/tokens/themes/{light,dark}.json
//
// token_lint requirement: EVERY line below that carries a raw hex or number ends
// with `// ux:ignore`. Spacing stays on the 4/8 grid (4, 8, 12, 16, 24, 32, 48).
//
// In a production app you would carry these on a ThemeExtension<T> (see
// frameworks/flutter/tokens.md); a plain resolver keeps this file dependency-free.

import 'package:flutter/material.dart';

/// Primitive palette — named by value, no semantic meaning. Referenced only by
/// [LoginColors] below; widgets never touch these directly.
class _LoginPalette {
  const _LoginPalette._();

  static const Color neutral0 = Color(0xFFFFFFFF); // ux:ignore  #FFFFFF
  static const Color neutral50 = Color(0xFFF8FAFC); // ux:ignore  #F8FAFC
  static const Color neutral100 = Color(0xFFF1F5F9); // ux:ignore  #F1F5F9
  static const Color neutral200 = Color(0xFFE2E8F0); // ux:ignore  #E2E8F0
  static const Color neutral400 = Color(0xFF94A3B8); // ux:ignore  #94A3B8
  static const Color neutral500 = Color(0xFF64748B); // ux:ignore  #64748B
  static const Color neutral600 = Color(0xFF475569); // ux:ignore  #475569
  static const Color neutral800 = Color(0xFF1E293B); // ux:ignore  #1E293B
  static const Color neutral900 = Color(0xFF0F172A); // ux:ignore  #0F172A
  static const Color neutral950 = Color(0xFF020617); // ux:ignore  #020617
  static const Color blue400 = Color(0xFF60A5FA); // ux:ignore  #60A5FA
  static const Color blue500 = Color(0xFF2563EB); // ux:ignore  #2563EB
  static const Color red400 = Color(0xFFF87171); // ux:ignore  #F87171
  static const Color red600 = Color(0xFFB91C1C); // ux:ignore  #B91C1C
  static const Color green400 = Color(0xFF4ADE80); // ux:ignore  #4ADE80
  static const Color green600 = Color(0xFF15803D); // ux:ignore  #15803D
}

/// Semantic color roles, resolved per [Brightness]. Every role maps to a
/// design-system semantic token in themes/{light,dark}.json.
@immutable
class LoginColors {
  const LoginColors({
    required this.surface,
    required this.surfaceContainer,
    required this.outline,
    required this.focus,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.primary,
    required this.onPrimary,
    required this.error,
    required this.success,
    required this.divider,
  });

  /// Screen background — `color.surface`.
  final Color surface;

  /// Field background / raised container — `color.surface-raised`.
  final Color surfaceContainer;

  /// Field border / control outline — `color.border` (>= 3:1, WCAG 1.4.11).
  final Color outline;

  /// Focus ring — `color.action.focus` (>= 3:1).
  final Color focus;

  /// Body / title / label text — `color.on-surface` (>= 4.5:1).
  final Color onSurface;

  /// Placeholder / helper text — `color.on-surface-muted`.
  final Color onSurfaceMuted;

  /// Primary button background — `color.action.primary`.
  final Color primary;

  /// Primary button label — `color.action.on-primary`.
  final Color onPrimary;

  /// Error text + icon — `color.text.error` (paired with an icon, never
  /// color-only).
  final Color error;

  /// Success accent — `color.text.success`.
  final Color success;

  /// Hairline divider — `color.divider`.
  final Color divider;

  static const LoginColors light = LoginColors(
    surface: _LoginPalette.neutral0,
    surfaceContainer: _LoginPalette.neutral50,
    outline: _LoginPalette.neutral500,
    focus: _LoginPalette.blue500,
    onSurface: _LoginPalette.neutral900,
    onSurfaceMuted: _LoginPalette.neutral600,
    primary: _LoginPalette.blue500,
    onPrimary: _LoginPalette.neutral0,
    error: _LoginPalette.red600,
    success: _LoginPalette.green600,
    divider: _LoginPalette.neutral200,
  );

  static const LoginColors dark = LoginColors(
    surface: _LoginPalette.neutral950,
    surfaceContainer: _LoginPalette.neutral800,
    outline: _LoginPalette.neutral500,
    focus: _LoginPalette.blue400,
    onSurface: _LoginPalette.neutral100,
    onSurfaceMuted: _LoginPalette.neutral400,
    primary: _LoginPalette.blue400,
    onPrimary: _LoginPalette.neutral950,
    error: _LoginPalette.red400,
    success: _LoginPalette.green400,
    divider: _LoginPalette.neutral800,
  );

  /// ThemeMode-aware resolver: pick the palette for the active brightness.
  static LoginColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Spacing scale on the 4/8 grid (semantic/spacing.json). Screen edge = 16.
class LoginSpace {
  const LoginSpace._();

  static const double xs = 4; // ux:ignore  space.1
  static const double sm = 8; // ux:ignore  space.2 — target gap
  static const double md = 16; // ux:ignore  space.4 — default content padding
  static const double lg = 24; // ux:ignore  space.6
  static const double xl = 32; // ux:ignore  space.8

  static const double edge = 16; // ux:ignore  screen edge inset (SPC-003)
  static const double fieldGap = 16; // ux:ignore  between fields (SPC-013)
  static const double labelGap = 8; // ux:ignore  label -> input
  static const double errorGap = 4; // ux:ignore  input -> error
  static const double actionGap = 12; // ux:ignore  primary -> SSO
}

/// Corner radii (dimension.json). Fields and buttons share `radius.md`.
class LoginRadius {
  const LoginRadius._();

  static const double control = 12; // ux:ignore  radius.md — fields + buttons
}

/// Control sizing. Touch targets meet Material 48dp / Apple 44pt.
class LoginSize {
  const LoginSize._();

  static const double targetMin = 48; // ux:ignore  Material min touch target
  static const double targetMinIOS = 44; // ux:ignore  Apple HIG min target
  static const double icon = 24; // ux:ignore  field / action glyph
  static const double spinner = 20; // ux:ignore  inline button spinner
  static const double stroke = 2; // ux:ignore  spinner / focus-ring stroke
}

/// Motion tokens. All screen animation is transform/opacity only and is
/// collapsed to [Duration.zero] under reduce-motion (MOT-004, A11Y-011).
class LoginMotion {
  const LoginMotion._();

  static const Duration fast = Duration(milliseconds: 150); // ux:ignore  focus/label (MIC-001)
  static const Duration standard = Duration(milliseconds: 180); // ux:ignore  error/loading reveal (MOT-001)
  static const Duration demoLatency = Duration(milliseconds: 1200); // ux:ignore  simulated network only
}

/// Typography roles map to `Theme.textTheme`, so text scales with Dynamic Type /
/// font scale automatically (no fixed sizes — TYP-002, A11Y-010).
class LoginType {
  const LoginType._();

  static TextStyle? title(BuildContext c) => Theme.of(c).textTheme.headlineSmall;
  static TextStyle? field(BuildContext c) => Theme.of(c).textTheme.bodyLarge;
  static TextStyle? body(BuildContext c) => Theme.of(c).textTheme.bodyMedium;
  static TextStyle? label(BuildContext c) => Theme.of(c).textTheme.labelLarge;
  static TextStyle? button(BuildContext c) => Theme.of(c).textTheme.titleMedium;
  static TextStyle? caption(BuildContext c) => Theme.of(c).textTheme.bodySmall;
}
