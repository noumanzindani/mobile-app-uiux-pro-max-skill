#!/usr/bin/env python3
"""token_lint — flags hardcoded design values that should be tokens.

Heuristic source linter. Detects:
  - Hardcoded hex colors in UI code (should reference a semantic color token).
  - Off-grid spacing/padding literals (not a multiple of 4).
It intentionally ignores token definition files (design-system/tokens/**) and
comments. Heuristic: prefer few false positives; suppress a line with `// ux:ignore`.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _common import Finding, WARNING, ERROR, iter_source_files, lines_of, HEX_RE  # noqa: E402

IGNORE = re.compile(r"ux:ignore")
COMMENT = re.compile(r"^\s*(//|#|/\*|\*)")
# spacing-ish properties followed by a raw number
SPACING_RE = re.compile(
    r"(padding|margin|gap|spacing|EdgeInsets\.(all|symmetric|only)|SizedBox|"
    r"\bheight|\bwidth)\b[^;\n]*?(?<![\w.])(\d{1,4})(?:\.0)?\b",
    re.IGNORECASE,
)
NAMED_COLOR = re.compile(r"\bColor\(0x[0-9a-fA-F]{8}\)")  # Flutter ARGB literal


def check(paths=None):
    findings = []
    for path, text in iter_source_files(paths or ["."]):
        if "design-system/tokens" in str(path):
            continue
        for ln, line in lines_of(text):
            if IGNORE.search(line) or COMMENT.match(line):
                continue
            for m in HEX_RE.finditer(line):
                findings.append(Finding(
                    "token_lint", "COL-TOK", ERROR, str(path), ln,
                    f"Hardcoded color '{m.group(0)}' — reference a semantic color token instead.",
                ))
            for m in NAMED_COLOR.finditer(line):
                findings.append(Finding(
                    "token_lint", "COL-TOK", ERROR, str(path), ln,
                    f"Hardcoded ARGB color '{m.group(0)}' — use a token.",
                ))
            for m in SPACING_RE.finditer(line):
                val = int(m.group(3))
                if val not in (0, 1) and val % 4 != 0 and val < 1000:
                    findings.append(Finding(
                        "token_lint", "SPC-TOK", WARNING, str(path), ln,
                        f"Off-grid value {val} for '{m.group(1)}' — snap to the 4/8pt grid "
                        f"or use a spacing token.",
                    ))
    return findings


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    findings = check(argv or ["."])
    if not findings:
        print("✓ token_lint: PASS (no hardcoded values)")
    for f in findings:
        print(f.format())
    return 1 if any(f.severity == ERROR for f in findings) else 0


if __name__ == "__main__":
    raise SystemExit(main())
