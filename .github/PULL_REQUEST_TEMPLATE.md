<!-- Conventional Commit title, e.g. "rule: FRM — require inline validation timing" -->

## What & why
<one-paragraph summary>

## Changes
- Rules/packs touched: <IDs or pack names>
- Validators added/changed: <names, or "none">
- Examples updated: <yes/no>

## Checks (paste output)
- [ ] `python3 scripts/build_registry.py --check` — registry in sync, no dup IDs
- [ ] `python3 -m pytest quality-checks/validators/tests` — green
- [ ] `python3 quality-checks/validators/run_all.py examples/` — golden examples PASS
- [ ] New/changed rules follow the schema and cite a source
- [ ] Volatile platform facts are date-stamped

## Sources
<links to standards/research backing new guidance>
