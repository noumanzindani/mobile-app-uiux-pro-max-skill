# Tables & Data Grids (TAB)

> Rules for tabular data on mobile: prefer cards on compact widths, sticky headers, horizontal-scroll affordance, numeric alignment, and accessible table semantics.

## Contents
- [TAB-001 — Prefer cards/list rows on compact widths](#tab-001--prefer-cardslist-rows-on-compact-widths)
- [TAB-002 — Keep a sticky header row](#tab-002--keep-a-sticky-header-row)
- [TAB-003 — Signal and support horizontal scroll](#tab-003--signal-and-support-horizontal-scroll)
- [TAB-004 — Freeze the identifying first column](#tab-004--freeze-the-identifying-first-column)
- [TAB-005 — Right-align numbers with tabular figures](#tab-005--right-align-numbers-with-tabular-figures)
- [TAB-006 — Expose table semantics with header associations](#tab-006--expose-table-semantics-with-header-associations)
- [TAB-007 — Sort state is explicit and not color-only](#tab-007--sort-state-is-explicit-and-not-color-only)
- [TAB-008 — Interactive cells meet the target minimum](#tab-008--interactive-cells-meet-the-target-minimum)
- [TAB-009 — Virtualize long tables](#tab-009--virtualize-long-tables)
- [TAB-010 — Loading, empty, and error states](#tab-010--loading-empty-and-error-states)
- [TAB-011 — Zebra/grid lines meet ≥3:1 when load-bearing](#tab-011--zebragrid-lines-meet-31-when-load-bearing)
- [TAB-012 — Style tables from tokens](#tab-012--style-tables-from-tokens)

---

### TAB-001 — Prefer cards/list rows on compact widths
- **Rule:** Below the compact breakpoint (<600dp), multi-column tables SHOULD be reflowed into stacked cards or key-value list rows rather than shown as a wide, pinch-to-read grid.
- **Why:** Dense grids are unusable on phones; card reflow keeps each record readable one-handed.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual at <600dp.
- **Exceptions:** Genuinely spreadsheet-like tools where the grid is the point (still apply TAB-003/TAB-004).
- **See also:** [[GRD-002]], [[CRD-001]]

### TAB-002 — Keep a sticky header row
- **Rule:** Scrolling tables MUST pin the header row so column meaning stays visible while the body scrolls vertically.
- **Why:** Without a sticky header, users lose track of what each column means.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — scroll the body.
- **Exceptions:** Tables short enough to fit without vertical scroll.
- **See also:** [[LST-011]], [[TAB-006]]

### TAB-003 — Signal and support horizontal scroll
- **Rule:** When a table is wider than the viewport, it MUST scroll horizontally with a visible affordance (edge fade/shadow, partial next column, or scrollbar) so users know more columns exist off-screen.
- **Why:** Hidden columns with no affordance are undiscoverable.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual on a narrow width.
- **Exceptions:** Tables that fit fully on screen.
- **See also:** [[TAB-004]], [[CHP-005]]

### TAB-004 — Freeze the identifying first column
- **Rule:** In horizontally scrolling tables, the first (identifying) column SHOULD stay frozen/pinned so each row remains identifiable as other columns scroll.
- **Why:** Scrolling away the row label makes the remaining cells meaningless.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual.
- **Exceptions:** Tables with no single identifying column.
- **See also:** [[TAB-003]], [[TAB-002]]

### TAB-005 — Right-align numbers with tabular figures
- **Rule:** Numeric columns MUST be right-aligned (or decimal-aligned) and use tabular/monospaced figures so digits line up by place value; currency/units are consistent within a column.
- **Why:** Right-aligned tabular numerals make magnitudes comparable at a glance and prevent misreading.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — inspect numeric column alignment and font feature.
- **Exceptions:** None.
- **See also:** [[TYP-008]], [[CHT-010]]

### TAB-006 — Expose table semantics with header associations
- **Rule:** Data tables MUST expose row/column header associations to assistive tech so a screen reader announces the relevant header(s) when reading each cell.
- **Why:** Without header association, cell values are meaningless out of context (WCAG 1.3.1).
- **Platforms:** all
- **Severity:** error
- **Check:** a11y audit.
- **Exceptions:** Purely presentational layout grids (which should not use table semantics).
- **See also:** [[A11Y-005]], [[TAB-002]]

### TAB-007 — Sort state is explicit and not color-only
- **Rule:** Sortable columns MUST show current sort direction with an icon/arrow (not color alone), expose the sort state to assistive tech, and give the header a ≥44pt/48dp tap target.
- **Why:** Users must know which column/direction is active; WCAG 1.4.1 and target size.
- **Platforms:** all
- **Severity:** warning
- **Check:** a11y audit + `target_size_lint.py`.
- **Exceptions:** Non-sortable tables.
- **See also:** [[A11Y-010]], [[TAB-008]]

### TAB-008 — Interactive cells meet the target minimum
- **Rule:** Tappable cells, row-select checkboxes, and header controls MUST each be ≥44pt/48dp with ≥8dp spacing, even when visual row density is tighter.
- **Why:** Dense tables tempt sub-minimum targets; padded hit areas keep them usable.
- **Platforms:** all
- **Severity:** error
- **Check:** `target_size_lint.py`.
- **Exceptions:** None.
- **See also:** [[A11Y-003]], [[LST-002]]

### TAB-009 — Virtualize long tables
- **Rule:** Tables that can exceed the viewport MUST virtualize rows using the framework's lazy list primitive rather than rendering all rows.
- **Why:** Rendering thousands of rows breaks the frame budget and memory.
- **Platforms:** all
- **Severity:** error
- **Check:** manual / code review.
- **Exceptions:** Small fixed tables.
- **See also:** [[LST-001]], [[PERF-002]]

### TAB-010 — Loading, empty, and error states
- **Rule:** Data tables MUST implement skeleton loading, a distinct empty state (with guidance), and an error state with retry — not a bare header over a blank body.
- **Why:** The 7-state model applies to tabular data too.
- **Platforms:** all
- **Severity:** error
- **Check:** `state_coverage.py`.
- **Exceptions:** None.
- **See also:** [[STATE-002]], [[STATE-003]]

### TAB-011 — Zebra/grid lines meet ≥3:1 when load-bearing
- **Rule:** When zebra striping or grid lines are the primary means of separating rows/columns, they MUST provide ≥3:1 contrast against the cell background.
- **Why:** WCAG 1.4.11; faint separators disappear for low-vision users and in bright light.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** `contrast_check.py`.
- **Exceptions:** Adequate spacing used instead of lines.
- **See also:** [[A11Y-002]], [[LST-016]]

### TAB-012 — Style tables from tokens
- **Rule:** Row height, padding, header background, borders, and stripe colors MUST reference tokens; no hardcoded values, and all cell text MUST meet ≥4.5:1 contrast in every theme.
- **Why:** Theming/dark mode and legibility.
- **Platforms:** all
- **Severity:** error
- **Check:** `token_lint.py` + `contrast_check.py`.
- **Exceptions:** None.
- **See also:** [[COL-001]], [[DRK-001]]
