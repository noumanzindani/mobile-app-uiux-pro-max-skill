/**
 * dashboardTokens.ts — semantic design tokens for the Dashboard example (React Native).
 *
 * This is the ONLY file in the example permitted to hold raw literals (hex colors,
 * pixel numbers, breakpoint widths). Every line that carries a raw value ends with
 * `// ux:ignore` so token_lint / target_size_lint / dynamic_type_check skip it —
 * components reference these named roles, never the raw values.
 *
 * Conventions enforced here:
 *  - Spacing / radius / size sit on the 4 / 8 pt grid, incl. the grid `gutter`.
 *  - Type roles keep fontSize >= 12 and never pin a fixed height, so text scales
 *    with the OS font setting (Dynamic Type / allowFontScaling).
 *  - Metric values use `tabular` (fontVariant tabular-nums) so digits align as they
 *    recompute after a refresh.
 *  - Chart series are semantic (`chart1..chart4`), distinguishable, and paired with
 *    labels/patterns in the component so nothing is encoded by color alone.
 *  - Colors resolve per theme via getColors(); both themes share one shape.
 *  - Breakpoints are tokens too: compact = 600, expanded = 840 (plus wide + max cap).
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
  onSurfaceStrong: string; // metric value emphasis — highest-contrast text role
  actionPrimary: string;
  actionPrimaryPressed: string;
  onActionPrimary: string;
  actionFocus: string;
  statusSuccess: string;
  statusError: string;
  // Skeleton block fill — a low-contrast neutral, never a data color.
  skeleton: string;
  // Chart series — semantic, distinguishable, pattern/label-backed (CHT-001).
  chart1: string;
  chart2: string;
  chart3: string;
  chart4: string;
};

const lightColors: ColorRoles = {
  surface: '#FFFFFF', // ux:ignore
  surfaceDim: '#EDEFF2', // ux:ignore
  surfaceContainer: '#F4F5F7', // ux:ignore
  outline: '#C3C7CF', // ux:ignore
  onSurface: '#191C20', // ux:ignore
  onSurfaceMuted: '#565E67', // ux:ignore
  onSurfaceStrong: '#0A0C10', // ux:ignore
  actionPrimary: '#0B57D0', // ux:ignore
  actionPrimaryPressed: '#0B47AE', // ux:ignore
  onActionPrimary: '#FFFFFF', // ux:ignore
  actionFocus: '#0B57D0', // ux:ignore
  statusSuccess: '#146C2E', // ux:ignore
  statusError: '#B3261E', // ux:ignore
  skeleton: '#E2E5EA', // ux:ignore
  chart1: '#2E5AAC', // ux:ignore
  chart2: '#1F7A63', // ux:ignore
  chart3: '#8A5A00', // ux:ignore
  chart4: '#6A3FA0', // ux:ignore
};

const darkColors: ColorRoles = {
  surface: '#131316', // ux:ignore
  surfaceDim: '#0D0D10', // ux:ignore
  surfaceContainer: '#1D1D21', // ux:ignore
  outline: '#43474E', // ux:ignore
  onSurface: '#E3E2E6', // ux:ignore
  onSurfaceMuted: '#A8ADB7', // ux:ignore
  onSurfaceStrong: '#F5F4F8', // ux:ignore
  actionPrimary: '#A8C7FA', // ux:ignore
  actionPrimaryPressed: '#8FB4F5', // ux:ignore
  onActionPrimary: '#062E6F', // ux:ignore
  actionFocus: '#A8C7FA', // ux:ignore
  statusSuccess: '#7AD98F', // ux:ignore
  statusError: '#F2B8B5', // ux:ignore
  skeleton: '#26262B', // ux:ignore
  chart1: '#9DB8F0', // ux:ignore
  chart2: '#7FD3BC', // ux:ignore
  chart3: '#E0B54A', // ux:ignore
  chart4: '#C4A2E8', // ux:ignore
};

export { lightColors, darkColors };

/** Pick the color role set for the active OS color scheme. */
export function getColors(scheme: 'light' | 'dark' | null | undefined): ColorRoles {
  return scheme === 'dark' ? darkColors : lightColors;
}

/** Ordered accessor so a tile can pick its series color by index. */
export function chartColor(colors: ColorRoles, index: number): string {
  const series = [colors.chart1, colors.chart2, colors.chart3, colors.chart4];
  return series[index % series.length];
}

// --- Spacing (4 / 8 pt grid) ------------------------------------------------
export const spacing = {
  none: 0, // ux:ignore
  xs: 4, // ux:ignore
  sm: 8, // ux:ignore
  md: 12, // dense data padding (space.3) // ux:ignore
  lg: 16, // card padding + screen edge (space.4) // ux:ignore
  gutter: 16, // responsive grid gutter (space.4) // ux:ignore
  xl: 24, // ux:ignore
  xxl: 32, // ux:ignore
} as const;

// --- Radius -----------------------------------------------------------------
export const radius = {
  sm: 8, // ux:ignore
  md: 12, // ux:ignore
  lg: 16, // card radius (radius.lg / SHP-001) // ux:ignore
  pill: 9999, // ux:ignore
} as const;

// --- Size (touch targets, chrome, skeleton + chart geometry) ----------------
export const size = {
  target: 48, // WCAG 2.5.8 / Material minimum touch target // ux:ignore
  hitSlop: 12, // 24 glyph + 12 * 2 => 48 effective target // ux:ignore
  icon: 24, // ux:ignore
  hairline: 1, // ux:ignore
  focusRing: 2, // >= 3:1 focus indicator thickness // ux:ignore
  rail: 88, // navigation rail width (medium / expanded) // ux:ignore
  chartHeight: 96, // bar-chart plot height (non-text View) // ux:ignore
  skelLine: 12, // skeleton label line height (non-text View) // ux:ignore
  skelBlock: 28, // skeleton number block height (non-text View) // ux:ignore
  dot: 8, // selected-nav indicator dot // ux:ignore
} as const;

// --- Motion (durations only — transform/opacity animations reference these) --
export const motion = {
  instant: 0, // reduce-motion fallback // ux:ignore
  base: 150, // skeleton -> content cross-fade (<= 150ms) // ux:ignore
  emphasis: 200, // per-tile resolve stagger (<= 200ms) // ux:ignore
  success: 300, // number-change settle (<= 300ms) // ux:ignore
  chart: 400, // chart draw-in (<= 400ms) // ux:ignore
} as const;

// --- Breakpoints (GRD-004) — the dashboard's whole point is size-class adaptation --
export const breakpoints = {
  compact: 600, // < 600: 1 column + bottom nav // ux:ignore
  expanded: 840, // >= 840: 3-4 columns + rail, chart spans 2 // ux:ignore
  wide: 1080, // >= 1080 inside expanded: 4 columns // ux:ignore
  maxContent: 1200, // content max-measure cap on very wide screens (GRD-005) // ux:ignore
} as const;

// --- Typography roles (scalable; no fixed height, fontSize >= 12) -----------
export const typography = {
  displaySm: { fontSize: 32, lineHeight: 38, fontWeight: '700' }, // ux:ignore
  titleLg: { fontSize: 28, lineHeight: 34, fontWeight: '700' }, // ux:ignore
  titleMd: { fontSize: 20, lineHeight: 26, fontWeight: '700' }, // ux:ignore
  bodyMd: { fontSize: 16, lineHeight: 22, fontWeight: '400' }, // ux:ignore
  bodyStrong: { fontSize: 16, lineHeight: 22, fontWeight: '600' }, // ux:ignore
  labelMd: { fontSize: 14, lineHeight: 20, fontWeight: '600' }, // ux:ignore
  labelSm: { fontSize: 13, lineHeight: 18, fontWeight: '500' }, // ux:ignore
  caption: { fontSize: 12, lineHeight: 16, fontWeight: '500' }, // ux:ignore
} as const satisfies Record<string, TextStyle>;

// --- Tabular figures (TYP-006) ----------------------------------------------
// Spread onto any Text that renders a metric so digits line up column-to-column
// as values recompute after a refresh. No raw literal — safe to reference from code.
export const tabular: TextStyle = { fontVariant: ['tabular-nums'] };
