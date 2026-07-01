# Design Token Spec

> Purpose: how tokens are structured, named, and themed. Format: **DTCG 2025.10**
> (first stable version). Tooling: **Style Dictionary v4**.

## 1. Three tiers (never skip a tier)
| Tier | Names by | Example | Rule |
|---|---|---|---|
| **Primitive / global** | how it *looks* | `color.blue.500`, `space.4` | Holds raw values only. |
| **Semantic / alias** | how it's *used* | `color.action.primary` → `{color.blue.500}` | Holds *intent*. Components read this. |
| **Component** | local scope | `button.primary.bg` → `{color.action.primary}` | Optional; local decisions. |

**Law:** components reference **semantic** tokens (or component tokens), **never**
primitives. Theme by swapping the semantic→primitive mapping, never by forking components.

## 2. Naming
- Primitives: `[category].[scale]` — `color.blue.500`, `space.4`, `font.size.300`.
- Semantics: `[category].[concept].[property?].[variant?].[state?]` — `color.action.primary`,
  `color.surface`, `color.text.error`, `color.action.bg.hover`.
- Name semantics for **why, not what**: `color.text.error` survives a hue change;
  `color.text.red` breaks.

## 3. DTCG format
```json
{ "color": { "$type": "color",
  "action-primary": { "$value": "{color.blue.500}", "$description": "Primary CTA" } } }
```
- `$value`, `$type`, `$description`; `$type` inherits down a group.
- Types: `color`, `dimension` (`{value,unit}`), `fontFamily`, `fontWeight`, `number`,
  `duration`, `cubicBezier`, `string`; composite: `shadow`, `border`, `typography`,
  `transition`, `gradient`, `strokeStyle`.
- Aliasing with `{group.token}` is the backbone of tiering.

## 4. Theming
- **Light/dark:** keep primitives fixed; swap the **semantic** layer per mode
  (`color.surface` → `gray.50` light / `gray.900` dark). See `themes/`.
- **High-contrast:** an extra semantic set raising ratios (text ≥ 4.5:1, UI ≥ 3:1).
- **Density:** alternate `spacing.*` / control-height sets (comfortable/compact).
- **Multi-brand / white-label:** swap primitive palettes + brand semantics; components untouched.
- **Material You:** treat M3 color *roles* (`primary`, `onPrimary`, `surfaceContainer`…) as
  the semantic layer, sourced from HCT tonal palettes.

## 5. Categories a mobile system defines
`color` · `typography` (family/size/weight/lineHeight/letterSpacing) · `spacing` · `radius`
· `elevation/shadow` · `motion` (`duration` + `cubicBezier` + M3 spring params) · `zIndex`
· `breakpoints` · `opacity` · `border`.

## 6. Build
`design-system/build/config.json` drives Style Dictionary v4 → per-platform outputs:
CSS custom properties, TS/JS, Swift, Kotlin/Android XML, Dart. Generated files are build
artifacts — **never hand-edit**. One source of truth: the JSON in `tokens/`.

## Token rules for an AI
1. Never hardcode raw values in components — reference semantic tokens. → `token_lint.py`
2. Components → semantic → primitive; never component → primitive.
3. Name semantics by intent, primitives by value.
4. Snap all spacing/sizing to the 4/8pt grid; reject off-grid values.
5. Use `$type` + composite tokens (`shadow`, `typography`) over loose scalars.
6. Maintain contrast: semantic `fg`/`onX` pairs meet WCAG AA in every theme.
