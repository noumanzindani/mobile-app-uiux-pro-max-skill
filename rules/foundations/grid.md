# Grid & Responsive Layout (GRD)

> Purpose: Enforce responsive layouts driven by window size classes (not device type), with adaptive columns, panes, and navigation that reflow correctly across phones, tablets, and foldables.

## Contents
- [GRD-001 — Drive layout by window size classes](#grd-001--drive-layout-by-window-size-classes)
- [GRD-002 — Single column below 600dp](#grd-002--single-column-below-600dp)
- [GRD-003 — Two-pane list-detail at ≥840dp](#grd-003--two-pane-list-detail-at-840dp)
- [GRD-004 — Treat size classes as dynamic](#grd-004--treat-size-classes-as-dynamic)
- [GRD-005 — Size class, not device type](#grd-005--size-class-not-device-type)
- [GRD-006 — Cap readable content width](#grd-006--cap-readable-content-width)
- [GRD-007 — Responsive column counts](#grd-007--responsive-column-counts)
- [GRD-008 — Scale gutters with breakpoint](#grd-008--scale-gutters-with-breakpoint)
- [GRD-009 — Adapt navigation across size classes](#grd-009--adapt-navigation-across-size-classes)
- [GRD-010 — Respect foldable hinges](#grd-010--respect-foldable-hinges)
- [GRD-011 — Support both orientations](#grd-011--support-both-orientations)
- [GRD-012 — Lay out inside safe areas and cutouts](#grd-012--lay-out-inside-safe-areas-and-cutouts)
- [GRD-013 — Align panes to a shared grid](#grd-013--align-panes-to-a-shared-grid)
- [GRD-014 — Reflow, do not zoom](#grd-014--reflow-do-not-zoom)
- [GRD-015 — Survive 200% text and zoom](#grd-015--survive-200-text-and-zoom)
- [GRD-016 — Edge-to-edge with inset-aware content](#grd-016--edge-to-edge-with-inset-aware-content)

---

### GRD-001 — Drive layout by window size classes
- **Rule:** Responsive breakpoints MUST use the three window size classes — compact (<600dp), medium (600–839dp), expanded (≥840dp) — from tokens, not custom per-screen pixel values.
- **Why:** Standard size classes are the cross-platform contract for adaptive layout and keep breakpoints consistent app-wide.
- **Platforms:** all
- **Severity:** error
- **Check:** manual (breakpoint token review).
- **Exceptions:** Additional large/xlarge classes for desktop targets, layered above these.
- **See also:** [[GRD-002]], [[GRD-003]], [[GRD-009]]

### GRD-002 — Single column below 600dp
- **Rule:** In the compact class (<600dp), primary content MUST be a single scrolling column; do not force multi-pane or side-by-side layouts onto phone widths.
- **Why:** Multiple columns on narrow screens produce cramped, unreadable content.
- **Platforms:** all
- **Severity:** error
- **Check:** manual.
- **Exceptions:** Small paired controls (e.g. two buttons in a row) that fit comfortably.
- **See also:** [[GRD-001]], [[GRD-007]]

### GRD-003 — Two-pane list-detail at ≥840dp
- **Rule:** In the expanded class (≥840dp), list-detail flows SHOULD present list and detail side-by-side (two-pane) instead of pushing a full-screen detail, keeping selection context visible.
- **Why:** Wide screens waste space and lose context with single-pane navigation; two panes match the space available.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Immersive full-screen content (media, maps) that intentionally uses the full width.
- **See also:** [[GRD-001]], [[GRD-009]], [[list-detail]]

### GRD-004 — Treat size classes as dynamic
- **Rule:** Layout MUST recompute on size-class changes at runtime (window resize, split-screen, unfold, rotation); never read the size class once at launch and cache the layout.
- **Why:** Foldables and multi-window mean the window size can change at any moment; static layouts break on fold/unfold.
- **Platforms:** all
- **Severity:** error
- **Check:** manual.
- **Exceptions:** None.
- **See also:** [[GRD-010]], [[GRD-011]]

### GRD-005 — Size class, not device type
- **Rule:** Decisions MUST branch on the current window size class, NOT on device type flags (isTablet/isPhone) or hardcoded screen dimensions.
- **Why:** Device-type checks fail for split-screen, foldables, and desktop windows; size class describes the actual available space.
- **Platforms:** all
- **Severity:** error
- **Check:** manual (grep for isTablet/isPhone/device-model branching).
- **Exceptions:** Genuinely hardware-specific features (e.g. Dynamic Island, hinge sensors).
- **See also:** [[GRD-001]], [[GRD-004]]

### GRD-006 — Cap readable content width
- **Rule:** On medium/expanded widths, constrain text-heavy content to a maximum readable width (≈600–720dp) and center or offset it, rather than stretching lines across the full window.
- **Why:** Full-width paragraphs on tablets produce long, tiring line lengths (see [[TYP-010]]).
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Tables, dashboards, and media grids designed for full width.
- **See also:** [[TYP-010]], [[SPC-018]]

### GRD-007 — Responsive column counts
- **Rule:** Grids MUST adjust column count by size class (e.g. 1–2 compact, 2–3 medium, 3–4+ expanded) driven by tokens/breakpoints, keeping each cell within a comfortable min/max width.
- **Why:** Fixed column counts either crowd phones or leave oversized cells on tablets.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** None.
- **See also:** [[GRD-001]], [[GRD-008]]

### GRD-008 — Scale gutters with breakpoint
- **Rule:** Column gutters and edge margins MUST widen at larger breakpoints (e.g. 16dp compact → 24dp medium → 24–32dp expanded) via responsive tokens.
- **Why:** Consistent small gutters look cramped on large screens; scaling them preserves rhythm and breathing room.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual.
- **Exceptions:** None.
- **See also:** [[SPC-018]], [[GRD-007]]

### GRD-009 — Adapt navigation across size classes
- **Rule:** Primary navigation MUST adapt by size class: bottom navigation bar in compact, navigation rail in medium, and rail or persistent/standard navigation drawer in expanded. Do not keep a phone bottom bar on a wide window.
- **Why:** Bottom bars waste horizontal space and strain reach on large screens; rails/drawers fit the space and ergonomics.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** iOS tab bars that the platform itself adapts (e.g. sidebar on iPad).
- **See also:** [[GRD-001]], [[NAV]]

### GRD-010 — Respect foldable hinges
- **Rule:** On foldables, layout MUST account for hinge/fold posture: avoid placing critical content or targets across the fold, and use hinge-aware APIs to split panes along the fold when appropriate.
- **Why:** Content bisected by a physical hinge is unreadable or untappable; posture awareness makes dual-screen usable.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** None.
- **See also:** [[GRD-004]], [[GRD-003]]

### GRD-011 — Support both orientations
- **Rule:** Screens MUST remain functional and reflow in both portrait and landscape; do not lock orientation unless the content genuinely requires it (e.g. a camera/video capture UI), and never clip content in the unsupported orientation.
- **Why:** Orientation locking harms tablet users, accessibility mounts, and split-screen; forced rotation is a common accessibility complaint.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Full-screen media, games, or capture flows with a documented reason.
- **See also:** [[GRD-004]], [[GRD-015]]

### GRD-012 — Lay out inside safe areas and cutouts
- **Rule:** Layout MUST respect safe-area insets and display cutouts/notches by reading them dynamically; interactive and essential content MUST NOT fall under cutouts, rounded corners, or system bars.
- **Why:** Content under cutouts or system bars is clipped or untappable and varies per device.
- **Platforms:** all
- **Severity:** error
- **Check:** manual; `rtl_check.py`/lint for hardcoded inset constants.
- **Exceptions:** Intentional full-bleed backgrounds behind (not carrying) content.
- **See also:** [[SPC-011]], [[GRD-016]]

### GRD-013 — Align panes to a shared grid
- **Rule:** Multi-pane and multi-column layouts MUST align to a shared underlying grid so content baselines, keylines, and gutters line up across panes.
- **Why:** Misaligned panes look disjointed; a shared grid ties the composition together.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual.
- **Exceptions:** None.
- **See also:** [[SPC-015]], [[GRD-007]]

### GRD-014 — Reflow, do not zoom
- **Rule:** Adapting to larger sizes/zoom MUST reflow content (wrap, re-column, resize) rather than requiring horizontal scrolling or pinch-zoom to read (WCAG 1.4.10 Reflow).
- **Why:** Requiring two-dimensional scrolling to read content fails reflow and is hostile to low-vision users.
- **Platforms:** all
- **Severity:** error
- **Check:** manual.
- **Exceptions:** Data tables, maps, and images where 2D panning is inherent.
- **See also:** [[GRD-015]], [[TYP-005]]

### GRD-015 — Survive 200% text and zoom
- **Rule:** Layouts MUST remain usable with no loss of content or function when text is enlarged to 200% (and up to AX5); nothing may overlap, clip, or become unreachable.
- **Why:** WCAG 1.4.4 requires content to resize to 200% without assistive tech; large text often breaks fragile fixed layouts.
- **Platforms:** all
- **Severity:** error
- **Check:** `dynamic_type_check.py`; manual.
- **Exceptions:** None.
- **See also:** [[TYP-005]], [[TYP-006]], [[GRD-014]]

### GRD-016 — Edge-to-edge with inset-aware content
- **Rule:** On Android 15+ (and equivalent iOS full-screen), draw backgrounds edge-to-edge but apply system-bar/gesture insets to interactive and text content so nothing is drawn behind or under the system bars where it can't be used.
- **Why:** Edge-to-edge is the modern default, but content must be inset-aware or it hides behind system UI.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** None.
- **See also:** [[SPC-011]], [[GRD-012]]
