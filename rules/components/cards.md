# Cards (CRD)

> Rules for card tap targets, nested actions, elevation, media, and content structure. Token-driven; all seven states apply to data-backed cards.

## Contents
- [CRD-001 — A tappable card is a single primary target](#crd-001--a-tappable-card-is-a-single-primary-target)
- [CRD-002 — Resolve nested tap conflicts](#crd-002--resolve-nested-tap-conflicts)
- [CRD-003 — Whole card meets the target minimum](#crd-003--whole-card-meets-the-target-minimum)
- [CRD-004 — Convey depth with elevation tokens, not ad-hoc shadows](#crd-004--convey-depth-with-elevation-tokens-not-ad-hoc-shadows)
- [CRD-005 — Give tappable cards a pressed state](#crd-005--give-tappable-cards-a-pressed-state)
- [CRD-006 — Use token corner radius and clip media to it](#crd-006--use-token-corner-radius-and-clip-media-to-it)
- [CRD-007 — Reserve media aspect ratio to prevent reflow](#crd-007--reserve-media-aspect-ratio-to-prevent-reflow)
- [CRD-008 — Consistent internal padding on the 4/8 grid](#crd-008--consistent-internal-padding-on-the-48-grid)
- [CRD-009 — Card content is a single semantic group](#crd-009--card-content-is-a-single-semantic-group)
- [CRD-010 — Don't nest cards](#crd-010--dont-nest-cards)
- [CRD-011 — Card boundary contrast ≥3:1 when it carries meaning](#crd-011--card-boundary-contrast-31-when-it-carries-meaning)
- [CRD-012 — Card grids/lists are virtualized and skeleton-loaded](#crd-012--card-gridslists-are-virtualized-and-skeleton-loaded)

---

### CRD-001 — A tappable card is a single primary target
- **Rule:** If a card navigates on tap, the entire card MUST be one accessible tap target with one accessible name summarizing its content, not a stack of independently focusable regions.
- **Why:** Multiple overlapping targets confuse pointer and screen-reader users and cause mis-taps.
- **Platforms:** all
- **Severity:** error
- **Check:** a11y audit — one focusable element per navigational card.
- **Exceptions:** Cards with explicit secondary actions (see [[CRD-002]]).
- **See also:** [[LST-004]], [[A11Y-004]]

### CRD-002 — Resolve nested tap conflicts
- **Rule:** When a card has both a whole-card tap and inner controls (favorite, overflow menu), inner controls MUST be ≥44pt/48dp, ≥8dp from the card's tap area, and stop event propagation so they don't trigger the card action.
- **Why:** Overlapping gesture targets cause the wrong action to fire.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — tap each inner control and the card body separately.
- **Exceptions:** None.
- **See also:** [[CRD-001]], [[BTN-003]]

### CRD-003 — Whole card meets the target minimum
- **Rule:** A tappable card's hit area MUST be ≥44pt (iOS) / 48dp (Android) tall.
- **Why:** Ensures reliable activation, especially for dense list-of-cards layouts.
- **Platforms:** all
- **Severity:** error
- **Check:** `target_size_lint.py`.
- **Exceptions:** None.
- **See also:** [[A11Y-003]], [[LST-002]]

### CRD-004 — Convey depth with elevation tokens, not ad-hoc shadows
- **Rule:** Card depth MUST use the defined elevation token scale (M3's levels; iOS subtle shadow/material); raise exactly one level on press/drag. No hardcoded shadow blur/offset values.
- **Why:** Consistent elevation communicates hierarchy and keeps dark-mode overlays correct.
- **Platforms:** all
- **Severity:** warning
- **Check:** `token_lint.py` on shadow/elevation literals.
- **Exceptions:** Flat/outlined card variants that use a border instead of shadow.
- **See also:** [[ELV-001]], [[DRK-001]]

### CRD-005 — Give tappable cards a pressed state
- **Rule:** Interactive cards MUST show a visible pressed/ripple state (overlay or slight elevation/scale change) within 100ms of touch-down.
- **Why:** Confirms the tap registered on a large surface where feedback is otherwise ambiguous.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Non-interactive display cards.
- **See also:** [[BTN-005]], [[MIC-001]]

### CRD-006 — Use token corner radius and clip media to it
- **Rule:** Card corner radius MUST come from the shape token scale (typically 12–16dp for standard cards), and inner media/images MUST be clipped to the same radius.
- **Why:** Unclipped media breaking the card silhouette looks broken; consistent radius reads as one system.
- **Platforms:** all
- **Severity:** warning
- **Check:** `token_lint.py` on radius literals.
- **Exceptions:** Full-bleed hero cards where media intentionally spans edge-to-edge.
- **See also:** [[SHP-001]], [[AVT-004]]

### CRD-007 — Reserve media aspect ratio to prevent reflow
- **Rule:** Cards containing remote images/video MUST reserve the media's aspect-ratio box before load so surrounding content does not reflow when media arrives.
- **Why:** Layout shift (CLS) is jarring and can cause mis-taps as content jumps.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — load on a slow connection and watch for jumps.
- **Exceptions:** None.
- **See also:** [[PERF-003]], [[LST-010]]

### CRD-008 — Consistent internal padding on the 4/8 grid
- **Rule:** Card content padding MUST use spacing tokens on the 4/8pt grid (commonly 16dp) and be identical across cards of the same type.
- **Why:** Rhythm and alignment; inconsistent padding reads as sloppy.
- **Platforms:** all
- **Severity:** warning
- **Check:** `token_lint.py`.
- **Exceptions:** Compact-density card variants using a documented tighter token.
- **See also:** [[SPC-001]], [[DEN-001]]

### CRD-009 — Card content is a single semantic group
- **Rule:** A card's title, meta, and media MUST be grouped so assistive tech announces them as one unit with a logical reading order (title first).
- **Why:** Prevents screen readers from reading fragmented, out-of-order snippets.
- **Platforms:** all
- **Severity:** warning
- **Check:** a11y audit — reading order.
- **Exceptions:** None.
- **See also:** [[A11Y-007]], [[CRD-001]]

### CRD-010 — Don't nest cards
- **Rule:** Cards MUST NOT be nested inside other cards; use dividers, sections, or list rows for internal grouping instead.
- **Why:** Nested elevation/rounding creates visual noise and ambiguous tap boundaries.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — inspect the view tree for card-in-card.
- **Exceptions:** None.
- **See also:** [[CRD-004]], [[LST-001]]

### CRD-011 — Card boundary contrast ≥3:1 when it carries meaning
- **Rule:** When a card's edge is the only cue separating it from the background (no shadow/fill difference), that boundary MUST have ≥3:1 contrast against the background.
- **Why:** WCAG 2.2 SC 1.4.11 non-text contrast; low-vision users must perceive the container.
- **Platforms:** all
- **Severity:** warning
- **Check:** `contrast_check.py` on border vs background tokens.
- **Exceptions:** Cards separated by an adequate fill or elevation difference instead of a border.
- **See also:** [[A11Y-002]], [[CRD-004]]

### CRD-012 — Card grids/lists are virtualized and skeleton-loaded
- **Rule:** A scrolling collection of cards MUST be virtualized (builder/lazy) and MUST show skeleton placeholders (not a blank screen or bare spinner) while loading.
- **Why:** Rendering all cards eagerly blows the frame budget; skeletons communicate structure and reduce perceived wait.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — inspect the list widget + loading state.
- **Exceptions:** Small, fixed sets (≤ ~10 cards) that fit on screen without scrolling.
- **See also:** [[LST-001]], [[LST-008]], [[STATE-001]]
