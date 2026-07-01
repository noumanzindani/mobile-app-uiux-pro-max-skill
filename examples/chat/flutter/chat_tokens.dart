// chat_tokens.dart
//
// The semantic token layer for the Chat example (1:1 / group messaging). This is
// the ONLY file in the example allowed to hold raw values (hex colors, grid
// numbers, milliseconds, opacities). The widget references these constants
// exclusively, so a rebrand or a dark-mode swap becomes a token change, not a
// refactor (COL-*, SPC-*, DRK-*, SHP-*, MOT-*).
//
// Values are faithful to the skill design system:
//   design-system/tokens/primitives/{color,dimension}.json
//   design-system/tokens/themes/{light,dark}.json
//
// token_lint requirement: EVERY line below that carries a raw hex or number ends
// with `// ux:ignore`. Spacing stays on the 4/8 grid (4, 8, 12, 16, 24, 32, 48).
//
// Contrast contract (verified, both themes, >= 4.5:1 WCAG 1.4.3):
//   own bubble   = brand primary fill + white text   (light 5.17:1 · dark 6.70:1)
//   other bubble = surface-container fill + on-surface (light 16.3:1 · dark 13.3:1)
//   own meta     = tinted white on the brand fill      (light 4.75:1 · dark 6.16:1)
// The own-bubble fill is the brand primary, darkened in dark mode so white text
// keeps its ratio — "primary bg + white text" that still passes in both themes.
//
// In a production app you would carry these on a ThemeExtension<T> (see
// frameworks/flutter/tokens.md); a plain resolver keeps this file dependency-free.

import 'package:flutter/material.dart';

/// Primitive palette — named by value, no semantic meaning. Referenced only by
/// [ChatColors] below; widgets never touch these directly.
class _ChatPalette {
  const _ChatPalette._();

  static const Color neutral0 = Color(0xFFFFFFFF); // ux:ignore  neutral #FFFFFF
  static const Color neutral100 = Color(0xFFF1F5F9); // ux:ignore  neutral #F1F5F9
  static const Color neutral200 = Color(0xFFE2E8F0); // ux:ignore  neutral #E2E8F0
  static const Color neutral400 = Color(0xFF94A3B8); // ux:ignore  neutral #94A3B8
  static const Color neutral600 = Color(0xFF475569); // ux:ignore  neutral #475569
  static const Color neutral800 = Color(0xFF1E293B); // ux:ignore  neutral #1E293B
  static const Color neutral900 = Color(0xFF0F172A); // ux:ignore  neutral #0F172A
  static const Color neutral950 = Color(0xFF020617); // ux:ignore  neutral #020617
  static const Color blue50 = Color(0xFFEFF6FF); // ux:ignore  own-meta tint #EFF6FF
  static const Color blue300 = Color(0xFF93C5FD); // ux:ignore  status info (dark) #93C5FD
  static const Color blue400 = Color(0xFF60A5FA); // ux:ignore  primary (dark) #60A5FA
  static const Color blue500 = Color(0xFF2563EB); // ux:ignore  primary + own bubble (light) #2563EB
  static const Color blue700 = Color(0xFF1D4ED8); // ux:ignore  own bubble (dark) #1D4ED8
  static const Color red400 = Color(0xFFF87171); // ux:ignore  status error (dark) #F87171
  static const Color red600 = Color(0xFFB91C1C); // ux:ignore  status error (light) #B91C1C
}

/// Semantic color roles, resolved per [Brightness]. Every role maps to a
/// design-system semantic token in themes/{light,dark}.json. Bubble roles carry
/// their own foreground so the >= 4.5:1 pairing is guaranteed by construction.
@immutable
class ChatColors {
  const ChatColors({
    required this.surface,
    required this.surfaceContainer,
    required this.outline,
    required this.focus,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.primary,
    required this.onPrimary,
    required this.selfBubble,
    required this.onSelfBubble,
    required this.onSelfBubbleMuted,
    required this.otherBubble,
    required this.onOtherBubble,
    required this.onOtherBubbleMuted,
    required this.statusInfo,
    required this.statusError,
  });

  /// Screen background — `color.surface`.
  final Color surface;

  /// Nav bar / composer / banner / other-bubble container — `color.surface-container`.
  final Color surfaceContainer;

  /// Hairline divider / field outline — `color.border`.
  final Color outline;

  /// Focus ring — `color.action.focus` (>= 3:1).
  final Color focus;

  /// Primary text: names, message body on surface — `color.on-surface` (>= 4.5:1).
  final Color onSurface;

  /// Timestamps, presence, muted labels — `color.on-surface-muted`.
  final Color onSurfaceMuted;

  /// Send button / pill / scroll-to-bottom fill — `color.action.primary`.
  final Color primary;

  /// Label/icon on [primary] — `color.action.on-primary` (>= 4.5:1).
  final Color onPrimary;

  /// Own message bubble fill — `color.chat.self.bg` (brand primary, tuned per theme).
  final Color selfBubble;

  /// Own message text — `color.on-chat.self` (white, >= 4.5:1 on [selfBubble]).
  final Color onSelfBubble;

  /// Own timestamp / status text — tinted white, still >= 4.5:1 on [selfBubble].
  final Color onSelfBubbleMuted;

  /// Other message bubble fill — `color.chat.other.bg` (surface-container).
  final Color otherBubble;

  /// Other message text — `color.on-chat.other` (>= 4.5:1 on [otherBubble]).
  final Color onOtherBubble;

  /// Other timestamp / meta text — muted, still >= 4.5:1 on [otherBubble].
  final Color onOtherBubbleMuted;

  /// Delivery status accent (sent / delivered / read) — `color.status.info`.
  /// Always paired with an icon + text label, never color-only (A11Y-012).
  final Color statusInfo;

  /// Failed-send accent — `color.status.error`. Paired with an icon + text.
  final Color statusError;

  static const ChatColors light = ChatColors(
    surface: _ChatPalette.neutral0,
    surfaceContainer: _ChatPalette.neutral100,
    outline: _ChatPalette.neutral200,
    focus: _ChatPalette.blue500,
    onSurface: _ChatPalette.neutral900,
    onSurfaceMuted: _ChatPalette.neutral600,
    primary: _ChatPalette.blue500,
    onPrimary: _ChatPalette.neutral0,
    selfBubble: _ChatPalette.blue500,
    onSelfBubble: _ChatPalette.neutral0,
    onSelfBubbleMuted: _ChatPalette.blue50,
    otherBubble: _ChatPalette.neutral100,
    onOtherBubble: _ChatPalette.neutral900,
    onOtherBubbleMuted: _ChatPalette.neutral600,
    statusInfo: _ChatPalette.blue500,
    statusError: _ChatPalette.red600,
  );

  static const ChatColors dark = ChatColors(
    surface: _ChatPalette.neutral950,
    surfaceContainer: _ChatPalette.neutral800,
    outline: _ChatPalette.neutral800,
    focus: _ChatPalette.blue400,
    onSurface: _ChatPalette.neutral100,
    onSurfaceMuted: _ChatPalette.neutral400,
    primary: _ChatPalette.blue400,
    onPrimary: _ChatPalette.neutral950,
    selfBubble: _ChatPalette.blue700,
    onSelfBubble: _ChatPalette.neutral0,
    onSelfBubbleMuted: _ChatPalette.blue50,
    otherBubble: _ChatPalette.neutral800,
    onOtherBubble: _ChatPalette.neutral100,
    onOtherBubbleMuted: _ChatPalette.neutral400,
    statusInfo: _ChatPalette.blue300,
    statusError: _ChatPalette.red400,
  );

  /// ThemeMode-aware resolver: pick the palette for the active brightness.
  static ChatColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Spacing scale on the 4/8 grid (semantic/spacing.json). Screen edge = 16.
class ChatSpace {
  const ChatSpace._();

  static const double xs = 4; // ux:ignore  space.1 — intra-group gap
  static const double sm = 8; // ux:ignore  space.2 — grouped-bubble gap (SPC-006)
  static const double md = 16; // ux:ignore  space.4 — edge + inter-group gap
  static const double lg = 24; // ux:ignore  space.6
  static const double xl = 32; // ux:ignore  space.8

  static const double edge = 16; // ux:ignore  screen edge inset (SPC-003)
  static const double bubblePadV = 8; // ux:ignore  bubble vertical padding
  static const double bubblePadH = 12; // ux:ignore  bubble horizontal padding
}

/// Corner radii (dimension.json). Bubble = radius.lg with a flattened tail corner.
class ChatRadius {
  const ChatRadius._();

  static const double bubble = 16; // ux:ignore  radius.lg — bubble body (SHP-001)
  static const double tail = 4; // ux:ignore  radius.xs — flattened tail corner
  static const double field = 24; // ux:ignore  radius.xl — composer field
  static const double pill = 9999; // ux:ignore  radius.full — pill / avatar / FAB
}

/// Control sizing. Touch targets meet Material 48dp / Apple 44pt.
class ChatSize {
  const ChatSize._();

  static const double targetMin = 48; // ux:ignore  Material min touch target
  static const double targetMinIOS = 44; // ux:ignore  Apple HIG min target
  static const double icon = 24; // ux:ignore  action / status glyph
  static const double statusIcon = 16; // ux:ignore  inline delivery-status glyph
  static const double avatarRadius = 20; // ux:ignore  40dp avatar diameter
  static const double avatarRadiusSm = 14; // ux:ignore  28dp in-list group avatar
  static const int composerMaxLines = 5; // ux:ignore  grows to 5 lines, then scrolls (FRM-003)
  static const double bubbleMaxFraction = 0.78; // ux:ignore  bubble max width as a fraction of screen
  static const double scrollThreshold = 240; // ux:ignore  "scrolled up" / load-older trigger distance
  static const double skeletonLine = 12; // ux:ignore  skeleton text-line height
  static const double dot = 8; // ux:ignore  typing-indicator dot diameter
  static const double stroke = 2; // ux:ignore  spinner stroke width
  static const double spinner = 20; // ux:ignore  inline spinner box
}

/// Opacity tokens. Ghosting an in-flight message and dimming skeletons stay here
/// so the widget never holds a raw alpha (COL-*).
class ChatOpacity {
  const ChatOpacity._();

  static const double hidden = 0; // ux:ignore  pre-insert (fade-in start)
  static const double full = 1; // ux:ignore  settled message
  static const double ghost = 0.55; // ux:ignore  sending / queued (optimistic, not yet acked)
  static const double skeleton = 0.4; // ux:ignore  loading placeholder
}

/// Motion tokens. All chat animation is transform/opacity only and collapses to
/// [Duration.zero] under reduce-motion (MOT-004, A11Y-011).
class ChatMotion {
  const ChatMotion._();

  static const Duration statusFade = Duration(milliseconds: 150); // ux:ignore  status cross-fade (MIC-001)
  static const Duration insert = Duration(milliseconds: 220); // ux:ignore  outgoing bubble insert (MOT-001)
  static const Duration pill = Duration(milliseconds: 180); // ux:ignore  new-messages pill reveal
  static const Duration typingCycle = Duration(milliseconds: 1200); // ux:ignore  typing-dot loop
  static const Duration scrollTo = Duration(milliseconds: 240); // ux:ignore  smooth scroll-to-bottom
  static const Duration demoLatency = Duration(milliseconds: 900); // ux:ignore  simulated network only
  static const Duration statusStep = Duration(milliseconds: 700); // ux:ignore  simulated sent->delivered->read
  static const Duration retryBackoff = Duration(milliseconds: 600); // ux:ignore  queue auto-flush backoff
}

/// Typography roles map to `Theme.textTheme`, so text scales with Dynamic Type /
/// font scale automatically (no fixed sizes — TYP-002, A11Y-010).
class ChatType {
  const ChatType._();

  static TextStyle? title(BuildContext c) => Theme.of(c).textTheme.titleMedium;
  static TextStyle? name(BuildContext c) => Theme.of(c).textTheme.titleSmall;
  static TextStyle? body(BuildContext c) => Theme.of(c).textTheme.bodyLarge;
  static TextStyle? meta(BuildContext c) => Theme.of(c).textTheme.labelMedium;
  static TextStyle? separator(BuildContext c) => Theme.of(c).textTheme.labelMedium;
}
