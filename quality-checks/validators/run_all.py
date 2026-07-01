#!/usr/bin/env python3
"""run_all — orchestrates every validator and prints a weighted readiness report.

Usage:
    python3 quality-checks/validators/run_all.py [path ...] [--json]

Aggregates findings from all six validators, computes a weighted readiness score
(errors block, warnings deduct, suggestions inform), and prints a markdown report.
Exit code is non-zero if any error-severity finding is present, so CI can gate on it.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _common import ERROR, WARNING, SUGGESTION, SEVERITY_WEIGHT  # noqa: E402
import contrast_check          # noqa: E402
import target_size_lint        # noqa: E402
import state_coverage          # noqa: E402
import token_lint              # noqa: E402
import dynamic_type_check      # noqa: E402
import rtl_check               # noqa: E402

VALIDATORS = [
    ("token_lint", token_lint.check),
    ("contrast_check", contrast_check.check),
    ("target_size_lint", target_size_lint.check),
    ("state_coverage", state_coverage.check),
    ("dynamic_type_check", dynamic_type_check.check),
    ("rtl_check", rtl_check.check),
]


def score(findings):
    """0–100 readiness. Each finding subtracts its weight, floored at 0."""
    penalty = sum(SEVERITY_WEIGHT.get(f.severity, 1) for f in findings)
    return max(0, 100 - penalty)


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    as_json = "--json" in argv
    paths = [a for a in argv if a != "--json"] or ["."]

    all_findings = []
    per_validator = {}
    for name, fn in VALIDATORS:
        try:
            found = fn(paths)
        except Exception as exc:  # a broken validator must not sink the run
            print(f"! {name} errored: {exc}", file=sys.stderr)
            found = []
        per_validator[name] = found
        all_findings.extend(found)

    errors = [f for f in all_findings if f.severity == ERROR]
    warnings = [f for f in all_findings if f.severity == WARNING]
    suggestions = [f for f in all_findings if f.severity == SUGGESTION]
    readiness = score(all_findings)

    if as_json:
        print(json.dumps({
            "readiness": readiness,
            "counts": {"error": len(errors), "warning": len(warnings),
                       "suggestion": len(suggestions)},
            "findings": [f.as_dict() for f in all_findings],
        }, indent=2))
        return 1 if errors else 0

    print(f"# Mobile UI/UX Readiness Report\n")
    print(f"**Readiness score: {readiness}/100**  "
          f"— {len(errors)} error · {len(warnings)} warning · {len(suggestions)} suggestion\n")
    verdict = "BLOCKED — fix errors before ship" if errors else (
        "PASS (with polish items)" if warnings else "PASS — clean")
    print(f"**Verdict:** {verdict}\n")
    for name, found in per_validator.items():
        status = "PASS" if not found else f"{len(found)} finding(s)"
        print(f"## {name} — {status}")
        for f in found:
            print(f"- `{f.severity}` {f.rule_id} — {f.file}:{f.line or '-'} — {f.message}")
        print()
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
