# Compose snippet — Edge-to-edge & safe drawing insets

`enableEdgeToEdge()` in the Activity, then let `Scaffold` apply `WindowInsets.safeDrawing` as `contentPadding`; use `imePadding()`/`navigationBarsPadding()` for pinned bars. Never hardcode status/nav-bar heights. Rules: `A11Y-*`, `BSH-*`, `STATE-*`, `GES-*`.

```kotlin
// Activity — draw behind system bars (GES-*, A11Y-*):
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()                    // transparent, edge-to-edge system bars
        setContent { AppTheme { CheckoutScreen() } }
    }
}
```

```kotlin
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier

@Composable
fun CheckoutScreen(isOnline: Boolean = true) {
    val snackbarHostState = remember { SnackbarHostState() }

    // Offline banner via Snackbar host — respects insets, never covers the gesture bar (OFF-*, STATE-*):
    LaunchedEffect(isOnline) {
        if (!isOnline) snackbarHostState.showSnackbar(
            "You're offline. Changes will sync later.",              // announced (A11Y-*)
            duration = SnackbarDuration.Indefinite
        )
    }

    Scaffold(
        // Scaffold consumes WindowInsets.safeDrawing and hands back contentPadding (A11Y-*):
        snackbarHost = { SnackbarHost(snackbarHostState) },
        bottomBar = {
            // Persistent CTA above the gesture bar — inset applied, not hardcoded (BSH-*):
            Surface(tonalElevation = 3.dp) {
                Button(
                    onClick = { /* pay */ },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(MaterialTheme.spacing.s4)
                        .navigationBarsPadding()
                        .imePadding()                                // rise above the keyboard (GES-*)
                ) { Text("Pay") }
            }
        }
    ) { padding ->
        LazyColumn(contentPadding = padding) { /* cart items — virtualized (LST-*) */ }
    }
}

// Note: do NOT read WindowInsets values and add manual dp — safeDrawing/Scaffold/imePadding
// already handle status bar, gesture nav, cutouts, and the IME, and update on rotation/fold.
```
