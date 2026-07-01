// BASELINE — intentionally-naive "no-skill" reference for the eval harness (do NOT
// copy). What an assistant typically emits WITHOUT the Mobile UI/UX Pro Max skill:
// hardcoded colors, off-grid spacing, sub-legible price text, and only the happy
// path — none of the required UI states, so nothing guards a double-charge.
// Graded against examples/checkout/jetpack-compose/.
package baseline.checkout

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun CheckoutScreen() {
    Column(modifier = Modifier.padding(18.dp)) {
        Text("Order summary", color = Color(0xFF111827), fontSize = 18.sp)
        Spacer(Modifier.height(14.dp))
        Row {
            Text("Wireless Headphones", color = Color(0xFF111827))
            Spacer(Modifier.weight(1f))
            Text("$129.00", fontSize = 10.sp)
        }
        Text("Tax and shipping calculated at charge", color = Color(0xFF9CA3AF), fontSize = 10.sp)
        Spacer(Modifier.height(22.dp))
        Button(
            onClick = { },
            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF16A34A)),
            modifier = Modifier.fillMaxWidth().padding(15.dp),
        ) {
            Text("Pay now", color = Color(0xFFFFFFFF))
        }
    }
}
