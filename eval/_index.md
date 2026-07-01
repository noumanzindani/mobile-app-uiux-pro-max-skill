# Eval Harness

Turns the skill's quality claim into a **reproducible, CI-gated number**. No model
call, no API key — both ends of every comparison are committed to the repo, and only
the deterministic grader (the six validators) runs.

## What it measures

| Harness | Goal | Question it answers |
|---|---|---|
| `run_eval.py` | **G7** — beat baseline generation | How many readiness points does the skill add over typical no-skill output? |
| `trigger_test.py` | **G2** — reliable triggering | Does the `SKILL.md` description actually cover the words users type? |

## `run_eval.py` — quality lift

Two committed corpora, graded by the exact `score()` + validators that ship in
`quality-checks/validators/` (imported via `run_all`):

- **with-skill** = `examples/<scenario>/<framework>/` — what the skill produces (100/100).
- **baseline** = `eval/baselines/<scenario>/<framework>/` — intentionally-naive code an
  assistant typically emits *without* the skill (hardcoded hex, off-grid spacing,
  physical left/right insets, undersized targets, missing states).

Lift for a cell = `with_skill_score − baseline_score`.

**Gate (policy = "absolute + lift"):**
> PASS iff `min(with-skill score) == 100` **AND** `mean(with-skill − baseline) ≥ 40`.

The report leads with the *paired* means, so adding more with-skill examples never
inflates the headline — only adding baselines moves it.

> **Note on `contrast_check`:** it audits the shipped token palette, not the code under
> test, so it is constant across both corpora and does **not** drive the lift. The
> measured delta comes from the five source-scanning validators.

### Scenarios & coverage

Scenarios are declarative JSON in `eval/scenarios/*.json` (prompt · framework · required
states · must-pass validators · with-skill and baseline paths). **All 25 cells** (5
flagships × 5 frameworks) are paired — `test_full_baseline_coverage` fails CI if any
with-skill cell lacks a baseline, so a new scenario cannot silently ship unmeasured.
`run_eval.py` still logs any uncovered cell rather than implying coverage. To add a new
scenario, drop naive code under `eval/baselines/<scenario>/<framework>/` and reference it
from the scenario's `baseline` map.

The baselines are graded by the regex validators, never compiled — the SwiftUI cells
assume a `Color(hex:)` extension (as such code usually does) purely to carry a hardcoded
hex the way real naive SwiftUI would. Naive Jetpack Compose scores a little higher than
the others because its idioms (`.size(n.dp)` with parens, `start/end` insets) sidestep
`target_size_lint` and `rtl_check` even when hand-rolled — an honest quirk the mean
reflects rather than hides.

## `trigger_test.py` — activation coverage

1. **Coverage** — every flagship trigger keyword (`login`, `checkout`, `chat`,
   `dashboard`, `settings`, `accessibility`, each v1 framework, …) must appear in the
   description. Catches an abstract rewrite that silently drops concrete triggers.
2. **Corpus** — a labeled set of should/should-not-trigger prompts; requires
   recall ≥ 0.90 on positives and specificity ≥ 0.90 on negatives.

It's a *necessary-condition* proxy: the real trigger decision is the model's, but a
description whose vocabulary doesn't cover user phrasing can never fire reliably.

## Run

```bash
python3 eval/run_eval.py            # lift report + gate exit code
python3 eval/run_eval.py --json     # machine-readable
python3 eval/trigger_test.py        # trigger coverage report + gate
python3 -m pytest eval/tests -q     # harness self-tests (incl. "the gate bites")
```

Both harnesses exit non-zero on gate failure, so CI gates on them directly
(`.github/workflows/ci.yml`).
