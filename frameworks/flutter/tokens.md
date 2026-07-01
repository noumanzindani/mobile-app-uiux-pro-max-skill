# Flutter — Tokens & Theming

**Purpose:** Show how Flutter consumes the skill's DTCG semantic tokens without hardcoding values. Two layers: (1) map DTCG **semantic color** tokens onto Material 3's `ColorScheme`, (2) carry everything M3 doesn't model (brand gradients, semantic `success`/`warning`/`info`, custom spacing/radius/motion) in typed `ThemeExtension<T>` classes. Read alongside `COL-*`, `DRK-*`, `SHP-*`, `SPC-*`, `MOT-*`.

## Table of contents
- [The pipeline](#the-pipeline)
- [Layer 1 — ColorScheme from tokens](#layer-1--colorscheme-from-tokens)
- [Layer 2 — ThemeExtension for everything else](#layer-2--themeextension-for-everything-else)
- [Reading tokens in a widget](#reading-tokens-in-a-widget)
- [Dark mode](#dark-mode)
- [Anti-patterns](#anti-patterns)

## The pipeline
```
design-system/tokens/*.json  (DTCG semantic)
        │  Style Dictionary v4 → dart target
        ▼
gen/tokens.g.dart  (const Color/double values — primitives, generated)
        │  hand-assembled once
        ▼
ThemeData(colorScheme, extensions:[AppColors, AppSpacing, AppRadii, AppMotion])
        │  Theme.of(context)
        ▼
Widgets read semantic roles only — never the generated primitives directly.
```
Widgets reference **semantic roles** (`colorScheme.primary`, `context.spacing.md`), not primitive values (`tokens.blue500`). Only the theme assembly touches primitives. This is what makes dark mode and rebrands a token swap, not a refactor (`COL-*`, `DRK-*`).

## Layer 1 — ColorScheme from tokens
Material 3 gives you a full tonal role system. Two supported paths:

**A. Seed (fast, harmonized):** `ColorScheme.fromSeed(seedColor: tokens.brandSeed, brightness: …)` — M3 derives all roles. Use when the brand is one seed color and you accept M3's harmonization.

**B. Explicit mapping (brand-exact):** build `ColorScheme(...)` (or `.fromSeed(...).copyWith(...)`) mapping each DTCG semantic token to its M3 role: `primary`←`color.action.primary`, `surface`←`color.surface`, `onSurface`←`color.text.primary`, `error`←`color.status.danger`, etc. Use when brand guidelines pin exact hexes. See `snippets/theme.md`.

## Layer 2 — ThemeExtension for everything else
M3's `ColorScheme` has no `success`, no brand gradient, no spacing/radius/motion scale. Put those in immutable `ThemeExtension<T>` classes so they are themeable, lerp-able (animate across theme changes), and type-safe:

```dart
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({required this.success, required this.warning, required this.brandGradient});
  final Color success;
  final Color warning;
  final LinearGradient brandGradient;

  @override
  AppColors copyWith({Color? success, Color? warning, LinearGradient? brandGradient}) => AppColors(
        success: success ?? this.success,
        warning: warning ?? this.warning,
        brandGradient: brandGradient ?? this.brandGradient,
      );

  @override
  AppColors lerp(AppColors? other, double t) => other is! AppColors
      ? this
      : AppColors(
          success: Color.lerp(success, other.success, t)!,
          warning: Color.lerp(warning, other.warning, t)!,
          brandGradient: LinearGradient.lerp(brandGradient, other.brandGradient, t)!,
        );
}
```
Register: `ThemeData(extensions: <ThemeExtension<dynamic>>[lightAppColors, appSpacing, appRadii])`. Repeat with dark values in `darkTheme`.

Do the same for non-color scales so nothing is a magic number (`SPC-*`, `SHP-*`, `MOT-*`):
```dart
class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({this.xs = 4, this.sm = 8, this.md = 16, this.lg = 24, this.xl = 32});
  final double xs, sm, md, lg, xl; // 4/8pt grid — SPC-*
  // copyWith + lerp …
}
```

## Reading tokens in a widget
Prefer a tiny extension on `BuildContext` for ergonomics:
```dart
extension ThemeX on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  AppColors get brand => Theme.of(this).extension<AppColors>()!;
  AppSpacing get space => Theme.of(this).extension<AppSpacing>()!;
}

// usage
Container(
  padding: EdgeInsets.all(context.space.md),
  decoration: BoxDecoration(
    color: context.colors.surfaceContainerHigh,
    borderRadius: BorderRadius.circular(context.brand /* … or AppRadii */ != null ? 16 : 16),
  ),
  child: Text('Balance', style: context.text.titleMedium?.copyWith(color: context.colors.onSurface)),
);
```

## Dark mode
Semantic layer does the work — one widget tree, two themes (`DRK-*`):
```dart
MaterialApp(
  themeMode: ThemeMode.system,             // follow OS; expose an override in Settings (SET-*)
  theme: buildTheme(Brightness.light),
  darkTheme: buildTheme(Brightness.dark),  // NOT pure #000 surfaces; use M3 surface tones
);
```
`buildTheme` assembles `ColorScheme` + the same `ThemeExtension` set with dark values. Because widgets only read semantic roles, none of them change. Verify each theme against `contrast_check.py`.

## Anti-patterns
- ❌ `color: Color(0xFF0A84FF)` in a widget → ✅ `context.colors.primary` (`COL-*`).
- ❌ `SizedBox(height: 16)` sprinkled ad-hoc → ✅ `SizedBox(height: context.space.md)` (`SPC-*`).
- ❌ `Colors.green` for success → ✅ `context.brand.success` (a11y + dark-mode safe).
- ❌ Two independent `ThemeData` blobs that drift → ✅ one `buildTheme(Brightness)` factory.
