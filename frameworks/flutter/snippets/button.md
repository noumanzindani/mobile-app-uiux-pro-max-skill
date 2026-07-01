# Snippet — Primary button (loading + disabled + a11y)

Token-driven, ≥48dp, stable width across loading, reduce-motion-aware press. See `BTN-*`, `A11Y-*`, `MIC-*`.

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      // announce busy state to screen readers while loading
      value: isLoading ? 'Loading' : null,
      child: SizedBox(
        width: double.infinity, // stable width so the spinner doesn't shift layout
        child: FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48), // target size — A11Y-*
          ),
          onPressed: enabled
              ? () {
                  HapticFeedback.selectionClick(); // MIC-*/HAP-*
                  onPressed!();
                }
              : null, // null → Material disabled visuals + no tap
          child: isLoading
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(label),
        ),
      ),
    );
  }
}
```

Destructive variant — recolor via theme, add confirm at the call site (`DLG-*`):
```dart
FilledButton(
  style: FilledButton.styleFrom(
    backgroundColor: Theme.of(context).colorScheme.error,
    foregroundColor: Theme.of(context).colorScheme.onError,
    minimumSize: const Size.fromHeight(48),
  ),
  onPressed: onDelete,
  child: const Text('Delete account'),
);
```
