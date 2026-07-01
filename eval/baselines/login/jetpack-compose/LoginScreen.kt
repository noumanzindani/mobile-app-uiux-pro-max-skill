// BASELINE — intentionally-naive "no-skill" reference for the eval harness (do NOT
// copy). What an assistant typically emits WITHOUT the Mobile UI/UX Pro Max skill:
// hardcoded colors, off-grid spacing, sub-legible text, and only the happy path
// with none of the required UI states. Graded against examples/login/jetpack-compose/.
package baseline.login

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun LoginScreen() {
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    Column(modifier = Modifier.padding(18.dp)) {
        Text("Login", color = Color(0xFF111827), fontSize = 26.sp)
        Spacer(Modifier.height(15.dp))
        OutlinedTextField(value = email, onValueChange = { email = it }, label = { Text("Email") })
        Spacer(Modifier.height(15.dp))
        OutlinedTextField(
            value = password,
            onValueChange = { password = it },
            label = { Text("Password") },
            visualTransformation = PasswordVisualTransformation(),
        )
        Text("Forgot password?", color = Color(0xFF3B82F6), fontSize = 10.sp)
        Spacer(Modifier.height(18.dp))
        Button(
            onClick = { },
            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF3B82F6)),
            modifier = Modifier.fillMaxWidth().padding(15.dp),
        ) {
            Text("Sign in", color = Color(0xFFFFFFFF))
        }
    }
}
