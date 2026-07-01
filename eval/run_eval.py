#!/usr/bin/env python3
"""run_eval — measures the Mobile UI/UX Pro Max skill's quality lift, and gates CI.

The eval fixes both ends of the comparison so the result is 100% reproducible with
no model call and no API key:

  * with-skill  = the committed flagship examples (examples/<scenario>/<framework>/),
                  i.e. what the skill produces.
  * baseline    = committed, intentionally-naive "no-skill" code
                  (eval/baselines/<scenario>/<framework>/), i.e. what an assistant
                  typically emits WITHOUT the skill.

Only the *grader* runs: every cell is scored by the exact same six validators and
`score()` that ship in quality-checks/validators (via run_all). The delta between
the two corpora is the skill's measured lift.

Gate (chosen policy — "absolute + lift"):
  PASS iff  min(with-skill score) == 100  AND  mean(with-skill - baseline) >= 40.

Note on contrast_check: it audits the shipped token palette, not the code under
test, so it is a constant across both corpora and does not drive the lift number —
the measurable delta comes from the five source-scanning validators.

Usage:
    python3 eval/run_eval.py            # human report + gate exit code
    python3 eval/run_eval.py --json     # machine-readable results
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VALIDATORS_DIR = ROOT / "quality-checks" / "validators"
SCENARIOS_DIR = Path(__file__).resolve().parent / "scenarios"

sys.path.insert(0, str(VALIDATORS_DIR))
import run_all                                    # noqa: E402
from _common import SOURCE_EXTS                   # noqa: E402

# --- gate policy (see module docstring) --------------------------------------
WITH_SKILL_FLOOR = 100      # every with-skill cell must be perfect
MIN_MEAN_LIFT = 40          # mean(with-skill - baseline) must clear this


def load_scenarios():
    """Return scenario dicts sorted by id (stable report order)."""
    scenarios = []
    for f in sorted(SCENARIOS_DIR.glob("*.json")):
        scenarios.append(json.loads(f.read_text(encoding="utf-8")))
    return sorted(scenarios, key=lambda s: s["id"])


def cell_files(rel):
    """Explicit source-file paths under a cell dir.

    We enumerate and pass files explicitly (not the dir) so grading is identical
    for examples/ and for eval/baselines/ — the latter is in EXCLUDE_DIRS, which
    only affects *directory* walks, never explicit file args.
    """
    d = ROOT / rel
    if not d.exists():
        return []
    return [str(p) for p in sorted(d.rglob("*"))
            if p.is_file() and p.suffix in SOURCE_EXTS]


def score_cell(rel):
    """(score, findings) for a cell, or (None, []) if the cell has no source."""
    files = cell_files(rel)
    if not files:
        return None, []
    findings = []
    for _name, fn in run_all.VALIDATORS:
        try:
            findings.extend(fn(files))
        except Exception as exc:  # a broken validator must not sink the eval
            print(f"! validator {_name} errored on {rel}: {exc}", file=sys.stderr)
    return run_all.score(findings), findings


def evaluate():
    """Grade every cell and assemble the results structure + verdict."""
    scenarios = load_scenarios()
    rows = []            # per with-skill cell, with optional paired baseline
    for scn in scenarios:
        for fw, ws_rel in sorted(scn.get("with_skill", {}).items()):
            ws_score, _ = score_cell(ws_rel)
            bl_rel = scn.get("baseline", {}).get(fw)
            bl_score = score_cell(bl_rel)[0] if bl_rel else None
            lift = (ws_score - bl_score) if (ws_score is not None and bl_score is not None) else None
            rows.append({
                "scenario": scn["id"], "framework": fw,
                "with_skill": ws_score, "baseline": bl_score, "lift": lift,
                "baseline_path": bl_rel,
            })

    ws_scores = [r["with_skill"] for r in rows]
    paired = [r for r in rows if r["lift"] is not None]
    lifts = [r["lift"] for r in paired]

    # a None score means a with-skill cell had no source — treat as 0 so it both
    # shows up as the min and fails the floor.
    min_ws = min((s if s is not None else 0 for s in ws_scores), default=0)
    mean_lift = round(sum(lifts) / len(lifts), 1) if lifts else None
    mean_ws_paired = round(sum(r["with_skill"] for r in paired) / len(paired), 1) if paired else None
    mean_bl_paired = round(sum(r["baseline"] for r in paired) / len(paired), 1) if paired else None

    floor_ok = all(s == WITH_SKILL_FLOOR for s in ws_scores) and bool(ws_scores)
    lift_ok = mean_lift is not None and mean_lift >= MIN_MEAN_LIFT
    gate_pass = floor_ok and lift_ok

    gaps = [f"{r['scenario']}/{r['framework']}" for r in rows if r["lift"] is None]

    return {
        "rows": rows,
        "summary": {
            "with_skill_cells": len(rows),
            "min_with_skill": min_ws,
            "baseline_cells": len(paired),
            "mean_with_skill_paired": mean_ws_paired,
            "mean_baseline_paired": mean_bl_paired,
            "mean_lift": mean_lift,
            "floor_ok": floor_ok,
            "lift_ok": lift_ok,
            "gate_pass": gate_pass,
            "policy": {"with_skill_floor": WITH_SKILL_FLOOR, "min_mean_lift": MIN_MEAN_LIFT},
            "coverage_gaps": gaps,
        },
    }


def render_markdown(result):
    s = result["summary"]
    out = ["# Mobile UI/UX Pro Max — Eval Report", ""]
    headline = (f"**Mean lift +{s['mean_lift']} pts** "
                f"({s['mean_with_skill_paired']} with-skill vs {s['mean_baseline_paired']} baseline) "
                f"over {s['baseline_cells']} paired cells."
                if s["mean_lift"] is not None else
                "**No baseline cells found — lift cannot be measured.**")
    out += [headline, ""]
    verdict = "✅ PASS" if s["gate_pass"] else "❌ FAIL"
    out += [f"**Gate:** {verdict} — floor(min with-skill == {s['policy']['with_skill_floor']}): "
            f"{'ok' if s['floor_ok'] else 'FAIL'} "
            f"(min={s['min_with_skill']}); "
            f"lift(mean >= {s['policy']['min_mean_lift']}): "
            f"{'ok' if s['lift_ok'] else 'FAIL'}.", ""]
    out += ["| Scenario | Framework | With-skill | Baseline | Lift |",
            "|---|---|---:|---:|---:|"]
    for r in result["rows"]:
        bl = "—" if r["baseline"] is None else str(r["baseline"])
        lift = "—" if r["lift"] is None else f"+{r['lift']}"
        ws = "missing" if r["with_skill"] is None else str(r["with_skill"])
        out.append(f"| {r['scenario']} | {r['framework']} | {ws} | {bl} | {lift} |")
    out.append("")
    if s["coverage_gaps"]:
        out += [f"> Coverage: {s['baseline_cells']} of {s['with_skill_cells']} with-skill "
                f"cells have a baseline. No baseline yet for: "
                f"{', '.join(s['coverage_gaps'])}. "
                f"Add one under eval/baselines/<scenario>/<framework>/ to widen the measured delta.",
                ""]
    return "\n".join(out)


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    result = evaluate()
    if "--json" in argv:
        print(json.dumps(result, indent=2))
    else:
        print(render_markdown(result))
    return 0 if result["summary"]["gate_pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
