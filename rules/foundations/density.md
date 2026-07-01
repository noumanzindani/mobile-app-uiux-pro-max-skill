# Density (DEN)

> Purpose: Enforce a token-driven density system offering comfortable and compact modes, defaulting to comfortable on phones while never dropping below minimum touch targets.

### DEN-001 — Provide comfortable and compact token sets
- **Rule:** The design system MUST expose at least two density token sets — comfortable and compact — that scale spacing, row heights, and component paddings together (not one-off overrides).
- **Why:** A defined density axis lets the same UI serve casual phone use and data-dense tablet/desktop use without re-authoring layouts.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual (density token review).
- **Exceptions:** None.
- **See also:** [[DEN-005]], [[SPC-004]]

### DEN-002 — Default to comfortable on phones
- **Rule:** Phone/compact layouts MUST default to the comfortable density; do not ship a compact-by-default phone UI that shrinks spacing below the comfortable set.
- **Why:** Comfortable spacing maximizes tap accuracy and readability for one-handed phone use.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Explicitly data-dense phone tools where the user opts into compact.
- **See also:** [[SPC-006]], [[DEN-004]]

### DEN-003 — Use compact for data-dense and larger surfaces
- **Rule:** Reserve compact density for information-dense contexts (tables, dashboards, enterprise/tablet views); apply it via the density token set at the appropriate size class, not by hand-tuning individual widgets.
- **Why:** Compact density fits more data where users scan large amounts of information on bigger screens.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual.
- **Exceptions:** None.
- **See also:** [[GRD-007]], [[TAB]]

### DEN-004 — Compact must still meet minimum targets
- **Rule:** Even in compact density, all interactive elements MUST keep touch targets ≥44pt/48dp (padding the hit area if the visual shrinks); density reduces spacing/visual size, never the minimum target.
- **Why:** Density is not a license to break accessibility; sub-minimum targets fail WCAG 2.2 regardless of density.
- **Platforms:** all
- **Severity:** error
- **Check:** `target_size_lint.py`.
- **Exceptions:** None.
- **See also:** [[ICN-001]], [[SPC-005]]

### DEN-005 — Apply density through tokens, not per-widget overrides
- **Rule:** Density MUST be switched by selecting a density token set (e.g. `visualDensity`, density scale), not by scattering manual spacing overrides across components.
- **Why:** Centralized density tokens keep density consistent and switchable; ad-hoc overrides drift and can't be toggled.
- **Platforms:** all
- **Severity:** warning
- **Check:** `token_lint.py` / manual.
- **Exceptions:** None.
- **See also:** [[DEN-001]], [[SPC-004]]

### DEN-006 — Respect system/user density preferences
- **Rule:** Where the platform exposes a density or display-size preference (e.g. Android display size, adaptive `VisualDensity.adaptivePlatformDensity`), the app SHOULD honor it rather than forcing a fixed density.
- **Why:** Respecting the user's chosen display density improves comfort and accessibility and matches platform behavior.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual.
- **Exceptions:** None.
- **See also:** [[DEN-002]], [[GRD-015]]
