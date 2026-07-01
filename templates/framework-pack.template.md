# <Framework> Pack

> Capability summary: <tokens/theming · safe area · sheet · a11y API · animation · adaptive>.
> When to choose: <single-platform vs adaptive guidance>.

## Files in this pack
- `_index.md` — this file (capability summary + routing + TOC)
- `tokens.md` — how this framework consumes DTCG design tokens / its theming API
- `components.md` — idiomatic button / list / sheet / navigation + safe area + a11y + animation
- `states.md` — how to implement the 7 UI states in this framework
- `adaptive.md` — platform-adaptive guidance (where supported)
- `snippets/` — minimal, copy-paste idiomatic code stubs

## Non-negotiables (baked into every pack)
- Lists MUST be virtualized.
- Always use the framework's safe-area primitive; never hardcode insets.
- Reference design tokens; never hardcode color/spacing/radius.
- Sheets/nav use detents/breakpoints + platform nav stacks.
- Targets ≥ 44pt (iOS) / 48dp (Android).
- Reference the core rule corpus by ID (e.g. [[A11Y-007]], [[STATE-003]]); do not restate rules.
