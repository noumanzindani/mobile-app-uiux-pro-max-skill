# Elevation & Shadow (ELV)

> Purpose: Enforce a token-driven depth system using Material's five elevation levels, consistent interaction-based raising, and dark-mode tonal overlays instead of pure-black shadows.

### ELV-001 — Use the five elevation levels
- **Rule:** Depth MUST be expressed through the five Material elevation levels (0, 1, 2, 3, 4/5 → 0/1/3/6/8/12dp equivalents) referenced as tokens; do not use arbitrary shadow blur/offset values.
- **Why:** A fixed, small set of elevation steps keeps depth hierarchy legible and consistent across the app.
- **Platforms:** all
- **Severity:** error
- **Check:** `token_lint.py` flags raw shadow/elevation literals.
- **Exceptions:** None.
- **See also:** [[ELV-004]], [[ELV-006]]

### ELV-002 — Raise one level on interaction
- **Rule:** On press, drag, or focus, an elevated surface MUST rise exactly one elevation level (e.g. resting 1 → pressed 2, dragged card → highest transient level), then return on release.
- **Why:** A single-step lift is the standard, readable cue that an element is active or being manipulated.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Flat/text buttons and iOS controls that signal press via opacity/scale instead of shadow.
- **See also:** [[ELV-001]], [[MIC]]

### ELV-003 — Dark mode uses tonal overlays, not black shadows
- **Rule:** In dark themes, convey elevation with tonal surface overlays (higher = lighter surface tint), not by relying on shadows against a near-black background. Base surface MUST NOT be pure `#000000`.
- **Why:** Shadows are nearly invisible in dark mode; tonal overlays are how depth is perceived, per M3.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual; cross-check with `contrast_check.py`.
- **Exceptions:** iOS, which uses vibrancy/materials rather than tonal overlays.
- **See also:** [[COL-008]], [[COL-016]], [[DRK]]

### ELV-004 — Reference elevation tokens
- **Rule:** Components MUST consume named elevation tokens (e.g. `elevation.level2`, `card.resting.elevation`) rather than inline shadow definitions.
- **Why:** Tokenized elevation lets depth be retuned globally and mapped correctly per platform (shadow vs overlay vs material).
- **Platforms:** all
- **Severity:** error
- **Check:** `token_lint.py`.
- **Exceptions:** Token definition files.
- **See also:** [[ELV-001]], [[ELV-007]]

### ELV-005 — Consistent light source
- **Rule:** All shadows MUST share one implied light source (top-down): vertical offset positive, symmetric horizontal, soft blur. Do not mix upward/sideways or hard shadows across components.
- **Why:** A single consistent light direction makes depth believable and cohesive.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual.
- **Exceptions:** None.
- **See also:** [[ELV-001]], [[ELV-010]]

### ELV-006 — Reserve high elevation for transient surfaces
- **Rule:** Elevation MUST correlate with z-order and transience: content/cards low (0–1), app bars/FAB mid (2–3), menus/dialogs/sheets high (3–5). Do not over-elevate resting content or flatten transient surfaces.
- **Why:** Consistent elevation-to-role mapping teaches users what floats above what and what is dismissible.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** None.
- **See also:** [[ELV-008]], [[SPC-009]]

### ELV-007 — iOS uses subtle shadows and materials
- **Rule:** On iOS, prefer subtle, low-opacity shadows and system materials/blur for separation rather than heavy Material-style drop shadows; sheets and popovers use system presentation with their built-in depth.
- **Why:** Heavy Android-style shadows look foreign on iOS, which signals depth through translucency and gentle shadows.
- **Platforms:** ios
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** None.
- **See also:** [[ELV-003]], [[PLAT]]

### ELV-008 — Highest elevation for modals, scrim below
- **Rule:** Dialogs, bottom sheets, and menus MUST sit at the top elevation level and be backed by a scrim/dim that separates them from and blocks interaction with content beneath.
- **Why:** The scrim plus top elevation communicates modality and focuses attention on the transient surface.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Non-modal sheets/popovers that intentionally allow background interaction.
- **See also:** [[ELV-006]], [[DLG]], [[BSH]]

### ELV-009 — Elevation maps consistently to interactivity
- **Rule:** Use elevation consistently to imply interactivity and grouping: if raised cards are tappable in one place, do not use the same elevation for non-interactive containers elsewhere.
- **Why:** Inconsistent elevation semantics mislead users about what is tappable.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual.
- **Exceptions:** None.
- **See also:** [[ELV-006]], [[CRD]]

### ELV-010 — Prefer tint over expensive shadows for performance
- **Rule:** Avoid large-blur or per-item shadows in scrolling lists; prefer tonal tint, borders, or a single shared shadow token. Real-time soft shadows on many items MUST NOT jeopardize the 16ms frame budget.
- **Why:** Large blurred shadows are GPU-costly and cause jank in long lists; tint achieves separation cheaply.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual; `PERF` profiling.
- **Exceptions:** None.
- **See also:** [[ELV-005]], [[PERF]]
