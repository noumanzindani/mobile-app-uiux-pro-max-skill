// BASELINE — intentionally-naive "no-skill" reference for the eval harness (do NOT
// copy). What an assistant typically emits WITHOUT the Mobile UI/UX Pro Max skill:
// hardcoded colors, off-grid spacing, physical left/right insets, an undersized
// send button, sub-legible timestamps, and only the happy path with none of the
// required UI states. Graded against examples/chat/flutter/.
import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final messages = ['Hey!', 'How are you?', 'On my way'];
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(left: 18, right: 18, top: 10),
              children: [
                for (final m in messages)
                  Container(
                    margin: const EdgeInsets.all(6),
                    padding: const EdgeInsets.all(10),
                    color: const Color(0xFF2563EB),
                    child: Text(m, style: const TextStyle(color: Color(0xFFFFFFFF))),
                  ),
                Container(
                  height: 14,
                  child: const Text('12:04', style: TextStyle(fontSize: 10)),
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Expanded(child: TextField(decoration: InputDecoration(hintText: 'Message'))),
              InkWell(onTap: () {}, child: const SizedBox(width: 36, height: 36, child: Icon(Icons.send))),
            ],
          ),
        ],
      ),
    );
  }
}
