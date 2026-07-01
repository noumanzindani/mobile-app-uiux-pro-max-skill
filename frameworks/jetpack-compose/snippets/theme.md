# Compose snippet — Token theme layer

`MaterialExpressiveTheme` maps DTCG semantic roles onto `ColorScheme`/`Shapes`/`Typography`/`MotionScheme` slots (with Material You dynamic color); a `CompositionLocal` carries the spacing scale M3 has no slot for. Rules: `COL-*`, `DRK-*`, `SPC-*`, `SHP-*`, `MOT-*`, `A11Y-*`.

```kotlin
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

// 1. SPACING — no M3 slot exists, so carry the DTCG space.* scale in a CompositionLocal (SPC-*).
data class Spacing(
    val s1: Dp = 4.dp, val s2: Dp = 8.dp, val s3: Dp = 12.dp,
    val s4: Dp = 16.dp, val s6: Dp = 24.dp, val s8: Dp = 32.dp,
)
val LocalSpacing = staticCompositionLocalOf { Spacing() }
val MaterialTheme.spacing: Spacing @Composable @ReadOnlyComposable get() = LocalSpacing.current

// 2. COLOR — brand fallbacks map DTCG semantic roles onto ColorScheme slots.
private val BrandLightColors = lightColorScheme(/* primary = …, surface = …, error = … (COL-*) */)
private val BrandDarkColors  = darkColorScheme(/* … */)

// 3. THEME — dark via isSystemInDarkTheme(); Material You dynamic color on Android 12+ (DRK-*, COL-*).
@Composable
fun AppTheme(
    useDynamicColor: Boolean = true,
    content: @Composable () -> Unit,
) {
    val dark = isSystemInDarkTheme()
    val context = LocalContext.current
    val colorScheme = when {
        useDynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ->
            if (dark) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        dark -> BrandDarkColors
        else -> BrandLightColors
    }

    CompositionLocalProvider(LocalSpacing provides Spacing()) {
        MaterialExpressiveTheme(          // Expressive: MotionScheme spatial/effects springs + shape morph (MOT-*, SHP-*)
            colorScheme = colorScheme,
            shapes = Shapes(),            // 10-step corner scale — extraSmall … extraLarge (SHP-*)
            typography = Typography(),    // sp roles scale with font size (TYP-*)
            content = content,
        )
    }
}

// Read tokens at call sites — never literals:
//   MaterialTheme.colorScheme.surface / .primary        (COL-*)
//   MaterialTheme.shapes.medium                          (SHP-*)
//   MaterialTheme.spacing.s4                             (SPC-*)
//   MaterialTheme.motionScheme.fastSpatialSpec<Float>()  (MOT-*)
//
// Reduce Motion: gate the MotionScheme spec duration when the system animator scale is 0
// (Settings.Global.ANIMATOR_DURATION_SCALE) so motion is shortened in ONE place (MOT-*, A11Y-*).
```
