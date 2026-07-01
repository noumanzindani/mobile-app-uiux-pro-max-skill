// BASELINE — intentionally-naive "no-skill" reference for the eval harness (do NOT
// copy). What an assistant typically emits WITHOUT the Mobile UI/UX Pro Max skill:
// hardcoded hex colors, off-grid spacing, a fixed-height text row, an undersized
// tap target, and only the happy path with none of the required UI states. Graded
// against examples/login/swiftui/. (Assumes a Color(hex:) extension, as such code
// usually does.)
import SwiftUI

struct LoginScreen: View {
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(alignment: .leading) {
            Text("Login").foregroundColor(Color(hex: "#111827")).frame(height: 22)
            TextField("Email", text: $email).padding(15)
            SecureField("Password", text: $password).padding(15)
            Text("Forgot password?").foregroundColor(Color(hex: "#3B82F6"))
            Button(action: {}) { Text("Sign in").frame(maxWidth: .infinity) }
                .padding(15)
                .background(Color(hex: "#3B82F6"))
            HStack {
                Button(action: {}) { Image(systemName: "xmark") }.frame(width: 36, height: 36)
                Text("Cancel")
            }
        }
        .padding(18)
    }
}
