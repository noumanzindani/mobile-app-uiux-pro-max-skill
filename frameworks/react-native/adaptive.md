# React Native — Platform-Adaptive Guidance

**Purpose:** RN renders native views but gives you **no `.adaptive` widgets** — platform correctness is manual. This file shows the levers, cheapest first (`PLAT-*`). Decide the paradigm in `_index.md` first; this is the *how*.

## Table of contents
- [Detect the platform](#detect-the-platform)
- [Lever 1 — Platform.select for values](#lever-1--platformselect-for-values-cheapest)
- [Lever 2 — branch a component](#lever-2--branch-a-component)
- [Lever 3 — platform-specific files](#lever-3--platform-specific-files)
- [Native menus & sheets](#native-menus--sheets)
- [What to branch vs share](#what-to-branch-vs-share)
- [Responsive is orthogonal](#responsive-is-orthogonal)

## Detect the platform
```ts
import { Platform } from 'react-native';
Platform.OS === 'ios';        // 'ios' | 'android' | 'web'
Platform.Version;             // iOS string / Android API level
Platform.select({ ios: A, android: B, default: B });
```

## Lever 1 — `Platform.select` for values (cheapest)
Fork just the token/value that differs — fonts, shadows, header height, haptic style:
```ts
const styles = {
  card: {
    ...Platform.select({
      ios:     { shadowColor: '#000', shadowOpacity: 0.1, shadowRadius: 8, shadowOffset: { width: 0, height: 2 } },
      android: { elevation: 3 }, // ELV-* — Android uses elevation, iOS uses shadow*
    }),
  },
  title: { fontFamily: Platform.select({ ios: 'System', android: 'sans-serif-medium' }) }, // TYP-*
};
```

## Lever 2 — branch a component
Where the platforms visibly diverge and no shared abstraction fits, branch inline:
```tsx
function PrimaryCTA({ label, onPress }: Props) {
  // iOS favors a filled pill; Android a Material-ish filled rect — both tokenized
  return Platform.OS === 'ios'
    ? <IOSFilledButton label={label} onPress={onPress} />
    : <MaterialFilledButton label={label} onPress={onPress} />;
}
```
Common branch points: **header/tab-bar chrome**, **sheets**, **action menus**, **switches** (iOS `Switch` already looks native — style the track per OS), **back behavior** (Android hardware back — handle with the navigator, never swallow it).

## Lever 3 — platform-specific files
For whole components that differ structurally, let Metro pick the file by extension — no runtime branch, smaller bundles:
```
components/
  Sheet.ios.tsx        // gorhom sheet tuned to iOS, or a real UISheet detent feel
  Sheet.android.tsx    // Material-style bottom sheet
  Sheet.tsx            // optional shared fallback / types
```
```tsx
import { Sheet } from './components/Sheet'; // resolves to .ios.tsx or .android.tsx automatically
```
Use for sheets, headers, or any component whose two implementations share only a prop contract.

## Native menus & sheets
Reach for OS-native affordances when the feel matters (`PLAT-*`, `BSH-*`, `DLG-*`):
```tsx
import { ActionSheetIOS, Platform } from 'react-native';
function showActions() {
  if (Platform.OS === 'ios') {
    ActionSheetIOS.showActionSheetWithOptions(
      { options: ['Cancel', 'Delete'], destructiveButtonIndex: 1, cancelButtonIndex: 0 },
      (i) => { if (i === 1) onDelete(); },
    );
  } else {
    openMaterialMenu(); // e.g. a gorhom sheet or a Material menu component
  }
}
```
Dialog button order is platform-specific (`DLG-*`); mirror each OS's convention.

## What to branch vs share
| Diverges most → branch | Safe to share |
|---|---|
| Header / tab-bar chrome | Business logic, hooks, data layer |
| Bottom sheets & gestures | Tokenized content components |
| Action menus (`ActionSheetIOS` vs Material) | Lists, cards, forms body |
| Shadows vs elevation | Token shape (values differ, keys don't) |
| Haptic style, back behavior | Typography scale (respect OS font scaling) |

## Responsive is orthogonal
Adaptive (which OS) ≠ responsive (how big). Do both (`GRD-*`):
```tsx
import { useWindowDimensions } from 'react-native';
const { width } = useWindowDimensions();
if (width >= 840) return <TwoPaneListDetail />;   // ≥840dp two-pane
if (width >= 600) return <RailLayout />;          // 600–839dp side rail
return <BottomTabLayout />;                        // <600dp bottom tabs
```
Reduce-motion, RTL (`L10N-*` — use `I18nManager` + logical `start/end` styles), and OS font scaling apply in every branch.
