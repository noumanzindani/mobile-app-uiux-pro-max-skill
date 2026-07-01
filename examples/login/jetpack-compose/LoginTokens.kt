package ux.examples.login

/**
 * LoginTokens — the semantic token layer for the login example.
 *
 * This is the ONLY file in this example allowed to contain raw values (hex colors,
 * dp spacing/radius/size, millis). Every such line is annotated `// ux:ignore` so the
 * token_lint validator treats this file as the single source of literals. The login
 * composable consumes ONLY these tokens plus `MaterialTheme.colorScheme` / `.typography`
 * roles — never a literal.
 *
 * Layering (DTCG → Compose): color/typography/shape flow through `MaterialExpressiveTheme`
 * (so dark mode + Material You resolve through role slots); spacing/size/radius — which M3
 * has no theme slot for — are carried as plain token objects (`Space`, `Size`, `Radius`).
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
// SPACING — DTCG space.* scale, snapped to the 4/8 grid (SPC-*).
// ─────────────────────────────────────────────────────────────────────────────
object Space {
    val xs: Dp = 4.dp   // ux:ignore
    val sm: Dp = 8.dp   // ux:ignore
    val md: Dp = 16.dp  // ux:ignore
    val lg: Dp = 24.dp  // ux:ignore
    val xl: Dp = 32.dp  // ux:ignore
}

// ─────────────────────────────────────────────────────────────────────────────
// SIZE — target minimums + glyph sizes (A11Y-*, ICN-*).
// ─────────────────────────────────────────────────────────────────────────────
object Size {
    /** Material minimum interactive target (also the iOS 44pt floor is cleared). */
    val minTarget: Dp = 48.dp     // ux:ignore
    val icon: Dp = 24.dp          // ux:ignore
    val ssoIcon: Dp = 20.dp       // ux:ignore
    val spinner: Dp = 20.dp       // ux:ignore
    val spinnerStroke: Dp = 2.dp  // ux:ignore
}

// ─────────────────────────────────────────────────────────────────────────────
// RADIUS / SHAPES — field radius (md) + brand pill for the primary CTA (SHP-*).
// ─────────────────────────────────────────────────────────────────────────────
object Radius {
    val md: Dp = 12.dp     // ux:ignore
    val pill: Dp = 9999.dp // ux:ignore  (fully-rounded "pill" per brand)
}

val LoginShapes = Shapes(
    extraSmall = RoundedCornerShape(Radius.md),
    small = RoundedCornerShape(Radius.md),
    medium = RoundedCornerShape(Radius.md),
    large = RoundedCornerShape(Radius.md),
    extraLarge = RoundedCornerShape(Radius.md),
)

/** Fully-rounded shape for the full-width primary and SSO buttons. */
val PillShape: Shape = RoundedCornerShape(Radius.pill)

// ─────────────────────────────────────────────────────────────────────────────
// MOTION — durations for the (alpha-only) transitions; reduce-motion collapses these
// to instant (see rememberReduceMotion). Only opacity/offset are ever animated (MOT-*).
// ─────────────────────────────────────────────────────────────────────────────
object Motion {
    const val shortMillis = 150      // ux:ignore  (error fade ≤200ms, no shake)
    const val simulatedDelayMs = 1200L // ux:ignore  (demo-only fake network latency)
}

// ─────────────────────────────────────────────────────────────────────────────
// COLOR — brand fallback palette. DTCG semantic roles are mapped onto M3 ColorScheme
// slots below; MaterialExpressiveTheme resolves light/dark (and Material You can be
// layered on top on Android 12+). All contrast pairs meet WCAG 2.2 (COL-*, DRK-*, A11Y-*).
// ─────────────────────────────────────────────────────────────────────────────
private object Palette {
    // Light
    val primaryLight = Color(0xFF6750A4)             // ux:ignore
    val onPrimaryLight = Color(0xFFFFFFFF)           // ux:ignore
    val primaryContainerLight = Color(0xFFEADDFF)    // ux:ignore
    val onPrimaryContainerLight = Color(0xFF21005D)  // ux:ignore
    val secondaryLight = Color(0xFF625B71)           // ux:ignore
    val onSecondaryLight = Color(0xFFFFFFFF)         // ux:ignore
    val surfaceLight = Color(0xFFFEF7FF)             // ux:ignore
    val onSurfaceLight = Color(0xFF1D1B20)           // ux:ignore
    val surfaceVariantLight = Color(0xFFE7E0EC)      // ux:ignore
    val onSurfaceVariantLight = Color(0xFF49454F)    // ux:ignore
    val surfaceContainerLight = Color(0xFFF3EDF7)    // ux:ignore
    val outlineLight = Color(0xFF79747E)             // ux:ignore
    val outlineVariantLight = Color(0xFFCAC4D0)      // ux:ignore
    val errorLight = Color(0xFFB3261E)               // ux:ignore
    val onErrorLight = Color(0xFFFFFFFF)             // ux:ignore
    val errorContainerLight = Color(0xFFF9DEDC)      // ux:ignore
    val onErrorContainerLight = Color(0xFF410E0B)    // ux:ignore

    // Dark
    val primaryDark = Color(0xFFD0BCFF)              // ux:ignore
    val onPrimaryDark = Color(0xFF381E72)            // ux:ignore
    val primaryContainerDark = Color(0xFF4F378B)     // ux:ignore
    val onPrimaryContainerDark = Color(0xFFEADDFF)   // ux:ignore
    val secondaryDark = Color(0xFFCCC2DC)            // ux:ignore
    val onSecondaryDark = Color(0xFF332D41)          // ux:ignore
    val surfaceDark = Color(0xFF141218)              // ux:ignore
    val onSurfaceDark = Color(0xFFE6E0E9)            // ux:ignore
    val surfaceVariantDark = Color(0xFF49454F)       // ux:ignore
    val onSurfaceVariantDark = Color(0xFFCAC4D0)     // ux:ignore
    val surfaceContainerDark = Color(0xFF211F26)     // ux:ignore
    val outlineDark = Color(0xFF938F99)              // ux:ignore
    val outlineVariantDark = Color(0xFF49454F)       // ux:ignore
    val errorDark = Color(0xFFF2B8B5)                // ux:ignore
    val onErrorDark = Color(0xFF601410)              // ux:ignore
    val errorContainerDark = Color(0xFF8C1D18)       // ux:ignore
    val onErrorContainerDark = Color(0xFFF9DEDC)     // ux:ignore
}

private val LoginLightColors: ColorScheme = lightColorScheme(
    primary = Palette.primaryLight,
    onPrimary = Palette.onPrimaryLight,
    primaryContainer = Palette.primaryContainerLight,
    onPrimaryContainer = Palette.onPrimaryContainerLight,
    secondary = Palette.secondaryLight,
    onSecondary = Palette.onSecondaryLight,
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

private val LoginDarkColors: ColorScheme = darkColorScheme(
    primary = Palette.primaryDark,
    onPrimary = Palette.onPrimaryDark,
    primaryContainer = Palette.primaryContainerDark,
    onPrimaryContainer = Palette.onPrimaryContainerDark,
    secondary = Palette.secondaryDark,
    onSecondary = Palette.onSecondaryDark,
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
// TYPOGRAPHY — semantic text roles resolve to MaterialTheme.typography, so every
// label scales with the user's font size / Dynamic Type (TYP-*, A11Y-*). No raw sp.
// ─────────────────────────────────────────────────────────────────────────────
object LoginType {
    val title: TextStyle @Composable @ReadOnlyComposable get() = MaterialTheme.typography.headlineSmall
    val subtitle: TextStyle @Composable @ReadOnlyComposable get() = MaterialTheme.typography.bodyLarge
    val body: TextStyle @Composable @ReadOnlyComposable get() = MaterialTheme.typography.bodyMedium
    val label: TextStyle @Composable @ReadOnlyComposable get() = MaterialTheme.typography.labelLarge
    val action: TextStyle @Composable @ReadOnlyComposable get() = MaterialTheme.typography.titleMedium
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME — one provider at the root. Dark via isSystemInDarkTheme(); Expressive theme
// carries the MotionScheme so reduce-motion is honored centrally (DRK-*, MOT-*).
// ─────────────────────────────────────────────────────────────────────────────
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun LoginTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    val colorScheme = if (darkTheme) LoginDarkColors else LoginLightColors
    MaterialExpressiveTheme(
        colorScheme = colorScheme,
        shapes = LoginShapes,
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
