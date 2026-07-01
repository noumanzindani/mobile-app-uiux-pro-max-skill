# Quality Checks — Review Pipeline & Scoring

> Purpose: how to audit a screen. Two layers: **executable validators** (deterministic,
> run not loaded) and **prose checklists** (model-judged, for non-mechanical items).

## Run the pipeline

```bash
# whole project or a single screen
python3 quality-checks/validators/run_all.py [path ...]
python3 quality-checks/validators/run_all.py --json lib/screens/home_screen.dart
```

`run_all.py` runs all six validators, aggregates findings, and prints a weighted
**readiness score** with a per-validator breakdown. Exit code is non-zero if any
**error**-severity finding exists, so CI can gate on it.

### The six validators
| Validator | Rule IDs | Enforces |
|---|---|---|
| `token_lint.py` | COL-TOK, SPC-TOK | no hardcoded color/spacing; 4/8pt grid |
| `contrast_check.py` | A11Y-CON | WCAG 2.2 text ≥4.5:1, UI/large ≥3:1 (per theme) |
| `target_size_lint.py` | A11Y-TGT | ≥44pt/48dp interactive targets |
| `state_coverage.py` | STATE-COV | loading/empty/error/offline present |
| `dynamic_type_check.py` | A11Y-DYN, TYP-MIN | no fixed text heights; ≥12pt |
| `rtl_check.py` | L10N-RTL | no hardcoded left/right; use start/end |

Ad-hoc contrast: `python3 quality-checks/validators/contrast_check.py --pair "#111" "#FFF"`.
Suppress a single line a validator misjudges with a `// ux:ignore` comment.

## Scoring
Readiness = `max(0, 100 − Σ weight)` where error=10, warning=3, suggestion=1.
- **error** → BLOCKED (fix before ship — breaks a11y/platform contract).
- **warning** → PASS with polish items (quality regressions).
- **suggestion** → informational (taste/polish).

## Prose checklists (model-judged)
After validators pass, reason through the domain checklists in `checklists/` for the
items no linter can see (hierarchy, platform paradigm correctness, motion purpose,
consistency, copy tone). Start with `checklists/accessibility.md` and
`checklists/states.md`.

## When to run
- After generating any screen (self-audit — see the Pre-Generation Protocol in `SKILL.md`).
- In `prompts/audit-screen.md` and `prompts/accessibility-review.md`.
- In CI (`.github/workflows/ci.yml`) on the golden examples as a regression gate.
