# Snippet — Modal bottom sheet with detents + keyboard

`showModalBottomSheet` + `DraggableScrollableSheet` for snap points; drag handle; safe-area bottom inset; keyboard-aware. See `BSH-*`, `A11Y-*`.

```dart
import 'package:flutter/material.dart';

Future<void> showFilterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true, // required for tall / keyboard sheets
    showDragHandle: true,     // M3 drag affordance (also a semantic handle)
    useSafeArea: true,        // keep below the status bar
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5, // detents ↓
      minChildSize: 0.25,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.25, 0.5, 0.95],
      builder: (context, scrollController) {
        return SafeArea(
          top: false, // bottom inset only — respects home indicator (BSH-*)
          child: Padding(
            // lift content above the keyboard when a field is focused
            padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
            child: ListView(
              controller: scrollController, // drag-to-scroll continuity
              padding: const EdgeInsets.all(16),
              children: [
                Text('Filters', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                const TextField(decoration: InputDecoration(labelText: 'Search')),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
```

iOS-native feel → branch to `showCupertinoModalPopup` / `CupertinoActionSheet` (see `adaptive.md`).
