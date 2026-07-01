# Jetpack Compose — Tokens & Theming

**Purpose:** How Compose consumes the skill's DTCG semantic tokens. Color/typography/shape/motion flow through **`MaterialExpressiveTheme`** (so dark mode and Material You resolve through role slots); custom tokens the M3 slots don't cover (e.g. a spacing scale, brand-specific roles) flow through **`CompositionLocal`**. Rules referenced, not restated: `COL-*`, `DRK-*`, `SPC-*`, `SHP-*`, `MOT-*`.

## Table of contents
- [Layering: DTCG → Compose](#layering-dtcg--compose)
- [Color: MaterialTheme roles + Material You](#color-materialtheme-roles--material-you)
- [Custom tokens: CompositionLocal](#custom-tokens-compositionlocal)
- [Motion tokens: MotionScheme](#motion-tokens-motionscheme)
- [Consuming tokens in a composable](#consuming-tokens-in-a-composable)
- [Do / Don't](#do--dont)

## Layering: DTCG → Compose
The design system emits primitive → semantic → component tiers. Compose binds **only to semantic/component tiers** (`COL-*` forbids referencing raw primitives):

| DTCG token tier | Compose carrier | Resolves |
|---|---|---|
| `color.surface`, `color.on-surface`, `color.action.primary`, `color.error` | `ColorScheme` role slots (`surface`, `onSurface`, `primary`, `error`) in `MaterialExpressiveTheme` | light / dark / dynamic, via `isSystemInDarkTheme()` |
| `radius.*`, shape families | `Shapes` (`extraSmall … extraLarge`) — the M3 10-step corner scale | per-component shape slots |
| `type.*` | `Typography` roles (`bodyLarge`, `titleMedium`, …) | Dynamic font scaling |
| `space.*` and any non-M3 token | `CompositionLocal` (`LocalSpacing`) | one provider at the theme root |
| `motion.spring.*` | `MotionScheme` (spatial vs effects springs) | reduce-motion honored centrally |

Style Dictionary can emit the `ColorScheme`/`Shapes`/spacing values as Kotlin; the **carrier** stays `MaterialTheme` so `isSystemInDarkTheme()` and dynamic color work for free (`DRK-*`).

## Color: MaterialTheme roles + Material You
Map DTCG semantic roles onto M3 `ColorScheme` slots and choose the scheme by system theme, preferring **Material You** dynamic color on Android 12+ with a brand fallback (`COL-*`, `DRK-*`). Full stub: `snippets/theme.md`.

```kotlin
@Composable
fun AppTheme(dynamic: Boolean = true, content: @Composable () -> Unit) {
    val dark = isSystemInDarkTheme()                 // DRK-*
    val context = LocalContext.current
    val colors = when {
        dynamic && Build.VERSION.SDK_INT >= 31 ->    // Material You (COL-*)
            if (dark) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        dark -> BrandDarkColors                       // brand fallback maps DTCG roles
        else -> BrandLightColors
    }
    MaterialExpressiveTheme(colorScheme = colors, shapes = BrandShapes, content = content)
}
```
Composables then read `MaterialTheme.colorScheme.surface` / `.primary` — never a hex literal.

## Custom tokens: CompositionLocal
M3 has no spacing scale slot, so carry the DTCG `space.*` scale in a `CompositionLocal` (`SPC-*`). This keeps spacing centralized and swappable (density variants) and keeps `token_lint` green:

```kotlin
data class Spacing(val s1: Dp = 4.dp, val s2: Dp = 8.dp, val s3: Dp = 12.dp,
                   val s4: Dp = 16.dp, val s6: Dp = 24.dp, val s8: Dp = 32.dp)

val LocalSpacing = staticCompositionLocalOf { Spacing() }
val MaterialTheme.spacing: Spacing @Composable get() = LocalSpacing.current
```
Provide it inside `AppTheme`: `CompositionLocalProvider(LocalSpacing provides Spacing()) { … }`.

## Motion tokens: MotionScheme
Material 3 Expressive splits motion into **spatial** springs (things that move — position/size, slightly bouncy) and **effects** springs (color/opacity — no bounce). Read them from `MaterialTheme.motionScheme` so timing is consistent and Reduce Motion is handled in one place (`MOT-*`, `A11Y-*`):

```kotlin
val spatial = MaterialTheme.motionScheme.fastSpatialSpec<Float>()   // list/nav movement
val effects = MaterialTheme.motionScheme.defaultEffectsSpec<Color>() // fades/tints
```

## Consuming tokens in a composable
```kotlin
@Composable
fun PriceRow(modifier: Modifier = Modifier) {
    Row(
        modifier
            .background(MaterialTheme.colorScheme.surface,          // token (COL-*)
                        shape = MaterialTheme.shapes.medium)        // 10-step scale (SHP-*)
            .padding(horizontal = MaterialTheme.spacing.s4,         // 16.dp — never a literal (SPC-*)
                     vertical = MaterialTheme.spacing.s3)
    ) { /* … */ }
}
```

## Do / Don't
- **Do** map DTCG roles onto `ColorScheme` slots and pick the scheme via `isSystemInDarkTheme()` (`COL-*`, `DRK-*`).
- **Do** prefer Material You dynamic color with a static brand fallback (`COL-*`).
- **Do** carry non-M3 tokens (spacing) in a `CompositionLocal`; read motion from `MotionScheme` (`SPC-*`, `MOT-*`).
- **Don't** use `Color(0xFF…)`, raw `.dp` paddings, or `RoundedCornerShape(12.dp)` inline in composables — that is what `token_lint` flags.
- **Don't** hardcode a dark palette app-wide; let the system theme + Material You drive it (`DRK-*`).
