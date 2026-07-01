# Contributing

Thanks for helping build the best open-source mobile UI/UX skill. This guide covers how to
add rules, packs, and validators.

## Ground rules
- **Rules are atomic and testable.** One rule = one idea. Use the schema in
  `templates/rule.template.md`.
- **Stable IDs.** `PREFIX-NNN` (zero-padded, sequential within a prefix). IDs are permanent —
  deprecate, never reuse or renumber.
- **Prefer machine checks.** If a validator can enforce a rule, name it in the `Check` field
  (and, ideally, extend the validator).
- **Reference, don't restate.** Framework/industry packs link core rules by `[[ID]]` rather
  than duplicating them.
- **Ground claims.** Cite a standard or human-factors source; date-stamp volatile platform
  facts and keep them in `frameworks/<x>/_index.md`.
- **No magic values in examples.** Examples must pass `token_lint.py`.

## Adding a rule
1. Pick the right file under `rules/<domain>/` (or add a new one).
2. Copy the block from `templates/rule.template.md`; assign the next free ID for that prefix.
3. Set a severity: **error** (blocks ship — a11y/platform contract), **warning** (degrades
   quality), **suggestion** (taste/polish).
4. Cross-link related rules with `[[ID]]`.
5. Regenerate the registry: `python3 scripts/build_registry.py` (updates `rules/_index.md`).

## Adding a framework or industry pack
Use `templates/framework-pack.template.md` / `templates/industry-pack.template.md`. A new
pack must add ≥ 1 worked example (framework) or ≥ 10 domain rules (industry).

## Adding / changing a validator
- Stdlib-only Python, one `check(paths) -> list[Finding]` + a `main()` CLI.
- Add golden good/bad fixtures under `quality-checks/validators/tests/fixtures/` and cover
  them in `test_validators.py`. Tune for **precision** (few false positives).

## Workflow
- **Branches:** `feat/`, `fix/`, `rule/`, `docs/`.
- **Commits:** [Conventional Commits](https://www.conventionalcommits.org)
  (`feat:`, `fix:`, `docs:`, `rule:`…).
- **Before opening a PR:** run
  ```bash
  python3 scripts/build_registry.py --check     # registry is in sync, no dup IDs
  python3 -m pytest quality-checks/validators/tests
  python3 quality-checks/validators/run_all.py examples/   # golden examples score PASS
  ```
- Fill in the PR template: rules/packs touched, validator results, sources cited.

## Review bar
A maintainer checks: schema compliance, ID uniqueness, resolvable `[[links]]`, grounded
rationale, and (for rules) a machine check where feasible.
