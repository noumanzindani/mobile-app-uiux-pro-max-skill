# Audit Screen

**Purpose:** Produce a full, scored readiness review of an existing mobile screen — combining executable validators with prose-checklist reasoning — without editing the code.

**Inputs:**
- *Required:* **The screen** — source code and/or screenshot.
- *Required:* **Framework** (infer from code if not stated).
- **Platform target** (iOS / Android / cross-platform) — sets which platform-convention checklist applies.
- **Industry** — optional; enables domain-specific pitfalls (`industries/<industry>/pitfalls.md`).
- **Scope** — full audit (default) or a named subset (a11y-only, states-only, tokens-only).

**Procedure:**
1. Run the **15-point Pre-Generation Protocol** from `SKILL.md` §6.1 as an inspection lens (not to generate) — note every point the screen violates.
2. Open the pipeline spec — `quality-checks/_index.md` — to follow the canonical review order and scoring weights.
3. **Run every validator** (execute, do not load): `quality-checks/validators/run_all.py <input>`, which orchestrates `token_lint.py`, `contrast_check.py`, `target_size_lint.py`, `state_coverage.py`, `dynamic_type_check.py`, and `rtl_check.py`. Capture the JSON + markdown report and the weighted readiness score.
4. Reason through the **prose checklists** for the non-mechanical items validators can't judge: `quality-checks/checklists/accessibility.md`, `states.md`, `spacing.md`, `typography.md`, `contrast.md`, `platform-conventions.md`, `responsive.md`, `motion.md`, `consistency.md`.
5. Check platform fit — `rules/system/platform-conventions.md` — and flag any "neither-native" hybrid.
6. If an industry is given, load `industries/<industry>/pitfalls.md` and check for the common domain mistakes.
7. Consolidate every finding by severity (**error** blocks, **warning** deducts, **suggestion** informs), each tagged with its rule ID and a `file:line` (or screenshot region) reference and a one-line fix.

**Output format:** A **scored report** mirroring the store-readiness style:
- **Readiness score** (0–100) + per-category breakdown (tokens, contrast, targets, states, Dynamic Type, RTL, platform, motion, consistency).
- **Blockers / Warnings / Suggestions** lists — each item: rule ID, location, what's wrong, why it matters, the fix.
- **7-state coverage matrix** — which states are present/missing.
- The raw **validator report** (from `run_all.py`) appended verbatim.
- A short **verdict**: ship / fix-blockers-then-ship / not-ready.

**Self-check:** Confirm `run_all.py` actually executed and its output is embedded (not paraphrased); verify every checklist in `quality-checks/checklists/` was addressed; ensure each finding has a rule ID + location + fix. This prompt **must not modify the screen** — if the user wants fixes, hand off to `improve-screen.md`.
