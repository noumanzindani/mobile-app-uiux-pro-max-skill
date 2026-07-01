# Snippet — Bottom sheet with detents + keyboard (@gorhom/bottom-sheet)

`snapPoints` are the detents; bottom safe-area inset; keyboard-aware. See `BSH-*`, `A11Y-*`.

```tsx
// App root — provide gesture + modal context once
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { BottomSheetModalProvider } from '@gorhom/bottom-sheet';
import { SafeAreaProvider } from 'react-native-safe-area-context';

export function AppRoot({ children }: { children: React.ReactNode }) {
  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <SafeAreaProvider>
        <BottomSheetModalProvider>{children}</BottomSheetModalProvider>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}
```

```tsx
// FilterSheet.tsx
import React, { useMemo, useRef, useCallback } from 'react';
import { Text, Pressable } from 'react-native';
import {
  BottomSheetModal, BottomSheetView, BottomSheetTextInput,
} from '@gorhom/bottom-sheet';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useTheme } from '../theme/ThemeProvider';

export function useFilterSheet() {
  const ref = useRef<BottomSheetModal>(null);
  const present = useCallback(() => ref.current?.present(), []);
  return { ref, present };
}

export function FilterSheet({ sheetRef }: { sheetRef: React.RefObject<BottomSheetModal> }) {
  const t = useTheme();
  const insets = useSafeAreaInsets();
  const snapPoints = useMemo(() => ['25%', '50%', '90%'], []); // detents — BSH-*

  return (
    <BottomSheetModal
      ref={sheetRef}
      snapPoints={snapPoints}
      enableDynamicSizing={false}
      keyboardBehavior="interactive"          // sheet follows the keyboard
      keyboardBlurBehavior="restore"
      handleIndicatorStyle={{ backgroundColor: t.colors.border }} // drag affordance
      backgroundStyle={{ backgroundColor: t.colors.surface }}
    >
      <BottomSheetView style={{ padding: t.spacing.md, paddingBottom: insets.bottom + t.spacing.md }}>
        <Text style={{ fontSize: 20, fontWeight: '600', color: t.colors.onSurface }}>Filters</Text>
        <BottomSheetTextInput
          placeholder="Search"
          placeholderTextColor={t.colors.muted}
          style={{ marginTop: t.spacing.md, minHeight: 48, borderWidth: 1, borderColor: t.colors.border, borderRadius: t.radii.md, paddingHorizontal: 12 }}
        />
        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Apply filters"
          onPress={() => sheetRef.current?.dismiss()}
          style={{ marginTop: t.spacing.md, minHeight: 48, borderRadius: t.radii.md, backgroundColor: t.colors.primary, alignItems: 'center', justifyContent: 'center' }}
        >
          <Text style={{ color: t.colors.onPrimary, fontWeight: '600' }}>Apply</Text>
        </Pressable>
      </BottomSheetView>
    </BottomSheetModal>
  );
}
```

iOS action-menu feel → `ActionSheetIOS` instead of a sheet (see `adaptive.md`).
