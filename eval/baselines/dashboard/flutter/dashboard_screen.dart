// BASELINE — intentionally-naive "no-skill" reference for the eval harness (do NOT
// copy). What an assistant typically emits WITHOUT the Mobile UI/UX Pro Max skill:
// hardcoded colors, off-grid spacing, physical left/right insets, a fixed-height
// metric row, sub-legible captions, a fixed 2-column grid (no size classes), and
// only the happy path with none of the required UI states. Graded against
// examples/dashboard/flutter/.
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = ['Revenue', 'Orders', 'Visitors', 'Refunds'];
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.only(left: 18, right: 18, top: 10),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          children: [
            for (final t in tiles)
              Container(
                padding: const EdgeInsets.all(10),
                color: const Color(0xFFFFFFFF),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 22, child: Text(t, style: const TextStyle(color: Color(0xFF111827)))),
                    const Text('+12%', style: TextStyle(fontSize: 10, color: Color(0xFF16A34A))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
