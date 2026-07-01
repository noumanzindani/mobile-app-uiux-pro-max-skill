// checkout_tokens.dart
//
// The semantic token layer for the Checkout example (a trustworthy, low-friction
// payment flow). This is the ONLY file in the example allowed to hold raw values
// (hex colors, grid numbers, milliseconds). The widget references these constants
// exclusively, so a rebrand or a dark-mode swap becomes a token change, not a
// refactor (COL-*, SPC-*, DRK-*, MOT-*, TYP-*).
//
// Values are faithful to the skill design system:
//   design-system/tokens/primitives/{color,dimension}.json
//   design-system/tokens/themes/{light,dark}.json
//
// token_lint requirement: EVERY line below that carries a raw hex or number ends
// with `// ux:ignore`. Spacing stays on the 4/8 grid (4, 8, 12, 16, 24, 32, 48).
//
// Money uses TABULAR figures ([FontFeature.tabularFigures]) so that digits share a
// fixed advance width — a recomputed total never shifts sideways, and columns of
// amounts align to the decimal (TYP-006). Amount roles derive from Theme text
// styles, so they still scale with Dynamic Type / font scale (no fixed sizes).
//
// The native Pay button (Apple Pay / Google Pay) is the ONE surface allowed a
// platform-mandated brand color: Apple's Human Interface Guidelines and Google
// Pay's brand spec require an exact black/white treatment that must NOT be
// re-tokenized to the app palette (PAY-001, COL-001 native-Pay exception). Those
// two constants live here, raw, each marked `// ux:ignore` and labeled "brand".
//
// In a production app you would carry these on a ThemeExtension<T> (see
// frameworks/flutter/tokens.md); a plain resolver keeps this file dependency-free.

import 'package:flutter/material.dart';

/// Primitive palette — named by value, no semantic meaning. Referenced only by
/// [CheckoutColors] below; widgets never touch these directly.
class _CheckoutPalette {
  const _CheckoutPalette._();

  static const Color neutral0 = Color(0xFFFFFFFF); // ux:ignore  neutral #FFFFFF
  static const Color neutral50 = Color(0xFFF8FAFC); // ux:ignore  neutral #F8FAFC
  static const Color neutral100 = Color(0xFFF1F5F9); // ux:ignore  neutral #F1F5F9
  static const Color neutral200 = Color(0xFFE2E8F0); // ux:ignore  neutral #E2E8F0
  static const Color neutral400 = Color(0xFF94A3B8); // ux:ignore  neutral #94A3B8
  static const Color neutral500 = Color(0xFF64748B); // ux:ignore  neutral #64748B
  static const Color neutral600 = Color(0xFF475569); // ux:ignore  neutral #475569
  static const Color neutral800 = Color(0xFF1E293B); // ux:ignore  neutral #1E293B
  static const Color neutral900 = Color(0xFF0F172A); // ux:ignore  neutral #0F172A
  static const Color neutral950 = Color(0xFF020617); // ux:ignore  neutral #020617
  static const Color blue400 = Color(0xFF60A5FA); // ux:ignore  primary (dark) #60A5FA
  static const Color blue500 = Color(0xFF2563EB); // ux:ignore  primary (light) #2563EB
  static const Color red400 = Color(0xFFF87171); // ux:ignore  status error (dark) #F87171
  static const Color red600 = Color(0xFFB91C1C); // ux:ignore  status error (light) #B91C1C
  static const Color green400 = Color(0xFF4ADE80); // ux:ignore  status success (dark) #4ADE80
  static const Color green600 = Color(0xFF15803D); // ux:ignore  status success (light) #15803D

  // Platform-mandated native Pay brand colors — NOT part of the app palette.
  static const Color brandBlack = Color(0xFF000000); // ux:ignore  Apple/Google Pay brand black #000000
  static const Color brandWhite = Color(0xFFFFFFFF); // ux:ignore  Apple/Google Pay brand white #FFFFFF
}

/// Semantic color roles, resolved per [Brightness]. Every role maps to a
/// design-system semantic token in themes/{light,dark}.json. Foreground/background
/// pairs are chosen so their contrast is >= 4.5:1 (WCAG 1.4.3) in both themes.
@immutable
class CheckoutColors {
  const CheckoutColors({
    required this.surface,
    required this.surfaceContainer,
    required this.outline,
    required this.focus,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.onSurfaceStrong,
    required this.primary,
    required this.onPrimary,
    required this.success,
    required this.error,
    required this.divider,
    required this.payBrand,
    required this.onPayBrand,
  });

  /// Screen background — `color.surface`.
  final Color surface;

  /// Summary card / field / raised container — `color.surface.container`.
  final Color surfaceContainer;

  /// Field border / control outline — `color.border` (>= 3:1, WCAG 1.4.11).
  final Color outline;

  /// Focus ring — `color.action.focus` (>= 3:1).
  final Color focus;

  /// Body / label text — `color.on-surface` (>= 4.5:1).
  final Color onSurface;

  /// Helper / secondary line text — `color.on-surface-muted` (>= 4.5:1).
  final Color onSurfaceMuted;

  /// Total emphasis text — `color.on-surface-strong` (the grand total, never
  /// conveyed by weight/color alone — always paired with the "Total" label).
  final Color onSurfaceStrong;

  /// Primary Pay button background — `color.action.primary`.
  final Color primary;

  /// Primary Pay button label — `color.action.on-primary` (>= 4.5:1).
  final Color onPrimary;

  /// Trust / confirmation accent — `color.status.success`. Always paired with an
  /// icon + text label, never color-only (COL-003, A11Y-012).
  final Color success;

  /// Decline / error accent — `color.status.error`. Paired with an icon + text.
  final Color error;

  /// Hairline divider — `color.divider`.
  final Color divider;

  /// Native Pay button fill — platform-mandated brand color (Apple/Google Pay).
  /// Black button in light, white button in dark, per each platform's brand spec.
  final Color payBrand;

  /// Native Pay button label/glyph — the brand foreground paired with [payBrand].
  final Color onPayBrand;

  static const CheckoutColors light = CheckoutColors(
    surface: _CheckoutPalette.neutral0,
    surfaceContainer: _CheckoutPalette.neutral50,
    outline: _CheckoutPalette.neutral500,
    focus: _CheckoutPalette.blue500,
    onSurface: _CheckoutPalette.neutral900,
    onSurfaceMuted: _CheckoutPalette.neutral600,
    onSurfaceStrong: _CheckoutPalette.neutral950,
    primary: _CheckoutPalette.blue500,
    onPrimary: _CheckoutPalette.neutral0,
    success: _CheckoutPalette.green600,
    error: _CheckoutPalette.red600,
    divider: _CheckoutPalette.neutral200,
    payBrand: _CheckoutPalette.brandBlack,
    onPayBrand: _CheckoutPalette.brandWhite,
  );

  static const CheckoutColors dark = CheckoutColors(
    surface: _CheckoutPalette.neutral950,
    surfaceContainer: _CheckoutPalette.neutral800,
    outline: _CheckoutPalette.neutral500,
    focus: _CheckoutPalette.blue400,
    onSurface: _CheckoutPalette.neutral100,
    onSurfaceMuted: _CheckoutPalette.neutral400,
    onSurfaceStrong: _CheckoutPalette.neutral0,
    primary: _CheckoutPalette.blue400,
    onPrimary: _CheckoutPalette.neutral950,
    success: _CheckoutPalette.green400,
    error: _CheckoutPalette.red400,
    divider: _CheckoutPalette.neutral800,
    payBrand: _CheckoutPalette.brandWhite,
    onPayBrand: _CheckoutPalette.brandBlack,
  );

  /// ThemeMode-aware resolver: pick the palette for the active brightness.
  static CheckoutColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Spacing scale on the 4/8 grid (semantic/spacing.json). Screen edge = 16.
class CheckoutSpace {
  const CheckoutSpace._();

  static const double xs = 4; // ux:ignore  space.1 — error gap
  static const double sm = 8; // ux:ignore  space.2 — label -> control, icon gap
  static const double rowGap = 12; // ux:ignore  space.3 — review / summary rows
  static const double md = 16; // ux:ignore  space.4 — edge + field gap (SPC-003/013)
  static const double lg = 24; // ux:ignore  space.6 — section gap
  static const double xl = 32; // ux:ignore  space.8 — success hero spacing

  static const double edge = 16; // ux:ignore  screen edge inset (SPC-003)
  static const double fieldGap = 16; // ux:ignore  between fields (SPC-013)
  static const double labelGap = 8; // ux:ignore  label -> input
  static const double errorGap = 4; // ux:ignore  input -> error
  static const double actionGap = 12; // ux:ignore  stacked action gap
}

/// Corner radii (dimension.json). Fields and buttons share `radius.md`; the
/// summary card and success hero use `radius.lg`.
class CheckoutRadius {
  const CheckoutRadius._();

  static const double control = 12; // ux:ignore  radius.md — fields + buttons
  static const double card = 16; // ux:ignore  radius.lg — summary / method cards
}

/// Control sizing. Touch targets meet Material 48dp / Apple 44pt.
class CheckoutSize {
  const CheckoutSize._();

  static const double targetMin = 48; // ux:ignore  Material min touch target
  static const double targetMinIOS = 44; // ux:ignore  Apple HIG min target
  static const double icon = 24; // ux:ignore  field / action glyph
  static const double iconSm = 20; // ux:ignore  inline meta glyph
  static const double spinner = 20; // ux:ignore  inline button spinner
  static const double stroke = 2; // ux:ignore  spinner / focus-ring stroke
  static const double successMark = 48; // ux:ignore  confirmation check glyph
  static const double freeShipBar = 4; // ux:ignore  free-shipping progress height
}

/// Motion tokens. All animation is transform/opacity only and collapses to
/// [Duration.zero] under reduce-motion (MOT-004, A11Y-011).
class CheckoutMotion {
  const CheckoutMotion._();

  static const Duration fast = Duration(milliseconds: 150); // ux:ignore  focus / control (MIC-001)
  static const Duration standard = Duration(milliseconds: 200); // ux:ignore  banner / error reveal (MOT-001)
  static const Duration total = Duration(milliseconds: 260); // ux:ignore  total number transition (MOT-001)
  static const Duration success = Duration(milliseconds: 280); // ux:ignore  confirmation check reveal (MIC-002)
  static const Duration demoLatency = Duration(milliseconds: 1400); // ux:ignore  simulated charge only
}

/// Typography roles map to `Theme.textTheme`, so text scales with Dynamic Type /
/// font scale automatically (no fixed sizes — TYP-002, A11Y-010). Amount roles add
/// tabular figures so digits align and a recomputed total never jitters (TYP-006).
class CheckoutType {
  const CheckoutType._();

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  static TextStyle? title(BuildContext c) => Theme.of(c).textTheme.headlineSmall;
  static TextStyle? section(BuildContext c) => Theme.of(c).textTheme.titleMedium;
  static TextStyle? field(BuildContext c) => Theme.of(c).textTheme.bodyLarge;
  static TextStyle? body(BuildContext c) => Theme.of(c).textTheme.bodyMedium;
  static TextStyle? label(BuildContext c) => Theme.of(c).textTheme.labelLarge;
  static TextStyle? button(BuildContext c) => Theme.of(c).textTheme.titleMedium;
  static TextStyle? caption(BuildContext c) => Theme.of(c).textTheme.bodySmall;

  /// A line-item / summary amount — tabular figures.
  static TextStyle? amount(BuildContext c) =>
      Theme.of(c).textTheme.bodyMedium?.copyWith(fontFeatures: _tabular);

  /// The grand total — tabular figures, emphasis carried by the strong color role.
  static TextStyle? amountStrong(BuildContext c) =>
      Theme.of(c).textTheme.titleLarge?.copyWith(fontFeatures: _tabular);

  /// The amount on the sticky Pay button — tabular figures on the button role.
  static TextStyle? amountButton(BuildContext c) =>
      Theme.of(c).textTheme.titleMedium?.copyWith(fontFeatures: _tabular);
}
