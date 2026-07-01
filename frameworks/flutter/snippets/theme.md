# Snippet — Theme assembly (tokens → ThemeData)

One `buildTheme(Brightness)` factory maps DTCG semantic tokens onto `ColorScheme` and carries the rest in `ThemeExtension`s. Widgets read semantic roles only. See `tokens.md`, `COL-*`, `DRK-*`.

```dart
import 'package:flutter/material.dart';

// --- generated primitives (Style Dictionary dart target) ---
class T { // e.g. gen/tokens.g.dart
  static const brandSeed = Color(0xFF3D5AFE);
  static const success = Color(0xFF1E8E3E);
  static const successDark = Color(0xFF81C995);
  static const warning = Color(0xFFF9AB00);
  static const warningDark = Color(0xFFFDD663);
}

// --- Layer 2: custom tokens M3 doesn't model ---
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({required this.success, required this.warning});
  final Color success;
  final Color warning;

  @override
  AppColors copyWith({Color? success, Color? warning}) =>
      AppColors(success: success ?? this.success, warning: warning ?? this.warning);

  @override
  AppColors lerp(AppColors? other, double t) => other is! AppColors
      ? this
      : AppColors(
          success: Color.lerp(success, other.success, t)!,
          warning: Color.lerp(warning, other.warning, t)!,
        );
}

@immutable
class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({this.xs = 4, this.sm = 8, this.md = 16, this.lg = 24, this.xl = 32});
  final double xs, sm, md, lg, xl; // 4/8pt grid — SPC-*
  @override
  AppSpacing copyWith({double? xs, double? sm, double? md, double? lg, double? xl}) =>
      AppSpacing(xs: xs ?? this.xs, sm: sm ?? this.sm, md: md ?? this.md, lg: lg ?? this.lg, xl: xl ?? this.xl);
  @override
  AppSpacing lerp(AppSpacing? other, double t) => other is! AppSpacing
      ? this
      : AppSpacing(
          xs: lerpDouble(xs, other.xs, t)!, sm: lerpDouble(sm, other.sm, t)!,
          md: lerpDouble(md, other.md, t)!, lg: lerpDouble(lg, other.lg, t)!, xl: lerpDouble(xl, other.xl, t)!);
}

// --- the single source of truth ---
ThemeData buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: T.brandSeed, brightness: brightness);
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    extensions: <ThemeExtension<dynamic>>[
      AppColors(success: isDark ? T.successDark : T.success, warning: isDark ? T.warningDark : T.warning),
      const AppSpacing(),
    ],
  );
}

// --- ergonomic access ---
extension ThemeX on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  AppColors get brand => Theme.of(this).extension<AppColors>()!;
  AppSpacing get space => Theme.of(this).extension<AppSpacing>()!;
}

// --- wire it up ---
class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        themeMode: ThemeMode.system,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        home: const SizedBox.shrink(),
      );
}
```
