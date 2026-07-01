package ux.examples.settings

/**
 * SettingsTokens — the semantic token layer for the settings example.
 *
 * This is the ONLY file in this example allowed to contain raw values (hex colors,
 * dp spacing / size / radius, the breakpoint dp values, and millis). Every such line is
 * annotated `// ux:ignore` so the token_lint validator treats this file as the single
 * source of literals. The settings composable consumes ONLY these tokens plus
 * `MaterialTheme.colorScheme` / `.typography` / `.shapes` roles — never a literal.
 *
 * Layering (DTCG -> Compose): color / typography / shape flow through
 * `MaterialExpressiveTheme` (so dark mode + Material You resolve through role slots);
 * spacing / size / radius / breakpoints — which M3 has no theme slot for — are carried as
 * plain token objects (`Space`, `Size`, `Radius`, `Breakpoints`). All the roles the settings
 * list needs map cleanly onto the M3 ColorScheme slots, so no CompositionLocal is required:
 *   • row background / grouped card    -> surface / surfaceContainer
 *   • row divider + group inset        -> outlineVariant
 *   • row label / value / header       -> onSurface / onSurfaceVariant
 *   • switch on-track / thumb          -> primary / onPrimary
 *   • destructive label (sign out …)   -> error / onError
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
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.remember
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

// ─────────────────────────────────────────────────────────────────────────────
// SPACING — DTCG space.* scale, snapped to the 4/8 grid (SPC-*). `rowInset` is the
// 16dp leading keyline (space.4) every row and divider aligns to; `group` is the 24dp
// gap between grouped sections (space.6 per the spec's token table).
// ─────────────────────────────────────────────────────────────────────────────
object Space {
    val zero: Dp = 0.dp   // ux:ignore  (animation rest / no-gap)
    val xs: Dp = 4.dp     // ux:ignore
    val sm: Dp = 8.dp     // ux:ignore
    val md: Dp = 16.dp    // ux:ignore
    val lg: Dp = 24.dp    // ux:ignore
    val xl: Dp = 32.dp    // ux:ignore

    /** Row leading keyline == divider inset (space.4). */
    val rowInset: Dp = 16.dp // ux:ignore

    /** Spacing between grouped sections (space.6). */
    val group: Dp = 24.dp    // ux:ignore
}

// ─────────────────────────────────────────────────────────────────────────────
// SIZE — target minimums + glyph / pane sizes (A11Y-*, ICN-*). `rowMinHeight` is the
// Material 48dp minimum every interactive row / switch / destructive row clears.
// ─────────────────────────────────────────────────────────────────────────────
object Size {
    /** Material minimum interactive target — every row clears it (also the iOS 44pt floor). */
    val rowMinHeight: Dp = 48.dp     // ux:ignore
    val icon: Dp = 24.dp             // ux:ignore
    val emptyIcon: Dp = 40.dp        // ux:ignore  (zero-results illustration glyph)

    // Shape-matched skeleton block heights (non-text placeholder boxes for synced values).
    val skeletonLabel: Dp = 16.dp    // ux:ignore
    val skeletonValue: Dp = 12.dp    // ux:ignore

    /** Leading category pane width in the expanded (≥840dp) two-pane layout. */
    val railWidth: Dp = 320.dp       // ux:ignore

    /** Max content measure so the list never stretches edge-to-edge on very wide screens. */
    val maxContentWidth: Dp = 640.dp // ux:ignore
}

// ─────────────────────────────────────────────────────────────────────────────
// RADIUS / SHAPES — grouped-card radius (lg) + field radius (md); the fully-rounded
// pill is kept for completeness (SHP-*).
// ─────────────────────────────────────────────────────────────────────────────
object Radius {
    val sm: Dp = 8.dp      // ux:ignore
    val md: Dp = 12.dp     // ux:ignore
    val lg: Dp = 16.dp     // ux:ignore  (grouped inset cards)
    val pill: Dp = 9999.dp // ux:ignore  (fully-rounded control, if needed)
}

val SettingsShapes = Shapes(
    extraSmall = RoundedCornerShape(Radius.sm),
    small = RoundedCornerShape(Radius.sm),
    medium = RoundedCornerShape(Radius.md),
    large = RoundedCornerShape(Radius.lg),
    extraLarge = RoundedCornerShape(Radius.lg),
)

/** Fully-rounded shape, available for pill-styled controls. */
val PillShape: Shape = RoundedCornerShape(Radius.pill)

// ─────────────────────────────────────────────────────────────────────────────
// BREAKPOINTS — M3 window-size-class widths (GRD-004). Compact < 600dp is a single
// scrolling list that pushes a sub-page; Expanded ≥ 840dp is a two-pane list-detail.
// The 600–839dp medium band stays single-pane. Same values M3's WindowSizeClass uses.
// ─────────────────────────────────────────────────────────────────────────────
object Breakpoints {
    val compact: Dp = 600.dp   // ux:ignore
    val expanded: Dp = 840.dp  // ux:ignore
}

// ─────────────────────────────────────────────────────────────────────────────
// MOTION — durations for the (alpha-only) banner transitions; reduce-motion collapses
// these to instant (see rememberReduceMotion). Only opacity is ever animated. The "*Ms"
// values are demo-only stand-ins for real save / sync latency (MOT-*).
// ─────────────────────────────────────────────────────────────────────────────
object Motion {
    const val shortMillis = 150       // ux:ignore  (banner fade ≤200ms, no bounce)
    const val simulatedSaveMs = 900L  // ux:ignore  (demo: server save round-trip)
    const val simulatedSyncMs = 1200L // ux:ignore  (demo: initial synced-value fetch)
}

// ─────────────────────────────────────────────────────────────────────────────
// COLOR — brand fallback palette. DTCG semantic roles are mapped onto M3 ColorScheme
// slots below; MaterialExpressiveTheme resolves light / dark (and Material You can be
// layered on Android 12+). Contrast pairs meet WCAG 2.2 (COL-*, DRK-*, A11Y-*).
// ─────────────────────────────────────────────────────────────────────────────
private object Palette {
    // Light
    val primaryLight = Color(0xFF4C5BC4)              // ux:ignore
    val onPrimaryLight = Color(0xFFFFFFFF)            // ux:ignore
    val primaryContainerLight = Color(0xFFE0E1FF)     // ux:ignore
    val onPrimaryContainerLight = Color(0xFF03105B)   // ux:ignore
    val secondaryLight = Color(0xFF5A5D72)            // ux:ignore
    val onSecondaryLight = Color(0xFFFFFFFF)          // ux:ignore
    val secondaryContainerLight = Color(0xFFDFE1F9)   // ux:ignore
    val onSecondaryContainerLight = Color(0xFF171B2C) // ux:ignore
    val surfaceLight = Color(0xFFFBF8FF)              // ux:ignore
    val onSurfaceLight = Color(0xFF1A1B21)            // ux:ignore
    val surfaceVariantLight = Color(0xFFE3E1EC)       // ux:ignore
    val onSurfaceVariantLight = Color(0xFF45464F)     // ux:ignore
    val surfaceContainerLight = Color(0xFFEFEDF7)     // ux:ignore
    val outlineLight = Color(0xFF767680)              // ux:ignore
    val outlineVariantLight = Color(0xFFC6C5D0)       // ux:ignore
    val errorLight = Color(0xFFB3261E)                // ux:ignore
    val onErrorLight = Color(0xFFFFFFFF)              // ux:ignore
    val errorContainerLight = Color(0xFFF9DEDC)       // ux:ignore
    val onErrorContainerLight = Color(0xFF410E0B)     // ux:ignore

    // Dark
    val primaryDark = Color(0xFFBEC2FF)               // ux:ignore
    val onPrimaryDark = Color(0xFF1B2678)             // ux:ignore
    val primaryContainerDark = Color(0xFF333EA0)      // ux:ignore
    val onPrimaryContainerDark = Color(0xFFE0E1FF)    // ux:ignore
    val secondaryDark = Color(0xFFC3C5DD)             // ux:ignore
    val onSecondaryDark = Color(0xFF2C2F42)           // ux:ignore
    val secondaryContainerDark = Color(0xFF424659)    // ux:ignore
    val onSecondaryContainerDark = Color(0xFFDFE1F9)  // ux:ignore
    val surfaceDark = Color(0xFF121318)               // ux:ignore
    val onSurfaceDark = Color(0xFFE3E1E9)             // ux:ignore
    val surfaceVariantDark = Color(0xFF45464F)        // ux:ignore
    val onSurfaceVariantDark = Color(0xFFC6C5D0)      // ux:ignore
    val surfaceContainerDark = Color(0xFF1E1F25)      // ux:ignore
    val outlineDark = Color(0xFF90909A)               // ux:ignore
    val outlineVariantDark = Color(0xFF45464F)        // ux:ignore
    val errorDark = Color(0xFFF2B8B5)                 // ux:ignore
    val onErrorDark = Color(0xFF601410)               // ux:ignore
    val errorContainerDark = Color(0xFF8C1D18)        // ux:ignore
    val onErrorContainerDark = Color(0xFFF9DEDC)      // ux:ignore
}

private val SettingsLightColors: ColorScheme = lightColorScheme(
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
    outline = Palette.outlineLight,
    outlineVariant = Palette.outlineVariantLight,
    error = Palette.errorLight,
    onError = Palette.onErrorLight,
    errorContainer = Palette.errorContainerLight,
    onErrorContainer = Palette.onErrorContainerLight,
)

private val SettingsDarkColors: ColorScheme = darkColorScheme(
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
    outline = Palette.outlineDark,
    outlineVariant = Palette.outlineVariantDark,
    error = Palette.errorDark,
    onError = Palette.onErrorDark,
    errorContainer = Palette.errorContainerDark,
    onErrorContainer = Palette.onErrorContainerDark,
)

// ─────────────────────────────────────────────────────────────────────────────
// TYPOGRAPHY — semantic text roles resolve to MaterialTheme.typography, so every label
// scales with the user's font size / Dynamic Type (TYP-*, A11Y-*). No raw sp. Maps the
// spec's type.body.md (row label / value) and type.label.md (group header) roles.
// ─────────────────────────────────────────────────────────────────────────────
object SettingsType {
    val screenTitle: TextStyle @Composable @ReadOnlyComposable get() = MaterialTheme.typography.headlineSmall
    val groupHeader: TextStyle @Composable @ReadOnlyComposable get() = MaterialTheme.typography.titleSmall
    val rowLabel: TextStyle @Composable @ReadOnlyComposable get() = MaterialTheme.typography.bodyLarge
    val rowValue: TextStyle @Composable @ReadOnlyComposable get() = MaterialTheme.typography.bodyMedium
    val emptyTitle: TextStyle @Composable @ReadOnlyComposable get() = MaterialTheme.typography.titleMedium
    val body: TextStyle @Composable @ReadOnlyComposable get() = MaterialTheme.typography.bodyMedium
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME — one provider at the root. Dark via isSystemInDarkTheme(); the Expressive
// theme carries the MotionScheme so reduce-motion is honored centrally (DRK-*, MOT-*).
// The app can override the system value with an explicit light/dark choice (see the
// theme selector in SettingsScreen) by passing `darkTheme`.
// ─────────────────────────────────────────────────────────────────────────────
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun SettingsTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    val colorScheme = if (darkTheme) SettingsDarkColors else SettingsLightColors
    MaterialExpressiveTheme(
        colorScheme = colorScheme,
        shapes = SettingsShapes,
        content = content,
    )
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
