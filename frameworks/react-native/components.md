# React Native — Idiomatic Components

**Purpose:** The correct RN primitive + shape for each core UI job, with safe-area, accessibility, and animation baked in. Every value resolves through the theme (see `tokens.md`); rules referenced by ID. Copy-paste stubs in `snippets/`.

## Table of contents
- [Buttons](#buttons)
- [Lists (virtualized)](#lists-virtualized)
- [Bottom sheets (snap points)](#bottom-sheets-snap-points)
- [Navigation](#navigation)
- [Safe area & keyboard](#safe-area--keyboard)
- [Accessibility](#accessibility)
- [Animation](#animation)

## Buttons
Build on **`Pressable`** — the RN `Button` is unstylable. Set a ≥44×44 target and expose a11y props. **One primary action per view** (`BTN-*`).
```tsx
<Pressable
  onPress={onPress}
  disabled={disabled || loading}
  accessibilityRole="button"
  accessibilityLabel="Continue"
  accessibilityState={{ disabled: disabled || loading, busy: loading }}
  hitSlop={8}                                   // extend target without visual bulk
  style={({ pressed }) => [
    { minHeight: 48, borderRadius: theme.radii.md, backgroundColor: theme.colors.primary, // BTN-*/A11Y-*
      opacity: pressed ? 0.9 : 1, alignItems: 'center', justifyContent: 'center' },
  ]}
>
  {loading ? <ActivityIndicator color={theme.colors.onPrimary} /> : <Text style={{ color: theme.colors.onPrimary }}>Continue</Text>}
</Pressable>
```
- Loading: swap children for `ActivityIndicator`; keep width stable.
- Press feedback: `pressed` style + `Haptics.selectionAsync()` (expo-haptics) on primary/destructive (`MIC-*`, `HAP-*`).
- Prefer Reanimated press-scale over `Animated` for 60fps (see [Animation](#animation) + `snippets/button.md`).

## Lists (virtualized)
**Always** `FlatList` or **`FlashList`** — both recycle rows. Never `.map()` inside a `ScrollView` (`LST-*`, `PERF-*`).
```tsx
<FlashList
  data={items}
  keyExtractor={(it) => it.id}
  estimatedItemSize={72}                         // FlashList needs a size hint
  ItemSeparatorComponent={Separator}
  refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />} // OFF-*
  renderItem={({ item }) => <Row item={item} onPress={() => open(item)} />}
  ListEmptyComponent={<EmptyView onCreate={create} />} // wires the empty state (STATE-*)
/>
```
- `FlatList` equivalent: same props minus `estimatedItemSize`; add `getItemLayout` for fixed-height rows.
- Loading: render a skeleton list of the same row shape (see `states.md`), not a bare spinner.
- Keep `renderItem` a memoized component; avoid inline closures creating new styles each render.

## Bottom sheets (snap points)
Use **`@gorhom/bottom-sheet`** (built on Reanimated + Gesture Handler). `snapPoints` are your detents; add the bottom safe-area inset (`BSH-*`).
```tsx
const ref = useRef<BottomSheetModal>(null);
const insets = useSafeAreaInsets();
const snapPoints = useMemo(() => ['25%', '50%', '90%'], []); // detents — BSH-*

<BottomSheetModal ref={ref} snapPoints={snapPoints} enableDynamicSizing={false}>
  <BottomSheetView style={{ paddingBottom: insets.bottom, padding: 16 }}>
    {/* content */}
  </BottomSheetView>
</BottomSheetModal>
```
Wrap the app in `<GestureHandlerRootView>` + `<BottomSheetModalProvider>`. Full stub incl. keyboard in `snippets/sheet.md`. iOS action menus → `ActionSheetIOS` (see `adaptive.md`).

## Navigation
- Bottom tabs (**≤5**, `NAV-*`): `@react-navigation/bottom-tabs` or Expo Router `(tabs)` group. Use a rail/side layout at ≥600dp for tablets (`GRD-*`).
- **Never override the hardware/edge back gesture** (`NAV-*`, `GES-*`); use the navigator's back. Deep links via linking config / Expo Router file routes.
```tsx
// Expo Router — app/(tabs)/_layout.tsx
import { Tabs } from 'expo-router';
export default () => (
  <Tabs screenOptions={{ headerShown: true }}>
    <Tabs.Screen name="index"   options={{ title: 'Home',    tabBarIcon: HomeIcon }} />
    <Tabs.Screen name="search"  options={{ title: 'Search',  tabBarIcon: SearchIcon }} />
    <Tabs.Screen name="profile" options={{ title: 'Profile', tabBarIcon: ProfileIcon }} />
  </Tabs>
);
```

## Safe area & keyboard
Use `react-native-safe-area-context` — **never** `StatusBar.currentHeight` or hardcoded `44`/`34` (`A11Y-*`):
- Wrap the app once in `<SafeAreaProvider>`.
- `useSafeAreaInsets()` for precise, per-edge insets (preferred for footers/sheets).
- `<SafeAreaView edges={['top']}>` when you only guard some edges.
- Keyboard: `KeyboardAvoidingView` (`behavior={Platform.OS === 'ios' ? 'padding' : 'height'}`) or `react-native-keyboard-controller`. See `snippets/safe-area.md`.

## Accessibility
Every interactive element gets role + label + state (`A11Y-*`):
```tsx
<Pressable accessibilityRole="switch"
  accessibilityState={{ checked: on }}
  accessibilityLabel="Notifications"
  onPress={toggle} />
```
- `accessibilityRole`: `button` | `link` | `header` | `image` | `switch` | `adjustable` (sliders) | `alert`.
- `accessibilityState`: `{ disabled, selected, checked, busy, expanded }`.
- Group related nodes with `accessible` on the parent; hide decorative art with `accessibilityElementsHidden` / `importantForAccessibility="no-hide-descendants"`.
- Announce async results: `AccessibilityInfo.announceForAccessibility('Item added')` (`STATE-*` success/offline).
- Never fix text container heights — let text scale with the OS font setting (`dynamic_type_check.py`).

## Animation
Use **Reanimated 3** (worklets run on the UI thread → 60/120fps) + **Gesture Handler**, not the legacy `Animated`:
```tsx
const scale = useSharedValue(1);
const style = useAnimatedStyle(() => ({ transform: [{ scale: scale.value }] })); // worklet
const onPressIn  = () => { scale.value = withTiming(reduceMotion ? 1 : 0.97, { duration: 120 }); }; // MIC-*
const onPressOut = () => { scale.value = withSpring(1); };
// <Animated.View style={style}> … </Animated.View>
```
- Springs: `withSpring`; timing: `withTiming`; sequences: `withSequence`. Durations from motion tokens (`MOT-*`): micro 100ms, small 200–250, medium 300–400; avoid >500 routine.
- Layout transitions: `Animated.View entering={FadeIn} layout={LinearTransition}`.
- **Reduce motion:** gate non-essential animation on `useReducedMotion()` (from `react-native-reanimated`) and fall back to instant/cross-fade (`MOT-*`, `A11Y-*`).
- Animate `transform`/`opacity` only for jank-free 60fps (`PERF-*`).
