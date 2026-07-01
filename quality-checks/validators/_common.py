"""Shared helpers for the Mobile UI/UX Pro Max validators.

Stdlib-only. Every validator exposes `check(paths) -> list[Finding]` and a CLI
`main()` that prints findings and exits non-zero if any error-severity finding
is present. `run_all.py` imports each `check()` and aggregates a weighted score.
"""
from __future__ import annotations

import json
import os
import re
from dataclasses import dataclass, asdict
from pathlib import Path

# --- severity ----------------------------------------------------------------
ERROR, WARNING, SUGGESTION = "error", "warning", "suggestion"
SEVERITY_WEIGHT = {ERROR: 10, WARNING: 3, SUGGESTION: 1}

SOURCE_EXTS = {".dart", ".ts", ".tsx", ".js", ".jsx", ".swift", ".kt", ".kts",
               ".xml", ".vue", ".cs", ".xaml"}


@dataclass
class Finding:
    validator: str
    rule_id: str
    severity: str
    file: str
    line: int
    message: str

    def as_dict(self):
        return asdict(self)

    def format(self) -> str:
        loc = f"{self.file}:{self.line}" if self.line else self.file
        return f"[{self.severity.upper():10}] {self.rule_id:10} {loc}\n    {self.message}"


# --- file iteration ----------------------------------------------------------
def iter_source_files(paths, exts=SOURCE_EXTS):
    """Yield (Path, text) for every source file under the given paths."""
    for raw in _as_list(paths):
        p = Path(raw)
        if p.is_file():
            if p.suffix in exts:
                yield p, _read(p)
        elif p.is_dir():
            for f in sorted(p.rglob("*")):
                s = str(f)
                if (f.is_file() and f.suffix in exts
                        and not any(x in s for x in EXCLUDE_DIRS)):
                    yield f, _read(f)


# Directories excluded from *recursive* scans (explicit file args are always read,
# so test fixtures and eval baselines can still be validated directly).
# `eval/baselines/` holds intentionally-bad "no-skill" reference code used by the
# eval harness; it must never pollute a repo-wide `run_all.py .` scan.
EXCLUDE_DIRS = ("build/output", "/fixtures/", "validators/tests", "/.git/",
                "/node_modules/", "/.dart_tool/", "eval/baselines/")


def _as_list(x):
    if x is None:
        return ["."]
    return x if isinstance(x, (list, tuple)) else [x]


def _read(p: Path) -> str:
    try:
        return p.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def lines_of(text: str):
    return enumerate(text.splitlines(), start=1)


# --- color / contrast (WCAG 2.x) --------------------------------------------
HEX_RE = re.compile(r"#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})\b")


def parse_hex(s: str):
    """Return (r, g, b) 0–255 from #RGB / #RRGGBB / #RRGGBBAA, else None."""
    m = HEX_RE.search(s.strip())
    if not m:
        return None
    h = m.group(1)
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def _lin(c: float) -> float:
    c /= 255.0
    return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4


def relative_luminance(rgb) -> float:
    r, g, b = rgb
    return 0.2126 * _lin(r) + 0.7152 * _lin(g) + 0.0722 * _lin(b)


def contrast_ratio(hex1: str, hex2: str) -> float:
    c1, c2 = parse_hex(hex1), parse_hex(hex2)
    if not c1 or not c2:
        raise ValueError(f"bad hex: {hex1!r} {hex2!r}")
    l1, l2 = relative_luminance(c1), relative_luminance(c2)
    hi, lo = max(l1, l2), min(l1, l2)
    return round((hi + 0.05) / (lo + 0.05), 2)


# --- DTCG token loading + alias resolution -----------------------------------
def flatten_tokens(obj, prefix="", out=None):
    """Flatten a DTCG token tree into {dotted.path: raw $value}."""
    if out is None:
        out = {}
    if isinstance(obj, dict):
        if "$value" in obj:
            out[prefix] = obj["$value"]
            return out
        for k, v in obj.items():
            if k.startswith("$"):
                continue
            key = f"{prefix}.{k}" if prefix else k
            flatten_tokens(v, key, out)
    return out


def load_flat_tokens(tokens_dir, theme="light"):
    """Merge primitives + semantic + one theme file into a flat token map."""
    tokens_dir = Path(tokens_dir)
    files = []
    files += sorted((tokens_dir / "primitives").glob("*.json")) if (tokens_dir / "primitives").exists() else []
    files += sorted((tokens_dir / "semantic").glob("*.json")) if (tokens_dir / "semantic").exists() else []
    theme_file = tokens_dir / "themes" / f"{theme}.json"
    if theme_file.exists():
        files.append(theme_file)
    flat = {}
    for f in files:
        try:
            flatten_tokens(json.loads(f.read_text(encoding="utf-8")), out=flat)
        except (OSError, json.JSONDecodeError):
            continue
    return flat


_REF_RE = re.compile(r"^\{([^}]+)\}$")


def resolve(value, flat, _depth=0):
    """Resolve DTCG alias chains ({group.token}) to a concrete value."""
    if _depth > 20:
        return value
    if isinstance(value, str):
        m = _REF_RE.match(value.strip())
        if m:
            return resolve(flat.get(m.group(1)), flat, _depth + 1)
    return value


# --- CLI plumbing ------------------------------------------------------------
def run_cli(name, check_fn, argv):
    import argparse
    ap = argparse.ArgumentParser(prog=name)
    ap.add_argument("paths", nargs="*", default=["."], help="files or directories")
    ap.add_argument("--json", action="store_true", help="emit JSON")
    args = ap.parse_args(argv)
    findings = check_fn(args.paths or ["."])
    if args.json:
        print(json.dumps([f.as_dict() for f in findings], indent=2))
    else:
        if not findings:
            print(f"✓ {name}: PASS (no findings)")
        for f in findings:
            print(f.format())
    return 1 if any(f.severity == ERROR for f in findings) else 0
