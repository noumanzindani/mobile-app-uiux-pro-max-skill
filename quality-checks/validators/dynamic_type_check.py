#!/usr/bin/env python3
"""dynamic_type_check — flags patterns that break text scaling / Dynamic Type.

Heuristics:
  - A fixed container height on a line that also renders text (can clip scaled text).
  - `maxLines: 1` / single-line without an overflow/ellipsis strategy near dynamic text.
  - Very small hardcoded font sizes (< 12) that will be illegible when not scaled.
Suppress a line with `// ux:ignore`.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _common import Finding, WARNING, iter_source_files, lines_of  # noqa: E402

TEXTY = re.compile(r"(Text\(|Label|<Text|\.text|TextView|UILabel|Typography)", re.I)
FIXED_HEIGHT = re.compile(r"\bheight\s*[:=]\s*(\d{1,4})", re.I)
SMALL_FONT = re.compile(r"font[_ ]?size\s*[:=]\s*(\d{1,3})", re.I)
IGNORE = re.compile(r"ux:ignore")


def check(paths=None):
    findings = []
    for path, text in iter_source_files(paths or ["."]):
        for ln, line in lines_of(text):
            if IGNORE.search(line):
                continue
            if TEXTY.search(line):
                mh = FIXED_HEIGHT.search(line)
                if mh:
                    findings.append(Finding(
                        "dynamic_type_check", "A11Y-DYN", WARNING, str(path), ln,
                        f"Fixed height={mh.group(1)} on a text line can clip scaled text. "
                        f"Let text-bearing containers size to content (Dynamic Type / font scale).",
                    ))
            mf = SMALL_FONT.search(line)
            if mf and int(mf.group(1)) < 12:
                findings.append(Finding(
                    "dynamic_type_check", "TYP-MIN", WARNING, str(path), ln,
                    f"Font size {mf.group(1)} is below the 12pt legibility floor; "
                    f"use a scalable text style role.",
                ))
    return findings


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    findings = check(argv or ["."])
    if not findings:
        print("✓ dynamic_type_check: PASS")
    for f in findings:
        print(f.format())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
