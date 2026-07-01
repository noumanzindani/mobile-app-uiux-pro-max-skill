/**
 * loginTokens.ts — semantic design tokens for the Login example (React Native).
 *
 * This is the ONLY file in the example permitted to hold raw literals (hex
 * colors, pixel numbers). Every line that carries a raw value ends with
 * `// ux:ignore` so token_lint / target_size_lint / dynamic_type_check skip it —
 * components reference these named roles, never the raw values.
 *
 * Conventions enforced here:
 *  - Spacing / radius / size sit on the 4 / 8 pt grid (COL-*, SPC-*, SHP-*).
 *  - Type roles keep fontSize >= 12 and never pin a fixed height, so text scales
 *    with the OS font setting (Dynamic Type / allowFontScaling).
 *  - Colors resolve per theme via getColors(); both themes share one shape (DRK-*).
 */
import type { TextStyle } from 'react-native';

// --- Color ------------------------------------------------------------------
// Semantic roles only. Raw hex lives here and nowhere else.
export type ColorRoles = {
  surface: string;
  surfaceDim: string;
  surfaceContainer: string;
  outline: string;
  onSurface: string;
  onSurfaceMuted: string;
  actionPrimary: string;
  actionPrimaryPressed: string;
  onActionPrimary: string;
  actionFocus: string;
  statusError: string;
  statusSuccess: string;
  ssoSurface: string;
  onSsoSurface: string;
  scrim: string;
};

const lightColors: ColorRoles = {
  surface: '#FFFFFF', // ux:ignore
  surfaceDim: '#EDEFF2', // ux:ignore
  surfaceContainer: '#F4F5F7', // ux:ignore
  outline: '#C3C7CF', // ux:ignore
  onSurface: '#191C20', // ux:ignore
  onSurfaceMuted: '#565E67', // ux:ignore
  actionPrimary: '#0B57D0', // ux:ignore
  actionPrimaryPressed: '#0B47AE', // ux:ignore
  onActionPrimary: '#FFFFFF', // ux:ignore
  actionFocus: '#0B57D0', // ux:ignore
  statusError: '#B3261E', // ux:ignore
  statusSuccess: '#146C2E', // ux:ignore
  ssoSurface: '#FFFFFF', // ux:ignore
  onSsoSurface: '#191C20', // ux:ignore
  scrim: '#0B0F1AAA', // ux:ignore
};

const darkColors: ColorRoles = {
  surface: '#131316', // ux:ignore
  surfaceDim: '#0D0D10', // ux:ignore
  surfaceContainer: '#1D1D21', // ux:ignore
  outline: '#43474E', // ux:ignore
  onSurface: '#E3E2E6', // ux:ignore
  onSurfaceMuted: '#A8ADB7', // ux:ignore
  actionPrimary: '#A8C7FA', // ux:ignore
  actionPrimaryPressed: '#8FB4F5', // ux:ignore
  onActionPrimary: '#062E6F', // ux:ignore
  actionFocus: '#A8C7FA', // ux:ignore
  statusError: '#F2B8B5', // ux:ignore
  statusSuccess: '#7AD98F', // ux:ignore
  ssoSurface: '#1D1D21', // ux:ignore
  onSsoSurface: '#E3E2E6', // ux:ignore
  scrim: '#0B0F1AAA', // ux:ignore
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
  md: 16, // ux:ignore
  lg: 24, // ux:ignore
  xl: 32, // ux:ignore
} as const;

// --- Radius -----------------------------------------------------------------
export const radius = {
  sm: 8, // ux:ignore
  md: 12, // ux:ignore
  lg: 16, // ux:ignore
  pill: 9999, // ux:ignore
} as const;

// --- Size (touch targets, hairlines, focus ring) ----------------------------
export const size = {
  target: 48, // WCAG 2.5.8 / Material minimum touch target // ux:ignore
  hitSlop: 12, // 24 glyph + 12 * 2 => 48 effective target // ux:ignore
  icon: 24, // ux:ignore
  hairline: 1, // ux:ignore
  focusRing: 2, // >= 3:1 focus indicator thickness // ux:ignore
} as const;

// --- Motion (durations only — transform/opacity animations reference these) --
export const motion = {
  instant: 0, // reduce-motion fallback // ux:ignore
  base: 150, // field focus + error reveal (<= 150ms) // ux:ignore
  emphasis: 200, // button loading cross-fade (<= 200ms) // ux:ignore
} as const;

// --- Typography roles (scalable; no fixed height, fontSize >= 12) -----------
export const typography = {
  titleLg: { fontSize: 28, lineHeight: 34, fontWeight: '700' }, // ux:ignore
  titleMd: { fontSize: 20, lineHeight: 26, fontWeight: '600' }, // ux:ignore
  bodyMd: { fontSize: 16, lineHeight: 22, fontWeight: '400' }, // ux:ignore
  labelMd: { fontSize: 14, lineHeight: 20, fontWeight: '600' }, // ux:ignore
  labelSm: { fontSize: 13, lineHeight: 18, fontWeight: '500' }, // ux:ignore
} as const satisfies Record<string, TextStyle>;
