// BASELINE — intentionally-naive "no-skill" reference for the eval harness (do NOT
// copy). What an assistant typically emits WITHOUT the Mobile UI/UX Pro Max skill:
// hardcoded colors, off-grid spacing, physical left/right insets, a destructive
// action inline with the rest (not isolated), sub-legible captions, and only the
// happy path with none of the required UI states. Graded against
// examples/settings/flutter/.
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notifications = true;
  bool darkTheme = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(left: 18, right: 18, top: 10),
        children: [
          SwitchListTile(
            title: const Text('Notifications'),
            value: notifications,
            onChanged: (v) => setState(() => notifications = v),
          ),
          SwitchListTile(
            title: const Text('Dark theme'),
            value: darkTheme,
            onChanged: (v) => setState(() => darkTheme = v),
          ),
          const SizedBox(height: 15),
          const Text('Signed in as user@example.com', style: TextStyle(fontSize: 10)),
          TextButton(
            onPressed: () {},
            child: const Text('Delete account', style: TextStyle(color: Color(0xFFDC2626))),
          ),
        ],
      ),
    );
  }
}
