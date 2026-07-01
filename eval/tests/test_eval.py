"""Tests for the eval harness (run_eval + trigger_test).

Run:  python3 -m pytest eval/tests -q

These prove three things:
  1. The lift measurement is real — every with-skill cell beats its baseline, the
     with-skill floor holds at 100, and the mean lift clears the gate.
  2. The trigger coverage holds — the shipped description passes recall/specificity
     and carries every required keyword.
  3. The gates actually BITE — a degraded description and an un-scoreable cell make
     the respective harness FAIL, so a green run means something.
"""
import sys
import tempfile
from pathlib import Path

EVAL = Path(__file__).resolve().parents[1]
ROOT = EVAL.parent
sys.path.insert(0, str(EVAL))

import run_eval        # noqa: E402
import trigger_test    # noqa: E402


# --- run_eval: the lift is real ----------------------------------------------
def test_eval_gate_passes():
    assert run_eval.evaluate()["summary"]["gate_pass"] is True

def test_every_with_skill_cell_is_perfect():
    rows = run_eval.evaluate()["rows"]
    assert rows, "no with-skill cells were graded"
    assert all(r["with_skill"] == 100 for r in rows), \
        [f"{r['scenario']}/{r['framework']}={r['with_skill']}" for r in rows if r["with_skill"] != 100]

def test_mean_lift_clears_floor():
    s = run_eval.evaluate()["summary"]
    assert s["mean_lift"] is not None
    assert s["mean_lift"] >= run_eval.MIN_MEAN_LIFT

def test_each_paired_baseline_loses_to_with_skill():
    rows = [r for r in run_eval.evaluate()["rows"] if r["lift"] is not None]
    assert rows, "expected at least one paired baseline cell"
    for r in rows:
        assert r["lift"] > 0, f"{r['scenario']}/{r['framework']} baseline did not lose"
        assert r["baseline"] < 100

def test_a_known_baseline_scores_low():
    # the login/flutter baseline is intentionally bad; it must not sneak near 100
    score, findings = run_eval.score_cell("eval/baselines/login/flutter")
    assert score is not None and score < 50
    assert findings, "baseline should produce findings"

def test_missing_cell_scores_none():
    assert run_eval.score_cell("eval/baselines/does/not/exist") == (None, [])


# --- run_eval: the gate bites ------------------------------------------------
def test_floor_fails_when_a_with_skill_cell_is_unscoreable(monkeypatch):
    # if a with-skill cell has no source (score None), the floor must fail.
    real = run_eval.score_cell

    def fake(rel):
        if rel == "examples/login/flutter":
            return (None, [])
        return real(rel)

    monkeypatch.setattr(run_eval, "score_cell", fake)
    assert run_eval.evaluate()["summary"]["floor_ok"] is False


# --- trigger_test: coverage + corpus -----------------------------------------
def test_trigger_gate_passes():
    assert trigger_test.evaluate()["gate_pass"] is True

def test_trigger_has_no_missing_keywords():
    assert trigger_test.evaluate()["missing_keywords"] == []

def test_trigger_meets_recall_and_specificity():
    r = trigger_test.evaluate()
    assert r["recall"] >= trigger_test.RECALL_TARGET
    assert r["specificity"] >= trigger_test.SPECIFICITY_TARGET


# --- trigger_test: the gate bites --------------------------------------------
def _write_skill(description):
    tmp = Path(tempfile.mkdtemp()) / "SKILL.md"
    tmp.write_text(f"---\nname: x\ndescription: >-\n  {description}\nlicense: Apache-2.0\n---\n# body\n")
    return tmp

def test_trigger_fails_on_degraded_description():
    # a vague description that drops every concrete trigger keyword must FAIL.
    degraded = _write_skill("A helpful assistant for making nice things look good.")
    r = trigger_test.evaluate(degraded)
    assert r["gate_pass"] is False
    assert r["missing_keywords"], "degraded description should be missing required keywords"

def test_read_description_parses_folded_block():
    md = _write_skill("Design a login screen in Flutter with dark mode and RTL.")
    desc = trigger_test.read_description(md)
    assert "login" in desc.lower() and "flutter" in desc.lower()
