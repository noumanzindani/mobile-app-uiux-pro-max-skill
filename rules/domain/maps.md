# Maps & Location (MAP)

> Purpose: Design map screens that stay one-handed and legible — bottom-sheet detail, bottom-anchored controls, graceful location-permission handling, recenter, and marker clustering.

## Contents
- [MAP-001 — Present place detail in a draggable bottom sheet](#map-001--present-place-detail-in-a-draggable-bottom-sheet)
- [MAP-002 — Bottom-anchor primary map controls](#map-002--bottom-anchor-primary-map-controls)
- [MAP-003 — Handle location-permission-denied with a fallback](#map-003--handle-location-permission-denied-with-a-fallback)
- [MAP-004 — Provide a recenter / my-location control](#map-004--provide-a-recenter--my-location-control)
- [MAP-005 — Cluster markers at low zoom](#map-005--cluster-markers-at-low-zoom)
- [MAP-006 — Keep controls clear of system-gesture edges](#map-006--keep-controls-clear-of-system-gesture-edges)
- [MAP-007 — Show tile-loading and no-results states](#map-007--show-tile-loading-and-no-results-states)
- [MAP-008 — Markers meet touch-target and non-color selection rules](#map-008--markers-meet-touch-target-and-non-color-selection-rules)
- [MAP-009 — Prime location permission just-in-time](#map-009--prime-location-permission-just-in-time)
- [MAP-010 — Do not cover the map center with the sheet](#map-010--do-not-cover-the-map-center-with-the-sheet)
- [MAP-011 — Communicate offline and no-signal location states](#map-011--communicate-offline-and-no-signal-location-states)
- [MAP-012 — Provide an accessible alternative to the map](#map-012--provide-an-accessible-alternative-to-the-map)

---

### MAP-001 — Present place detail in a draggable bottom sheet
- **Rule:** Selecting a marker/place MUST open a draggable bottom sheet with detents (peek / half / full) rather than navigating away from the map; the map stays visible behind the peek state.
- **Why:** Keeping the map in view while browsing detail preserves spatial context and is the established maps pattern.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — tap a marker and confirm a detented sheet over a still-visible map.
- **Exceptions:** Very small screens may push to a full detail screen for dense content.
- **See also:** [[MAP-010]], [[BSH-001]]

### MAP-002 — Bottom-anchor primary map controls
- **Rule:** Recenter, layers, and other frequent controls MUST sit in the lower thumb-reachable region; do not strand primary controls in the top corners of a full-screen map.
- **Why:** Maps are used one-handed on the move; top-corner controls are unreachable without a grip shift.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — verify frequent controls fall within the bottom thumb arc.
- **Exceptions:** Search entry conventionally sits at the top; secondary/rare controls may live there.
- **See also:** [[MAP-004]], [[GES-006]]

### MAP-003 — Handle location-permission-denied with a fallback
- **Rule:** When location permission is denied, the map MUST still function (manual search / a sensible default region), explain what is limited, and offer a one-tap deep link to Settings.
- **Why:** Denied permission must degrade gracefully, not dead-end; a Settings deep link is the only recovery once the OS prompt is spent.
- **Platforms:** all
- **Severity:** error
- **Check:** manual — deny location and confirm a usable, explained fallback + Settings link.
- **Exceptions:** None.
- **See also:** [[MAP-009]], [[PERM-004]], [[MAP-011]]

### MAP-004 — Provide a recenter / my-location control
- **Rule:** Offer a clearly-labeled recenter button that returns to the user's location; show heading/orientation when relevant and reflect the follow/idle state of the control.
- **Why:** Users pan away constantly and need a reliable one-tap way back to themselves.
- **Platforms:** all
- **Severity:** warning
- **Check:** target_size_lint.py on the control; manual — pan away and recenter.
- **Exceptions:** Static/informational maps with no user location.
- **See also:** [[MAP-002]], [[MAP-011]]

### MAP-005 — Cluster markers at low zoom
- **Rule:** Dense marker sets MUST cluster at low zoom levels, showing counts, and expand/split as the user zooms or taps a cluster.
- **Why:** Hundreds of overlapping pins are unreadable and unhittable; clustering keeps the map legible and performant.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — zoom out over a dense area and confirm clustering with counts.
- **Exceptions:** Maps with only a handful of markers.
- **See also:** [[MAP-008]], [[PERF-004]]

### MAP-006 — Keep controls clear of system-gesture edges
- **Rule:** Interactive controls MUST inset from the screen edges and the home-indicator/back-gesture zones so map panning and OS gestures do not conflict with control taps.
- **Why:** Controls hugging the edge get swallowed by system edge-swipes and are hard to hit.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — attempt edge controls near gesture zones on a gesture-nav device.
- **Exceptions:** Full-bleed map canvas itself (it is meant to pan under the insets).
- **See also:** [[MAP-002]], [[GES-006]], [[SPC-011]]

### MAP-007 — Show tile-loading and no-results states
- **Rule:** The map MUST show a loading/buffering state while tiles or results load and a distinct 'no places found' state for empty search/area results.
- **Why:** A blank or frozen map is indistinguishable from a crash; explicit states set expectations.
- **Platforms:** all
- **Severity:** warning
- **Check:** state_coverage.py; manual — throttle network and run an empty-area search.
- **Exceptions:** None.
- **See also:** [[MAP-012]], [[STATE-002]], [[SRCH-009]]

### MAP-008 — Markers meet touch-target and non-color selection rules
- **Rule:** Marker/pin tap targets MUST be ≥44pt/48dp (pad the hit area beyond the glyph), and the selected marker MUST be distinguished by size/shape/elevation, not color alone.
- **Why:** Tiny pins are unhittable, and color-only selection fails colorblind users (WCAG §2.5.8, §1.4.1).
- **Platforms:** all
- **Severity:** error
- **Check:** target_size_lint.py on marker hit areas; manual — verify non-color selected state.
- **Exceptions:** Purely decorative, non-interactive map annotations.
- **See also:** [[MAP-005]], [[A11Y-011]], [[ICN-004]]

### MAP-009 — Prime location permission just-in-time
- **Rule:** Explain the value of location in-context BEFORE triggering the OS prompt, and request the least precision needed (approximate vs precise) for the feature.
- **Why:** Value-first priming raises grant rates and avoids burning the one-shot OS prompt; minimizing precision respects privacy expectations and store policy.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — confirm a priming rationale precedes the OS dialog and precision is scoped.
- **Exceptions:** Flows where the OS itself shows sufficient context.
- **See also:** [[MAP-003]], [[PERM-002]], [[ONB-005]]

### MAP-010 — Do not cover the map center with the sheet
- **Rule:** A bottom sheet's default peek height SHOULD leave roughly the top 60% of the map (including the selected point) visible; the selected marker must not be hidden behind the sheet.
- **Why:** A sheet that buries the point of interest defeats the purpose of showing detail in context.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual — select a marker and confirm it stays visible above the peek sheet.
- **Exceptions:** Full-detent state intentionally covering the map for reading.
- **See also:** [[MAP-001]], [[BSH-003]]

### MAP-011 — Communicate offline and no-signal location states
- **Rule:** When maps are offline or GPS is unavailable, show a clear message, use cached/last-known position with a staleness caveat, and avoid presenting a stale fix as live.
- **Why:** A silently stale or blank map misleads users navigating in real space.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual — disable network/GPS and verify messaging and last-known handling.
- **Exceptions:** None.
- **See also:** [[MAP-003]], [[OFF-003]]

### MAP-012 — Provide an accessible alternative to the map
- **Rule:** Map content MUST have a non-visual path: a labeled list of nearby results/markers reachable by screen reader, with each marker exposing a meaningful accessible name.
- **Why:** A raw map canvas is invisible to screen readers; a list alternative makes the feature usable (WCAG §1.1.1).
- **Platforms:** all
- **Severity:** error
- **Check:** manual — navigate results with VoiceOver/TalkBack via the list alternative.
- **Exceptions:** None.
- **See also:** [[MAP-008]], [[A11Y-024]]
