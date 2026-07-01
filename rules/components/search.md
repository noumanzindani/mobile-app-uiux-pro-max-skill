# Search (SRCH)

> Rules for search fields and results: debounce, recent/suggested content, zero-results, correct input semantics, and clearing.

## Contents
- [SRCH-001 — Debounce query execution](#srch-001--debounce-query-execution)
- [SRCH-002 — Show recent and suggested before typing](#srch-002--show-recent-and-suggested-before-typing)
- [SRCH-003 — Distinct zero-results empty state](#srch-003--distinct-zero-results-empty-state)
- [SRCH-004 — Correct input type and no autocorrect traps](#srch-004--correct-input-type-and-no-autocorrect-traps)
- [SRCH-005 — Provide a clear (✕) affordance](#srch-005--provide-a-clear--affordance)
- [SRCH-006 — Field and results respect the keyboard and safe-area](#srch-006--field-and-results-respect-the-keyboard-and-safe-area)
- [SRCH-007 — Loading and error states for results](#srch-007--loading-and-error-states-for-results)
- [SRCH-008 — Reflect active scope and filters](#srch-008--reflect-active-scope-and-filters)
- [SRCH-009 — Announce result count and suggestions](#srch-009--announce-result-count-and-suggestions)
- [SRCH-010 — Search field meets target and contrast minimums](#srch-010--search-field-meets-target-and-contrast-minimums)
- [SRCH-011 — Highlight matches without color-only emphasis](#srch-011--highlight-matches-without-color-only-emphasis)
- [SRCH-012 — Submit and dismiss the keyboard sensibly](#srch-012--submit-and-dismiss-the-keyboard-sensibly)

---

### SRCH-001 — Debounce query execution
- **Rule:** As-you-type search MUST debounce network/query execution by ~250–400ms (or wait for submit for expensive queries), cancel superseded in-flight requests, and never fire a request on every keystroke.
- **Why:** Un-debounced search floods the backend and produces flickering, out-of-order results.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — type quickly and inspect request timing.
- **Exceptions:** Instant local/in-memory filtering may run per keystroke.
- **See also:** [[PERF-002]], [[SRCH-007]]

### SRCH-002 — Show recent and suggested before typing
- **Rule:** On focus with an empty query, the field MUST show useful content — recent searches and/or suggested queries/categories — with a way to clear recents.
- **Why:** Reduces typing, aids re-finding, and avoids a blank, dead search screen.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — focus the empty field.
- **Exceptions:** First-run with no history may show suggestions/popular only.
- **See also:** [[STATE-002]], [[SRCH-003]]

### SRCH-003 — Distinct zero-results empty state
- **Rule:** A query returning no results MUST show a dedicated zero-results state — distinct from the initial empty and loading states — echoing the query, explaining why, and offering next steps (clear filters, check spelling, suggested alternatives).
- **Why:** A blank result area reads as broken; guidance keeps the user moving.
- **Platforms:** all
- **Severity:** error
- **Check:** `state_coverage.py` / manual — search for a nonsense term.
- **Exceptions:** None.
- **See also:** [[STATE-003]], [[CHP-008]]

### SRCH-004 — Correct input type and no autocorrect traps
- **Rule:** The search field MUST use the search input/return-key type and disable aggressive autocapitalize/autocorrect that would mangle names, codes, or emails.
- **Why:** Wrong keyboard and forced autocorrect make searching frustrating and error-prone.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Prose/content search where autocorrect helps.
- **See also:** [[FRM-004]], [[SRCH-012]]

### SRCH-005 — Provide a clear (✕) affordance
- **Rule:** When the field is non-empty, a clear button MUST appear with a ≥44pt/48dp target and an accessible label ("Clear search"); tapping it empties the field and returns to the recent/suggested state.
- **Why:** Fast reset is essential; a missing clear button forces tedious backspacing.
- **Platforms:** all
- **Severity:** warning
- **Check:** `target_size_lint.py` + a11y audit.
- **Exceptions:** None.
- **See also:** [[BTN-010]], [[SRCH-002]]

### SRCH-006 — Field and results respect the keyboard and safe-area
- **Rule:** The search field MUST stay visible above the keyboard, results MUST scroll independently under it, and the last result MUST NOT be trapped behind the keyboard or home indicator.
- **Why:** Trapping results/field under the keyboard blocks selection.
- **Platforms:** all
- **Severity:** error
- **Check:** manual with the keyboard open.
- **Exceptions:** None.
- **See also:** [[FRM-008]], [[LST-015]]

### SRCH-007 — Loading and error states for results
- **Rule:** While querying, results MUST show a loading indicator (inline/skeleton) without discarding prior results abruptly; on failure show an error state with retry that preserves the query.
- **Why:** Flicker to blank and silent failures make search feel unreliable.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — simulate slow/failed queries.
- **Exceptions:** None.
- **See also:** [[LST-008]], [[STATE-004]]

### SRCH-008 — Reflect active scope and filters
- **Rule:** When search is scoped (category/tab) or filtered, the active scope/filters MUST be visibly reflected near the field with a way to change or clear them.
- **Why:** Users otherwise can't tell why results are limited.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Single-scope search.
- **See also:** [[CHP-008]], [[SRCH-003]]

### SRCH-009 — Announce result count and suggestions
- **Rule:** After a query resolves, the result count (and appearance of a suggestions listbox) MUST be announced to assistive tech via a live region, and results MUST be exposed with proper list/option semantics.
- **Why:** Non-visual users need to know results arrived and how many (WCAG 4.1.3).
- **Platforms:** all
- **Severity:** warning
- **Check:** a11y audit.
- **Exceptions:** None.
- **See also:** [[A11Y-006]], [[LST-012]]

### SRCH-010 — Search field meets target and contrast minimums
- **Rule:** The search field MUST be ≥44pt/48dp tall, with placeholder/query text at ≥4.5:1 contrast and a leading search icon; the field is styled from tokens (no hardcoded colors/radii).
- **Why:** Legible, adequately sized, theme-aware search input.
- **Platforms:** all
- **Severity:** error
- **Check:** `contrast_check.py` + `target_size_lint.py` + `token_lint.py`.
- **Exceptions:** None.
- **See also:** [[FRM-002]], [[A11Y-001]]

### SRCH-011 — Highlight matches without color-only emphasis
- **Rule:** If query matches are highlighted in results, the emphasis MUST use weight/background+text change, not color alone, and MUST maintain ≥4.5:1 text contrast.
- **Why:** WCAG 1.4.1; color-only highlights are invisible to color-blind users.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — desaturate.
- **Exceptions:** None.
- **See also:** [[A11Y-010]], [[BDG-004]]

### SRCH-012 — Submit and dismiss the keyboard sensibly
- **Rule:** The return/search key MUST submit the query, scrolling the results MUST dismiss the keyboard, and selecting a suggestion/recent MUST fill and run it — with no dead-end where the keyboard hides all results.
- **Why:** Smooth keyboard behavior is core to search usability.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** None.
- **See also:** [[FRM-009]], [[SRCH-006]]
