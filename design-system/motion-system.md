# Motion System

> Purpose: durations, easing, and spring tokens for purposeful motion.

## Durations (ms)
| Token | Value | Use |
|---|---|---|
| `motion.duration.micro` | 100–150 | icon/state change, ripple |
| `motion.duration.small` | 200–250 | chips, switches, small enter |
| `motion.duration.medium` | 300–400 | cards, sheets, container transform |
| `motion.duration.large` | 400–500 | full-screen / complex |

Never exceed **500ms** for routine UI; **>1000ms** only for onboarding/hero moments.

## Easing (cubic-bezier tokens)
| Token | Curve | Use |
|---|---|---|
| `motion.easing.standard` | (0.2, 0, 0, 1) | most on-screen moves |
| `motion.easing.decelerate` | (0, 0, 0, 1) | elements **entering** (longer) |
| `motion.easing.accelerate` | (0.3, 0, 1, 1) | elements **leaving** (~30% shorter) |
| `motion.easing.emphasized` | (0.05, 0.7, 0.1, 1) | hero moments |

Never `linear` except continuous loops (spinners, progress). Enter decelerates + longer;
exit accelerates + shorter.

## Springs (Material 3 Expressive, 2025)
Physics-based: **stiffness + damping + initial velocity**.
- **Spatial** springs (position/size/rotation/corner) — may overshoot/bounce.
- **Effects** springs (color/opacity) — **no** overshoot.
- Schemes: **standard** (subdued) vs **expressive** (playful, lower damping).
- Tokens: `motion.spring.{fast|default|slow}.{spatial|effects}`.
- iOS/SwiftUI: `smooth` (no overshoot), `snappy` (slight), `bouncy` (visible); default
  response 0.55, dampingFraction 0.825.

## Rules
- Animate only `transform`/`opacity`; hold the **16ms/60fps** frame budget (8.3ms @120Hz).
- Every animation must orient, give feedback, show a relationship, or guide attention —
  else cut it.
- Always honor reduce-motion: swap movement for cross-fades/instant; keep the feedback.
