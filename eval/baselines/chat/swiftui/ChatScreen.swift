// BASELINE — intentionally-naive "no-skill" reference for the eval harness (do NOT
// copy). What an assistant typically emits WITHOUT the Mobile UI/UX Pro Max skill:
// hardcoded hex colors, off-grid spacing, a fixed-height timestamp row, an
// undersized send button, and only the happy path with none of the required UI
// states. Graded against examples/chat/swiftui/. (Assumes a Color(hex:) extension.)
import SwiftUI

struct ChatScreen: View {
    private let messages = ["Hey!", "How are you?", "On my way"]
    @State private var draft = ""

    var body: some View {
        VStack {
            ScrollView {
                ForEach(messages, id: \.self) { m in
                    Text(m)
                        .foregroundColor(Color(hex: "#FFFFFF"))
                        .padding(10)
                        .background(Color(hex: "#2563EB"))
                }
                Text("12:04").foregroundColor(Color(hex: "#6B7280")).frame(height: 14)
            }
            .padding(15)
            HStack {
                TextField("Message", text: $draft)
                Button(action: {}) { Image(systemName: "paperplane") }.frame(width: 36, height: 36)
            }
            .padding(15)
        }
    }
}
