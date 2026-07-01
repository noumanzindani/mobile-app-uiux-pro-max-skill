#!/usr/bin/env python3
"""trigger_test — checks the SKILL.md `description` reliably triggers the skill.

A skill that generates perfectly but never *activates* is worthless in practice,
so the description is the real product surface (Goal G2). The genuine trigger
decision is the model's and can't be unit-tested deterministically — but a
*necessary* condition is that the description's vocabulary actually covers the
words users type. This test is a deterministic proxy for that:

  1. Coverage — every flagship trigger keyword (login, checkout, chat, dashboard,
     settings, accessibility, each v1 framework, ...) must appear in the
     description. Guards against someone rewriting it in abstract terms and
     silently dropping concrete triggers.
  2. Corpus — a labeled set of prompts (should- vs should-not-trigger). We predict
     "trigger" when a prompt shares >=1 content word with the description vocab,
     then require high recall on positives and high specificity on negatives.

Run:  python3 eval/trigger_test.py            # report + gate exit code
      python3 eval/trigger_test.py --json
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SKILL_MD = ROOT / "SKILL.md"

# --- gate policy -------------------------------------------------------------
RECALL_TARGET = 0.90        # of prompts that SHOULD trigger, how many do
SPECIFICITY_TARGET = 0.90   # of prompts that should NOT trigger, how many correctly don't

# Concrete triggers that must never fall out of the description.
REQUIRED_KEYWORDS = [
    "flutter", "react", "swiftui", "compose", "ios", "android",
    "login", "signup", "checkout", "dashboard", "chat", "settings",
    "onboarding", "profile", "accessible", "accessibility", "audit",
    "responsive", "rtl", "dark",
]

# Labeled prompt corpus. (prompt, should_trigger)
CORPUS = [
    ("Design a login screen in Flutter", True),
    ("Build a mobile UI for a checkout flow", True),
    ("Make this screen accessible", True),
    ("Audit my app's UX for accessibility", True),
    ("Generate a dashboard in SwiftUI", True),
    ("Add dark mode to this settings page", True),
    ("Improve this chat screen's UX", True),
    ("Make the layout responsive for foldables", True),
    ("Add RTL support for Arabic localization", True),
    ("Review this UI for design quality", True),
    ("The touch targets are too small to tap", True),
    ("Create an onboarding flow in Jetpack Compose", True),
    # --- should NOT trigger (backend / infra / data / general CS) ---
    ("Optimize this SQL query", False),
    ("Set up a CI/CD pipeline in GitHub Actions", False),
    ("Parse a CSV file in Python", False),
    ("Configure an nginx reverse proxy", False),
    ("Explain the CAP theorem", False),
    ("Index the users column in Postgres", False),
    ("Write a bash script to rotate logs", False),
    ("Debug a segfault in a C program", False),
]

# Words in the description that carry no routing signal (structural filler).
STOPWORDS = {
    "use", "when", "or", "in", "on", "by", "no", "of", "to", "for", "the",
    "an", "and", "this", "that", "my", "your", "with", "as", "at", "is", "are",
    "be", "all", "any", "default", "applies", "enforces", "triggers", "values",
    "hardcoded", "correct", "native",  # 'native' only meaningful as 'React Native'
}
TOKEN_RE = re.compile(r"[a-z0-9]+")


def read_description(skill_md=SKILL_MD):
    """Extract the raw `description:` block from the SKILL.md YAML frontmatter."""
    text = skill_md.read_text(encoding="utf-8")
    if not text.startswith("---"):
        raise ValueError("SKILL.md has no YAML frontmatter")
    fm = text.split("---", 2)[1]
    lines = fm.splitlines()
    desc, capturing = [], False
    for line in lines:
        if re.match(r"^description:", line):
            capturing = True
            # tolerate inline (`description: text`) as well as folded (`>-`)
            inline = line.split(":", 1)[1].strip()
            if inline and inline not in (">-", ">", "|", "|-"):
                desc.append(inline)
            continue
        if capturing:
            # a new top-level key (no indent, ends the folded block)
            if re.match(r"^[a-z].*:", line):
                break
            desc.append(line.strip())
    return " ".join(d for d in desc if d)


def tokenize(text):
    toks = TOKEN_RE.findall(text.lower())
    return {t for t in toks if len(t) >= 2 and not t.isdigit() and t not in STOPWORDS}


def evaluate(skill_md=SKILL_MD):
    description = read_description(skill_md)
    vocab = tokenize(description)

    missing = [k for k in REQUIRED_KEYWORDS if k not in vocab]

    tp = fp = tn = fn = 0
    preds = []
    for prompt, should in CORPUS:
        predicted = bool(tokenize(prompt) & vocab)
        preds.append({"prompt": prompt, "should_trigger": should, "predicted": predicted})
        if should and predicted:
            tp += 1
        elif should and not predicted:
            fn += 1
        elif not should and predicted:
            fp += 1
        else:
            tn += 1

    recall = tp / (tp + fn) if (tp + fn) else 1.0
    specificity = tn / (tn + fp) if (tn + fp) else 1.0
    precision = tp / (tp + fp) if (tp + fp) else 1.0

    coverage_ok = not missing
    recall_ok = recall >= RECALL_TARGET
    specificity_ok = specificity >= SPECIFICITY_TARGET
    gate_pass = coverage_ok and recall_ok and specificity_ok

    return {
        "vocab_size": len(vocab),
        "missing_keywords": missing,
        "recall": round(recall, 3),
        "specificity": round(specificity, 3),
        "precision": round(precision, 3),
        "counts": {"tp": tp, "fp": fp, "tn": tn, "fn": fn},
        "predictions": preds,
        "coverage_ok": coverage_ok,
        "recall_ok": recall_ok,
        "specificity_ok": specificity_ok,
        "gate_pass": gate_pass,
        "policy": {"recall_target": RECALL_TARGET, "specificity_target": SPECIFICITY_TARGET},
    }


def render(result):
    r = result
    out = ["# SKILL.md Trigger Coverage", ""]
    out.append(f"Description vocab: {r['vocab_size']} routing words.")
    out.append(f"Recall {r['recall']} (target {r['policy']['recall_target']}) · "
               f"Specificity {r['specificity']} (target {r['policy']['specificity_target']}) · "
               f"Precision {r['precision']}.")
    if r["missing_keywords"]:
        out.append(f"MISSING required trigger keywords: {', '.join(r['missing_keywords'])}")
    else:
        out.append(f"All {len(REQUIRED_KEYWORDS)} required trigger keywords present.")
    out.append("")
    for p in r["predictions"]:
        want = "trigger" if p["should_trigger"] else "skip"
        got = "trigger" if p["predicted"] else "skip"
        mark = "✓" if (p["should_trigger"] == p["predicted"]) else "✗"
        out.append(f"{mark} [want {want:>7} · got {got:>7}] {p['prompt']}")
    out += ["", f"**Gate:** {'✅ PASS' if r['gate_pass'] else '❌ FAIL'}"]
    return "\n".join(out)


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    result = evaluate()
    if "--json" in argv:
        print(json.dumps(result, indent=2))
    else:
        print(render(result))
    return 0 if result["gate_pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
