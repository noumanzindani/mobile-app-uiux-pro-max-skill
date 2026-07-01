# Jetpack Compose — The 7 UI States

**Purpose:** How to implement the mandatory state model in Compose. Drive the UI from a sealed `UiState` exposed by the ViewModel (`StateFlow`) and `when` over it, so every data-backed screen ships all seven states. Rules referenced, not restated: `STATE-*`, `OFF-*`, `PERM-*`, `A11Y-*`, `LST-*`.

## Table of contents
- [State-driven when()](#state-driven-when)
- [1. Ideal (loaded)](#1-ideal-loaded)
- [2. Empty (×3)](#2-empty-3)
- [3. Loading](#3-loading)
- [4. Error](#4-error)
- [5. Offline](#5-offline)
- [6. Success](#6-success)
- [7. Permission-denied](#7-permission-denied)

## State-driven when()
Model the phase as a sealed interface and `when` over it — this makes coverage auditable (`STATE-*`, `state_coverage.py`):

```kotlin
sealed interface UiState<out T> {
    data object Loading : UiState<Nothing>
    data object Empty : UiState<Nothing>
    data class Loaded<T>(val data: T) : UiState<T>
    data class Failed(val message: String) : UiState<Nothing>
}

@Composable
fun <T> StateHost(state: UiState<T>, onRetry: () -> Unit, loaded: @Composable (T) -> Unit) {
    when (state) {
        UiState.Loading   -> SkeletonList()
        UiState.Empty     -> EmptyState()
        is UiState.Loaded -> loaded(state.data)
        is UiState.Failed -> ErrorState(state.message, onRetry)
    }
}
```
Offline and success are **cross-cutting** (Snackbar / banner), not sealed cases; permission-denied gates before the fetch. Reduce Motion applies to all transitions (`A11Y-*`).

## 1. Ideal (loaded)
The virtualized happy path (`LazyColumn` with stable keys, `LST-*`). Token binding + `semantics` grouping only — see `components.md`.

## 2. Empty (×3)
Distinguish **first-run empty**, **user-cleared empty**, and **no-results empty** (`STATE-*`, `SRCH-*`). Compose has no single "content unavailable" widget, so compose a centered illustration + headline + supporting text + one action, all from tokens:

```kotlin
@Composable
fun EmptyState() = Column(
    Modifier.fillMaxSize().padding(MaterialTheme.spacing.s6),
    horizontalAlignment = Alignment.CenterHorizontally,
    verticalArrangement = Arrangement.Center
) {
    Icon(Icons.Rounded.Inbox, contentDescription = null, Modifier.size(48.dp))
    Spacer(Modifier.height(MaterialTheme.spacing.s4))
    Text("No transactions yet", style = MaterialTheme.typography.titleMedium)
    Text("Your purchases will show up here.", style = MaterialTheme.typography.bodyMedium)
    Spacer(Modifier.height(MaterialTheme.spacing.s4))
    Button(onClick = { /* add */ }) { Text("Add account") }   // ≥48dp (BTN-*)
}
```
No-results reuses this container with search-specific copy (`SRCH-*`).

## 3. Loading
Skeleton over spinner for content-shaped screens (`STATE-*`, `LST-*`). Compose real row layout with a shimmer/placeholder brush so metrics match; `CircularProgressIndicator` only for short indeterminate waits. Announce via `semantics`:

```kotlin
LazyColumn(Modifier.semantics { contentDescription = "Loading" }) {   // announce (A11Y-*)
    items(8) { TxnRow(txn = Txn.placeholder, Modifier.shimmerPlaceholder()) }
}
```

## 4. Error
Recoverable, with a **retry** — never a dead end (`STATE-*`). Reuse the centered container with an error icon + human copy + a retry `Button` that re-triggers the ViewModel load:

```kotlin
@Composable
fun ErrorState(message: String, onRetry: () -> Unit) = Column(/* centered */) {
    Icon(Icons.Rounded.ErrorOutline, contentDescription = null, tint = MaterialTheme.colorScheme.error)
    Text(message, style = MaterialTheme.typography.bodyMedium)   // human copy, not a stack trace
    Button(onClick = onRetry) { Text("Try again") }
}
```

## 5. Offline
Non-blocking banner or `Snackbar`, plus optimistic UI with visible rollback for writes (`OFF-*`, `STATE-*`). Host it in `Scaffold` so it respects insets and never covers the gesture bar; announce as a live region (`A11Y-*`):

```kotlin
Scaffold(snackbarHost = { SnackbarHost(snackbarHostState) }) { padding -> … }

LaunchedEffect(isOnline) {
    if (!isOnline) snackbarHostState.showSnackbar(
        "You're offline. Changes will sync later.", duration = SnackbarDuration.Indefinite
    )
}
```

## 6. Success
Transient confirmation — a `Snackbar` with optional Undo action, or an inline check; don't block routine success with a dialog (`STATE-*`, `BDG-*`). Fire a success haptic (`HapticFeedbackType.Confirm`) as reinforcement, never the sole signal (`HAP-*`, `A11Y-*`):

```kotlin
val result = snackbarHostState.showSnackbar("Saved", actionLabel = "Undo")
if (result == SnackbarResult.ActionPerformed) viewModel.undo()
```

## 7. Permission-denied
Gate the feature; on permanent denial route to app settings (you can't re-prompt) with value-first copy (`PERM-*`, `STATE-*`). Use the Accompanist/`ActivityResult` permission APIs:

```kotlin
val camera = rememberPermissionState(Manifest.permission.CAMERA)
when {
    camera.status.isGranted -> CameraView()
    camera.status.shouldShowRationale -> PrimingCard { camera.launchPermissionRequest() }  // just-in-time (PERM-*)
    else -> DeniedCard(onOpenSettings = {
        context.startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts("package", context.packageName, null)))
    })
}
```

> Self-check: `state_coverage.py` should find loading, all three empties, error, offline, and permission-denied for any data-backed screen (`STATE-*`).
