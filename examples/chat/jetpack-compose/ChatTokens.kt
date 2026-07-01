package ux.examples.chat

/**
 * ChatTokens — the semantic token layer for the chat example.
 *
 * This is the ONLY file in this example allowed to contain raw values (hex colors,
 * dp spacing/size/radius, millis). Every such line is annotated `// ux:ignore` so the
 * token_lint validator treats this file as the single source of literals. The chat
 * composable consumes ONLY these tokens plus `MaterialTheme.colorScheme` / `.typography`
 * / `.shapes` roles — never a literal.
 *
 * Layering (DTCG -> Compose): color/typography/shape flow through `MaterialExpressiveTheme`
 * (so dark mode + Material You resolve through role slots); spacing/size/radius — which M3
 * has no theme slot for — are carried as plain token objects (`Space`, `Size`, `Radius`).
 * Bubble + delivery-status colors are not standard M3 roles, so they ride a
 * `CompositionLocal` (`LocalChatColors`) provided once at the theme root. Every own/other
 * bubble text-on-fill pair clears WCAG 2.2 body contrast (>= 4.5:1) in BOTH themes.
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
    val xxs: Dp = 2.dp  // ux:ignore  (tight status-icon / dot gap)
    val xs: Dp = 4.dp   // ux:ignore
    val sm: Dp = 8.dp   // ux:ignore
    val md: Dp = 16.dp  // ux:ignore
    val lg: Dp = 24.dp  // ux:ignore
    val xl: Dp = 32.dp  // ux:ignore
}

// ─────────────────────────────────────────────────────────────────────────────
// SIZE — target minimums + glyph / bubble sizes (A11Y-*, ICN-*).
// ─────────────────────────────────────────────────────────────────────────────
object Size {
    /** Material minimum interactive target (also clears the iOS 44pt floor). */
    val minTarget: Dp = 48.dp        // ux:ignore
    val icon: Dp = 24.dp             // ux:ignore
    val statusIcon: Dp = 16.dp       // ux:ignore
    val avatar: Dp = 40.dp           // ux:ignore
    val typingDot: Dp = 8.dp         // ux:ignore
    val bubbleMax: Dp = 320.dp       // ux:ignore  (max bubble width; text wraps within)
    val skeletonLine: Dp = 16.dp     // ux:ignore  (skeleton placeholder bar height)
    val skeletonShort: Dp = 120.dp   // ux:ignore
    val skeletonLong: Dp = 220.dp    // ux:ignore
    val spinner: Dp = 24.dp          // ux:ignore
}

// ─────────────────────────────────────────────────────────────────────────────
// RADIUS / SHAPES — bubble radius (lg) + banner radius (md) + brand pill (SHP-*).
// ─────────────────────────────────────────────────────────────────────────────
object Radius {
    val sm: Dp = 8.dp      // ux:ignore
    val md: Dp = 12.dp     // ux:ignore
    val lg: Dp = 20.dp     // ux:ignore  (message bubble)
    val pill: Dp = 9999.dp // ux:ignore  (fully-rounded "new messages" pill)
}

val ChatShapes = Shapes(
    extraSmall = RoundedCornerShape(Radius.sm),
    small = RoundedCornerShape(Radius.sm),
    medium = RoundedCornerShape(Radius.md),
    large = RoundedCornerShape(Radius.lg),
    extraLarge = RoundedCornerShape(Radius.lg),
)

/** Fully-rounded shape for the "N new messages" jump pill. */
val PillShape: Shape = RoundedCornerShape(Radius.pill)

// ─────────────────────────────────────────────────────────────────────────────
// MOTION — durations for the (alpha/offset-only) transitions; reduce-motion collapses
// these to instant (see rememberReduceMotion). Only opacity/offset are ever animated,
// and the "*Ms" values are the demo-only stand-ins for real network timing (MOT-*).
// ─────────────────────────────────────────────────────────────────────────────
object Motion {
    const val shortMillis = 150       // ux:ignore  (status icon cross-fade <=150ms)
    const val insertMillis = 220      // ux:ignore  (outgoing bubble insert <=250ms)
    const val typingPeriodMillis = 900 // ux:ignore (typing-dot loop period)
    const val settleMs = 700L         // ux:ignore  (demo: sending -> sent latency)
    const val stepMs = 650L           // ux:ignore  (demo: sent -> delivered -> read step)
    const val replyMs = 1400L         // ux:ignore  (demo: peer typing -> reply latency)
    const val retryBackoffMs = 1200L  // ux:ignore  (demo: offline flush backoff)
}

// ─────────────────────────────────────────────────────────────────────────────
// COLOR — brand fallback palette. DTCG semantic roles are mapped onto M3 ColorScheme
// slots below; MaterialExpressiveTheme resolves light/dark (and Material You can be
// layered on top on Android 12+). Contrast pairs meet WCAG 2.2 (COL-*, DRK-*, A11Y-*).
// ─────────────────────────────────────────────────────────────────────────────
private object Palette {
    // Light
    val primaryLight = Color(0xFF2563EB)             // ux:ignore
    val onPrimaryLight = Color(0xFFFFFFFF)           // ux:ignore
    val primaryContainerLight = Color(0xFFDBE4FF)    // ux:ignore
    val onPrimaryContainerLight = Color(0xFF001849)  // ux:ignore
    val secondaryLight = Color(0xFF565E71)           // ux:ignore
    val onSecondaryLight = Color(0xFFFFFFFF)         // ux:ignore
    val surfaceLight = Color(0xFFFDFBFF)             // ux:ignore
    val onSurfaceLight = Color(0xFF1A1B1F)           // ux:ignore
    val surfaceVariantLight = Color(0xFFE1E2EC)      // ux:ignore
    val onSurfaceVariantLight = Color(0xFF44474F)    // ux:ignore
    val surfaceContainerLight = Color(0xFFF1F0F7)    // ux:ignore
    val outlineLight = Color(0xFF75777F)             // ux:ignore
    val outlineVariantLight = Color(0xFFC5C6D0)      // ux:ignore
    val errorLight = Color(0xFFB3261E)               // ux:ignore
    val onErrorLight = Color(0xFFFFFFFF)             // ux:ignore
    val errorContainerLight = Color(0xFFF9DEDC)      // ux:ignore
    val onErrorContainerLight = Color(0xFF410E0B)    // ux:ignore

    // Dark
    val primaryDark = Color(0xFFB4C5FF)              // ux:ignore
    val onPrimaryDark = Color(0xFF002A78)            // ux:ignore
    val primaryContainerDark = Color(0xFF1E439E)     // ux:ignore
    val onPrimaryContainerDark = Color(0xFFDBE4FF)   // ux:ignore
    val secondaryDark = Color(0xFFBEC6DC)            // ux:ignore
    val onSecondaryDark = Color(0xFF283041)          // ux:ignore
    val surfaceDark = Color(0xFF121316)             // ux:ignore
    val onSurfaceDark = Color(0xFFE3E2E6)           // ux:ignore
    val surfaceVariantDark = Color(0xFF44474F)      // ux:ignore
    val onSurfaceVariantDark = Color(0xFFC5C6D0)    // ux:ignore
    val surfaceContainerDark = Color(0xFF1E1F23)    // ux:ignore
    val outlineDark = Color(0xFF8F9099)             // ux:ignore
    val outlineVariantDark = Color(0xFF44474F)      // ux:ignore
    val errorDark = Color(0xFFF2B8B5)               // ux:ignore
    val onErrorDark = Color(0xFF601410)             // ux:ignore
    val errorContainerDark = Color(0xFF8C1D18)      // ux:ignore
    val onErrorContainerDark = Color(0xFFF9DEDC)    // ux:ignore
}

private val ChatLightColors: ColorScheme = lightColorScheme(
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

private val ChatDarkColors: ColorScheme = darkColorScheme(
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
// CHAT COLORS — bubble + delivery-status roles the M3 ColorScheme has no slot for.
// Carried on a CompositionLocal so the chat composable reads them like theme roles.
// Every text-on-bubble pair below clears WCAG 2.2 body contrast (>= 4.5:1):
//   own light   #FFFFFF on #2563EB = 5.17:1   own dark   #FFFFFF on #3D5AFE = 5.13:1
//   other light #1A1B1F on #E1E2EC = 12.8:1   other dark #E3E2E6 on #2B2930 = 11.0:1
// ─────────────────────────────────────────────────────────────────────────────
data class ChatColors(
    val ownBubble: Color,
    val onOwnBubble: Color,
    val onOwnBubbleMeta: Color,
    val otherBubble: Color,
    val onOtherBubble: Color,
    val onOtherBubbleMeta: Color,
    val statusInfo: Color,
    val statusError: Color,
)

private val ChatColorsLight = ChatColors(
    ownBubble = Color(0xFF2563EB),         // ux:ignore
    onOwnBubble = Color(0xFFFFFFFF),       // ux:ignore
    onOwnBubbleMeta = Color(0xFFFFFFFF),   // ux:ignore  (#FFFFFF on #2563EB = 5.17:1)
    otherBubble = Color(0xFFE1E2EC),       // ux:ignore
    onOtherBubble = Color(0xFF1A1B1F),     // ux:ignore
    onOtherBubbleMeta = Color(0xFF44474F), // ux:ignore  (#44474F on #E1E2EC = 6.9:1)
    statusInfo = Color(0xFF2563EB),        // ux:ignore
    statusError = Color(0xFFB3261E),       // ux:ignore
)

private val ChatColorsDark = ChatColors(
    ownBubble = Color(0xFF3D5AFE),         // ux:ignore
    onOwnBubble = Color(0xFFFFFFFF),       // ux:ignore
    onOwnBubbleMeta = Color(0xFFFFFFFF),   // ux:ignore  (#FFFFFF on #3D5AFE = 5.13:1)
    otherBubble = Color(0xFF2B2930),       // ux:ignore
    onOtherBubble = Color(0xFFE3E2E6),     // ux:ignore
    onOtherBubbleMeta = Color(0xFFC5C6D0), // ux:ignore  (#C5C6D0 on #2B2930 = 8.4:1)
    statusInfo = Color(0xFFAAC7FF),        // ux:ignore
    statusError = Color(0xFFF2B8B5),       // ux:ignore
)

/** Read the chat bubble/status roles anywhere under [ChatTheme], like a theme role. */
val LocalChatColors = staticCompositionLocalOf { ChatColorsLight }
val MaterialTheme.chatColors: ChatColors
    @Composable @ReadOnlyComposable get() = LocalChatColors.current

// ─────────────────────────────────────────────────────────────────────────────
// TYPOGRAPHY — semantic text roles resolve to MaterialTheme.typography, so every
// label scales with the user's font size / Dynamic Type (TYP-*, A11Y-*). No raw sp.
// ─────────────────────────────────────────────────────────────────────────────
object ChatType {
    val contactName: TextStyle @Composable @ReadOnlyComposable get() = MaterialTheme.typography.titleMedium
    val presence: TextStyle @Composable @ReadOnlyComposable get() = MaterialTheme.typography.bodySmall
    val body: TextStyle @Composable @ReadOnlyComposable get() = MaterialTheme.typography.bodyLarge
    val meta: TextStyle @Composable @ReadOnlyComposable get() = MaterialTheme.typography.labelMedium
    val separator: TextStyle @Composable @ReadOnlyComposable get() = MaterialTheme.typography.labelMedium
    val banner: TextStyle @Composable @ReadOnlyComposable get() = MaterialTheme.typography.bodyMedium
    val emptyTitle: TextStyle @Composable @ReadOnlyComposable get() = MaterialTheme.typography.headlineSmall
    val emptyBody: TextStyle @Composable @ReadOnlyComposable get() = MaterialTheme.typography.bodyLarge
    val pill: TextStyle @Composable @ReadOnlyComposable get() = MaterialTheme.typography.labelLarge
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME — one provider at the root. Dark via isSystemInDarkTheme(); Expressive theme
// carries the MotionScheme so reduce-motion is honored centrally. LocalChatColors is
// provided here so bubble/status roles swap with the theme too (DRK-*, MOT-*).
// ─────────────────────────────────────────────────────────────────────────────
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun ChatTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    val colorScheme = if (darkTheme) ChatDarkColors else ChatLightColors
    val chat = if (darkTheme) ChatColorsDark else ChatColorsLight
    MaterialExpressiveTheme(
        colorScheme = colorScheme,
        shapes = ChatShapes,
    ) {
        CompositionLocalProvider(LocalChatColors provides chat, content = content)
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
