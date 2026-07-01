# <Domain Title> Rules

> Purpose: <one line — what this file governs>.
> Prefix: `XXX` · Related: [[other-domain]]

<!-- TOC required if this file exceeds 100 lines -->

### XXX-001 — <short imperative title>
- **Rule:** <the testable requirement, in MUST/SHOULD language, with concrete numbers (dp/pt, ms, ratios)>
- **Why:** <1–2 sentence rationale grounded in a standard or human factor>
- **Platforms:** all | ios | android | <framework>
- **Severity:** error | warning | suggestion
- **Check:** <how to verify — a validator name (e.g. `token_lint.py`) or "manual review">
- **Exceptions:** <legitimate exceptions, or "none">
- **See also:** [[XXX-002]], [[OTHER-000]]

<!--
AUTHORING RULES:
- IDs are stable forever. Deprecate, never reuse or renumber.
- IDs are zero-padded 3 digits, sequential within a prefix.
- Prefer machine-checkable rules; if a validator can enforce it, name the validator.
- One rule = one atomic, testable idea. Split compound rules.
- Severity: error = blocks ship / breaks a11y or platform contract; warning = degrades
  quality; suggestion = polish / taste.
- Cross-link generously with [[ID]] — unresolved links are fine; they mark future work.
-->
