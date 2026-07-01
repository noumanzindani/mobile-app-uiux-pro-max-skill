# Snippet — Safe area & keyboard insets

Use the framework primitive; never hardcode notch/indicator values. See `A11Y-*`, `BSH-*`.

```dart
import 'package:flutter/material.dart';

class Screen extends StatelessWidget {
  const Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // default true: content resizes above the keyboard automatically
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Compose')),
      body: SafeArea(
        // AppBar already pads the top; only guard the sides + bottom
        top: false,
        child: Column(
          children: [
            const Expanded(child: Placeholder()),
            // a sticky footer that lifts above the keyboard
            Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16 + MediaQuery.viewInsetsOf(context).bottom, // keyboard height
              ),
              child: const TextField(decoration: InputDecoration(hintText: 'Message')),
            ),
          ],
        ),
      ),
    );
  }
}

// Reading insets manually (cheaper than MediaQuery.of — scoped rebuilds):
//   final pad   = MediaQuery.paddingOf(context);        // notch / home indicator
//   final kbd   = MediaQuery.viewInsetsOf(context);     // keyboard
//   final size  = MediaQuery.sizeOf(context);           // for responsive branches
```

Edge-to-edge content behind a translucent bar? Wrap only the parts that must clear the insets in `SafeArea`, and let media bleed to the edges.
