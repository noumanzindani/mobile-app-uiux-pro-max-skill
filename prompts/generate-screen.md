# Generate Screen

**Purpose:** Produce a new, production-ready mobile screen with all 7 UI states, token-driven styling, WCAG 2.2 AA accessibility, and the correct platform paradigm for the target framework.

**Inputs:**
- *Required:* **Screen intent** (what the user accomplishes here, e.g. "browse and filter products").
- *Required:* **Framework** (Flutter · React Native · SwiftUI · Jetpack Compose).
- **Platform target** (iOS-only · Android-only · cross-platform/adaptive). If omitted, ask or default to adaptive.
- **Industry** (finance-banking · healthcare · ecommerce-marketplace · social-messaging · productivity) — optional but strongly recommended.
- **Brand / token source** (seed color, existing `design-system/tokens/`, or a Figma link). If absent, generate a semantic token set first.
- **Data model / content** the screen renders; **key actions**; **constraints** (offline-first, one-handed, large Dynamic Type, etc.).

**Procedure:**
1. Run the **15-point Pre-Generation Protocol** from `SKILL.md` §6.1; state (briefly) the chosen platform paradigm, framework, and information hierarchy before generating.
2. Resolve the paradigm — load `rules/system/platform-conventions.md` (HIG/Liquid Glass vs Material 3 Expressive vs adaptive) and follow the Platform router.
3. Load framework idioms — `frameworks/<framework>/_index.md`, `frameworks/<framework>/components.md`, and `frameworks/<framework>/states.md` (idiomatic widgets, theming API, safe-area primitive, a11y API, animation primitive).
4. If an industry is given, load `industries/<industry>/_index.md` plus its `patterns.md` and `copy-and-tone.md` for domain patterns and microcopy.
5. Load foundations — `rules/foundations/spacing.md`, `typography.md`, `color.md`, and `design-system/token-spec.md`. If no token source was supplied, first run `design-system-generator.md` to emit a semantic token set, then bind to it.
6. Enumerate states — load `rules/interaction/states.md` and `patterns/empty-error-offline.md`; run the **State router** to decide which of the 7 states (`ideal`, `empty`, `loading`, `error`, `offline`, `success`, `permission-denied`) apply to this screen and design each. A data-backed screen ships all 7.
7. Load accessibility — `rules/system/accessibility.md` (contrast 4.5:1, targets 44pt/48dp + 8dp spacing, labels/roles/state, focus order, Dynamic Type), `rules/system/dark-mode.md`, and `rules/system/localization-rtl.md`.
8. Load the relevant component + interaction rules for what the screen contains (e.g. `rules/components/lists.md`, `nav.md`, `forms.md`, `sheets.md`; `rules/interaction/motion.md`, `gestures.md`, `haptics.md`).
9. Generate the screen: bind every color/spacing/radius/motion value to a semantic token (no magic values), place primary/destructive actions in the thumb zone, virtualize lists, wire the framework's safe-area primitive, and attach a11y label+role+state to every interactive element.

**Output format:**
- A **paradigm declaration** (1–2 lines: platform, framework, why).
- **Code for all 7 states** in the target framework (a single stateful screen switching on a view-state enum is preferred over 7 detached widgets).
- A **token-usage table** (semantic token → where used) proving no hardcoded values.
- **Accessibility notes** (labels/roles, focus order, Dynamic Type behavior, reduce-motion path, dark-mode resolution).
- A short **motion & gesture spec** (durations/easing/springs + reduce-motion fallback; gesture fallbacks).

**Self-check:** Run `quality-checks/validators/run_all.py <output>` and confirm PASS: `state_coverage.py` shows all 7 states, `token_lint.py` finds zero magic values, `contrast_check.py` passes in both themes, `target_size_lint.py` passes (44pt/48dp + 8dp), `dynamic_type_check.py` (no fixed text heights), `rtl_check.py` (no hardcoded left/right). Then reason through `quality-checks/checklists/states.md`, `accessibility.md`, and `platform-conventions.md`. Fix any finding before returning.
