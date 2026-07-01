# Snippet — Theme provider (tokens → Context)

Zero-dep baseline: DTCG tokens as typed objects, provided via Context, selected by OS color scheme with a manual override. Components read semantic roles only. See `tokens.md`, `COL-*`, `DRK-*`.

```tsx
// theme/tokens.ts  (generated from DTCG semantic tokens)
export const light = {
  colors: {
    primary: '#3D5AFE', onPrimary: '#FFFFFF',
    surface: '#FFFFFF', onSurface: '#1A1C1E',
    border: '#E2E2E6', muted: '#5F6368',
    success: '#1E8E3E', danger: '#D32F2F',
  },
  spacing: { xs: 4, sm: 8, md: 16, lg: 24, xl: 32 }, // 4/8pt grid — SPC-*
  radii: { sm: 8, md: 12, lg: 16, pill: 9999 },      // SHP-*
} as const;

export const dark: typeof light = {
  colors: {
    primary: '#9FB0FF', onPrimary: '#0A1A5C',
    surface: '#1A1C1E', onSurface: '#E3E2E6',
    border: '#2E3134', muted: '#9AA0A6',
    success: '#81C995', danger: '#F2B8B5',
  },
  spacing: light.spacing,
  radii: light.radii,
};

export type Theme = typeof light;
```

```tsx
// theme/ThemeProvider.tsx
import React, { createContext, useContext, useMemo, useState } from 'react';
import { useColorScheme } from 'react-native';
import { light, dark, Theme } from './tokens';

type Mode = 'system' | 'light' | 'dark';
const ThemeContext = createContext<{ theme: Theme; mode: Mode; setMode: (m: Mode) => void }>({
  theme: light, mode: 'system', setMode: () => {},
});

export const useTheme = () => useContext(ThemeContext).theme;
export const useThemeMode = () => useContext(ThemeContext);

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const os = useColorScheme();                 // DRK-* — follows OS
  const [mode, setMode] = useState<Mode>('system'); // SET-* — user override
  const resolved = mode === 'system' ? os : mode;
  const theme = resolved === 'dark' ? dark : light;
  const value = useMemo(() => ({ theme, mode, setMode }), [theme, mode]);
  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}
```

```tsx
// consuming — memoize styles per theme
import { StyleSheet } from 'react-native';
function Card() {
  const t = useTheme();
  const s = useMemo(() => StyleSheet.create({
    card: { backgroundColor: t.colors.surface, padding: t.spacing.md, borderRadius: t.radii.md },
  }), [t]);
  return <View style={s.card}>{/* … */}</View>;
}
```
