# Charts & Data Visualization (CHT)

> Rules for charts and graphs: never color-only encoding, a data-table accessibility fallback, direct labeling, touch-friendly interaction, and honest scales.

## Contents
- [CHT-001 — Never encode meaning by color alone](#cht-001--never-encode-meaning-by-color-alone)
- [CHT-002 — Provide a data-table accessibility fallback](#cht-002--provide-a-data-table-accessibility-fallback)
- [CHT-003 — Give the chart an accessible summary](#cht-003--give-the-chart-an-accessible-summary)
- [CHT-004 — Label series directly; don't rely on a legend alone](#cht-004--label-series-directly-dont-rely-on-a-legend-alone)
- [CHT-005 — Use a colorblind-safe categorical palette](#cht-005--use-a-colorblind-safe-categorical-palette)
- [CHT-006 — Meet non-text contrast for marks and axes](#cht-006--meet-non-text-contrast-for-marks-and-axes)
- [CHT-007 — Interactive points meet the touch-target minimum](#cht-007--interactive-points-meet-the-touch-target-minimum)
- [CHT-008 — Tooltips/scrubbing have a non-gesture alternative](#cht-008--tooltipsscrubbing-have-a-non-gesture-alternative)
- [CHT-009 — Don't mislead with truncated or dual axes](#cht-009--dont-mislead-with-truncated-or-dual-axes)
- [CHT-010 — Format numbers, units, and dates for locale](#cht-010--format-numbers-units-and-dates-for-locale)
- [CHT-011 — Loading, empty, and error states](#cht-011--loading-empty-and-error-states)
- [CHT-012 — Honor reduce-motion in chart animation](#cht-012--honor-reduce-motion-in-chart-animation)
- [CHT-013 — Style charts from tokens](#cht-013--style-charts-from-tokens)
- [CHT-014 — Keep dense charts legible and responsive](#cht-014--keep-dense-charts-legible-and-responsive)

---

### CHT-001 — Never encode meaning by color alone
- **Rule:** Categories, series, and thresholds MUST be distinguishable by a redundant channel — shape/marker, line style, direct label, pattern, or position — in addition to color.
- **Why:** WCAG 2.2 SC 1.4.1; ~8% of men are color-blind and cannot separate color-only series.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — render the chart in grayscale and confirm it's still readable.
- **Exceptions:** None.
- **See also:** [[A11Y-010]], [[CHT-004]], [[CHT-005]]

### CHT-002 — Provide a data-table accessibility fallback
- **Rule:** Every chart MUST offer an accessible equivalent of the underlying data — an adjacent/toggleable data table or a structured accessible representation — reachable by assistive tech.
- **Why:** Canvas/SVG charts are opaque to screen readers; the data itself must be perceivable (WCAG 1.1.1).
- **Platforms:** all
- **Severity:** error
- **Check:** a11y audit — is the data available non-visually?
- **Exceptions:** None.
- **See also:** [[TAB-006]], [[CHT-003]]

### CHT-003 — Give the chart an accessible summary
- **Rule:** Charts MUST expose a concise text summary of what they show and the key takeaway (trend, max/min) as their accessible name/description.
- **Why:** A summary conveys the insight quickly to non-visual users and cognitively benefits everyone.
- **Platforms:** all
- **Severity:** warning
- **Check:** a11y audit.
- **Exceptions:** None.
- **See also:** [[A11Y-004]], [[CHT-002]]

### CHT-004 — Label series directly; don't rely on a legend alone
- **Rule:** Where space allows, series SHOULD be labeled directly at the line/segment end or on the mark; a separate legend MUST NOT be the only way to map color to meaning.
- **Why:** Direct labeling removes the color-matching lookup and helps color-blind users.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual.
- **Exceptions:** Very dense multi-series charts where direct labels would overlap — then ensure non-color legend cues (CHT-001).
- **See also:** [[CHT-001]], [[CHT-014]]

### CHT-005 — Use a colorblind-safe categorical palette
- **Rule:** Categorical series MUST use a palette designed to remain distinguishable under common color-vision deficiencies (avoid red/green as the only differentiator) and reference chart color tokens.
- **Why:** Reduces reliance on redundant encoding and improves clarity for all users.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — simulate deuteranopia/protanopia.
- **Exceptions:** None.
- **See also:** [[COL-001]], [[CHT-001]]

### CHT-006 — Meet non-text contrast for marks and axes
- **Rule:** Data marks, axis lines, and their labels MUST meet contrast minimums — ≥3:1 for graphical marks/axes against the background and ≥4.5:1 for value/axis text.
- **Why:** WCAG 1.4.11/1.4.3; faint chart lines are unreadable for low-vision users.
- **Platforms:** all
- **Severity:** warning
- **Check:** `contrast_check.py`.
- **Exceptions:** Adjacent overlapping series distinguished by ≥3:1 from each other where a shared background isn't the reference.
- **See also:** [[A11Y-002]], [[CHT-013]]

### CHT-007 — Interactive points meet the touch-target minimum
- **Rule:** Tappable data points, bars, and legend toggles MUST have a hit area ≥44pt/48dp (expand the touch region beyond the visual mark).
- **Why:** Small data points are impossible to tap accurately.
- **Platforms:** all
- **Severity:** warning
- **Check:** `target_size_lint.py`.
- **Exceptions:** Read-only static charts with no interaction.
- **See also:** [[A11Y-003]], [[CHT-008]]

### CHT-008 — Tooltips/scrubbing have a non-gesture alternative
- **Rule:** Values revealed only by hover/scrub/drag MUST also be reachable without a continuous gesture — via tap on a point, an accessible data table, or focusable values.
- **Why:** WCAG 2.5.7 (dragging) and 2.5.1; scrub-only value reveal excludes motor-impaired and screen-reader users.
- **Platforms:** all
- **Severity:** warning
- **Check:** a11y audit + manual.
- **Exceptions:** None.
- **See also:** [[A11Y-012]], [[CHT-002]]

### CHT-009 — Don't mislead with truncated or dual axes
- **Rule:** Bar-chart value axes MUST start at zero (or clearly annotate a truncated axis); dual/independent Y-axes and non-linear scales MUST be labeled to avoid implying false magnitude or correlation.
- **Why:** Truncated/misleading axes distort the story and erode trust; a data-viz honesty requirement.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Line/area trend charts where a non-zero baseline is standard and clearly scaled.
- **See also:** [[CHT-010]], [[CHT-014]]

### CHT-010 — Format numbers, units, and dates for locale
- **Rule:** Axis values, tooltips, and labels MUST use locale-aware number/currency/date formatting, explicit units, and thousands/decimal separators — never hardcoded formats.
- **Why:** Ambiguous or wrongly formatted numbers cause misreads across locales (WCAG/L10N).
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — switch locale.
- **Exceptions:** None.
- **See also:** [[L10N-001]], [[TAB-005]]

### CHT-011 — Loading, empty, and error states
- **Rule:** Charts MUST implement a loading (skeleton/placeholder), a distinct empty/no-data state (explaining why and what to do), and an error state with retry.
- **Why:** The 7-state model; a blank chart area reads as broken.
- **Platforms:** all
- **Severity:** error
- **Check:** `state_coverage.py`.
- **Exceptions:** None.
- **See also:** [[STATE-002]], [[STATE-003]]

### CHT-012 — Honor reduce-motion in chart animation
- **Rule:** Entrance/transition animations (bars growing, lines drawing) MUST be reduced or disabled when reduce-motion is enabled, rendering the final state directly.
- **Why:** WCAG 2.3.3; motion can cause discomfort and delays access to the data.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — enable reduce-motion.
- **Exceptions:** None.
- **See also:** [[A11Y-009]], [[MOT-002]]

### CHT-013 — Style charts from tokens
- **Rule:** Series colors, gridline colors, axis colors, and typography MUST reference chart/semantic tokens; no hardcoded hex values, so charts theme across light/dark/high-contrast.
- **Why:** Token binding keeps data-viz consistent and theme-aware.
- **Platforms:** all
- **Severity:** error
- **Check:** `token_lint.py`.
- **Exceptions:** None.
- **See also:** [[COL-001]], [[DRK-001]]

### CHT-014 — Keep dense charts legible and responsive
- **Rule:** Charts MUST reduce density on small widths (thin labels, aggregate, or enable horizontal scroll) so axis labels don't overlap and marks stay tappable; text MUST scale with Dynamic Type without clipping.
- **Why:** Overcrowded phone charts are unreadable; responsive density preserves the insight.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual at small widths and large font scales.
- **Exceptions:** None.
- **See also:** [[GRD-002]], [[A11Y-008]]
