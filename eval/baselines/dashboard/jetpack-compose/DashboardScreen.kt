// BASELINE — intentionally-naive "no-skill" reference for the eval harness (do NOT
// copy). What an assistant typically emits WITHOUT the Mobile UI/UX Pro Max skill:
// hardcoded colors, off-grid spacing, sub-legible captions, a fixed 2-column grid
// (no window size classes), and only the happy path with none of the required UI
// states. Graded against examples/dashboard/jetpack-compose/.
package baseline.dashboard

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun DashboardScreen() {
    val tiles = listOf("Revenue", "Orders", "Visitors", "Refunds")
    Column(modifier = Modifier.padding(18.dp)) {
        Text("Dashboard", color = Color(0xFF111827), fontSize = 22.sp)
        LazyVerticalGrid(columns = GridCells.Fixed(2)) {
            items(tiles) { t ->
                Column(modifier = Modifier.padding(10.dp).background(Color(0xFFFFFFFF))) {
                    Text(t, color = Color(0xFF111827))
                    Text("+12%", color = Color(0xFF16A34A), fontSize = 10.sp)
                }
            }
        }
    }
}
