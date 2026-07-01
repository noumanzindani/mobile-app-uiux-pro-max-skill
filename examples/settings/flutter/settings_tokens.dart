// settings_tokens.dart
//
// The semantic token layer for the Settings example — a grouped, searchable
// preferences surface with an isolated destructive zone. This is the ONLY file
// in the example allowed to hold raw values (hex colors, grid numbers,
// milliseconds, breakpoints). The widget references these constants exclusively,
// so a rebrand or a dark-mode swap becomes a token change, not a refactor
// (COL-*, SPC-*, DRK-*, MOT-*, TYP-*).
//
// Values are faithful to the skill design system:
//   design-system/tokens/primitives/{color,dimension}.json
//   design-system/tokens/themes/{light,dark}.json
//
// token_lint requirement: EVERY line below that carries a raw hex or number ends
// with `// ux:ignore`. Spacing stays on the 4/8 grid (4, 8, 12, 16, 24, 32); the
// responsive breakpoints (600 / 840) also live here, each marked `// ux:ignore`
// so the widget can reference them by name.
//
// Grouped-inset rows follow the platform convention: raised row containers on a
// tinted background, hairline `outline.variant` dividers, an action-primary
// switch on-track, and a `status.error` label reserved for the destructive zone.
//
// In a production app you would carry these on a ThemeExtension<T> (see
// frameworks/flutter/tokens.md); a plain resolver keeps this file dependency-free.

import 'package:flutter/material.dart';

/// Primitive palette — named by value, no semantic meaning. Referenced only by
/// [SettingsColors] below; widgets never touch these directly.
class _SettingsPalette {
  const _SettingsPalette._();

  static const Color neutral0 = Color(0xFFFFFFFF); // ux:ignore  #FFFFFF
  static const Color neutral50 = Color(0xFFF8FAFC); // ux:ignore  #F8FAFC
  static const Color neutral100 = Color(0xFFF1F5F9); // ux:ignore  #F1F5F9
  static const Color neutral200 = Color(0xFFE2E8F0); // ux:ignore  #E2E8F0
  static const Color neutral400 = Color(0xFF94A3B8); // ux:ignore  #94A3B8
  static const Color neutral600 = Color(0xFF475569); // ux:ignore  #475569
  static const Color neutral700 = Color(0xFF334155); // ux:ignore  #334155
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
/// design-system semantic token in themes/{light,dark}.json. Foreground /
/// background pairs are chosen so their contrast is >= 4.5:1 (text) / >= 3:1
/// (switch tracks, dividers) in both themes (WCAG 1.4.3 / 1.4.11).
@immutable
class SettingsColors {
  const SettingsColors({
    required this.surface,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.skeleton,
    required this.outlineVariant,
    required this.focus,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.primary,
    required this.onPrimary,
    required this.error,
    required this.success,
  });

  /// Screen / grouped background — `color.surface`.
  final Color surface;

  /// Raised row container (grouped inset card) — `color.surface.container`.
  final Color surfaceContainer;

  /// Emphasized container (offline banner) — `color.surface.container-high`.
  final Color surfaceContainerHigh;

  /// Skeleton placeholder fill for server-synced values — `color.surface.container-highest`.
  final Color skeleton;

  /// Row divider / group inset hairline — `color.outline.variant` (>= 3:1).
  final Color outlineVariant;

  /// Focus ring / search field focus — `color.action.focus` (>= 3:1).
  final Color focus;

  /// Row label + value text — `color.on-surface` (>= 4.5:1).
  final Color onSurface;

  /// Secondary value / helper / section header text — `color.on-surface-variant`
  /// (>= 4.5:1).
  final Color onSurfaceVariant;

  /// Switch on-track / action-button background — `color.action.primary`.
  final Color primary;

  /// Switch thumb / on-primary label — `color.on.action.primary`.
  final Color onPrimary;

  /// Destructive label + confirm accent — `color.status.error` (paired with a
  /// confirm dialog, never color-only — COL-003).
  final Color error;

  /// Saved-confirmed accent — `color.status.success` (icon + text).
  final Color success;

  static const SettingsColors light = SettingsColors(
    surface: _SettingsPalette.neutral100,
    surfaceContainer: _SettingsPalette.neutral0,
    surfaceContainerHigh: _SettingsPalette.neutral50,
    skeleton: _SettingsPalette.neutral200,
    outlineVariant: _SettingsPalette.neutral200,
    focus: _SettingsPalette.blue500,
    onSurface: _SettingsPalette.neutral900,
    onSurfaceVariant: _SettingsPalette.neutral600,
    primary: _SettingsPalette.blue500,
    onPrimary: _SettingsPalette.neutral0,
    error: _SettingsPalette.red600,
    success: _SettingsPalette.green600,
  );

  static const SettingsColors dark = SettingsColors(
    surface: _SettingsPalette.neutral950,
    surfaceContainer: _SettingsPalette.neutral900,
    surfaceContainerHigh: _SettingsPalette.neutral800,
    skeleton: _SettingsPalette.neutral700,
    outlineVariant: _SettingsPalette.neutral800,
    focus: _SettingsPalette.blue400,
    onSurface: _SettingsPalette.neutral100,
    onSurfaceVariant: _SettingsPalette.neutral400,
    primary: _SettingsPalette.blue400,
    onPrimary: _SettingsPalette.neutral950,
    error: _SettingsPalette.red400,
    success: _SettingsPalette.green400,
  );

  /// ThemeMode-aware resolver: pick the palette for the active brightness.
  static SettingsColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Spacing scale on the 4/8 grid (semantic/spacing.json). Screen edge = 16; the
/// row leading keyline = 16; groups are separated by 24 (space.6).
class SettingsSpace {
  const SettingsSpace._();

  static const double xs = 4; // ux:ignore  space.1
  static const double sm = 8; // ux:ignore  space.2 — target gap
  static const double rowGap = 12; // ux:ignore  space.3 — label -> value rhythm
  static const double md = 16; // ux:ignore  space.4 — default content padding
  static const double lg = 24; // ux:ignore  space.6 — group spacing (SPC-006)
  static const double xl = 32; // ux:ignore  space.8 — zero-results hero spacing

  static const double edge = 16; // ux:ignore  screen edge inset (SPC-003)
  static const double rowLeadingInset = 16; // ux:ignore  row leading keyline (SPC-015)
  static const double groupGap = 24; // ux:ignore  gap between groups (SPC-006)
  static const double rowVertical = 12; // ux:ignore  row interior vertical padding
}

/// Corner radii (dimension.json). Grouped row cards use `radius.md`; the search
/// field and action buttons `radius.md`; chips/skeleton blocks `radius.sm`.
class SettingsRadius {
  const SettingsRadius._();

  static const double sm = 8; // ux:ignore  radius.sm — chip / skeleton block
  static const double md = 12; // ux:ignore  radius.md — grouped card / field / button
  static const double lg = 16; // ux:ignore  radius.lg — sheet / large container
}

/// Control + glyph sizing. Touch targets meet Material 48dp / Apple 44pt. The row
/// minimum height is a *minimum* (not a fixed height) so rows grow with Dynamic
/// Type and long / localized labels wrap without clipping (A11Y-010, L10N-003).
class SettingsSize {
  const SettingsSize._();

  static const double targetMin = 48; // ux:ignore  Material min touch target
  static const double targetMinIOS = 44; // ux:ignore  Apple HIG min target
  static const double rowMinHeight = 48; // ux:ignore  min row height (SPC-008)
  static const double icon = 24; // ux:ignore  row leading / chevron glyph
  static const double iconSm = 20; // ux:ignore  inline meta glyph
  static const double iconLg = 32; // ux:ignore  zero-results hero glyph
  static const double spinner = 20; // ux:ignore  inline progress spinner
  static const double stroke = 2; // ux:ignore  spinner / divider stroke width

  // Skeleton block dimensions — NON-text placeholder boxes (safe to fix-size;
  // they render no text, so Dynamic Type never clips — A11Y-010).
  static const double skelBlockH = 16; // ux:ignore  skeleton value block height
  static const double skelBlockW = 96; // ux:ignore  skeleton value block width

  // Two-pane leading list width on expanded windows (>= 840dp).
  static const double paneWidth = 320; // ux:ignore  group-list pane width

  // Very-wide clamp: keep a comfortable max content measure so a single column
  // never stretches edge-to-edge on a desktop-class window (SPC-018).
  static const double maxContent = 720; // ux:ignore  max content measure
}

/// Responsive breakpoints in logical pixels. The widget switches size class
/// strictly by these named tokens — never a magic literal in layout code.
class SettingsBreakpoint {
  const SettingsBreakpoint._();

  static const double compact = 600; // ux:ignore  < 600dp: single scrolling list
  static const double expanded = 840; // ux:ignore  >= 840dp: two-pane list + detail
}

/// Motion tokens. All animation is transform/opacity only and collapses to
/// [Duration.zero] under reduce-motion (MOT-004, A11Y-011).
class SettingsMotion {
  const SettingsMotion._();

  static const Duration fast = Duration(milliseconds: 150); // ux:ignore  switch / control (MIC-001)
  static const Duration standard = Duration(milliseconds: 200); // ux:ignore  search reflow / banner (MOT-001)
  static const Duration demoLatency = Duration(milliseconds: 900); // ux:ignore  simulated sync only
}

/// Typography roles map to `Theme.textTheme`, so text scales with Dynamic Type /
/// font scale automatically (no fixed sizes — TYP-002, A11Y-010). Long labels
/// wrap rather than truncate at large scales (L10N-003).
class SettingsType {
  const SettingsType._();

  /// Screen title — `type.title.lg`.
  static TextStyle? title(BuildContext c) => Theme.of(c).textTheme.titleLarge;

  /// Section header (Account, Notifications, …) — `type.label.md`.
  static TextStyle? header(BuildContext c) => Theme.of(c).textTheme.labelLarge;

  /// Row label — `type.body.md`.
  static TextStyle? rowLabel(BuildContext c) => Theme.of(c).textTheme.bodyLarge;

  /// Row value / secondary — `type.body.md` (on-surface-variant).
  static TextStyle? value(BuildContext c) => Theme.of(c).textTheme.bodyMedium;

  /// Body / helper copy — `type.body.md`.
  static TextStyle? body(BuildContext c) => Theme.of(c).textTheme.bodyMedium;

  /// Caption / reason text — `type.body.sm`.
  static TextStyle? caption(BuildContext c) => Theme.of(c).textTheme.bodySmall;

  /// Button / action label — `type.label.lg`.
  static TextStyle? button(BuildContext c) => Theme.of(c).textTheme.titleMedium;
}
