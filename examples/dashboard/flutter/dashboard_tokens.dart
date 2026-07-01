// dashboard_tokens.dart
//
// The semantic token layer for the Dashboard example (a glanceable, responsive
// grid where every widget owns its own state). This is the ONLY file in the
// example allowed to hold raw values (hex colors, grid numbers, milliseconds,
// breakpoints). The widget references these constants exclusively, so a rebrand,
// a dark-mode swap, or a breakpoint tweak becomes a token change, not a refactor
// (COL-*, SPC-*, DRK-*, MOT-*, TYP-*, GRD-004).
//
// Values are faithful to the skill design system:
//   design-system/tokens/primitives/{color,dimension}.json
//   design-system/tokens/themes/{light,dark}.json
//
// token_lint requirement: EVERY line below that carries a raw hex or number ends
// with `// ux:ignore`. Spacing stays on the 4/8 grid (4, 8, 12, 16, 24, 32, 48);
// the responsive breakpoints (600 / 840 / 1240) also live here, each marked
// `// ux:ignore` so the screen file can reference them by name (GRD-004).
//
// Metric values, amounts, and chart axes use TABULAR figures
// ([FontFeature.tabularFigures]) so digits share a fixed advance width: a metric
// that recounts on refresh never shifts sideways, and a column of amounts aligns
// to the decimal (TYP-006). Value roles derive from Theme text styles, so they
// still scale with Dynamic Type / font scale (no fixed sizes — TYP-002).
//
// Chart series colors are chosen to be perceptually DISTINGUISHABLE (distinct
// hues, not just tints) and are always paired with value height + text labels +
// a data-table fallback, never encoded by color alone (CHT-001, COL-003).
//
// In a production app you would carry these on a ThemeExtension<T> (see
// frameworks/flutter/tokens.md); a plain resolver keeps this file dependency-free.

import 'package:flutter/material.dart';

/// Primitive palette — named by value, no semantic meaning. Referenced only by
/// [DashColors] below; widgets never touch these directly.
class _DashPalette {
  const _DashPalette._();

  static const Color neutral0 = Color(0xFFFFFFFF); // ux:ignore  neutral #FFFFFF
  static const Color neutral50 = Color(0xFFF8FAFC); // ux:ignore  neutral #F8FAFC
  static const Color neutral100 = Color(0xFFF1F5F9); // ux:ignore  neutral #F1F5F9
  static const Color neutral200 = Color(0xFFE2E8F0); // ux:ignore  neutral #E2E8F0
  static const Color neutral300 = Color(0xFFCBD5E1); // ux:ignore  neutral #CBD5E1
  static const Color neutral400 = Color(0xFF94A3B8); // ux:ignore  neutral #94A3B8
  static const Color neutral600 = Color(0xFF475569); // ux:ignore  neutral #475569
  static const Color neutral700 = Color(0xFF334155); // ux:ignore  neutral #334155
  static const Color neutral800 = Color(0xFF1E293B); // ux:ignore  neutral #1E293B
  static const Color neutral900 = Color(0xFF0F172A); // ux:ignore  neutral #0F172A
  static const Color neutral950 = Color(0xFF020617); // ux:ignore  neutral #020617

  static const Color blue400 = Color(0xFF60A5FA); // ux:ignore  primary (dark) #60A5FA
  static const Color blue500 = Color(0xFF2563EB); // ux:ignore  primary (light) #2563EB
  static const Color red400 = Color(0xFFF87171); // ux:ignore  status error (dark) #F87171
  static const Color red600 = Color(0xFFB91C1C); // ux:ignore  status error (light) #B91C1C
  static const Color green400 = Color(0xFF4ADE80); // ux:ignore  status success (dark) #4ADE80
  static const Color green600 = Color(0xFF15803D); // ux:ignore  status success (light) #15803D
  static const Color amber400 = Color(0xFFFBBF24); // ux:ignore  status warning (dark) #FBBF24
  static const Color amber600 = Color(0xFFB45309); // ux:ignore  status warning (light) #B45309

  // Chart series — distinct HUES so pairs stay separable without relying on color
  // alone (each bar also carries a label + a data-table fallback). One tint per
  // theme keeps >= 3:1 against the card surface (CHT-001, A11Y-002).
  static const Color teal500 = Color(0xFF0D9488); // ux:ignore  chart.3 (light) #0D9488
  static const Color teal300 = Color(0xFF2DD4BF); // ux:ignore  chart.3 (dark) #2DD4BF
  static const Color violet500 = Color(0xFF7C3AED); // ux:ignore  chart.4 (light) #7C3AED
  static const Color violet300 = Color(0xFFA78BFA); // ux:ignore  chart.4 (dark) #A78BFA

  // Elevation shadow — a low-alpha ink so cards lift on the surface (ELV-001).
  static const Color shadowInk = Color(0x1A020617); // ux:ignore  shadow @ 10% #020617
}

/// Semantic color roles, resolved per [Brightness]. Every role maps to a
/// design-system semantic token in themes/{light,dark}.json. Foreground/background
/// pairs are chosen so their contrast is >= 4.5:1 (text) / >= 3:1 (UI + chart)
/// in both themes (WCAG 1.4.3 / 1.4.11).
@immutable
class DashColors {
  const DashColors({
    required this.surface,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.skeleton,
    required this.outline,
    required this.focus,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.onSurfaceStrong,
    required this.primary,
    required this.onPrimary,
    required this.success,
    required this.error,
    required this.warning,
    required this.divider,
    required this.shadow,
    required this.chart1,
    required this.chart2,
    required this.chart3,
    required this.chart4,
  });

  /// Screen background — `color.surface`.
  final Color surface;

  /// Card / raised container — `color.surface.container`.
  final Color surfaceContainer;

  /// Emphasized container (offline banner) — `color.surface.container-high`.
  final Color surfaceContainerHigh;

  /// Skeleton placeholder fill — `color.surface.container-highest`.
  final Color skeleton;

  /// Card border / control outline — `color.border` (>= 3:1, WCAG 1.4.11).
  final Color outline;

  /// Focus ring — `color.action.focus` (>= 3:1).
  final Color focus;

  /// Value / body / label text — `color.on-surface` (>= 4.5:1).
  final Color onSurface;

  /// Helper / caption / stale text — `color.on-surface-muted` (>= 4.5:1).
  final Color onSurfaceMuted;

  /// Metric-value emphasis — `color.on-surface-strong`.
  final Color onSurfaceStrong;

  /// Primary action background — `color.action.primary`.
  final Color primary;

  /// Primary action label — `color.action.on-primary` (>= 4.5:1).
  final Color onPrimary;

  /// Positive trend accent — `color.status.success`. Always paired with an
  /// up-arrow + a signed value, never color-only (COL-003, A11Y-012).
  final Color success;

  /// Negative trend / tile error accent — `color.status.error`. Icon + text.
  final Color error;

  /// Attention accent (stale / permission) — `color.status.warning`. Icon + text.
  final Color warning;

  /// Hairline divider — `color.divider`.
  final Color divider;

  /// Card elevation shadow — `color.shadow` (ELV-001).
  final Color shadow;

  /// Chart series 1..4 — semantic, distinguishable, pattern/label-backed.
  final Color chart1;
  final Color chart2;
  final Color chart3;
  final Color chart4;

  /// Chart series as an ordered list, so a painter can cycle them by index.
  List<Color> get chartSeries => [chart1, chart2, chart3, chart4];

  static const DashColors light = DashColors(
    surface: _DashPalette.neutral50,
    surfaceContainer: _DashPalette.neutral0,
    surfaceContainerHigh: _DashPalette.neutral100,
    skeleton: _DashPalette.neutral200,
    outline: _DashPalette.neutral300,
    focus: _DashPalette.blue500,
    onSurface: _DashPalette.neutral900,
    onSurfaceMuted: _DashPalette.neutral600,
    onSurfaceStrong: _DashPalette.neutral950,
    primary: _DashPalette.blue500,
    onPrimary: _DashPalette.neutral0,
    success: _DashPalette.green600,
    error: _DashPalette.red600,
    warning: _DashPalette.amber600,
    divider: _DashPalette.neutral200,
    shadow: _DashPalette.shadowInk,
    chart1: _DashPalette.blue500,
    chart2: _DashPalette.amber600,
    chart3: _DashPalette.teal500,
    chart4: _DashPalette.violet500,
  );

  static const DashColors dark = DashColors(
    surface: _DashPalette.neutral950,
    surfaceContainer: _DashPalette.neutral900,
    surfaceContainerHigh: _DashPalette.neutral800,
    skeleton: _DashPalette.neutral700,
    outline: _DashPalette.neutral600,
    focus: _DashPalette.blue400,
    onSurface: _DashPalette.neutral100,
    onSurfaceMuted: _DashPalette.neutral400,
    onSurfaceStrong: _DashPalette.neutral0,
    primary: _DashPalette.blue400,
    onPrimary: _DashPalette.neutral950,
    success: _DashPalette.green400,
    error: _DashPalette.red400,
    warning: _DashPalette.amber400,
    divider: _DashPalette.neutral800,
    shadow: _DashPalette.shadowInk,
    chart1: _DashPalette.blue400,
    chart2: _DashPalette.amber400,
    chart3: _DashPalette.teal300,
    chart4: _DashPalette.violet300,
  );

  /// ThemeMode-aware resolver: pick the palette for the active brightness.
  static DashColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Spacing scale on the 4/8 grid (semantic/spacing.json). Screen edge = 16; the
/// grid gutter between cards is 16 and doubles as card padding (SPC-007).
class DashSpace {
  const DashSpace._();

  static const double xs = 4; // ux:ignore  space.1 — chip / caption gap
  static const double sm = 8; // ux:ignore  space.2 — icon gap, min tile gap
  static const double rowGap = 12; // ux:ignore  space.3 — list-row rhythm
  static const double md = 16; // ux:ignore  space.4 — edge inset (SPC-003)
  static const double lg = 24; // ux:ignore  space.6 — section gap
  static const double xl = 32; // ux:ignore  space.8 — empty-state hero spacing

  static const double edge = 16; // ux:ignore  screen edge inset (SPC-003)
  static const double gutter = 16; // ux:ignore  grid gutter between cards (SPC-007)
  static const double cardPadding = 16; // ux:ignore  card interior padding (SPC-007)
  static const double tileGap = 8; // ux:ignore  min gap between a card and its actions (A11Y-010)
}

/// Corner radii (dimension.json). Cards use `radius.lg`; controls `radius.md`;
/// chips and chart bars a tight `radius.sm`.
class DashRadius {
  const DashRadius._();

  static const double card = 16; // ux:ignore  radius.lg — metric / chart cards (SHP-001)
  static const double control = 12; // ux:ignore  radius.md — buttons / retry
  static const double chip = 8; // ux:ignore  radius.sm — filter chip
  static const double bar = 4; // ux:ignore  radius.xs — chart bar cap
}

/// Material elevation levels (M3). Cards rest at level1 over the surface; the
/// offline banner at level2 (ELV-001).
class DashElevation {
  const DashElevation._();

  static const double level0 = 0; // ux:ignore  flat
  static const double level1 = 1; // ux:ignore  M3 elevation.level1 — cards
  static const double level2 = 3; // ux:ignore  M3 elevation.level2 — banner
}

/// Control + glyph sizing. Touch targets meet Material 48dp / Apple 44pt. Fixed
/// sizes here are non-text (skeleton blocks, chart canvas) so they never clip
/// scaled text (Dynamic Type applies to text roles only — A11Y-010).
class DashSize {
  const DashSize._();

  static const double targetMin = 48; // ux:ignore  Material min touch target
  static const double targetMinIOS = 44; // ux:ignore  Apple HIG min target
  static const double iconLg = 32; // ux:ignore  empty / permission hero glyph
  static const double icon = 24; // ux:ignore  card header / action glyph
  static const double iconSm = 20; // ux:ignore  inline meta glyph (trend, stale)
  static const double spinner = 20; // ux:ignore  inline progress spinner
  static const double stroke = 2; // ux:ignore  spinner / chart stroke width
  static const double avatar = 40; // ux:ignore  account avatar

  // Skeleton block dimensions — NON-text placeholder boxes (safe to fix-size).
  static const double skelLine = 14; // ux:ignore  skeleton text line height
  static const double skelValue = 28; // ux:ignore  skeleton value block height
  static const double skelTitleW = 96; // ux:ignore  skeleton title width
  static const double skelValueW = 132; // ux:ignore  skeleton value width
  static const double skelTrendW = 72; // ux:ignore  skeleton trend width

  // Chart canvas — a NON-text box; bars scale to it, labels sit outside it.
  static const double chartHeight = 140; // ux:ignore  bar-chart canvas height

  // Very-wide clamp: preserve a comfortable max content measure so a single
  // column never stretches edge-to-edge on a desktop-class window (GRD-005).
  static const double maxContent = 1280; // ux:ignore  max content measure (SPC-018)
}

/// Responsive breakpoints in logical pixels (GRD-004). The screen switches size
/// class strictly by these named tokens — never a magic literal in layout code.
class DashBreakpoint {
  const DashBreakpoint._();

  static const double compact = 600; // ux:ignore  < 600dp: 1 col + bottom nav
  static const double expanded = 840; // ux:ignore  >= 840dp: 3-4 cols + rail
  static const double wide = 1240; // ux:ignore  >= 1240dp: 4 cols
}

/// Motion tokens. All animation is transform/opacity only and collapses to
/// [Duration.zero] under reduce-motion (MOT-004, A11Y-011).
class DashMotion {
  const DashMotion._();

  static const Duration fast = Duration(milliseconds: 150); // ux:ignore  chip / control (MIC-001)
  static const Duration standard = Duration(milliseconds: 200); // ux:ignore  skeleton cross-fade / banner (MOT-001)
  static const Duration number = Duration(milliseconds: 280); // ux:ignore  metric change transition (<=300, MOT-005)
  static const Duration chart = Duration(milliseconds: 400); // ux:ignore  chart draw-in (<=400, MOT-004)
  static const Duration shimmer = Duration(milliseconds: 1200); // ux:ignore  skeleton pulse cycle
  static const Duration demoLatency = Duration(milliseconds: 900); // ux:ignore  simulated fetch only
}

/// Typography roles map to `Theme.textTheme`, so text scales with Dynamic Type /
/// font scale automatically (no fixed sizes — TYP-002, A11Y-010). Value / amount
/// roles add tabular figures so digits align and a recomputed number never
/// jitters (TYP-006).
class DashType {
  const DashType._();

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// Greeting / page display line — `type.display.sm`.
  static TextStyle? display(BuildContext c) =>
      Theme.of(c).textTheme.headlineMedium;

  /// A metric value — `type.display.sm`, tabular figures.
  static TextStyle? value(BuildContext c) =>
      Theme.of(c).textTheme.headlineSmall?.copyWith(fontFeatures: _tabular);

  /// A large / spanning metric value — tabular figures.
  static TextStyle? valueStrong(BuildContext c) =>
      Theme.of(c).textTheme.headlineMedium?.copyWith(fontFeatures: _tabular);

  /// Card / section title — `type.title.md`.
  static TextStyle? title(BuildContext c) => Theme.of(c).textTheme.titleLarge;
  static TextStyle? section(BuildContext c) => Theme.of(c).textTheme.titleMedium;

  /// Metric label — `type.label.md`.
  static TextStyle? label(BuildContext c) => Theme.of(c).textTheme.labelMedium;
  static TextStyle? labelStrong(BuildContext c) =>
      Theme.of(c).textTheme.labelLarge;

  static TextStyle? body(BuildContext c) => Theme.of(c).textTheme.bodyMedium;
  static TextStyle? button(BuildContext c) => Theme.of(c).textTheme.titleMedium;
  static TextStyle? caption(BuildContext c) => Theme.of(c).textTheme.bodySmall;

  /// A tabular number in body/caption rhythm (activity amounts, chart axis).
  static TextStyle? number(BuildContext c) =>
      Theme.of(c).textTheme.bodyMedium?.copyWith(fontFeatures: _tabular);

  /// A trend delta ("+4%") — label rhythm, tabular so the sign column aligns.
  static TextStyle? trend(BuildContext c) =>
      Theme.of(c).textTheme.labelLarge?.copyWith(fontFeatures: _tabular);
}
