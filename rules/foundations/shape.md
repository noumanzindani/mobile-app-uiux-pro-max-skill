# Shape & Corner Radius (SHP)

> Purpose: Enforce a consistent, token-driven corner system based on Material 3's 10-step shape scale, with concentric radii and iOS hardware-aligned corners.

### SHP-001 — Use the M3 10-step corner scale
- **Rule:** Corner radii MUST come from the Material 3 shape scale — extraSmall 4dp, small 8, medium 12, large 16, largeIncreased 20, extraLarge 24, extraLargeIncreased 32, full 9999 (plus none 0) — exposed as tokens. No arbitrary radii like 6, 10, or 14.
- **Why:** A closed shape scale keeps corner treatment consistent and makes shape a systematic design decision.
- **Platforms:** all
- **Severity:** error
- **Check:** `token_lint.py` flags off-scale radius literals.
- **Exceptions:** Circular avatars/FABs (`full`); iOS concentric radii per [[SHP-005]].
- **See also:** [[SHP-006]], [[SHP-007]]

### SHP-002 — Cards use medium–large radii
- **Rule:** Cards and content containers MUST use a radius in the 12–16dp range (medium/large tokens) unless a brand shape system says otherwise.
- **Why:** This range reads as a modern card on both platforms without looking either sharp or bubble-like.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual.
- **Exceptions:** Full-bleed cards with square corners at the screen edge.
- **See also:** [[SHP-001]], [[CRD]]

### SHP-003 — Buttons use a defined shape token
- **Rule:** Buttons MUST use a single shape token consistently — either fully rounded (`full`) or a fixed corner (e.g. small/medium) — applied to all buttons of the same type. Do not mix pill and boxy buttons of the same rank.
- **Why:** Mixed button shapes look unintentional and weaken the component system.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Distinct shapes to differentiate button categories, if defined as tokens.
- **See also:** [[SHP-004]], [[BTN]]

### SHP-004 — Pill shape equals full (9999)
- **Rule:** Pill/stadium shapes MUST use the `full` radius token (9999), which resolves to half the component height, rather than a large fixed number that fails to stay fully round as height changes.
- **Why:** A fixed large radius stops being a true pill when the component grows with Dynamic Type; `full` stays correct.
- **Platforms:** all
- **Severity:** warning
- **Check:** `token_lint.py`.
- **Exceptions:** None.
- **See also:** [[SHP-001]], [[TYP-005]]

### SHP-005 — iOS corners concentric with the hardware
- **Rule:** On iOS/iPadOS 26, container corners that sit near the screen or a parent's rounded edge MUST be concentric (continuous corners aligned to the device/parent radius), not a mismatched fixed radius.
- **Why:** Concentric, continuous corners are core to the iOS 26 look; mismatched radii read as non-native.
- **Platforms:** ios
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** None.
- **See also:** [[SHP-008]], [[PLAT]]

### SHP-006 — Reference shape tokens per component category
- **Rule:** Components MUST reference category shape tokens (e.g. `shape.card`, `shape.button`, `shape.sheet`) instead of inline radius numbers, so the shape family can be retuned globally.
- **Why:** Tokenized shape enables brand shape theming (sharp vs rounded) without editing every component.
- **Platforms:** all
- **Severity:** error
- **Check:** `token_lint.py`.
- **Exceptions:** Token definition files.
- **See also:** [[SHP-001]], [[SHP-007]]

### SHP-007 — Keep one corner family across the app
- **Rule:** Choose a coherent shape family (e.g. rounded) and apply it consistently; do not mix sharp-cornered and heavily-rounded components arbitrarily within the same surface.
- **Why:** A consistent corner family is a strong, low-effort signal of a designed, cohesive product.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual.
- **Exceptions:** Deliberate accent shapes with documented rationale.
- **See also:** [[SHP-002]], [[SHP-003]]

### SHP-008 — Nest radii concentrically
- **Rule:** When nesting rounded containers, the inner radius MUST equal the outer radius minus the gap between them (inner = outer − padding), so corners stay parallel; never nest a larger radius inside a smaller one.
- **Why:** Concentric nesting keeps corners visually parallel; non-concentric radii create awkward pinched or bulging corners.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual.
- **Exceptions:** None.
- **See also:** [[SHP-005]], [[SPC-014]]
