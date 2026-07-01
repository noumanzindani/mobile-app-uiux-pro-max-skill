package ux.examples.dashboard

/**
 * DashboardTokens — the semantic token layer for the dashboard example.
 *
 * This is the ONLY file in this example allowed to contain raw values (hex colors,
 * dp spacing / size / radius, millis, the breakpoint dp values, and the chart-series
 * colors). Every such line is annotated `// ux:ignore` so the token_lint validator treats
 * this file as the single source of literals. The dashboard composable consumes ONLY these
 * tokens plus `MaterialTheme.colorScheme` / `.typography` / `.shapes` roles — never a literal.
 *
 * Layering (DTCG -> Compose): color / typography / shape flow through `MaterialExpressiveTheme`
 * (so dark mode + Material You resolve through role slots); spacing / size / radius / breakpoints
 * — which M3 has no theme slot for — are carried as plain token objects (`Space`, `Size`,
 * `Radius`, `Breakpoint`). Roles the M3 ColorScheme has no slot for — `on-surface-strong`,
 * `status.success`, `status.error`, and the `chart.1…n` series — ride a `CompositionLocal`
 * (`LocalDashboardColors`) provided once at the theme root and read as `MaterialTheme.dashboardColors`.
 * The `value` text roles enable TABULAR FIGURES (`fontFeatureSettings = "tnum"`) so metric columns
 * align and never jitter as digits change (TYP-006).
 */

import android.provider.Settings
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialExpressiveTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.remember
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

// ─────────────────────────────────────────────────────────────────────────────
// SPACING — DTCG space.* scale, snapped to the 4/8 grid (SPC-*). `gutter` is the
// grid gutter AND the card padding (both space.4 = 16dp per the spec's token table).
// ─────────────────────────────────────────────────────────────────────────────
object Space {
    val zero: Dp = 0.dp   // ux:ignore  (animation rest offset)
    val xxs: Dp = 2.dp    // ux:ignore  (hair gap between a trend icon and its label)
    val xs: Dp = 4.dp     // ux:ignore
    val sm: Dp = 8.dp     // ux:ignore
    val md: Dp = 16.dp    // ux:ignore
    val lg: Dp = 24.dp    // ux:ignore
    val xl: Dp = 32.dp    // ux:ignore

    /** Grid gutter between tiles == card inner padding (space.4). */
    val gutter: Dp = 16.dp // ux:ignore
}

// ─────────────────────────────────────────────────────────────────────────────
// SIZE — target minimums, glyph / avatar sizes, and the fixed pixel sizes for the
// non-text Canvas chart + shape-matched skeleton boxes (A11Y-*, ICN-*, GRD-005).
// ─────────────────────────────────────────────────────────────────────────────
object Size {
    /** Material minimum interactive target (also clears the iOS 44pt floor). */
    val minTarget: Dp = 48.dp        // ux:ignore

    /** Metric tile minimum height so a single-tap card is always a comfortable target. */
    val cardMinHeight: Dp = 112.dp   // ux:ignore
    val icon: Dp = 24.dp             // ux:ignore
    val trendIcon: Dp = 18.dp        // ux:ignore
    val avatar: Dp = 40.dp           // ux:ignore

    /** Fixed height for the Canvas bar chart (a non-text drawing surface). */
    val chartHeight: Dp = 168.dp     // ux:ignore

    // Shape-matched skeleton block heights (non-text placeholder boxes).
    val skeletonValue: Dp = 28.dp    // ux:ignore
    val skeletonLabel: Dp = 16.dp    // ux:ignore
    val skeletonRow: Dp = 20.dp      // ux:ignore

    /** Max content measure on very wide screens — never stretch tiles edge-to-edge (GRD-005, SPC-018). */
    val maxContentWidth: Dp = 1200.dp // ux:ignore
}

// ─────────────────────────────────────────────────────────────────────────────
// RADIUS / SHAPES — tile radius (lg), field/chip radius (md/sm) + bar corners (SHP-001).
// ─────────────────────────────────────────────────────────────────────────────
object Radius {
    val sm: Dp = 8.dp      // ux:ignore  (chart bar corners, chips, skeleton blocks)
    val md: Dp = 12.dp     // ux:ignore
    val lg: Dp = 16.dp     // ux:ignore  (metric / chart / activity cards)
    val pill: Dp = 9999.dp // ux:ignore  (fully-rounded refresh / filter chips)
}

val DashboardShapes = Shapes(
    extraSmall = RoundedCornerShape(Radius.sm),
    small = RoundedCornerShape(Radius.sm),
    medium = RoundedCornerShape(Radius.md),
    large = RoundedCornerShape(Radius.lg),
    extraLarge = RoundedCornerShape(Radius.lg),
)

/** Fully-rounded shape for the refresh / filter chips. */
val PillShape: Shape = RoundedCornerShape(Radius.pill)

// ─────────────────────────────────────────────────────────────────────────────
// BREAKPOINTS — M3 window-size-class widths (GRD-004). Compact < 600dp (1 column +
// bottom nav), Medium 600–839dp (2 columns + rail), Expanded ≥ 840dp (3 columns +
// rail; chart spans 2), and Large ≥ 1240dp promotes the grid to 4 columns.
// ─────────────────────────────────────────────────────────────────────────────
object Breakpoint {
    val compact: Dp = 600.dp   // ux:ignore
    val expanded: Dp = 840.dp  // ux:ignore
    val large: Dp = 1240.dp    // ux:ignore
}

// ─────────────────────────────────────────────────────────────────────────────
// MOTION — durations for the (alpha / offset-only) transitions; reduce-motion collapses
// these to instant (see rememberReduceMotion). Only opacity / offset are ever animated;
// the "*Ms" values are demo-only stand-ins for real refresh latency (MOT-*, PRG-*).
// ─────────────────────────────────────────────────────────────────────────────
object Motion {
    const val shortMillis = 150       // ux:ignore  (offline banner fade ≤200ms)
    const val updatedMillis = 250     // ux:ignore  ("Updated" reveal ≤250ms)
    const val chartDrawMillis = 400   // ux:ignore  (chart draw-in ≤400ms)
    const val countUpMillis = 300     // ux:ignore  (metric change ≤300ms)
    const val skeletonMs = 900        // ux:ignore  (skeleton pulse half-cycle)
    const val refreshSettleMs = 1200L // ux:ignore  (demo: pull-to-refresh network settle)
}

// ─────────────────────────────────────────────────────────────────────────────
// COLOR — brand fallback palette. DTCG semantic roles are mapped onto M3 ColorScheme
// slots below; MaterialExpressiveTheme resolves light / dark (and Material You can be
// layered on Android 12+). Contrast pairs meet WCAG 2.2 (COL-*, DRK-*, A11Y-*).
// ─────────────────────────────────────────────────────────────────────────────
private object Palette {
    // Light
    val primaryLight = Color(0xFF4C5BC4)             // ux:ignore
    val onPrimaryLight = Color(0xFFFFFFFF)           // ux:ignore
    val primaryContainerLight = Color(0xFFE0E1FF)    // ux:ignore
    val onPrimaryContainerLight = Color(0xFF03105B)  // ux:ignore
    val secondaryLight = Color(0xFF5A5D72)           // ux:ignore
    val onSecondaryLight = Color(0xFFFFFFFF)         // ux:ignore
    val secondaryContainerLight = Color(0xFFDFE1F9)  // ux:ignore
    val onSecondaryContainerLight = Color(0xFF171B2C) // ux:ignore
    val surfaceLight = Color(0xFFFBF8FF)             // ux:ignore
    val onSurfaceLight = Color(0xFF1A1B21)           // ux:ignore
    val surfaceVariantLight = Color(0xFFE3E1EC)      // ux:ignore
    val onSurfaceVariantLight = Color(0xFF45464F)    // ux:ignore
    val surfaceContainerLight = Color(0xFFEFEDF7)    // ux:ignore
    val surfaceContainerHighLight = Color(0xFFE9E7F1) // ux:ignore
    val surfaceContainerHighestLight = Color(0xFFE3E1EC) // ux:ignore
    val outlineLight = Color(0xFF767680)             // ux:ignore
    val outlineVariantLight = Color(0xFFC6C5D0)      // ux:ignore
    val errorLight = Color(0xFFB3261E)               // ux:ignore
    val onErrorLight = Color(0xFFFFFFFF)             // ux:ignore
    val errorContainerLight = Color(0xFFF9DEDC)      // ux:ignore
    val onErrorContainerLight = Color(0xFF410E0B)    // ux:ignore

    // Dark
    val primaryDark = Color(0xFFBEC2FF)              // ux:ignore
    val onPrimaryDark = Color(0xFF1B2678)            // ux:ignore
    val primaryContainerDark = Color(0xFF333EA0)     // ux:ignore
    val onPrimaryContainerDark = Color(0xFFE0E1FF)   // ux:ignore
    val secondaryDark = Color(0xFFC3C5DD)            // ux:ignore
    val onSecondaryDark = Color(0xFF2C2F42)          // ux:ignore
    val secondaryContainerDark = Color(0xFF424659)   // ux:ignore
    val onSecondaryContainerDark = Color(0xFFDFE1F9) // ux:ignore
    val surfaceDark = Color(0xFF121318)              // ux:ignore
    val onSurfaceDark = Color(0xFFE3E1E9)            // ux:ignore
    val surfaceVariantDark = Color(0xFF45464F)       // ux:ignore
    val onSurfaceVariantDark = Color(0xFFC6C5D0)     // ux:ignore
    val surfaceContainerDark = Color(0xFF1E1F25)     // ux:ignore
    val surfaceContainerHighDark = Color(0xFF292A2F) // ux:ignore
    val surfaceContainerHighestDark = Color(0xFF33343A) // ux:ignore
    val outlineDark = Color(0xFF90909A)              // ux:ignore
    val outlineVariantDark = Color(0xFF45464F)       // ux:ignore
    val errorDark = Color(0xFFF2B8B5)                // ux:ignore
    val onErrorDark = Color(0xFF601410)              // ux:ignore
    val errorContainerDark = Color(0xFF8C1D18)       // ux:ignore
    val onErrorContainerDark = Color(0xFFF9DEDC)     // ux:ignore
}

private val DashboardLightColors: ColorScheme = lightColorScheme(
    primary = Palette.primaryLight,
    onPrimary = Palette.onPrimaryLight,
    primaryContainer = Palette.primaryContainerLight,
    onPrimaryContainer = Palette.onPrimaryContainerLight,
    secondary = Palette.secondaryLight,
    onSecondary = Palette.onSecondaryLight,
    secondaryContainer = Palette.secondaryContainerLight,
    onSecondaryContainer = Palette.onSecondaryContainerLight,
    background = Palette.surfaceLight,
    onBackground = Palette.onSurfaceLight,
    surface = Palette.surfaceLight,
    onSurface = Palette.onSurfaceLight,
    surfaceVariant = Palette.surfaceVariantLight,
    onSurfaceVariant = Palette.onSurfaceVariantLight,
    surfaceContainer = Palette.surfaceContainerLight,
    surfaceContainerHigh = Palette.surfaceContainerHighLight,
    surfaceContainerHighest = Palette.surfaceContainerHighestLight,
    outline = Palette.outlineLight,
    outlineVariant = Palette.outlineVariantLight,
    error = Palette.errorLight,
    onError = Palette.onErrorLight,
    errorContainer = Palette.errorContainerLight,
    onErrorContainer = Palette.onErrorContainerLight,
)

private val DashboardDarkColors: ColorScheme = darkColorScheme(
    primary = Palette.primaryDark,
    onPrimary = Palette.onPrimaryDark,
    primaryContainer = Palette.primaryContainerDark,
    onPrimaryContainer = Palette.onPrimaryContainerDark,
    secondary = Palette.secondaryDark,
    onSecondary = Palette.onSecondaryDark,
    secondaryContainer = Palette.secondaryContainerDark,
    onSecondaryContainer = Palette.onSecondaryContainerDark,
    background = Palette.surfaceDark,
    onBackground = Palette.onSurfaceDark,
    surface = Palette.surfaceDark,
    onSurface = Palette.onSurfaceDark,
    surfaceVariant = Palette.surfaceVariantDark,
    onSurfaceVariant = Palette.onSurfaceVariantDark,
    surfaceContainer = Palette.surfaceContainerDark,
    surfaceContainerHigh = Palette.surfaceContainerHighDark,
    surfaceContainerHighest = Palette.surfaceContainerHighestDark,
    outline = Palette.outlineDark,
    outlineVariant = Palette.outlineVariantDark,
    error = Palette.errorDark,
    onError = Palette.onErrorDark,
    errorContainer = Palette.errorContainerDark,
    onErrorContainer = Palette.onErrorContainerDark,
)

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD COLORS — roles the M3 ColorScheme has no slot for, carried on a
// CompositionLocal so the dashboard composable reads them like theme roles:
//   • onSurfaceStrong — highest-emphasis role for a metric value.
//   • statusSuccess / statusError — the honest positive / negative TREND cues, ALWAYS
//     paired with an icon + sign + text (never color alone), clearing WCAG 2.2.
//   • chart[] — the semantic, distinguishable chart series. The chart is never color-only:
//     bars are labeled and backed by a screen-reader data-table fallback (CHT-001, CHT-002).
//   • chartTrack — the muted baseline / gridline stroke.
// All contrast pairs clear WCAG 2.2 (text ≥ 4.5:1, large-text / UI ≥ 3:1) in BOTH themes.
// ─────────────────────────────────────────────────────────────────────────────
data class DashboardColors(
    val onSurfaceStrong: Color,
    val statusSuccess: Color,
    val statusError: Color,
    val chart: List<Color>,
    val chartTrack: Color,
)

private val DashboardColorsLight = DashboardColors(
    onSurfaceStrong = Color(0xFF141218),  // ux:ignore  (#141218 on #FBF8FF = 16.7:1)
    statusSuccess = Color(0xFF146C2E),    // ux:ignore  (#146C2E on #FBF8FF = 4.9:1, paired with ▲ + sign)
    statusError = Color(0xFFB3261E),      // ux:ignore  (#B3261E on #FBF8FF = 5.6:1, paired with ▼ + sign)
    chart = listOf(
        Color(0xFF4C5BC4),                // ux:ignore  (series 1 — indigo)
        Color(0xFF116B5D),                // ux:ignore  (series 2 — teal)
        Color(0xFF8A5000),                // ux:ignore  (series 3 — amber)
        Color(0xFF9A3B7A),                // ux:ignore  (series 4 — magenta)
    ),
    chartTrack = Color(0xFFC6C5D0),       // ux:ignore  (baseline / gridline)
)

private val DashboardColorsDark = DashboardColors(
    onSurfaceStrong = Color(0xFFFFFFFF),  // ux:ignore  (#FFFFFF on #121318 = 18.9:1)
    statusSuccess = Color(0xFF6DD58C),    // ux:ignore  (#6DD58C on #121318 = 9.9:1)
    statusError = Color(0xFFF2B8B5),      // ux:ignore  (#F2B8B5 on #121318 = 9.3:1)
    chart = listOf(
        Color(0xFFBEC2FF),                // ux:ignore  (series 1 — indigo)
        Color(0xFF5CD6C0),                // ux:ignore  (series 2 — teal)
        Color(0xFFF0BE6E),                // ux:ignore  (series 3 — amber)
        Color(0xFFF0AFD4),                // ux:ignore  (series 4 — magenta)
    ),
    chartTrack = Color(0xFF45464F),       // ux:ignore  (baseline / gridline)
)

/** Read the dashboard strong / status / chart roles anywhere under [DashboardTheme]. */
val LocalDashboardColors = staticCompositionLocalOf { DashboardColorsLight }
val MaterialTheme.dashboardColors: DashboardColors
    @Composable @ReadOnlyComposable get() = LocalDashboardColors.current

// ─────────────────────────────────────────────────────────────────────────────
// TYPOGRAPHY — semantic text roles resolve to MaterialTheme.typography, so every
// label scales with the user's font size / Dynamic Type (TYP-*, A11Y-*). No raw sp.
// `value` / `valueLarge` enable TABULAR FIGURES ('tnum') so metric columns align and
// never jitter as digits change — the only place a font feature string is set (TYP-006).
// (Maps the spec's type.display.sm / type.label.md metric-value + label roles.)
// ─────────────────────────────────────────────────────────────────────────────
object DashboardType {
    val greeting: TextStyle @Composable @ReadOnlyComposable get() = MaterialTheme.typography.headlineSmall
    val cardTitle: TextStyle @Composable @ReadOnlyComposable get() = MaterialTheme.typography.titleMedium
    val sectionTitle: TextStyle @Composable @ReadOnlyComposable get() = MaterialTheme.typography.titleLarge
    val body: TextStyle @Composable @ReadOnlyComposable get() = MaterialTheme.typography.bodyMedium
    val label: TextStyle @Composable @ReadOnlyComposable get() = MaterialTheme.typography.labelLarge
    val meta: TextStyle @Composable @ReadOnlyComposable get() = MaterialTheme.typography.labelMedium
    val trend: TextStyle @Composable @ReadOnlyComposable get() = MaterialTheme.typography.labelLarge

    /** Secondary numbers (data-table rows, cached / stale amounts) — tabular figures. */
    val amount: TextStyle @Composable @ReadOnlyComposable
        get() = MaterialTheme.typography.bodyLarge.copy(fontFeatureSettings = "tnum") // ux:ignore  ('tnum' = tabular figures)

    /** Metric value — tabular figures so the number column stays aligned as it updates. */
    val value: TextStyle @Composable @ReadOnlyComposable
        get() = MaterialTheme.typography.headlineMedium.copy(fontFeatureSettings = "tnum") // ux:ignore  ('tnum' = tabular figures)

    /** Hero metric value — larger, highest emphasis, tabular figures. */
    val valueLarge: TextStyle @Composable @ReadOnlyComposable
        get() = MaterialTheme.typography.displaySmall.copy(fontFeatureSettings = "tnum") // ux:ignore  ('tnum' = tabular figures)
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME — one provider at the root. Dark via isSystemInDarkTheme(); the Expressive
// theme carries the MotionScheme so reduce-motion is honored centrally.
// LocalDashboardColors is provided here so strong / status / chart roles swap with the
// theme too (DRK-*, MOT-*).
// ─────────────────────────────────────────────────────────────────────────────
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun DashboardTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    val colorScheme = if (darkTheme) DashboardDarkColors else DashboardLightColors
    val extra = if (darkTheme) DashboardColorsDark else DashboardColorsLight
    MaterialExpressiveTheme(
        colorScheme = colorScheme,
        shapes = DashboardShapes,
    ) {
        CompositionLocalProvider(LocalDashboardColors provides extra, content = content)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// REDUCE MOTION — read the system animator scale once; when it's 0 ("Remove animations"
// in Accessibility settings) all transitions collapse to instant (MOT-*, A11Y-*).
// ─────────────────────────────────────────────────────────────────────────────
@Composable
fun rememberReduceMotion(): Boolean {
    val resolver = LocalContext.current.contentResolver
    return remember(resolver) {
        Settings.Global.getFloat(resolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f // ux:ignore
    }
}
