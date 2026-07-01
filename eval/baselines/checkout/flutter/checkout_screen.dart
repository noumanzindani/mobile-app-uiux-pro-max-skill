// BASELINE — "no-skill" reference generation for the eval harness.
// Typical AI-emitted checkout WITHOUT the Mobile UI/UX Pro Max skill: hardcoded
// colors, off-grid spacing, physical left/right insets, a sub-legible price line,
// a fixed-height text row that clips scaled text, and — most dangerous for
// checkout — no processing / error / offline states, so nothing guards against a
// double-charge. Graded against examples/checkout/flutter/.
//
// DO NOT copy this file. It exists only to measure the skill's lift.
import 'package:flutter/material.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.only(left: 18, right: 18, top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 26,
              child: const Text('Order summary',
                  style: TextStyle(fontSize: 18, color: Color(0xFF111827))),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Wireless Headphones'),
                Text('\$129.00', style: TextStyle(fontSize: 10)),
              ],
            ),
            const SizedBox(height: 6),
            const Text('Tax and shipping calculated at charge',
                style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
            const SizedBox(height: 22),
            InkWell(
              onTap: () {},
              child: Container(
                height: 44,
                color: const Color(0xFF16A34A),
                alignment: Alignment.center,
                child: const Text('Pay now',
                    style: TextStyle(color: Color(0xFFFFFFFF))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
