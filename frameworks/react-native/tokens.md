# React Native — Tokens & Theming

**Purpose:** RN has **no theme system** — you build one. This file shows how to consume the skill's DTCG semantic tokens without hardcoding values, and how to pick a styling engine. Read alongside `COL-*`, `DRK-*`, `SPC-*`.

## Table of contents
- [The pipeline](#the-pipeline)
- [Pick a styling engine](#pick-a-styling-engine)
- [Baseline — Context + hook (no extra deps)](#baseline--context--hook-no-extra-deps)
- [Restyle](#restyle) · [NativeWind](#nativewind) · [Unistyles](#unistyles)
- [Dark mode](#dark-mode)
- [Anti-patterns](#anti-patterns)

## The pipeline
```
design-system/tokens/*.json  (DTCG semantic)
        │  Style Dictionary v4 → js/ts target
        ▼
theme/tokens.ts  (typed light + dark objects — generated)
        │  provided once via Context / engine config
        ▼
useTheme() / restyle props / className / StyleSheet.create
        ▼
Components read semantic roles only — never raw hex/px.
```
Components reference **semantic roles** (`theme.colors.primary`, `theme.spacing.md`), never primitives. Only the theme object touches raw values (`COL-*`, `SPC-*`).

## Pick a styling engine
Decide before writing UI — this is the single most important RN theming choice:
| Engine | Best when | Token binding |
|---|---|---|
| **Context + hook** (built-in) | Small app, no deps, full control | `useTheme()` → `StyleSheet.create` per theme |
| **Shopify Restyle** | Type-safe design-system props (`<Box bg="surface" p="md">`) | theme object typed end-to-end |
| **NativeWind** | Team fluent in Tailwind; utility classes | `tailwind.config` maps tokens → classes |
| **Unistyles** | Performance-critical theming, C++ engine, variants | `StyleSheet.configure({ themes })` |

All four satisfy the token mandate as long as raw values live only in the theme config. Below: the zero-dep baseline plus how each engine ingests the same tokens.

## Baseline — Context + hook (no extra deps)
```ts
// theme/tokens.ts  (generated from DTCG)
export const light = {
  colors: { primary: '#3D5AFE', onPrimary: '#FFFFFF', surface: '#FFFFFF',
            onSurface: '#1A1C1E', border: '#E2E2E6', success: '#1E8E3E',
            danger: '#D32F2F', muted: '#5F6368' },
  spacing: { xs: 4, sm: 8, md: 16, lg: 24, xl: 32 }, // 4/8pt grid — SPC-*
  radii:   { sm: 8, md: 12, lg: 16, pill: 9999 },    // SHP-*
} as const;
export const dark: typeof light = { /* dark values, same shape — DRK-* */ };
export type Theme = typeof light;
```
```tsx
// theme/ThemeProvider.tsx
import { createContext, useContext } from 'react';
import { useColorScheme } from 'react-native';
import { light, dark, Theme } from './tokens';

const ThemeContext = createContext<Theme>(light);
export const useTheme = () => useContext(ThemeContext);

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const scheme = useColorScheme();                 // DRK-* — follows OS
  return <ThemeContext.Provider value={scheme === 'dark' ? dark : light}>{children}</ThemeContext.Provider>;
}
```
```tsx
// consuming — styles derived from tokens, memoized per theme
const theme = useTheme();
const s = useMemo(() => StyleSheet.create({
  card: { backgroundColor: theme.colors.surface, padding: theme.spacing.md, borderRadius: theme.radii.md },
}), [theme]);
```

## Restyle
```ts
// theme/restyle.ts
import { createTheme } from '@shopify/restyle';
import { light } from './tokens';
export const theme = createTheme({
  colors: light.colors, spacing: light.spacing, borderRadii: light.radii,
});
```
```tsx
// <Box bg="surface" p="md" borderRadius="md"><Text variant="body" color="onSurface">…</Text></Box>
```

## NativeWind
```js
// tailwind.config.js — map DTCG tokens to Tailwind scale (no raw values in JSX)
module.exports = {
  theme: { extend: {
    colors: { primary: '#3D5AFE', surface: '#FFFFFF', danger: '#D32F2F' },
    spacing: { md: 16, lg: 24 }, borderRadius: { md: 12 },
  }},
};
// <View className="bg-surface p-md rounded-md">  darkMode via `dark:` variants (DRK-*)
```

## Unistyles
```ts
import { StyleSheet } from 'react-native-unistyles';
import { light, dark } from './tokens';
StyleSheet.configure({ themes: { light, dark }, settings: { adaptiveThemes: true } });
// const styles = StyleSheet.create((theme) => ({ card: { backgroundColor: theme.colors.surface } }));
```

## Dark mode
Drive theme selection from `useColorScheme()` (reactive) or `Appearance.getColorScheme()` (imperative); expose a manual override in Settings (`SET-*`). Because components read semantic roles, none change. Never pure `#000` surfaces (`DRK-*`); verify each theme with `contrast_check.py`.

## Anti-patterns
- ❌ `backgroundColor: '#3D5AFE'` in a component → ✅ `theme.colors.primary` (`COL-*`).
- ❌ `padding: 16` literals → ✅ `theme.spacing.md` (`SPC-*`).
- ❌ Two style objects for light/dark drifting apart → ✅ one token shape, two value sets.
- ❌ `StatusBar.currentHeight` for insets → ✅ `useSafeAreaInsets()` (`A11Y-*`).
