# Typography (TYP)

> Purpose: Enforce a legible, token-driven type system with a clear modular hierarchy that scales fully with Dynamic Type / font-scale up to AX5, never clipping or truncating essential text.

## Contents
- [TYP-001 — Body base size 16](#typ-001--body-base-size-16)
- [TYP-002 — Modular type scale ~1.2](#typ-002--modular-type-scale-12)
- [TYP-003 — Body line-height ~1.5](#typ-003--body-line-height-15)
- [TYP-004 — Heading line-height 1.1–1.25](#typ-004--heading-line-height-1112-5)
- [TYP-005 — Support Dynamic Type to AX5](#typ-005--support-dynamic-type-to-ax5)
- [TYP-006 — No fixed text heights](#typ-006--no-fixed-text-heights)
- [TYP-007 — Reference semantic text-style tokens](#typ-007--reference-semantic-text-style-tokens)
- [TYP-008 — Limit the type ramp](#typ-008--limit-the-type-ramp)
- [TYP-009 — Minimum readable sizes](#typ-009--minimum-readable-sizes)
- [TYP-010 — Line length 45–75 characters](#typ-010--line-length-4575-characters)
- [TYP-011 — At most two type families](#typ-011--at-most-two-type-families)
- [TYP-012 — Semantic font weights](#typ-012--semantic-font-weights)
- [TYP-013 — Size-appropriate tracking](#typ-013--size-appropriate-tracking)
- [TYP-014 — Tabular figures for data](#typ-014--tabular-figures-for-data)
- [TYP-015 — Align left, do not justify](#typ-015--align-left-do-not-justify)
- [TYP-016 — Truncate accessibly](#typ-016--truncate-accessibly)
- [TYP-017 — Never disable font scaling](#typ-017--never-disable-font-scaling)
- [TYP-018 — Uppercase sparingly](#typ-018--uppercase-sparingly)
- [TYP-019 — Meet text contrast minimums](#typ-019--meet-text-contrast-minimums)
- [TYP-020 — Prefer platform system fonts](#typ-020--prefer-platform-system-fonts)
- [TYP-021 — Use semantic text styles on iOS](#typ-021--use-semantic-text-styles-on-ios)
- [TYP-022 — Do not skip heading levels](#typ-022--do-not-skip-heading-levels)

---

### TYP-001 — Body base size 16
- **Rule:** Default body text MUST be 16pt/sp at the user's default scale. Never set primary reading text below 16 to fit more content.
- **Why:** 16 is the cross-platform legibility baseline; smaller body text drives zoom, strain, and accessibility failures.
- **Platforms:** all
- **Severity:** error
- **Check:** `dynamic_type_check.py` / manual for body size token.
- **Exceptions:** Captions, labels, and metadata down to 12 (see [[TYP-009]]).
- **See also:** [[TYP-002]], [[TYP-009]]

### TYP-002 — Modular type scale ~1.2
- **Rule:** Build the type ramp from a modular scale with a ratio of ~1.2 on mobile (e.g. 12, 14, 16, 20, 24, 28, 34), defined once as tokens; do not pick arbitrary sizes per screen.
- **Why:** A consistent ratio produces a harmonious hierarchy and keeps step sizes predictable.
- **Platforms:** all
- **Severity:** warning
- **Check:** `token_lint.py` for off-ramp font-size literals.
- **Exceptions:** Display/marketing headers may use a larger ratio within the token set.
- **See also:** [[TYP-008]], [[TYP-007]]

### TYP-003 — Body line-height ~1.5
- **Rule:** Body and paragraph text MUST use a line-height of ~1.5× (144–160%) the font size. Do not set line-height below 1.3 for multi-line body copy.
- **Why:** Adequate leading improves readability and satisfies WCAG 1.4.12 text-spacing expectations.
- **Platforms:** all
- **Severity:** warning
- **Check:** `dynamic_type_check.py` / manual.
- **Exceptions:** Single-line labels and buttons.
- **See also:** [[TYP-004]], [[TYP-010]]

### TYP-004 — Heading line-height 1.1–1.25
- **Rule:** Headings and display text MUST use tighter line-height of 1.1–1.25× so large type does not float apart; keep it proportionally tighter than body leading.
- **Why:** Large text needs less relative leading to hold together as a unit and read as a single heading.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual.
- **Exceptions:** None.
- **See also:** [[TYP-003]]

### TYP-005 — Support Dynamic Type to AX5
- **Rule:** All text MUST scale with the OS text-size setting through the accessibility sizes (AX5, ≥200%). Layouts MUST remain usable and readable at the largest setting without loss of function.
- **Why:** WCAG 1.4.4 and platform guidance require content to reflow and remain operable when users enlarge text.
- **Platforms:** all
- **Severity:** error
- **Check:** `dynamic_type_check.py`.
- **Exceptions:** None for content text; purely decorative glyphs may be fixed.
- **See also:** [[TYP-006]], [[TYP-017]], [[GRD-015]]

### TYP-006 — No fixed text heights
- **Rule:** Never constrain text containers to a fixed height that clips scaled text; height MUST derive from content. Avoid fixed-height buttons/rows that crop labels at large font sizes.
- **Why:** Fixed heights are the primary cause of truncation and overlap when Dynamic Type grows.
- **Platforms:** all
- **Severity:** error
- **Check:** `dynamic_type_check.py` flags fixed heights wrapping text.
- **Exceptions:** Minimum-height (not fixed-height) touch targets that still allow growth.
- **See also:** [[TYP-005]], [[TYP-016]], [[SPC-008]]

### TYP-007 — Reference semantic text-style tokens
- **Rule:** Text MUST use named type roles/tokens (e.g. `title.lg`, `body.md`, `label.sm`) instead of inline font-size/weight/line-height literals.
- **Why:** Named roles guarantee consistency and let the whole type system be retuned or themed centrally.
- **Platforms:** all
- **Severity:** error
- **Check:** `token_lint.py` flags inline font styling literals.
- **Exceptions:** Token/theme definition files.
- **See also:** [[TYP-002]], [[TYP-021]]

### TYP-008 — Limit the type ramp
- **Rule:** Use at most ~6–7 distinct text roles across the app (e.g. display, headline, title, body, label, caption). Do not proliferate one-off sizes.
- **Why:** A small, reused ramp keeps hierarchy legible and prevents visual noise.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** None.
- **See also:** [[TYP-002]], [[TYP-007]]

### TYP-009 — Minimum readable sizes
- **Rule:** No legible UI text below 12pt/sp; captions/labels 12–14, body ≥16. Never render meaningful text under 11.
- **Why:** Below ~12 text becomes unreadable for many users and fails legibility expectations.
- **Platforms:** all
- **Severity:** error
- **Check:** `dynamic_type_check.py` / manual.
- **Exceptions:** Non-essential legal/branding microtext that has an accessible equivalent elsewhere.
- **See also:** [[TYP-001]]

### TYP-010 — Line length 45–75 characters
- **Rule:** Constrain paragraph measure to ~45–75 characters per line (~60 optimal) using max-width, especially on tablets/expanded windows.
- **Why:** Overly long lines hurt reading speed and comprehension; a bounded measure keeps text scannable.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual.
- **Exceptions:** Data cells, code, and single-line labels.
- **See also:** [[GRD-006]], [[SPC-018]]

### TYP-011 — At most two type families
- **Rule:** Limit the app to two type families (e.g. one for headings, one for body/UI); pair intentionally and define both as tokens. Do not mix three or more typefaces.
- **Why:** A disciplined pairing reads as designed; more families look inconsistent and increase bundle size.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Monospace for code/numeric alignment counts as a functional third.
- **See also:** [[TYP-020]], [[TYP-014]]

### TYP-012 — Semantic font weights
- **Rule:** Assign weights by role, not by whim: body/regular 400, emphasis/medium 500, headings/semibold–bold 600–700. Avoid using ultra-light (<300) for body or reading text.
- **Why:** Weight is a primary hierarchy signal; consistent weight-to-role mapping keeps emphasis meaningful and legible.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual.
- **Exceptions:** Display type may use lighter or heavier weights within tokens.
- **See also:** [[TYP-007]], [[TYP-008]]

### TYP-013 — Size-appropriate tracking
- **Rule:** Tighten letter-spacing on large headings and loosen slightly on small all-caps labels, following the platform type scale's tracking values; do not apply a single tracking to all sizes.
- **Why:** Optical tracking varies with size; correct tracking improves legibility at both extremes.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual.
- **Exceptions:** None.
- **See also:** [[TYP-018]]

### TYP-014 — Tabular figures for data
- **Rule:** Use tabular (monospaced) figures for aligned numeric data — prices, balances, tables, timers — so digits align in columns and do not shift as values change.
- **Why:** Proportional figures cause jitter and misalignment in financial and data UIs; tabular figures keep columns and live counters stable.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Prose that happens to contain numbers.
- **See also:** [[TYP-011]], [[TAB]], [[TYP-015]]

### TYP-015 — Align left, do not justify
- **Rule:** Set body text left-aligned (start-aligned) in LTR; never full-justify body copy on mobile. Right/end alignment is reserved for RTL and numeric columns.
- **Why:** Justification creates rivers and uneven spacing on narrow screens; start alignment is the most legible and RTL-safe default.
- **Platforms:** all
- **Severity:** warning
- **Check:** `rtl_check.py` for hardcoded left/right alignment; manual for justify.
- **Exceptions:** Centered short headings/empty-state copy; numeric right-alignment in tables.
- **See also:** [[TYP-014]], [[L10N]]

### TYP-016 — Truncate accessibly
- **Rule:** When truncating, use a single trailing ellipsis and expose the full value to assistive tech (accessible label/value) or via expand-on-tap; never silently cut text without indication.
- **Why:** Truncation without an ellipsis or a11y fallback hides information from all users, especially screen-reader users.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual; `dynamic_type_check.py` flags high truncation risk.
- **Exceptions:** None.
- **See also:** [[TYP-006]], [[A11Y]]

### TYP-017 — Never disable font scaling
- **Rule:** Do not disable OS font scaling (no `allowFontScaling={false}`, no clamped `textScaleFactor`, no `UIFontMetrics` opt-out) to preserve a layout. Fix the layout instead.
- **Why:** Disabling scaling directly violates accessibility guidance and locks out users who need larger text.
- **Platforms:** all
- **Severity:** error
- **Check:** `dynamic_type_check.py` flags scaling-disable APIs.
- **Exceptions:** None.
- **See also:** [[TYP-005]], [[TYP-006]]

### TYP-018 — Uppercase sparingly
- **Rule:** Reserve all-caps for short labels/overlines (≤ ~20 chars). Do not set sentences or long labels in uppercase, and always keep the accessible name in normal case.
- **Why:** All-caps reduces reading speed for longer text and can be mispronounced by screen readers as initialisms.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual.
- **Exceptions:** Brand wordmarks.
- **See also:** [[TYP-013]]

### TYP-019 — Meet text contrast minimums
- **Rule:** Text MUST meet WCAG 2.2 contrast: ≥4.5:1 for normal text, ≥3:1 for large text (≥18.66px bold or ≥24px). Verify in every theme.
- **Why:** Insufficient contrast is the most common accessibility failure and blocks low-vision users.
- **Platforms:** all
- **Severity:** error
- **Check:** `contrast_check.py`.
- **Exceptions:** Incidental/decorative or disabled text (see [[COL-014]]).
- **See also:** [[COL-004]], [[COL-005]], [[TYP-020]]

### TYP-020 — Prefer platform system fonts
- **Rule:** Default to the platform system font (SF Pro on iOS, Roboto on Android) unless a brand typeface is specified; when using a custom font, ship platform-correct fallbacks and preserve Dynamic Type behavior.
- **Why:** System fonts are optically tuned, ship with the OS (no load cost), and support Dynamic Type/optical sizing natively.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual.
- **Exceptions:** Brand-mandated typefaces bound to tokens.
- **See also:** [[TYP-011]], [[TYP-021]]

### TYP-021 — Use semantic text styles on iOS
- **Rule:** On iOS/SwiftUI, map text to semantic text styles (`.body`, `.headline`, `.caption`, via `UIFontMetrics`) rather than fixed point sizes, so text tracks Dynamic Type automatically.
- **Why:** Semantic styles inherit correct scaling, weight, and leading per user setting without manual math.
- **Platforms:** ios
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Custom brand fonts scaled through `UIFontMetrics.scaledFont`.
- **See also:** [[TYP-005]], [[TYP-007]]

### TYP-022 — Do not skip heading levels
- **Rule:** Maintain a logical, sequential heading hierarchy (H1→H2→H3) for both visual order and accessibility semantics; do not jump levels or use size to fake a level.
- **Why:** Correct heading order gives screen-reader users a navigable document outline and reinforces visual hierarchy.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** None.
- **See also:** [[TYP-008]], [[A11Y]]
