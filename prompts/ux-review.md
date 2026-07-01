# UX Review

**Purpose:** Critique a screen or flow against usability heuristics and mobile ergonomics (thumb reach, touch targets, information hierarchy, state design, platform conventions), returning findings ranked by severity.

**Inputs:**
- *Required:* **The screen or flow** — code, screenshot(s), or a step-by-step description.
- **Framework / platform target** — optional; sharpens platform-convention and ergonomics findings.
- **Industry** — optional; enables domain UX expectations (`industries/<industry>/patterns.md`, `pitfalls.md`).
- **Primary user goal & context** (one-handed on the go? tablet? high-stakes/irreversible actions?) — optional but improves relevance.

**Procedure:**
1. Run the **15-point Pre-Generation Protocol** from `SKILL.md` §6.1 as a heuristic lens; note where user goal, hierarchy, and reach are unclear or wrong.
2. Load ergonomics + interaction rules — `rules/foundations/grid.md` (responsive/size classes), `rules/interaction/gestures.md`, `rules/components/nav.md`, and `rules/components/buttons.md` (one primary action; destructive placement).
3. Load state design — `rules/interaction/states.md` and `patterns/empty-error-offline.md` — and evaluate whether all applicable states are designed, not just the ideal state.
4. Load platform conventions — `rules/system/platform-conventions.md` — and check nav/sheet/back/gesture correctness for the target OS.
5. If a multi-screen flow, load the matching recipe: `patterns/form-flows.md`, `patterns/checkout-patterns.md`, `patterns/onboarding-patterns.md`, `patterns/search-patterns.md`, or `patterns/feed-patterns.md`.
6. Reason through `quality-checks/checklists/platform-conventions.md`, `responsive.md`, and `consistency.md`.
7. Evaluate against core heuristics: visibility of system status, match to real-world/platform conventions, user control & undo, error prevention & recovery, recognition over recall, minimalist hierarchy, and thumb-zone placement of primary/destructive actions (out of the thumb arc when irreversible).

**Output format:** **Findings ranked by severity** (blocker / major / minor / nitpick):
- Each finding: heuristic or rule ID · location · what's wrong · user impact · recommended change.
- A **thumb-zone / one-handed assessment** (where do primary and destructive actions land?).
- A **state-design assessment** (which of the 7 states are missing or under-designed).
- A **flow assessment** (for multi-screen: friction points, dead-ends, missing back/undo/confirm).
- A short **prioritized fix list** (top 3–5 changes by impact).

**Self-check:** Run `quality-checks/validators/target_size_lint.py` to back the touch-target findings with data and `state_coverage.py` to back the state findings; confirm every finding maps to a heuristic or rule ID and names a concrete change. Reason through `quality-checks/checklists/consistency.md`. Do not rewrite the screen — hand actionable fixes to `improve-screen.md` if the user wants them applied.
