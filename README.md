# Mobile App UI/UX Pro Max Skill

_by **Nouman Zindani**_

**A Claude Agent Skill that makes any AI coding assistant design mobile apps like a senior
product designer** — accessible, platform-correct, token-driven, and emotionally resonant —
on the first try, across Flutter, React Native, SwiftUI, and Jetpack Compose.

> AI-generated mobile UI is usually generic, inaccessible, and native to neither iOS nor
> Android. This skill fixes that by enforcing Material 3 Expressive, Apple HIG (iOS 26),
> and WCAG 2.2 by default — with **runnable validators**, not just advice.

## Why it's different
- **Mobile-first & cross-framework** — not another web/React-only generator.
- **Enforced, not suggested** — ships six executable validators (contrast, target size,
  state coverage, token lint, Dynamic Type, RTL) that give a deterministic PASS/FAIL. They
  run as scripts, so they cost **zero context tokens**.
- **Token-driven by construction** — DTCG-2025.10 tokens; no hardcoded values.
- **All 7 UI states, always** — ideal, empty, loading, error, offline, success, permission-denied.
- **Current** — Material 3 Expressive (2025), iOS 26 Liquid Glass, Android 16 size classes,
  WCAG 2.2, DTCG 2025.10.
- **Progressive disclosure** — a lean `SKILL.md` router; deep knowledge loads only on demand.

## What's inside
```
SKILL.md            Router + the 15-point Pre-Generation Protocol (the brain)
rules/              ~670 atomic, testable rules (foundations, components, interaction, system, domain)
design-system/      DTCG tokens + theming spec + Style Dictionary build
frameworks/         Flutter · React Native · SwiftUI · Jetpack Compose packs
industries/         Finance · Healthcare · E-commerce · Social · Productivity packs
patterns/           Composed recipes (nav, list-detail, forms, feeds, checkout, states)
prompts/            15 task prompts (generate / improve / audit / *-generator)
quality-checks/     Prose checklists + 6 runnable validators + tests
examples/           Flagship screen specs (login, dashboard, chat, checkout, settings)
```

## Quickstart
1. **Install** — place this folder where your assistant loads skills (e.g. `~/.claude/skills/`).
2. **Use** — ask your assistant to *"design a login screen in Flutter"* or *"audit this
   screen for accessibility."* The skill runs the Pre-Generation Protocol, generates
   token-driven UI with all states, then self-audits.
3. **Audit anything** deterministically:
   ```bash
   python3 quality-checks/validators/run_all.py lib/screens/home_screen.dart
   python3 quality-checks/validators/contrast_check.py --pair "#0F172A" "#FFFFFF"
   ```

## The 5 Laws (non-negotiable)
1. Token-driven (no magic values) · 2. All 7 states · 3. WCAG 2.2 AA + platform a11y ·
4. Correct platform paradigm · 5. Thumb-zone & 44pt/48dp targets.

## Requirements
- The validators are **Python 3 stdlib-only** (no dependencies). Tested on 3.9+.
- The Style Dictionary build (optional) needs Node + `style-dictionary` v4.

## Contributing
See [CONTRIBUTING.md](CONTRIBUTING.md). New rules need a rationale and, where possible, a
machine check. Rules are atomic and identified by a stable `PREFIX-NNN` id.

## License
[Apache-2.0](LICENSE). See [NOTICE](NOTICE) for attribution. Design standards referenced
(Material Design, Apple HIG, WCAG, DTCG) are the property of their respective owners; no
source documentation is reproduced verbatim.

## Status
`v0.1.0` — Phase 1 foundation + core rule corpus + validators. See [CHANGELOG.md](CHANGELOG.md)
and `BLUEPRINT.md` for the full roadmap.
