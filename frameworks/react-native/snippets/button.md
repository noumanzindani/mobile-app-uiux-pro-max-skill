# Snippet — Primary button (Reanimated press + loading + a11y)

`Pressable` core, ≥48 target, token-driven, reduce-motion-aware press-scale, full a11y. See `BTN-*`, `A11Y-*`, `MIC-*`.

```tsx
import React from 'react';
import { Pressable, Text, ActivityIndicator, StyleSheet } from 'react-native';
import Animated, { useSharedValue, useAnimatedStyle, withTiming, withSpring, useReducedMotion } from 'react-native-reanimated';
import * as Haptics from 'expo-haptics';
import { useTheme } from '../theme/ThemeProvider';

const AnimatedPressable = Animated.createAnimatedComponent(Pressable);

type Props = {
  label: string;
  onPress: () => void;
  loading?: boolean;
  disabled?: boolean;
  variant?: 'filled' | 'tonal';
};

export function PrimaryButton({ label, onPress, loading = false, disabled = false, variant = 'filled' }: Props) {
  const t = useTheme();
  const reduce = useReducedMotion();
  const scale = useSharedValue(1);
  const animStyle = useAnimatedStyle(() => ({ transform: [{ scale: scale.value }] }));
  const isOff = disabled || loading;

  const bg = variant === 'filled' ? t.colors.primary : t.colors.border;
  const fg = variant === 'filled' ? t.colors.onPrimary : t.colors.onSurface;

  return (
    <AnimatedPressable
      onPress={() => { Haptics.selectionAsync(); onPress(); }}      // MIC-*/HAP-*
      onPressIn={() => { scale.value = withTiming(reduce ? 1 : 0.97, { duration: 120 }); }}
      onPressOut={() => { scale.value = withSpring(1); }}
      disabled={isOff}
      accessibilityRole="button"
      accessibilityLabel={label}
      accessibilityState={{ disabled: isOff, busy: loading }}
      hitSlop={8}
      style={[styles.base, { backgroundColor: bg, borderRadius: t.radii.md, opacity: isOff ? 0.5 : 1 }, animStyle]}
    >
      {loading ? <ActivityIndicator color={fg} /> : <Text style={[styles.label, { color: fg }]}>{label}</Text>}
    </AnimatedPressable>
  );
}

const styles = StyleSheet.create({
  base: { minHeight: 48, paddingHorizontal: 20, alignItems: 'center', justifyContent: 'center' }, // A11Y-*
  label: { fontSize: 16, fontWeight: '600' },
});
```

Destructive: pass `variant="filled"` with `backgroundColor: t.colors.danger` and confirm at the call site (`DLG-*`).
