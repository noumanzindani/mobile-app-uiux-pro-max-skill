# Spacing & Layout Grid (SPC)

> Purpose: Enforce a token-driven 4/8pt spacing system so every margin, padding, and gap produces consistent optical rhythm and correct touch density across iOS and Android.

## Contents
- [SPC-001 — Snap spacing to the 4/8pt grid](#spc-001--snap-spacing-to-the-48pt-grid)
- [SPC-002 — Use the canonical spacing scale](#spc-002--use-the-canonical-spacing-scale)
- [SPC-003 — Screen edge margins](#spc-003--screen-edge-margins)
- [SPC-004 — Reference spacing tokens, never literals](#spc-004--reference-spacing-tokens-never-literals)
- [SPC-005 — Minimum gap between touch targets](#spc-005--minimum-gap-between-touch-targets)
- [SPC-006 — Section spacing and vertical rhythm](#spc-006--section-spacing-and-vertical-rhythm)
- [SPC-007 — Component internal padding](#spc-007--component-internal-padding)
- [SPC-008 — List row padding and minimum row height](#spc-008--list-row-padding-and-minimum-row-height)
- [SPC-009 — Proximity: relate with space, not lines](#spc-009--proximity-relate-with-space-not-lines)
- [SPC-010 — Consistent gaps over ad-hoc margins](#spc-010--consistent-gaps-over-ad-hoc-margins)
- [SPC-011 — Safe-area insets are additive and dynamic](#spc-011--safe-area-insets-are-additive-and-dynamic)
- [SPC-012 — Icon-to-label gap](#spc-012--icon-to-label-gap)
- [SPC-013 — Form field spacing](#spc-013--form-field-spacing)
- [SPC-014 — Do not compound padding off-grid](#spc-014--do-not-compound-padding-off-grid)
- [SPC-015 — Keyline alignment of content edges](#spc-015--keyline-alignment-of-content-edges)
- [SPC-016 — Bottom inset above the home indicator](#spc-016--bottom-inset-above-the-home-indicator)
- [SPC-017 — Whitespace is functional, not filler](#spc-017--whitespace-is-functional-not-filler)
- [SPC-018 — Scale margins with size class](#spc-018--scale-margins-with-size-class)

---

### SPC-001 — Snap spacing to the 4/8pt grid
- **Rule:** All margins, padding, and gaps MUST be multiples of 4dp/pt; prefer 8dp steps for anything ≥8. Sub-4 values are only permitted for hairline borders (1px) and optical glyph nudges.
- **Why:** A shared base unit produces predictable optical rhythm and keeps layouts consistent across iOS and Android densities.
- **Platforms:** all
- **Severity:** error
- **Check:** `token_lint.py` flags off-grid spacing literals.
- **Exceptions:** 1px hairlines; dynamically read platform insets; ±1pt optical alignment of vector glyphs.
- **See also:** [[SPC-002]], [[GRD-001]], [[DEN-002]]

### SPC-002 — Use the canonical spacing scale
- **Rule:** Spacing values MUST come from the fixed scale `4, 8, 12, 16, 24, 32, 48, 64`. Do not invent intermediate values such as 10, 14, 18, 20, or 30.
- **Why:** A closed scale prevents drift into dozens of near-duplicate values and makes spacing decisions token lookups instead of guesses.
- **Platforms:** all
- **Severity:** error
- **Check:** `token_lint.py` rejects spacing literals outside the scale token set.
- **Exceptions:** Continuous, computed values (e.g. flex distribution, `space-between`) that resolve at runtime.
- **See also:** [[SPC-001]], [[SPC-004]]

### SPC-003 — Screen edge margins
- **Rule:** Root screen content MUST use horizontal edge margins of 16–20pt on iOS and 16dp on Android, applied via a single layout token, not per-widget padding.
- **Why:** Consistent edge margins define the content column and match each platform's default gutter expectation.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — verify root container margin token; `token_lint.py` flags literal edge padding.
- **Exceptions:** Full-bleed media, edge-to-edge lists, and carousels that intentionally run to the screen edge.
- **See also:** [[SPC-015]], [[GRD-006]], [[SPC-018]]

### SPC-004 — Reference spacing tokens, never literals
- **Rule:** Layout code MUST reference named spacing tokens (e.g. `space.md`, `space.4`) rather than raw numbers so the scale can be retuned centrally.
- **Why:** Token indirection is what makes density switching, theming, and global re-spacing possible without touching every screen.
- **Platforms:** all
- **Severity:** error
- **Check:** `token_lint.py` flags numeric spacing literals in component/layout source.
- **Exceptions:** The token definition files themselves; `0` and `1px` hairlines.
- **See also:** [[SPC-002]], [[DEN-005]]

### SPC-005 — Minimum gap between touch targets
- **Rule:** Adjacent interactive elements MUST have at least 8dp of clear space between their touchable bounds (target the full 44pt/48dp hit area, not just the visible glyph).
- **Why:** Sub-8dp gaps cause mis-taps and fail WCAG 2.2 target-spacing expectations, especially for larger fingers and motor impairments.
- **Platforms:** all
- **Severity:** error
- **Check:** `target_size_lint.py` measures inter-target spacing.
- **Exceptions:** Segmented controls and connected button groups that are a single logical control.
- **See also:** [[ICN-001]], [[SPC-012]]

### SPC-006 — Section spacing and vertical rhythm
- **Rule:** Separate major content sections with 24–32dp of vertical space; keep 8–16dp between grouped items within a section. Section spacing MUST always exceed intra-group spacing.
- **Why:** A clear spacing ratio communicates hierarchy through proximity without needing dividers or boxes.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Deliberately dense data views governed by density tokens.
- **See also:** [[SPC-009]], [[DEN-003]]

### SPC-007 — Component internal padding
- **Rule:** Interactive containers MUST use grid-aligned internal padding: buttons ≥16dp horizontal / ≥12dp vertical, cards 16dp, list content insets 16dp leading. Padding comes from component tokens.
- **Why:** Consistent internal padding gives components a uniform feel and guarantees the visible label sits inside a compliant touch target.
- **Platforms:** all
- **Severity:** warning
- **Check:** `token_lint.py` for padding literals; manual for values.
- **Exceptions:** Icon-only compact controls that still meet [[ICN-001]].
- **See also:** [[SPC-004]], [[BTN]], [[CRD]]

### SPC-008 — List row padding and minimum row height
- **Rule:** List/table rows MUST be at least 44pt (iOS) / 48dp (Android) tall, with ≥12dp vertical content padding, so the entire row is a valid touch target.
- **Why:** Rows are the most-tapped surface in mobile UIs; short rows create mis-taps and fail minimum target size.
- **Platforms:** all
- **Severity:** error
- **Check:** `target_size_lint.py`.
- **Exceptions:** Non-interactive display-only rows (still keep ≥40dp for legibility).
- **See also:** [[SPC-005]], [[LST]]

### SPC-009 — Proximity: relate with space, not lines
- **Rule:** Group related elements by reducing the space between them and increasing space to unrelated groups; do not add dividers or borders where a spacing difference already communicates grouping.
- **Why:** Whitespace is a cheaper, cleaner grouping signal than chrome and reduces visual clutter.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual.
- **Exceptions:** Dividers required for scannability in dense lists/tables or by platform convention (e.g. grouped table sections).
- **See also:** [[SPC-006]], [[ELV-006]]

### SPC-010 — Consistent gaps over ad-hoc margins
- **Rule:** Use a single gap token between siblings (via a stack/spacer) instead of per-child margins; never mix top and bottom margins to space the same axis.
- **Why:** One-directional, tokenized gaps prevent collapsing-margin bugs and off-grid totals.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** None.
- **See also:** [[SPC-014]], [[SPC-004]]

### SPC-011 — Safe-area insets are additive and dynamic
- **Rule:** Read safe-area/system insets at runtime and ADD them to design margins; never hardcode status-bar, notch, or navigation-bar offsets. Use the framework safe-area primitive (`SafeArea`, `safe-area-context`, `.safeAreaInset`, `WindowInsets`).
- **Why:** Insets vary by device and orientation; hardcoding them clips content or wastes space on the wrong hardware.
- **Platforms:** all
- **Severity:** error
- **Check:** `rtl_check.py`/manual for hardcoded inset constants (e.g. `44`, `34`, `24` used as status/home offsets).
- **Exceptions:** None.
- **See also:** [[SPC-016]], [[GRD-012]], [[GRD-016]]

### SPC-012 — Icon-to-label gap
- **Rule:** Place exactly 8dp between an icon and its adjacent text label (buttons, list rows, chips). Do not use 4dp (too tight) or 12dp+ (visually disconnected).
- **Why:** A consistent 8dp pairing keeps icon+label combos reading as one unit across the app.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual.
- **Exceptions:** Large hero/marketing layouts with intentionally looser spacing.
- **See also:** [[SPC-002]], [[ICN-004]]

### SPC-013 — Form field spacing
- **Rule:** Stack form fields with 16dp vertical gaps; keep label-to-input at 4–8dp and input-to-helper/error at 4dp, so a field and its metadata read as one cluster.
- **Why:** Tight label/helper coupling plus a clear inter-field gap makes long forms scannable and reduces mis-association of errors.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Multi-column tablet forms governed by [[GRD-007]].
- **See also:** [[SPC-009]], [[FRM]]

### SPC-014 — Do not compound padding off-grid
- **Rule:** When nesting padded containers, ensure the SUM of nested paddings still lands on the 4/8pt grid; avoid stacking a 16 inside a 12 inside an 8 that yields off-grid content offsets.
- **Why:** Compounded paddings silently push content off the grid and misalign it with adjacent columns.
- **Platforms:** all
- **Severity:** warning
- **Check:** `token_lint.py`/manual.
- **Exceptions:** None.
- **See also:** [[SPC-001]], [[SPC-015]]

### SPC-015 — Keyline alignment of content edges
- **Rule:** All primary content (titles, body, list text, inputs) MUST align to a single leading keyline defined by the screen edge margin; icons and avatars align to their own consistent keyline.
- **Why:** A shared vertical keyline creates a clean reading edge and makes the layout feel engineered rather than ad hoc.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Intentionally indented hierarchies (nested lists, threaded replies).
- **See also:** [[SPC-003]], [[GRD-013]]

### SPC-016 — Bottom inset above the home indicator
- **Rule:** Bottom-pinned actions and bars MUST sit above the home-indicator / gesture-navigation inset (≈34pt iOS) read from the safe area, with ≥8dp additional clearance so the control is not crowded by the system gesture zone.
- **Why:** Content under the home indicator conflicts with the system swipe gesture and is hard to tap one-handed.
- **Platforms:** all
- **Severity:** error
- **Check:** manual; `target_size_lint.py` for bottom-bar target clearance.
- **Exceptions:** None.
- **See also:** [[SPC-011]], [[GES]]

### SPC-017 — Whitespace is functional, not filler
- **Rule:** Do not add empty space merely to fill a screen; every gap should express grouping, hierarchy, or breathing room. Conversely, do not remove required minimum spacing to cram in content.
- **Why:** Purposeful whitespace improves comprehension and perceived quality; arbitrary whitespace wastes valuable mobile real estate.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual.
- **Exceptions:** None.
- **See also:** [[SPC-006]], [[DEN-002]]

### SPC-018 — Scale margins with size class
- **Rule:** Increase edge margins/gutters at wider breakpoints (16dp compact → 24dp medium → 24–32dp expanded) via responsive tokens rather than stretching a single column full-width.
- **Why:** Fixed small margins on large screens produce fatiguing full-width text; scaling gutters preserves a readable measure.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Full-bleed media and immersive layouts.
- **See also:** [[SPC-003]], [[GRD-006]], [[GRD-008]]
