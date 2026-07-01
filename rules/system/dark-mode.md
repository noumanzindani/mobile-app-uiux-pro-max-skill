# Dark Mode (DRK)

> Ship a real dark theme through the semantic token layer: dark-grey (not pure black) surfaces, elevation-as-overlay, per-theme contrast verification, and no theme flash on launch.

## Table of contents
- Theme architecture — DRK-001, DRK-002, DRK-008, DRK-011
- Color & contrast in dark — DRK-003, DRK-004, DRK-006, DRK-007, DRK-012
- Depth & assets — DRK-005, DRK-009, DRK-010

---

### DRK-001 — Provide a purpose-built dark theme
- **Rule:** Apps MUST ship a genuine dark theme with its own color values, not an automatic/programmatic inversion of the light palette. Every screen and component MUST be verified in dark.
- **Why:** Naive inversion breaks brand colors, imagery, and contrast; dark mode is now an expected baseline, not a nice-to-have.
- **Platforms:** all
- **Severity:** error
- **Check:** Manual dark-theme sweep of all screens; `theme_audit` verifies a dedicated dark token set exists.
- **Exceptions:** None for consumer apps; internal tools may defer with justification.
- **See also:** [[DRK-002]], [[DRK-004]]

### DRK-002 — Theme via the semantic token layer only
- **Rule:** Components MUST reference semantic role tokens (`color.surface`, `color.onSurface`, `color.action.primary`), never raw primitives or hardcoded hex. Both light and dark themes resolve the same semantic roles to theme-specific values.
- **Why:** A semantic layer is what makes a single component correct in every theme without per-widget conditionals; hardcoded colors defeat theming.
- **Platforms:** all
- **Severity:** error
- **Check:** `token_lint.py` flags hardcoded color literals and primitive references in components.
- **Exceptions:** Token-definition files themselves.
- **See also:** [[DRK-001]], [[COL-001]], [[COL-002]]

### DRK-003 — Dark surfaces are dark grey, not pure black
- **Rule:** The base dark surface MUST be a dark grey (Material baseline `#121212`-class), not pure `#000000`. Reserve pure black for OLED-specific/AMOLED opt-in themes only.
- **Why:** Pure black maximizes halation/smearing on OLED, makes elevation overlays invisible, and produces harsh contrast that fatigues the eye.
- **Platforms:** all
- **Severity:** warning
- **Check:** `theme_audit` checks the base dark surface token is not `#000000`.
- **Exceptions:** A deliberate, user-selectable AMOLED/black theme.
- **See also:** [[DRK-005]], [[DRK-012]]

### DRK-004 — Re-verify contrast in the dark theme
- **Rule:** Contrast MUST be re-checked independently in dark; do not assume light-theme pairs pass. All text/icon/component pairs meet the same AA floors ([[A11Y-001]], [[A11Y-002]], [[A11Y-003]]) using dark-theme values.
- **Why:** A pair that passes on light can fail on dark (and vice versa); each theme is a separate contrast surface.
- **Platforms:** all
- **Severity:** error
- **Check:** `contrast_check.py --theme dark` over resolved dark token pairs.
- **Exceptions:** Same as [[A11Y-001]].
- **See also:** [[A11Y-001]], [[A11Y-003]], [[DRK-007]]

### DRK-005 — Convey elevation with lighter overlays, not shadows
- **Rule:** In dark themes, express elevation by lightening the surface (Material elevation-overlay / surface-tint at higher levels), since drop shadows are nearly invisible on dark backgrounds. Higher elevation = lighter surface.
- **Why:** Shadow-based depth disappears in dark mode; overlay tinting restores the depth hierarchy users rely on.
- **Platforms:** all
- **Severity:** warning
- **Check:** `theme_audit` verifies elevated surface tokens lighten with level in dark.
- **Exceptions:** Flat designs that avoid elevation entirely.
- **See also:** [[DRK-003]], [[ELV-002]]

### DRK-006 — Support a high-contrast dark variant
- **Rule:** Provide a high-contrast dark theme (or respond to Increase Contrast) that raises text/border contrast above the standard dark palette, wired to the same semantic roles.
- **Why:** Low-vision users who need dark AND high contrast are otherwise unserved; the OS setting must have an effect.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** Manual toggle of Increase Contrast in dark; `theme_audit` for a high-contrast token set.
- **Exceptions:** Standard dark theme already exceeds AAA everywhere.
- **See also:** [[A11Y-030]], [[DRK-004]]

### DRK-007 — Desaturate/adjust accent colors for dark
- **Rule:** Vivid, saturated accent colors from light mode MUST be softened (lighter, less saturated tones) for dark surfaces so they meet contrast without vibrating against the dark background.
- **Why:** Highly saturated hues on dark backgrounds cause optical vibration and eye strain and often fail contrast.
- **Platforms:** all
- **Severity:** warning
- **Check:** `contrast_check.py` on dark accent tokens; manual eye-strain review.
- **Exceptions:** Brand-critical accents where contrast is still met.
- **See also:** [[DRK-004]], [[COL-005]]

### DRK-008 — Follow the system theme by default, with in-app override
- **Rule:** The app MUST default to the OS light/dark setting and offer an explicit in-app control for Light / Dark / System.
- **Why:** Users expect apps to match their system preference automatically, while some want a per-app override.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual: change OS theme → app follows; verify Light/Dark/System setting exists.
- **Exceptions:** Single-theme brand experiences (rare) with justification.
- **See also:** [[DRK-011]], [[SET-006]]

### DRK-009 — Theme-aware images, illustrations & logos
- **Rule:** Images/illustrations/logos MUST have dark-appropriate variants or adaptive treatment; avoid white logos on white cards or hard white rectangles bleeding into dark surfaces. Provide theme-specific assets or transparent PNG/SVG that adapt.
- **Why:** Light-only artwork looks broken and glares on dark backgrounds, harming polish and legibility.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual dark-theme review of all imagery/logos.
- **Exceptions:** Full-bleed photography meant to display identically in both themes.
- **See also:** [[DRK-003]], [[AVT-002]]

### DRK-010 — System chrome matches the theme
- **Rule:** Status bar, navigation bar, and system-bar icon styles MUST match the active theme (light icons on dark, dark on light), with no mismatched bright bars in dark mode.
- **Why:** A white status bar over a dark app (or invisible icons) looks unfinished and can hide system indicators.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual review of status/nav bar per theme.
- **Exceptions:** Immersive/full-screen modes that hide system bars.
- **See also:** [[PLAT-019]], [[DRK-008]]

### DRK-011 — No theme flash on launch
- **Rule:** Persist the resolved theme and apply it before the first frame so the app never flashes the wrong theme (e.g., white splash → dark UI). Native splash and initial background match the resolved theme.
- **Why:** A bright flash in a dark environment is jarring and signals low quality.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual cold launch in dark mode; watch for light flash.
- **Exceptions:** None.
- **See also:** [[DRK-008]], [[PERF-016]]

### DRK-012 — Avoid large pure-white areas in dark mode
- **Rule:** Do not render full-screen or large pure-white blocks in dark mode; use dark surfaces with elevated dialogs/sheets slightly lighter than the base. Keep bright fills to small, intentional highlights.
- **Why:** Big white areas defeat the purpose of dark mode, cause glare in low light, and spike power on OLED.
- **Platforms:** all
- **Severity:** warning
- **Check:** Manual dark sweep for large white surfaces.
- **Exceptions:** Content that is inherently white (e.g., a document/photo canvas), ideally with a dim toggle.
- **See also:** [[DRK-003]], [[DRK-005]]
