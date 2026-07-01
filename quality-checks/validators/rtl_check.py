#!/usr/bin/env python3
"""rtl_check — flags layout that won't mirror correctly in right-to-left locales.

Heuristics: hardcoded left/right directional properties that should use start/end,
and left/right text alignment. Suppress with `// ux:ignore`.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _common import Finding, WARNING, iter_source_files, lines_of  # noqa: E402

PATTERNS = [
    (re.compile(r"EdgeInsets\.only\([^)]*\b(left|right)\s*:", re.I),
     "EdgeInsets.only(left/right:) — use EdgeInsetsDirectional.only(start/end:)."),
    (re.compile(r"(margin|padding)[-_]?(Left|Right)\b", re.I),
     "margin/padding Left/Right — use marginStart/marginEnd (start/end)."),
    (re.compile(r"TextAlign\.(left|right)\b", re.I),
     "TextAlign.left/right — use TextAlign.start/end so text mirrors in RTL."),
    (re.compile(r"textAlign\s*[:=]\s*['\"](left|right)['\"]", re.I),
     "textAlign 'left'/'right' — use 'start'/'end' (or logical properties)."),
    (re.compile(r"Alignment\.(centerLeft|centerRight|topLeft|topRight|bottomLeft|bottomRight)", re.I),
     "Physical Alignment.*Left/Right — prefer AlignmentDirectional (start/end)."),
    (re.compile(r"\b(left|right)\s*:\s*\d", re.I),
     "Absolute left/right offset — use start/end or logical inset for RTL."),
]
IGNORE = re.compile(r"ux:ignore")


def check(paths=None):
    findings = []
    for path, text in iter_source_files(paths or ["."]):
        for ln, line in lines_of(text):
            if IGNORE.search(line):
                continue
            for rx, msg in PATTERNS:
                if rx.search(line):
                    findings.append(Finding(
                        "rtl_check", "L10N-RTL", WARNING, str(path), ln, msg,
                    ))
                    break
    return findings


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    findings = check(argv or ["."])
    if not findings:
        print("✓ rtl_check: PASS (no hardcoded directional layout)")
    for f in findings:
        print(f.format())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
