# Color & Theming (COL)

> Purpose: Enforce a three-tier token architecture (primitive → semantic → component) where components consume only semantic roles, color never carries meaning alone, and every text/UI pairing meets WCAG 2.2 AA in both light and dark themes.

## Contents
- [COL-001 — Three token tiers](#col-001--three-token-tiers)
- [COL-002 — Components reference semantic roles only](#col-002--components-reference-semantic-roles-only)
- [COL-003 — Never encode meaning with color alone](#col-003--never-encode-meaning-with-color-alone)
- [COL-004 — Normal text contrast ≥4.5:1](#col-004--normal-text-contrast-451)
- [COL-005 — Large text contrast ≥3:1](#col-005--large-text-contrast-31)
- [COL-006 — UI and icon contrast ≥3:1](#col-006--ui-and-icon-contrast-31)
- [COL-007 — Generate palettes with HCT tonal ramps](#col-007--generate-palettes-with-hct-tonal-ramps)
- [COL-008 — Dark surfaces are not pure black](#col-008--dark-surfaces-are-not-pure-black)
- [COL-009 — Pair foreground and background tokens](#col-009--pair-foreground-and-background-tokens)
- [COL-010 — Reserve the primary color for primary actions](#col-010--reserve-the-primary-color-for-primary-actions)
- [COL-011 — Verify contrast in every theme](#col-011--verify-contrast-in-every-theme)
- [COL-012 — No hardcoded color literals](#col-012--no-hardcoded-color-literals)
- [COL-013 — Visible focus indicator contrast](#col-013--visible-focus-indicator-contrast)
- [COL-014 — Distinguish disabled state perceptibly](#col-014--distinguish-disabled-state-perceptibly)
- [COL-015 — Placeholder text is not the only cue](#col-015--placeholder-text-is-not-the-only-cue)
- [COL-016 — Convey elevation with surface tint tokens](#col-016--convey-elevation-with-surface-tint-tokens)
- [COL-017 — Guarantee legibility over imagery](#col-017--guarantee-legibility-over-imagery)
- [COL-018 — Keep an accent palette disciplined](#col-018--keep-an-accent-palette-disciplined)
- [COL-019 — Status colors carry an icon and text](#col-019--status-colors-carry-an-icon-and-text)
- [COL-020 — Support high-contrast and forced-colors modes](#col-020--support-high-contrast-and-forced-colors-modes)

---

### COL-001 — Three token tiers
- **Rule:** Colors MUST be organized in three tiers: primitives (raw values, `color.blue.500`) → semantic roles (intent, `color.action.primary`, `color.surface`) → component tokens (scope, `button.primary.bg`). Each tier references only the tier above it.
- **Why:** Tiering separates palette from meaning from usage, enabling theming and rebranding without rewriting components.
- **Platforms:** all
- **Severity:** error
- **Check:** manual (token architecture review); `token_lint.py` for literals.
- **Exceptions:** None.
- **See also:** [[COL-002]], [[COL-012]]

### COL-002 — Components reference semantic roles only
- **Rule:** Components MUST reference semantic (or component) tokens, NEVER primitives directly. A button uses `color.action.primary`, never `color.blue.500`.
- **Why:** Binding components to intent-based roles is what lets a single theme swap recolor the entire app coherently.
- **Platforms:** all
- **Severity:** error
- **Check:** `token_lint.py` flags primitive references inside component/screen code.
- **Exceptions:** The semantic token layer, which is the only place primitives are referenced.
- **See also:** [[COL-001]], [[COL-010]]

### COL-003 — Never encode meaning with color alone
- **Rule:** Any information conveyed by color MUST also be conveyed by a second channel — text, icon, shape, pattern, or position. Never rely on hue alone (e.g. red/green) to signal state, validity, or category.
- **Why:** WCAG 1.4.1 — color-only meaning is invisible to color-blind users and in monochrome/high-contrast contexts.
- **Platforms:** all
- **Severity:** error
- **Check:** manual; cross-checked in `contrast_check.py` reports.
- **Exceptions:** None.
- **See also:** [[COL-019]], [[ICN-007]], [[CHT]]

### COL-004 — Normal text contrast ≥4.5:1
- **Rule:** Normal-size text MUST have a contrast ratio of at least 4.5:1 against its background (WCAG 2.2 AA, 1.4.3).
- **Why:** This is the AA legibility floor for standard text and the most common audit failure.
- **Platforms:** all
- **Severity:** error
- **Check:** `contrast_check.py`.
- **Exceptions:** Disabled text, pure decoration, and logotypes (1.4.3 incidental exceptions).
- **See also:** [[COL-005]], [[TYP-019]], [[COL-011]]

### COL-005 — Large text contrast ≥3:1
- **Rule:** Large text (≥24px, or ≥18.66px bold) MUST have a contrast ratio of at least 3:1 against its background.
- **Why:** Larger glyphs remain legible at a lower ratio, per WCAG 2.2 AA.
- **Platforms:** all
- **Severity:** error
- **Check:** `contrast_check.py`.
- **Exceptions:** Disabled/decorative text and logotypes.
- **See also:** [[COL-004]], [[TYP-019]]

### COL-006 — UI and icon contrast ≥3:1
- **Rule:** Meaningful non-text elements — icons, input borders, focus rings, control boundaries, chart strokes — MUST meet ≥3:1 contrast against adjacent colors (WCAG 2.2 1.4.11).
- **Why:** Users must be able to perceive the presence and boundaries of interactive and informational graphics.
- **Platforms:** all
- **Severity:** error
- **Check:** `contrast_check.py`.
- **Exceptions:** Purely decorative graphics that convey no information.
- **See also:** [[COL-013]], [[ICN-009]]

### COL-007 — Generate palettes with HCT tonal ramps
- **Rule:** Derive color palettes as tonal ramps (e.g. Material You / HCT tones 0–100) from seed colors so each role has a full, contrast-predictable range for light and dark. Do not hand-pick disconnected hex values per role.
- **Why:** Tonal palettes make contrast relationships systematic and provide the tones dark mode and elevation tinting require.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Fixed brand colors, which should still be placed on a generated ramp.
- **See also:** [[COL-001]], [[COL-016]]

### COL-008 — Dark surfaces are not pure black
- **Rule:** Dark-theme base surfaces MUST use a very dark neutral (≈#121212 or a dark tonal surface), not pure `#000000`. Text should be near-white, not pure `#FFFFFF`, to reduce halation.
- **Why:** Pure black/white maximizes eye strain and smearing on OLED and removes the tonal range needed for elevation overlays.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual; `contrast_check.py` verifies resulting ratios.
- **Exceptions:** Deliberate true-black themes for OLED power saving, still meeting contrast.
- **See also:** [[COL-016]], [[ELV-003]], [[DRK]]

### COL-009 — Pair foreground and background tokens
- **Rule:** Every surface/container token MUST have a matching "on-" foreground token (e.g. `surface` ↔ `on-surface`, `primary` ↔ `on-primary`) and components MUST use the paired foreground for content placed on that surface.
- **Why:** Explicit foreground/background pairs guarantee contrast holds when a surface color changes across themes.
- **Platforms:** all
- **Severity:** error
- **Check:** `contrast_check.py` validates token pairs; manual for pairing coverage.
- **Exceptions:** None.
- **See also:** [[COL-004]], [[COL-002]]

### COL-010 — Reserve the primary color for primary actions
- **Rule:** The primary/brand accent MUST be reserved for the single primary action and key emphasis on a view; do not paint large backgrounds, multiple buttons, or decorative areas with it.
- **Why:** Overusing the accent destroys the visual hierarchy that makes the primary action stand out.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Brand/marketing surfaces where the accent is intentionally dominant.
- **See also:** [[COL-018]], [[BTN]]

### COL-011 — Verify contrast in every theme
- **Rule:** Contrast MUST be validated independently for light, dark, and any high-contrast theme; a token that passes in one theme is not assumed to pass in another.
- **Why:** Foreground/background relationships invert between themes and can silently drop below AA.
- **Platforms:** all
- **Severity:** error
- **Check:** `contrast_check.py` run per theme.
- **Exceptions:** None.
- **See also:** [[COL-004]], [[COL-008]], [[DRK]]

### COL-012 — No hardcoded color literals
- **Rule:** Screens and components MUST NOT contain raw color literals (hex, `rgb()`, `Color(0xFF…)`, named colors); all color comes from tokens.
- **Why:** Hardcoded colors break theming, dark mode, and contrast guarantees and cannot be audited centrally.
- **Platforms:** all
- **Severity:** error
- **Check:** `token_lint.py` flags color literals.
- **Exceptions:** Token definition files; `transparent`.
- **See also:** [[COL-001]], [[COL-002]]

### COL-013 — Visible focus indicator contrast
- **Rule:** Keyboard/focus and selection indicators MUST be clearly visible with ≥3:1 contrast against both the component and its background, and MUST NOT be removed. Focus must also not be obscured (WCAG 2.2 2.4.11/2.4.13).
- **Why:** Focus visibility is essential for keyboard, switch, and external-keyboard users on mobile and tablets.
- **Platforms:** all
- **Severity:** error
- **Check:** `contrast_check.py` (focus token pairs); manual.
- **Exceptions:** None.
- **See also:** [[COL-006]], [[A11Y]]

### COL-014 — Distinguish disabled state perceptibly
- **Rule:** Disabled controls are exempt from the 4.5:1/3:1 minimums but MUST still be clearly distinguishable from enabled controls (e.g. reduced opacity token + removed affordance), and disabled state must not be the only signal a control is unavailable.
- **Why:** Disabled elements are excluded from contrast rules, but users still need to perceive that they exist and are inactive.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual.
- **Exceptions:** None.
- **See also:** [[COL-004]], [[BTN]]

### COL-015 — Placeholder text is not the only cue
- **Rule:** Placeholder text MUST meet contrast if used to convey information and MUST NOT be the only label for a field; provide a persistent visible label. Prefer 4.5:1 for placeholders that carry hints.
- **Why:** Placeholder-only labels disappear on input and low-contrast placeholders fail legibility.
- **Platforms:** all
- **Severity:** warning
- **Check:** `contrast_check.py`; manual for label presence.
- **Exceptions:** Search fields with a persistent icon + accessible label.
- **See also:** [[COL-004]], [[FRM]]

### COL-016 — Convey elevation with surface tint tokens
- **Rule:** In Material contexts, express elevation in dark mode by applying tonal surface tint tokens (higher surfaces lighter), not by darkening or by shadow alone. Map each elevation level to a surface-tint token.
- **Why:** Shadows are nearly invisible on dark backgrounds; tonal overlays are how M3 signals depth in dark themes.
- **Platforms:** android
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** iOS, which uses materials/blur instead of tonal elevation.
- **See also:** [[ELV-003]], [[COL-008]]

### COL-017 — Guarantee legibility over imagery
- **Rule:** Text placed over images or video MUST sit on a scrim, gradient, or solid backing sufficient to meet its contrast minimum against the worst-case pixels behind it. Never place raw text on uncontrolled imagery.
- **Why:** Image backgrounds vary per photo; without a scrim, contrast is unpredictable and often fails AA.
- **Platforms:** all
- **Severity:** error
- **Check:** manual; spot-check with `contrast_check.py` against scrim color.
- **Exceptions:** None.
- **See also:** [[COL-004]], [[MEDIA]]

### COL-018 — Keep an accent palette disciplined
- **Rule:** Limit the app to a small, tokenized accent set (typically 1 primary + 1 secondary/tertiary + neutrals + status colors). Do not introduce arbitrary one-off colors per screen.
- **Why:** A constrained palette reads as a coherent brand; unlimited colors look chaotic and untrustworthy.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Data-visualization categorical palettes designed for distinguishability.
- **See also:** [[COL-010]], [[CHT]]

### COL-019 — Status colors carry an icon and text
- **Rule:** Success/warning/error/info states MUST use their semantic status token PLUS a distinct icon and text label; never signal status by color swatch alone. Error is not "red-only."
- **Why:** Reinforces [[COL-003]] for the highest-stakes signals, where misreading state has real consequences.
- **Platforms:** all
- **Severity:** error
- **Check:** manual.
- **Exceptions:** None.
- **See also:** [[COL-003]], [[BDG]], [[FRM]]

### COL-020 — Support high-contrast and forced-colors modes
- **Rule:** Respect OS high-contrast / increased-contrast / forced-colors settings by exposing a high-contrast theme or honoring system color overrides; do not fight or override them with fixed colors.
- **Why:** Users who enable increased contrast rely on the app honoring it; overriding harms the users who need it most.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** None.
- **See also:** [[COL-011]], [[A11Y]]
