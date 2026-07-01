#!/usr/bin/env python3
"""target_size_lint — flags likely-too-small touch targets.

Heuristic: on lines that reference an interactive element (button/icon-button/tap/
gesture/onPressed/onTap/InkWell/TouchableOpacity/Pressable), find explicit
width/height/size values and flag those below the platform minimum:
  iOS 44pt · Android/Material 48dp.  Bare icon glyph sizes < 24 are flagged unless
padding is present on the same line. Suppress with `// ux:ignore`.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _common import Finding, ERROR, WARNING, iter_source_files, lines_of  # noqa: E402

MIN_TARGET = 44          # conservative floor (iOS); Material prefers 48
INTERACTIVE = re.compile(
    r"(button|icon[-_ ]?button|onPressed|onTap|onClick|GestureDetector|InkWell|"
    r"TouchableOpacity|Pressable|clickable|IconButton|FloatingAction)",
    re.IGNORECASE,
)
SIZE_RE = re.compile(r"\b(width|height|size|minWidth|minHeight)\s*[:=]\s*(\d{1,4})(?:\.0)?",
                     re.IGNORECASE)
IGNORE = re.compile(r"ux:ignore")


def check(paths=None):
    findings = []
    for path, text in iter_source_files(paths or ["."]):
        for ln, line in lines_of(text):
            if IGNORE.search(line) or not INTERACTIVE.search(line):
                continue
            has_padding = "padding" in line.lower()
            for m in SIZE_RE.finditer(line):
                val = int(m.group(2))
                if val < MIN_TARGET and not has_padding:
                    findings.append(Finding(
                        "target_size_lint", "A11Y-TGT", ERROR, str(path), ln,
                        f"Interactive target {m.group(1)}={val} < {MIN_TARGET}pt/48dp minimum. "
                        f"Enlarge or pad the hit area (WCAG 2.5.8 / Apple 44pt / Material 48dp).",
                    ))
                elif MIN_TARGET <= val < 48:
                    findings.append(Finding(
                        "target_size_lint", "A11Y-TGT", WARNING, str(path), ln,
                        f"Target {m.group(1)}={val} meets iOS 44pt but is below Material 48dp.",
                    ))
    return findings


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    findings = check(argv or ["."])
    if not findings:
        print("✓ target_size_lint: PASS (no undersized targets found)")
    for f in findings:
        print(f.format())
    return 1 if any(f.severity == ERROR for f in findings) else 0


if __name__ == "__main__":
    raise SystemExit(main())
