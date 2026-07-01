# Improve Screen

**Purpose:** Upgrade an existing mobile screen to the skill's standards — fixing tokens, states, accessibility, platform fit, and ergonomics — and return a reviewable diff whose every change is justified by a rule ID.

**Inputs:**
- *Required:* **The screen** — source code (any of the 4 frameworks) and/or a screenshot.
- *Required:* **Framework** (infer from code if not stated).
- **Improvement goals** (e.g. "make it accessible", "add dark mode", "modernize to Material 3 Expressive", "fix the empty/error states", "tighten spacing"). If omitted, improve holistically across all 5 laws.
- **Platform target** and **industry** — optional; sharpen the recommendations when provided.
- **Constraints** to preserve (existing design language, brand tokens, do-not-touch areas).

**Procedure:**
1. Run the **15-point Pre-Generation Protocol** from `SKILL.md` §6.1 against the *current* screen to find where it deviates.
2. Baseline the screen — run `quality-checks/validators/run_all.py` on the input to get an objective list of failures (magic values, missing states, contrast, target size, RTL, Dynamic Type) before changing anything.
3. Load the paradigm check — `rules/system/platform-conventions.md` — and confirm the screen matches the target OS (no "neither-native" hybrid).
4. Load the rules matching the goals / failures: `rules/interaction/states.md` + `patterns/empty-error-offline.md` (missing states), `rules/system/accessibility.md` (a11y), `rules/foundations/spacing.md` + `typography.md` + `color.md` and `design-system/token-spec.md` (tokens/type/spacing), `rules/system/dark-mode.md` (theming), plus the specific `rules/components/*.md` for components present.
5. Load framework idioms — `frameworks/<framework>/components.md` and `states.md` — so refactors stay idiomatic (correct widgets, theming API, safe-area primitive, a11y API).
6. Produce a **minimal, targeted diff**: replace magic values with semantic tokens, add missing states, add a11y label+role+state, correct target sizes and thumb-zone placement, and mirror-safe any hardcoded left/right. Do not rewrite working code that already complies (per the "don't rewrite working code" preference) — change only what a rule flags.

**Output format:**
- A **before/after diff** (or annotated patch) in the target framework.
- A **rationale table**: each change → the rule ID it satisfies (e.g. `A11Y-007`, `SPC-001`, `STATE-…`, `COL-…`) → severity (error/warning/suggestion).
- The list of **any states that were missing and have now been added**.
- A **residual list**: anything out of scope or requiring a product decision, flagged for the user.

**Self-check:** Re-run `quality-checks/validators/run_all.py` on the improved output and show the **before → after score delta**; confirm every previously failing validator (`token_lint`, `contrast_check`, `target_size_lint`, `state_coverage`, `dynamic_type_check`, `rtl_check`) now passes or is explicitly waived with a reason. Reason through `quality-checks/checklists/consistency.md` to ensure the diff didn't introduce new inconsistencies.
