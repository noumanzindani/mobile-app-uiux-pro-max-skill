# Compose snippet — Button + press micro-interaction

M3 `Button` (48dp target built in), token-bound, with a spring press-scale + haptic and an explicit loading/disabled state. Rules: `BTN-*`, `MIC-*`, `A11Y-*`, `MOT-*`, `STATE-*`.

```kotlin
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.semantics.*

@Composable
fun PrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    isLoading: Boolean = false,
    enabled: Boolean = true,
) {
    val interaction = remember { MutableInteractionSource() }
    val pressed by interaction.collectIsPressedAsState()
    val haptics = LocalHapticFeedback.current

    // Spring press-scale from the M3 MotionScheme (MIC-*, MOT-*):
    val scale by animateFloatAsState(
        targetValue = if (pressed) 0.97f else 1f,
        animationSpec = MaterialTheme.motionScheme.fastSpatialSpec(),
        label = "press"
    )

    Button(
        onClick = {
            haptics.performHapticFeedback(HapticFeedbackType.Confirm)  // reinforcement only (HAP-*)
            onClick()
        },
        // Filled Button already enforces the 48dp minimum interactive size (A11Y-*, BTN-*).
        // Colors/shape come from MaterialTheme — no literals (COL-*, SHP-*).
        enabled = enabled && !isLoading,                               // disabled is explicit (STATE-*)
        interactionSource = interaction,
        modifier = modifier
            .scale(scale)
            .semantics { if (isLoading) stateDescription = "Loading" } // announce (A11Y-*)
    ) {
        if (isLoading) {
            CircularProgressIndicator(
                Modifier.size(18.dp),
                strokeWidth = 2.dp,
                color = MaterialTheme.colorScheme.onPrimary            // loading state (BTN-*, STATE-*)
            )
        } else {
            Text(text)                                                 // Dynamic font scaling (TYP-*)
        }
    }
}

// Destructive: OutlinedButton/Button tinted with colorScheme.error AND a confirm dialog —
// color is never the only signal (A11Y-*, DLG-*).
```
