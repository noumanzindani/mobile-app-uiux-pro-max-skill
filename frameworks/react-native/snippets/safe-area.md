# Snippet — Safe area & keyboard (react-native-safe-area-context)

Use the library primitive; never `StatusBar.currentHeight` or hardcoded `44`/`34`. See `A11Y-*`, `BSH-*`.

```tsx
// App root (once)
import { SafeAreaProvider } from 'react-native-safe-area-context';
export const Root = ({ children }: { children: React.ReactNode }) => (
  <SafeAreaProvider>{children}</SafeAreaProvider>
);
```

```tsx
// Screen with a sticky footer that clears the home indicator + keyboard
import React from 'react';
import { View, TextInput, Platform, KeyboardAvoidingView } from 'react-native';
import { useSafeAreaInsets, SafeAreaView } from 'react-native-safe-area-context';
import { useTheme } from '../theme/ThemeProvider';

export function ComposeScreen() {
  const t = useTheme();
  const insets = useSafeAreaInsets(); // { top, bottom, left, right } — real device insets

  return (
    // guard the top edge only; the footer handles the bottom inset itself
    <SafeAreaView edges={['top']} style={{ flex: 1, backgroundColor: t.colors.surface }}>
      <View style={{ flex: 1 }}>{/* content / list */}</View>

      <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : 'height'}>
        <View
          style={{
            paddingHorizontal: t.spacing.md,
            paddingTop: t.spacing.sm,
            paddingBottom: insets.bottom + t.spacing.sm, // home-indicator inset — never hardcoded
            borderTopWidth: 1,
            borderTopColor: t.colors.border,
          }}
        >
          <TextInput
            placeholder="Message"
            placeholderTextColor={t.colors.muted}
            style={{ minHeight: 44, color: t.colors.onSurface }} // target ≥44 — A11Y-*
          />
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}
```

Full-bleed media behind a translucent bar? Don't wrap the media in `SafeAreaView`; apply `insets` only to the controls that must clear the notch/indicator.
