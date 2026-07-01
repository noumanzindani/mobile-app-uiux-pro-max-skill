# Spacing System

> Purpose: the grid and spacing scale that all layout snaps to.

## Grid
- **8pt grid** for layout and components; **4pt baseline grid** for typography.
- Spacing scale (dp/pt): **4, 8, 12, 16, 24, 32, 48, 64**. Reject off-grid values.
- Screen edge margins: **16–20pt** (iOS) / **16dp** (Android).
- Gap between adjacent touch targets: **≥ 8dp**.

## Semantic spacing tokens
| Token | Value | Typical use |
|---|---|---|
| `spacing.xs` | 4 | icon-to-label, tight inline |
| `spacing.sm` | 8 | intra-component padding |
| `spacing.md` | 16 | default content padding, edge margin |
| `spacing.lg` | 24 | section separation |
| `spacing.xl` | 32 | large section / hero |
| `spacing.2xl` | 48 | screen-level rhythm |

## Density
- Provide **comfortable** (default on phones) and **compact** sets. Compact reduces the scale
  by one step for dense data (tables, enterprise/CRM). Never below the 4pt grid.

## Safe areas (read dynamically, never hardcode)
- iOS home indicator bottom ≈ **34pt**; notch/Dynamic Island top ≈ **47–59pt**.
- Android: draw edge-to-edge; pad content out of status + gesture bars via insets.
- Keep interactive elements out of inset zones and system-gesture edges.
