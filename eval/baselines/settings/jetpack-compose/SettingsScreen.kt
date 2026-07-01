// BASELINE — intentionally-naive "no-skill" reference for the eval harness (do NOT
// copy). What an assistant typically emits WITHOUT the Mobile UI/UX Pro Max skill:
// hardcoded colors, off-grid spacing, a destructive action inline with the rest
// (not isolated), sub-legible captions, and only the happy path with none of the
// required UI states. Graded against examples/settings/jetpack-compose/.
package baseline.settings

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun SettingsScreen() {
    var notifications by remember { mutableStateOf(true) }
    var darkTheme by remember { mutableStateOf(false) }
    Column(modifier = Modifier.padding(18.dp)) {
        Text("Settings", color = Color(0xFF111827), fontSize = 22.sp)
        Row(modifier = Modifier.padding(15.dp)) {
            Text("Notifications", modifier = Modifier.weight(1f))
            Switch(checked = notifications, onCheckedChange = { notifications = it })
        }
        Row(modifier = Modifier.padding(15.dp)) {
            Text("Dark theme", modifier = Modifier.weight(1f))
            Switch(checked = darkTheme, onCheckedChange = { darkTheme = it })
        }
        Text("Signed in as user@example.com", color = Color(0xFF6B7280), fontSize = 10.sp)
        TextButton(onClick = { }) { Text("Delete account", color = Color(0xFFDC2626)) }
    }
}
