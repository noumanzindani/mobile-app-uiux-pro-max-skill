#!/usr/bin/env python3
"""state_coverage — checks a screen for the required UI states.

The skill mandates 7 states; this validator checks for evidence of the four that
are most often skipped: loading, empty, error, offline. It is a keyword heuristic
run per source file (a "screen"). Absence is reported as a warning (loading/empty/
error) or suggestion (offline). Use it as a prompt, not a proof.

Run on a single screen file for best signal:
    python3 state_coverage.py lib/screens/home_screen.dart
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _common import Finding, WARNING, SUGGESTION, iter_source_files  # noqa: E402

SIGNALS = {
    "loading": re.compile(r"(isLoading|loading|CircularProgress|ActivityIndicator|"
                          r"skeleton|shimmer|ProgressIndicator|\.loading)", re.I),
    "empty":   re.compile(r"(empty[_ ]?state|emptyState|isEmpty|no[_ ]?results|"
                          r"placeholder|nothing[_ ]?here|no[_ ]?data)", re.I),
    "error":   re.compile(r"(error[_ ]?state|onError|hasError|isError|catchError|"
                          r"try[_ ]?again|retry|\.error)", re.I),
    "offline": re.compile(r"(offline|connectivity|no[_ ]?connection|isConnected|"
                          r"NetworkStatus|reconnect)", re.I),
}
SEVERITY = {"loading": WARNING, "empty": WARNING, "error": WARNING, "offline": SUGGESTION}
# only look at files that look like screens/pages/views
SCREENISH = re.compile(r"(screen|page|view|route|_ui|scaffold)", re.I)


def check(paths=None):
    findings = []
    for path, text in iter_source_files(paths or ["."]):
        if not SCREENISH.search(path.name) and not SCREENISH.search(text[:400]):
            continue
        for state, rx in SIGNALS.items():
            if not rx.search(text):
                findings.append(Finding(
                    "state_coverage", "STATE-COV", SEVERITY[state], str(path), 0,
                    f"No '{state}' state detected. Design the {state} state "
                    f"(see rules/interaction/states.md).",
                ))
    return findings


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    findings = check(argv or ["."])
    if not findings:
        print("✓ state_coverage: PASS (loading/empty/error/offline signals present)")
    for f in findings:
        print(f.format())
    return 0  # never blocks; states are a warning-level nudge


if __name__ == "__main__":
    raise SystemExit(main())
