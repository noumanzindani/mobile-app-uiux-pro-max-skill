// BASELINE — intentionally-naive "no-skill" reference for the eval harness (do NOT
// copy). What an assistant typically emits WITHOUT the Mobile UI/UX Pro Max skill:
// hardcoded colors, off-grid spacing, sub-legible timestamps, and only the happy
// path with none of the required UI states. Graded against examples/chat/jetpack-compose/.
package baseline.chat

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun ChatScreen() {
    val messages = listOf("Hey!", "How are you?", "On my way")
    var draft by remember { mutableStateOf("") }
    Column(modifier = Modifier.padding(18.dp)) {
        Column(modifier = Modifier.weight(1f).verticalScroll(rememberScrollState())) {
            messages.forEach { m ->
                Text(
                    m,
                    color = Color(0xFFFFFFFF),
                    modifier = Modifier.padding(10.dp).background(Color(0xFF2563EB)),
                )
            }
            Text("12:04", color = Color(0xFF6B7280), fontSize = 10.sp)
        }
        Row {
            OutlinedTextField(value = draft, onValueChange = { draft = it }, modifier = Modifier.weight(1f))
            Button(onClick = { }, modifier = Modifier.padding(15.dp)) { Text("Send") }
        }
    }
}
