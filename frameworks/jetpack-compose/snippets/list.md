# Compose snippet — Virtualized LazyColumn

`LazyColumn` composes only visible items (the virtualization `LST-*`/`PERF-*` require). Includes stable keys, pull-to-refresh (`PullToRefreshBox`, now stable), skeleton loading, insets from `Scaffold`, and combined-a11y rows. Rules: `LST-*`, `PERF-*`, `STATE-*`, `A11Y-*`, `OFF-*`.

```kotlin
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.*

data class Txn(val id: Long, val merchant: String, val amount: String, val pending: Boolean) {
    companion object { val placeholder = Txn(-1, "Placeholder Co", "$0.00", false) }
}

@Composable
fun TransactionList(
    txns: List<Txn>,
    isRefreshing: Boolean,
    onRefresh: () -> Unit,
    contentPadding: PaddingValues,          // supplied by Scaffold → WindowInsets.safeDrawing (A11Y-*)
) {
    PullToRefreshBox(isRefreshing = isRefreshing, onRefresh = onRefresh) {   // STATE-*, OFF-*
        LazyColumn(
            contentPadding = contentPadding,
            verticalArrangement = Arrangement.spacedBy(MaterialTheme.spacing.s2)  // token gap (SPC-*)
        ) {
            items(txns, key = { it.id }) { txn ->        // stable key (LST-*, PERF-*)
                TxnRow(txn)
            }
        }
    }
}

@Composable
private fun TxnRow(txn: Txn) {
    ListItem(
        headlineContent = { Text(txn.merchant) },
        trailingContent = { Text(txn.amount) },          // tabular alignment for money
        colors = ListItemDefaults.colors(
            containerColor = MaterialTheme.colorScheme.surface   // token, not literal (COL-*)
        ),
        modifier = Modifier.semantics(mergeDescendants = true) {}  // one TalkBack node (A11Y-*)
    )
}

// Loading skeleton: same rows with a shimmer/placeholder modifier so metrics match (STATE-*, LST-*):
// LazyColumn { items(8) { TxnRow(Txn.placeholder) /* .shimmerPlaceholder() */ } }
```
