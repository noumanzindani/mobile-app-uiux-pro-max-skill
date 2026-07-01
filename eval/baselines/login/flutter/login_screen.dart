// BASELINE — "no-skill" reference generation for the eval harness.
// This is the kind of login screen an AI assistant typically emits WITHOUT the
// Mobile UI/UX Pro Max skill: hardcoded colors, off-grid spacing, physical
// left/right insets, a tiny icon-button hit area, sub-legible text, and only the
// happy path (no loading / empty / error / offline states). run_eval.py grades it
// against the token-driven, all-states version in examples/login/flutter/.
//
// DO NOT copy this file. It exists only to measure the skill's lift.
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Padding(
        padding: const EdgeInsets.only(left: 18, right: 18, top: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 22,
              child: const Text('Login',
                  style: TextStyle(fontSize: 26, color: Color(0xFF111827))),
            ),
            const SizedBox(height: 15),
            const TextField(decoration: InputDecoration(hintText: 'Email')),
            const SizedBox(height: 15),
            const TextField(
                obscureText: true,
                decoration: InputDecoration(hintText: 'Password')),
            const SizedBox(height: 6),
            const Text('Forgot password?', style: TextStyle(fontSize: 10)),
            const SizedBox(height: 18),
            InkWell(
              onTap: () {},
              child: Container(
                height: 44,
                color: const Color(0xFF3B82F6),
                alignment: Alignment.center,
                child: const Text('Sign in',
                    style: TextStyle(color: Color(0xFFFFFFFF))),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              InkWell(onTap: () {}, child: const SizedBox(width: 36, height: 36, child: Icon(Icons.close))),
              const Text('Cancel'),
            ]),
          ],
        ),
      ),
    );
  }
}
