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
states · must-pass validators · with-skill and baseline paths). Baselines currently
cover **login** and **checkout** across Flutter + React Native (4 paired cells); the
other 16 with-skill cells are graded but unpaired, and `run_eval.py` **logs every
uncovered cell** rather than implying full coverage. To widen the measured delta, add a
folder under `eval/baselines/<scenario>/<framework>/` and reference it from the scenario's
`baseline` map.

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
