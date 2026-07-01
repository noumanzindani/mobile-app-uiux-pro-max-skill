package ux.examples.checkout

/**
 * CheckoutTokens — the semantic token layer for the checkout example.
 *
 * This is the ONLY file in this example allowed to contain raw values (hex colors,
 * dp spacing/size/radius, millis, and the one platform-mandated Google Pay brand color).
 * Every such line is annotated `// ux:ignore` so the token_lint validator treats this file
 * as the single source of literals. The checkout composable consumes ONLY these tokens
 * plus `MaterialTheme.colorScheme` / `.typography` / `.shapes` roles — never a literal.
 *
 * Layering (DTCG -> Compose): color/typography/shape flow through `MaterialExpressiveTheme`
 * (so dark mode + Material You resolve through role slots); spacing/size/radius — which M3
 * has no theme slot for — are carried as plain token objects (`Space`, `Size`, `Radius`).
 * Roles the M3 ColorScheme has no slot for — `on-surface-strong`, `status.success`, and the
 * platform-standard **Google Pay** button color — ride a `CompositionLocal`
 * (`LocalCheckoutColors`) provided once at the theme root. The Google Pay color is the only
 * literal the checkout spec permits outside a token (native Pay styling is not re-tokenized).
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
// SPACING — DTCG space.* scale, snapped to the 4/8 grid (SPC-*).
// ─────────────────────────────────────────────────────────────────────────────
object Space {
    val zero: Dp = 0.dp // ux:ignore  (animation rest offset)
    val xxs: Dp = 2.dp  // ux:ignore  (hair gap between an icon and its trust label)
    val xs: Dp = 4.dp   // ux:ignore
    val sm: Dp = 8.dp   // ux:ignore
    val md: Dp = 16.dp  // ux:ignore
    val lg: Dp = 24.dp  // ux:ignore
    val xl: Dp = 32.dp  // ux:ignore
}

// ─────────────────────────────────────────────────────────────────────────────
// SIZE — target minimums + glyph / control sizes (A11Y-*, ICN-*).
// ─────────────────────────────────────────────────────────────────────────────
object Size {
    /** Material minimum interactive target (also clears the iOS 44pt floor). */
    val minTarget: Dp = 48.dp        // ux:ignore
    val icon: Dp = 24.dp             // ux:ignore
    val trustIcon: Dp = 16.dp        // ux:ignore
    val payLogo: Dp = 24.dp          // ux:ignore  (native Pay wordmark height)
    val spinner: Dp = 20.dp          // ux:ignore
    val spinnerStroke: Dp = 2.dp     // ux:ignore
}

// ─────────────────────────────────────────────────────────────────────────────
// RADIUS / SHAPES — card/field radius (md), summary card (lg) + brand pill (SHP-*).
// ─────────────────────────────────────────────────────────────────────────────
object Radius {
    val sm: Dp = 8.dp      // ux:ignore
    val md: Dp = 12.dp     // ux:ignore
    val lg: Dp = 16.dp     // ux:ignore  (order-summary + confirmation cards)
    val pill: Dp = 9999.dp // ux:ignore  (fully-rounded primary Pay + native Pay buttons)
}

val CheckoutShapes = Shapes(
    extraSmall = RoundedCornerShape(Radius.sm),
    small = RoundedCornerShape(Radius.sm),
    medium = RoundedCornerShape(Radius.md),
    large = RoundedCornerShape(Radius.lg),
    extraLarge = RoundedCornerShape(Radius.lg),
)

/** Fully-rounded shape for the full-width primary Pay button and the native Pay shortcut. */
val PillShape: Shape = RoundedCornerShape(Radius.pill)

// ─────────────────────────────────────────────────────────────────────────────
// MOTION — durations for the (alpha/offset-only) transitions; reduce-motion collapses
// these to instant (see rememberReduceMotion). Only opacity/offset are ever animated, and
// the "*Ms" values are the demo-only stand-ins for the real payment latency (MOT-*, PRG-*).
// ─────────────────────────────────────────────────────────────────────────────
object Motion {
    const val shortMillis = 150       // ux:ignore  (total-change / status fade <=200ms)
    const val insertMillis = 220      // ux:ignore  (confirmation reveal <=250ms)
    const val processingMs = 1600L    // ux:ignore  (demo: authorizing the charge)
    const val reconcileMs = 900L      // ux:ignore  (demo: reconnect reconcile before result)
}

// ─────────────────────────────────────────────────────────────────────────────
// COLOR — brand fallback palette. DTCG semantic roles are mapped onto M3 ColorScheme
// slots below; MaterialExpressiveTheme resolves light/dark (and Material You can be
// layered on top on Android 12+). Contrast pairs meet WCAG 2.2 (COL-*, DRK-*, A11Y-*).
// ─────────────────────────────────────────────────────────────────────────────
private object Palette {
    // Light
    val primaryLight = Color(0xFF6750A4)             // ux:ignore
    val onPrimaryLight = Color(0xFFFFFFFF)           // ux:ignore
    val primaryContainerLight = Color(0xFFEADDFF)    // ux:ignore
    val onPrimaryContainerLight = Color(0xFF21005D)  // ux:ignore
    val secondaryLight = Color(0xFF625B71)           // ux:ignore
    val onSecondaryLight = Color(0xFFFFFFFF)         // ux:ignore
    val secondaryContainerLight = Color(0xFFE8DEF8)  // ux:ignore
    val onSecondaryContainerLight = Color(0xFF1D192B) // ux:ignore
    val surfaceLight = Color(0xFFFEF7FF)             // ux:ignore
    val onSurfaceLight = Color(0xFF1D1B20)           // ux:ignore
    val surfaceVariantLight = Color(0xFFE7E0EC)      // ux:ignore
    val onSurfaceVariantLight = Color(0xFF49454F)    // ux:ignore
    val surfaceContainerLight = Color(0xFFF3EDF7)    // ux:ignore
    val surfaceContainerHighLight = Color(0xFFECE6F0) // ux:ignore
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
    val secondaryContainerDark = Color(0xFF4A4458)   // ux:ignore
    val onSecondaryContainerDark = Color(0xFFE8DEF8) // ux:ignore
    val surfaceDark = Color(0xFF141218)              // ux:ignore
    val onSurfaceDark = Color(0xFFE6E0E9)            // ux:ignore
    val surfaceVariantDark = Color(0xFF49454F)       // ux:ignore
    val onSurfaceVariantDark = Color(0xFFCAC4D0)     // ux:ignore
    val surfaceContainerDark = Color(0xFF211F26)     // ux:ignore
    val surfaceContainerHighDark = Color(0xFF2B2930) // ux:ignore
    val outlineDark = Color(0xFF938F99)              // ux:ignore
    val outlineVariantDark = Color(0xFF49454F)       // ux:ignore
    val errorDark = Color(0xFFF2B8B5)                // ux:ignore
    val onErrorDark = Color(0xFF601410)              // ux:ignore
    val errorContainerDark = Color(0xFF8C1D18)       // ux:ignore
    val onErrorContainerDark = Color(0xFFF9DEDC)     // ux:ignore
}

private val CheckoutLightColors: ColorScheme = lightColorScheme(
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
    outline = Palette.outlineLight,
    outlineVariant = Palette.outlineVariantLight,
    error = Palette.errorLight,
    onError = Palette.onErrorLight,
    errorContainer = Palette.errorContainerLight,
    onErrorContainer = Palette.onErrorContainerLight,
)

private val CheckoutDarkColors: ColorScheme = darkColorScheme(
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
    outline = Palette.outlineDark,
    outlineVariant = Palette.outlineVariantDark,
    error = Palette.errorDark,
    onError = Palette.onErrorDark,
    errorContainer = Palette.errorContainerDark,
    onErrorContainer = Palette.onErrorContainerDark,
)

// ─────────────────────────────────────────────────────────────────────────────
// CHECKOUT COLORS — roles the M3 ColorScheme has no slot for, carried on a
// CompositionLocal so the checkout composable reads them like theme roles:
//   • on-surface-strong — the highest-emphasis role for the TOTAL amount.
//   • status.success — the honest "secure / order placed" cue, ALWAYS paired with
//     an icon + text (never color alone), clearing WCAG 2.2 large-text contrast.
//   • googlePay* — the platform-standard native Pay button color. Per the spec, native
//     Pay styling is NOT re-tokenized; this is the sole permitted brand literal.
// Text-on-fill pairs below clear WCAG 2.2 body contrast (>= 4.5:1) in BOTH themes.
// ─────────────────────────────────────────────────────────────────────────────
data class CheckoutColors(
    val onSurfaceStrong: Color,
    val statusSuccess: Color,
    val onStatusSuccess: Color,
    val statusSuccessContainer: Color,
    val onStatusSuccessContainer: Color,
    val googlePayContainer: Color,
    val onGooglePay: Color,
)

private val CheckoutColorsLight = CheckoutColors(
    onSurfaceStrong = Color(0xFF141218),           // ux:ignore  (#141218 on #FEF7FF = 16.9:1)
    statusSuccess = Color(0xFF146C2E),             // ux:ignore  (#146C2E on #FEF7FF = 4.9:1)
    onStatusSuccess = Color(0xFFFFFFFF),           // ux:ignore
    statusSuccessContainer = Color(0xFFB8F5C0),    // ux:ignore
    onStatusSuccessContainer = Color(0xFF00210B),  // ux:ignore  (#00210B on #B8F5C0 = 14.1:1)
    googlePayContainer = Color(0xFF000000),        // ux:ignore  (Google Pay brand — native Pay styling, not re-tokenized)
    onGooglePay = Color(0xFFFFFFFF),               // ux:ignore
)

private val CheckoutColorsDark = CheckoutColors(
    onSurfaceStrong = Color(0xFFFFFFFF),           // ux:ignore  (#FFFFFF on #141218 = 18.4:1)
    statusSuccess = Color(0xFF6DD58C),             // ux:ignore  (#6DD58C on #141218 = 9.8:1)
    onStatusSuccess = Color(0xFF00390F),           // ux:ignore
    statusSuccessContainer = Color(0xFF0A5124),    // ux:ignore
    onStatusSuccessContainer = Color(0xFFB8F5C0),  // ux:ignore  (#B8F5C0 on #0A5124 = 8.6:1)
    googlePayContainer = Color(0xFFFFFFFF),        // ux:ignore  (Google Pay brand — light button on dark, per spec)
    onGooglePay = Color(0xFF000000),               // ux:ignore
)

/** Read the checkout success/strong/native-Pay roles anywhere under [CheckoutTheme]. */
val LocalCheckoutColors = staticCompositionLocalOf { CheckoutColorsLight }
val MaterialTheme.checkoutColors: CheckoutColors
    @Composable @ReadOnlyComposable get() = LocalCheckoutColors.current

// ─────────────────────────────────────────────────────────────────────────────
// TYPOGRAPHY — semantic text roles resolve to MaterialTheme.typography, so every
// label scales with the user's font size / Dynamic Type (TYP-*, A11Y-*). No raw sp.
// `amount` / `total` enable TABULAR FIGURES ('tnum') so price columns align and never
// jitter as digits change — the only place a font feature string is set (TYP-006).
// ─────────────────────────────────────────────────────────────────────────────
object CheckoutType {
    val title: TextStyle @Composable @ReadOnlyComposable get() = MaterialTheme.typography.headlineSmall
    val sectionTitle: TextStyle @Composable @ReadOnlyComposable get() = MaterialTheme.typography.titleMedium
    val body: TextStyle @Composable @ReadOnlyComposable get() = MaterialTheme.typography.bodyLarge
    val bodySmall: TextStyle @Composable @ReadOnlyComposable get() = MaterialTheme.typography.bodyMedium
    val label: TextStyle @Composable @ReadOnlyComposable get() = MaterialTheme.typography.labelLarge
    val meta: TextStyle @Composable @ReadOnlyComposable get() = MaterialTheme.typography.labelMedium
    val action: TextStyle @Composable @ReadOnlyComposable get() = MaterialTheme.typography.titleMedium

    /** Line-item / summary-row amount — tabular figures so the price column stays aligned. */
    val amount: TextStyle @Composable @ReadOnlyComposable
        get() = MaterialTheme.typography.bodyLarge.copy(fontFeatureSettings = "tnum") // ux:ignore  ('tnum' = tabular figures)

    /** The grand TOTAL — larger, highest emphasis, tabular figures. */
    val total: TextStyle @Composable @ReadOnlyComposable
        get() = MaterialTheme.typography.titleLarge.copy(fontFeatureSettings = "tnum") // ux:ignore  ('tnum' = tabular figures)
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME — one provider at the root. Dark via isSystemInDarkTheme(); the Expressive
// theme carries the MotionScheme so reduce-motion is honored centrally.
// LocalCheckoutColors is provided here so success/strong/native-Pay roles swap with
// the theme too (DRK-*, MOT-*).
// ─────────────────────────────────────────────────────────────────────────────
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun CheckoutTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    val colorScheme = if (darkTheme) CheckoutDarkColors else CheckoutLightColors
    val extra = if (darkTheme) CheckoutColorsDark else CheckoutColorsLight
    MaterialExpressiveTheme(
        colorScheme = colorScheme,
        shapes = CheckoutShapes,
    ) {
        CompositionLocalProvider(LocalCheckoutColors provides extra, content = content)
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
