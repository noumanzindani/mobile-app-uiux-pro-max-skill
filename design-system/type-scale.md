# Type Scale

> Purpose: the mobile typographic system — sizes, leading, weights, optical sizing.

## Modular scale
- Mobile prefers a **~1.2 (minor third)** ratio; use 1.25 (major third) or 1.333 (perfect
  fourth) only for more dramatic display hierarchy.
- Recommended mobile steps (px/pt/sp): **12, 14, 16 (body base), 18, 20, 24, 30, 36**.
- Body base = **16**. Never set body below 14 for primary reading content.

## Roles (map to semantic tokens)
| Role | Size | Weight | Line-height |
|---|---|---|---|
| Display | 30–36 | 600–700 | 1.1–1.2 |
| Headline | 24 | 600 | 1.2 |
| Title | 20 | 600 | 1.25 |
| Body | 16 | 400 | 1.5 |
| Body-sm / Label | 14 | 400–500 | 1.4 |
| Caption | 12 | 400 | 1.35 |

## Leading (line-height)
- Body ~**1.5**; headings **1.1–1.25**. Align leading to the 4pt baseline grid (e.g. 16/24).

## Dynamic Type / scaling
- Support up to the largest accessibility sizes (iOS **AX5**, Android font scale).
- Use platform text-style APIs (`preferredFont(forTextStyle:)`, Material `Typography`); never
  fixed text-container heights. Test at **200%+** with no truncation, overlap, or clipping.
- Enable optical sizing (`opsz`) on variable fonts: large display tightens, small text opens.

## Platform fonts
- iOS: San Francisco (SF Pro) via Dynamic Type. Android: Roboto / Material `Typography`.
- Ban "default-font sameness" — if a brand type is chosen, apply it intentionally across the
  scale; don't leave everything at the system default by accident. See `frontend` principle
  in `rules/foundations/typography.md`.
