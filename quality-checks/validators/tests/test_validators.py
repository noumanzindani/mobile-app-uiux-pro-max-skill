"""Pytest suite for the Mobile UI/UX Pro Max validators.

Run:  pytest quality-checks/validators/tests
It proves the six validators fire on the golden BAD fixture and stay silent on
the golden GOOD fixture, and checks the WCAG contrast math against known values.
"""
import sys
from pathlib import Path

VALIDATORS = Path(__file__).resolve().parents[1]
FIXTURES = Path(__file__).resolve().parent / "fixtures"
GOOD = str(FIXTURES / "good_screen.dart")
BAD = str(FIXTURES / "bad_screen.dart")
sys.path.insert(0, str(VALIDATORS))

import _common  # noqa: E402
import token_lint, target_size_lint, state_coverage  # noqa: E402
import dynamic_type_check, rtl_check, contrast_check  # noqa: E402
import run_all  # noqa: E402


# --- WCAG contrast math ------------------------------------------------------
def test_contrast_black_on_white_is_21():
    assert _common.contrast_ratio("#000000", "#FFFFFF") == 21.0

def test_contrast_identical_is_1():
    assert _common.contrast_ratio("#777777", "#777777") == 1.0

def test_contrast_shorthand_hex():
    assert _common.contrast_ratio("#000", "#FFF") == 21.0

def test_theme_palette_passes():
    # our shipped palette must meet WCAG AA on every audited pair
    assert contrast_check.check() == []


# --- token_lint --------------------------------------------------------------
def test_token_lint_flags_bad():
    ids = {f.rule_id for f in token_lint.check([BAD])}
    assert "COL-TOK" in ids   # hardcoded ARGB colors
    assert "SPC-TOK" in ids   # off-grid spacing (13, 30)

def test_token_lint_clean_on_good():
    assert token_lint.check([GOOD]) == []


# --- target_size_lint --------------------------------------------------------
def test_target_size_flags_bad():
    errs = [f for f in target_size_lint.check([BAD]) if f.severity == _common.ERROR]
    assert errs, "expected an undersized interactive target error"

def test_target_size_clean_on_good():
    assert target_size_lint.check([GOOD]) == []


# --- rtl_check ---------------------------------------------------------------
def test_rtl_flags_bad():
    assert rtl_check.check([BAD]), "expected hardcoded left/right findings"

def test_rtl_clean_on_good():
    assert rtl_check.check([GOOD]) == []


# --- dynamic_type_check ------------------------------------------------------
def test_dynamic_type_flags_bad():
    ids = {f.rule_id for f in dynamic_type_check.check([BAD])}
    assert "A11Y-DYN" in ids or "TYP-MIN" in ids

def test_dynamic_type_clean_on_good():
    assert dynamic_type_check.check([GOOD]) == []


# --- state_coverage ----------------------------------------------------------
def test_state_coverage_flags_missing_states():
    assert state_coverage.check([BAD]), "bad screen declares no states"

def test_state_coverage_clean_on_good():
    assert state_coverage.check([GOOD]) == []


# --- run_all orchestration ---------------------------------------------------
def test_run_all_scores_bad_below_100():
    findings = []
    for _, fn in run_all.VALIDATORS:
        findings.extend(fn([BAD]))
    assert run_all.score(findings) < 100

def test_run_all_scores_good_100():
    findings = []
    for _, fn in run_all.VALIDATORS:
        findings.extend(fn([GOOD]))
    assert run_all.score(findings) == 100
