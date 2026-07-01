# Iconography (ICN)

> Purpose: Enforce clear, consistent, accessible icons with compliant hit areas, platform-native symbol systems, and non-color, non-icon-only meaning.

### ICN-001 — Pad glyph to a compliant hit area
- **Rule:** Interactive icons MUST have a touch target of at least 44pt (iOS) / 48dp (Android) even when the glyph itself is smaller (typically 24dp); pad the tappable area, do not enlarge the glyph.
- **Why:** Small icons are easy to miss; padding the hit area meets WCAG 2.2 target size without visual bulk.
- **Platforms:** all
- **Severity:** error
- **Check:** `target_size_lint.py`.
- **Exceptions:** None.
- **See also:** [[SPC-005]], [[ICN-008]]

### ICN-002 — SF Symbols scale with Dynamic Type
- **Rule:** On iOS, use SF Symbols configured to scale with the surrounding text style (image scale / `UIImage.SymbolConfiguration` or `.imageScale`) so icons grow with Dynamic Type.
- **Why:** Icons that stay fixed while text grows break alignment and legibility at large accessibility sizes.
- **Platforms:** ios
- **Severity:** warning
- **Check:** manual; `dynamic_type_check.py`.
- **Exceptions:** Decorative fixed-size glyphs with no adjacent text.
- **See also:** [[TYP-005]], [[ICN-006]]

### ICN-003 — Use Material Symbols on Android
- **Rule:** On Android, use the Material Symbols/Icons set with consistent style (outlined, rounded, or sharp) and standard optical size; do not mix icon styles within the app.
- **Why:** Material Symbols are optically tuned for Android and keep the icon language native and consistent.
- **Platforms:** android
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Brand/product logos.
- **See also:** [[ICN-004]], [[ICN-006]]

### ICN-004 — One icon family per app
- **Rule:** The app MUST use a single icon family/library with consistent style, weight, and metaphor. Do not mix multiple icon sets (e.g. Material + a random third-party pack) in the same UI.
- **Why:** Mixed icon families are an immediate tell of inconsistent, unpolished design.
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Official third-party brand logos (e.g. social sign-in marks).
- **See also:** [[ICN-003]], [[ICN-006]]

### ICN-005 — Icon-only controls need an accessible label
- **Rule:** Every icon-only button MUST have an accessible name (accessibilityLabel / contentDescription / semantics label) describing its action; decorative icons MUST be hidden from assistive tech.
- **Why:** Without a label, screen-reader users hear nothing meaningful; unlabeled decorative icons add noise.
- **Platforms:** all
- **Severity:** error
- **Check:** manual (a11y review).
- **Exceptions:** None.
- **See also:** [[ICN-007]], [[A11Y]]

### ICN-006 — Consistent optical size and stroke weight
- **Rule:** Icons MUST share a consistent optical size and stroke weight, aligned to the adjacent text weight; do not mix thin and heavy strokes or wildly different visual sizes in one context.
- **Why:** Matching weight and optical size makes icons feel like one coherent set and balances with text.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** manual.
- **Exceptions:** None.
- **See also:** [[ICN-002]], [[ICN-004]]

### ICN-007 — Icons are not the sole meaning for key actions
- **Rule:** Primary navigation and important actions MUST pair the icon with a text label; do not rely on an icon alone for meanings users cannot reliably infer (icon meaning is not universal).
- **Why:** Ambiguous icons without labels reduce discoverability and fail users who don't share the designer's mental model (reinforces color/icon-only prohibition).
- **Platforms:** all
- **Severity:** warning
- **Check:** manual.
- **Exceptions:** Universally understood glyphs (close ×, back chevron, search) with an accessible label.
- **See also:** [[COL-003]], [[ICN-005]], [[NAV]]

### ICN-008 — Standard icon sizes
- **Rule:** Use standard base icon sizes (24dp default; 20dp dense, 40–48dp prominent) from tokens; do not scatter arbitrary pixel sizes across the UI.
- **Why:** Standard sizes keep alignment predictable and icons crisp at common densities.
- **Platforms:** all
- **Severity:** suggestion
- **Check:** `token_lint.py` / manual.
- **Exceptions:** Illustrative/hero graphics.
- **See also:** [[ICN-001]], [[ICN-006]]

### ICN-009 — Icon color from tokens with ≥3:1 contrast
- **Rule:** Meaningful icons MUST take color from semantic tokens and meet ≥3:1 contrast against their background (WCAG 2.2 1.4.11); never hardcode icon colors.
- **Why:** Icons carry information and must be perceivable and themeable like any other UI element.
- **Platforms:** all
- **Severity:** error
- **Check:** `contrast_check.py`; `token_lint.py`.
- **Exceptions:** Purely decorative icons that convey no information.
- **See also:** [[COL-006]], [[COL-012]]

### ICN-010 — Mirror directional icons in RTL
- **Rule:** Direction-dependent icons (back/forward chevrons, list bullets with arrows, send, undo/redo) MUST mirror horizontally in RTL locales; non-directional icons (search, camera) MUST NOT mirror.
- **Why:** Directional glyphs point the wrong way in RTL if not mirrored, confusing navigation; over-mirroring corrupts neutral icons.
- **Platforms:** all
- **Severity:** warning
- **Check:** `rtl_check.py`; manual.
- **Exceptions:** Brand logos and glyphs with fixed real-world orientation.
- **See also:** [[L10N]], [[TYP-015]]
