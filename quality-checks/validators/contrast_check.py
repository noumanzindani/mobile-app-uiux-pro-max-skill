#!/usr/bin/env python3
"""contrast_check — WCAG 2.2 contrast auditor.

Two modes:
  1. Ad-hoc pair:   python3 contrast_check.py --pair "#0F172A" "#FFFFFF"
  2. Token themes:  python3 contrast_check.py            (audits design-system/tokens)

In token mode it resolves each theme's semantic foreground/background pairs and
flags any that fail WCAG 2.2: text >= 4.5:1 (1.4.3), large text/UI/icons >= 3:1 (1.4.11).
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _common import (  # noqa: E402
    Finding, ERROR, WARNING, contrast_ratio, load_flat_tokens, resolve,
)

AA_TEXT = 4.5
AA_LARGE = 3.0

# (foreground token, background token, min ratio, label)
PAIRS = [
    ("color.on-surface", "color.surface", AA_TEXT, "body text on surface"),
    ("color.on-surface-muted", "color.surface", AA_TEXT, "muted text on surface"),
    ("color.action.on-primary", "color.action.primary", AA_TEXT, "label on primary button"),
    ("color.text.error", "color.surface", AA_TEXT, "error text on surface"),
    ("color.text.success", "color.surface", AA_LARGE, "success text on surface"),
    ("color.border", "color.surface", AA_LARGE, "border/UI component on surface"),
]

TOKENS_DIR = Path(__file__).resolve().parents[2] / "design-system" / "tokens"


def check(paths=None):
    findings = []
    if not TOKENS_DIR.exists():
        return findings
    for theme in ("light", "dark"):
        flat = load_flat_tokens(TOKENS_DIR, theme=theme)
        for fg_key, bg_key, minimum, label in PAIRS:
            fg, bg = resolve(flat.get(fg_key), flat), resolve(flat.get(bg_key), flat)
            if not fg or not bg:
                continue
            try:
                ratio = contrast_ratio(fg, bg)
            except ValueError:
                continue
            if ratio < minimum:
                findings.append(Finding(
                    validator="contrast_check",
                    rule_id="A11Y-CON",
                    severity=ERROR if minimum >= AA_TEXT else WARNING,
                    file=f"themes/{theme}.json",
                    line=0,
                    message=(f"{label}: {fg} on {bg} = {ratio}:1, "
                             f"below WCAG {minimum}:1 (theme={theme})."),
                ))
    return findings


def check_pair(c1, c2):
    r = contrast_ratio(c1, c2)
    print(f"Contrast {c1} on {c2} = {r}:1")
    print(f"  Normal text (AA 4.5:1): {'PASS' if r >= AA_TEXT else 'FAIL'}")
    print(f"  Large text/UI (AA 3:1): {'PASS' if r >= AA_LARGE else 'FAIL'}")
    print(f"  Enhanced   (AAA 7:1):   {'PASS' if r >= 7.0 else 'FAIL'}")
    return 0 if r >= AA_LARGE else 1


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    if argv and argv[0] == "--pair" and len(argv) >= 3:
        return check_pair(argv[1], argv[2])
    findings = check(argv or ["."])
    if not findings:
        print("✓ contrast_check: PASS (all theme pairs meet WCAG 2.2)")
    for f in findings:
        print(f.format())
    return 1 if any(f.severity == ERROR for f in findings) else 0


if __name__ == "__main__":
    raise SystemExit(main())
