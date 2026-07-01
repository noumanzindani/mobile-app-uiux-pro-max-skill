/**
 * settingsTokens.ts — semantic design tokens for the Settings example (React Native).
 *
 * This is the ONLY file in the example permitted to hold raw literals (hex colors,
 * pixel numbers, breakpoint widths). Every line that carries a raw value ends with
 * `// ux:ignore` so token_lint / target_size_lint / dynamic_type_check skip it —
 * components reference these named roles, never the raw values.
 *
 * Conventions enforced here:
 *  - Spacing / radius / size sit on the 4 / 8 pt grid, incl. the row leading inset
 *    (`rowInset`) and the between-group gap (`group`).
 *  - Type roles keep fontSize >= 12 and never pin a fixed height, so text scales
 *    with the OS font setting (Dynamic Type / allowFontScaling).
 *  - A tappable row is at least `size.rowMin` (>= 48) tall, so every list item and
 *    switch clears the WCAG / Material target floor.
 *  - Colors resolve per theme via getColors(); both themes share one shape.
 *  - Breakpoints are tokens too: compact = 600, expanded = 840.
 */
import type { TextStyle } from 'react-native';

// --- Color ------------------------------------------------------------------
// Semantic roles only. Raw hex lives here and nowhere else.
export type ColorRoles = {
  surface: string; // base background
  surfaceDim: string; // pressed / recessed
  surfaceContainer: string; // grouped-row container (iOS inset table)
  outline: string; // switch off-track / borders / UI lines
  outlineVariant: string; // hairline divider between rows
  onSurface: string; // primary label text
  onSurfaceVariant: string; // secondary value / header / description text
  actionPrimary: string; // switch on-track + interactive accent
  actionPrimaryPressed: string; // pressed accent
  onActionPrimary: string; // text/thumb on the accent
  statusError: string; // destructive label + failed-save message
  statusSuccess: string; // saved-confirmed message
  skeleton: string; // synced-value placeholder fill
  scrim: string; // picker-sheet backdrop
};

const lightColors: ColorRoles = {
  surface: '#FFFFFF', // ux:ignore
  surfaceDim: '#EDEFF2', // ux:ignore
  surfaceContainer: '#F4F5F7', // ux:ignore
  outline: '#C3C7CF', // ux:ignore
  outlineVariant: '#DADDE3', // ux:ignore
  onSurface: '#191C20', // ux:ignore
  onSurfaceVariant: '#565E67', // ux:ignore
  actionPrimary: '#0B57D0', // ux:ignore
  actionPrimaryPressed: '#0B47AE', // ux:ignore
  onActionPrimary: '#FFFFFF', // ux:ignore
  statusError: '#B3261E', // ux:ignore
  statusSuccess: '#146C2E', // ux:ignore
  skeleton: '#E2E5EA', // ux:ignore
  scrim: '#0B0F1A8A', // ux:ignore
};

const darkColors: ColorRoles = {
  surface: '#131316', // ux:ignore
  surfaceDim: '#26262B', // ux:ignore
  surfaceContainer: '#1D1D21', // ux:ignore
  outline: '#43474E', // ux:ignore
  outlineVariant: '#33363B', // ux:ignore
  onSurface: '#E3E2E6', // ux:ignore
  onSurfaceVariant: '#A8ADB7', // ux:ignore
  actionPrimary: '#A8C7FA', // ux:ignore
  actionPrimaryPressed: '#8FB4F5', // ux:ignore
  onActionPrimary: '#062E6F', // ux:ignore
  statusError: '#F2B8B5', // ux:ignore
  statusSuccess: '#7AD98F', // ux:ignore
  skeleton: '#2A2A30', // ux:ignore
  scrim: '#00000099', // ux:ignore
};

export { lightColors, darkColors };

/** Pick the color role set for the active OS color scheme. */
export function getColors(scheme: 'light' | 'dark' | null | undefined): ColorRoles {
  return scheme === 'dark' ? darkColors : lightColors;
}

// --- Spacing (4 / 8 pt grid) ------------------------------------------------
export const spacing = {
  none: 0, // ux:ignore
  xs: 4, // ux:ignore
  sm: 8, // ux:ignore
  md: 12, // ux:ignore
  lg: 16, // container edge padding (space.4) // ux:ignore
  rowInset: 16, // row leading keyline (SPC-015 / space.4) // ux:ignore
  group: 24, // between grouped sections (SPC-006 / space.6) // ux:ignore
  xl: 32, // isolation gap above the destructive zone // ux:ignore
} as const;

// --- Radius -----------------------------------------------------------------
export const radius = {
  sm: 8, // ux:ignore
  md: 12, // grouped-card radius (iOS concentric / SHP-003) // ux:ignore
  lg: 16, // ux:ignore
  pill: 9999, // ux:ignore
} as const;

// --- Size (touch targets, hairlines, skeleton geometry) ---------------------
export const size = {
  target: 48, // WCAG 2.5.8 / Material minimum touch target // ux:ignore
  rowMin: 48, // minimum tappable row height (SPC-008) // ux:ignore
  hitSlop: 12, // grows a glyph button to a >= 48 effective target // ux:ignore
  icon: 24, // ux:ignore
  hairline: 1, // divider / border thickness // ux:ignore
  focusRing: 2, // >= 3:1 focus indicator thickness // ux:ignore
  pane: 320, // leading-pane width in the two-pane (expanded) layout // ux:ignore
  skelSwitchW: 44, // synced-toggle skeleton width (non-text View) // ux:ignore
  skelSwitchH: 24, // synced-toggle skeleton height (non-text View) // ux:ignore
  skelLine: 12, // skeleton label line (non-text View) // ux:ignore
} as const;

// --- Motion (durations only — transform/opacity animations reference these) --
export const motion = {
  instant: 0, // reduce-motion fallback // ux:ignore
  base: 150, // sub-page push + skeleton pulse leg (<= 150ms) // ux:ignore
  emphasis: 200, // switch save round-trip (<= 200ms) // ux:ignore
  success: 300, // saved-confirmation dwell (<= 300ms) // ux:ignore
} as const;

// --- Breakpoints (GRD-004) --------------------------------------------------
export const breakpoints = {
  compact: 600, // < 600: single list + push sub-page // ux:ignore
  expanded: 840, // >= 840: two-pane (group list + detail) // ux:ignore
} as const;

// --- Typography roles (scalable; no fixed height, fontSize >= 12) -----------
export const typography = {
  titleLg: { fontSize: 28, lineHeight: 34, fontWeight: '700' }, // ux:ignore
  titleMd: { fontSize: 20, lineHeight: 26, fontWeight: '700' }, // ux:ignore
  bodyMd: { fontSize: 16, lineHeight: 22, fontWeight: '400' }, // ux:ignore
  bodyStrong: { fontSize: 16, lineHeight: 22, fontWeight: '600' }, // ux:ignore
  labelMd: { fontSize: 14, lineHeight: 20, fontWeight: '600' }, // ux:ignore
  labelSm: { fontSize: 13, lineHeight: 18, fontWeight: '500' }, // ux:ignore
  caption: { fontSize: 12, lineHeight: 16, fontWeight: '500' }, // ux:ignore
} as const satisfies Record<string, TextStyle>;
