# Compose snippet — ModalBottomSheet

`ModalBottomSheet` + `rememberModalBottomSheetState` snaps to partial/expanded (the M3 analog of detents), shows a drag handle, and applies the navigation-bar inset. On expanded windows, prefer an inline pane. Rules: `BSH-*`, `A11Y-*`, `GRD-*`, `BTN-*`.

```kotlin
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProductScreen(expandedWindow: Boolean) {
    var showFilters by remember { mutableStateOf(false) }
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = false)

    Scaffold(
        topBar = { TopAppBar(
            title = { Text("Products") },
            actions = { IconButton(onClick = { showFilters = true }) {   // 48dp IconButton (A11Y-*)
                Icon(Icons.Rounded.FilterList, contentDescription = "Filters")
            } }
        ) }
    ) { padding -> ProductGrid(Modifier.padding(padding)) }              // insets applied (A11Y-*)

    if (showFilters) {
        if (expandedWindow) {
            // On expanded width use an inline side pane instead of a sheet (BSH-*, GRD-*).
            FiltersPane(onApply = { showFilters = false })
        } else {
            ModalBottomSheet(
                onDismissRequest = { showFilters = false },
                sheetState = sheetState,                                  // partial/expanded (BSH-*)
                // dragHandle + navigation-bar inset are built in — no hardcoded height.
            ) {
                Column(Modifier.padding(horizontal = MaterialTheme.spacing.s4)) {
                    FiltersContent()
                    Button(
                        onClick = { showFilters = false },
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = MaterialTheme.spacing.s4)  // token spacing (SPC-*)
                            .navigationBarsPadding()                       // clear gesture bar (BSH-*)
                    ) { Text("Apply") }                                    // ≥48dp (BTN-*)
                }
            }
        }
    }
}
```
