# Prompt Library — Index

> Reusable task prompts for the **mobile-uiux-pro-max** skill. Each prompt is a self-contained
> procedure the assistant can run when a user asks to generate, improve, audit, or review mobile UI.
> Prompts are **routers into the rule corpus** — they name exactly which Tier-3 reference files to
> load, then produce token-driven, all-states, WCAG-2.2-AA, platform-correct output and self-audit
> with the executable validators.

## How every prompt works

1. **Start with the Pre-Generation Protocol.** All generative prompts run the 15-point think-list in
   `SKILL.md` §6.1 before emitting UI, and briefly state their platform / framework / paradigm choice.
2. **Load only what you need.** Each `Procedure` step names specific reference files
   (`rules/…`, `frameworks/…`, `industries/…`, `patterns/…`, `design-system/…`). Do not read the whole
   corpus — pull the 1–5 files the task requires.
3. **Enforce the 5 laws.** Token-driven (no magic values) · all 7 UI states · WCAG 2.2 AA + platform
   a11y · correct platform paradigm · thumb-zone & 44pt/48dp targets.
4. **Self-check with validators, not vibes.** Finish by running
   `quality-checks/validators/run_all.py` (which orchestrates `token_lint.py`, `contrast_check.py`,
   `target_size_lint.py`, `state_coverage.py`, `dynamic_type_check.py`, `rtl_check.py`) and reason
   through the relevant prose checklists in `quality-checks/checklists/`.

## The 7 UI states (referenced everywhere)

`ideal` · `empty` · `loading` · `error` · `offline` · `success` · `permission-denied`
— design rules live in `rules/interaction/states.md`; the playbook is `patterns/empty-error-offline.md`;
coverage is verified by `quality-checks/validators/state_coverage.py`.

## Prompt catalog

### Screen lifecycle
| Prompt | Purpose | When to use |
|---|---|---|
| [`generate-screen`](generate-screen.md) | Produce a new screen with all 7 states, a11y, and tokens. | "Design/build a `<screen>` in `<framework>`" — starting a screen from scratch. |
| [`improve-screen`](improve-screen.md) | Upgrade an existing screen against the rule corpus. | "Improve / polish / modernize this screen" — you have code or a screenshot. |
| [`audit-screen`](audit-screen.md) | Full scored review (validators + checklists). | "Audit / review this screen" — you want a graded readiness report, no rewrite. |

### Focused reviews
| Prompt | Purpose | When to use |
|---|---|---|
| [`accessibility-review`](accessibility-review.md) | WCAG 2.2 AA + platform a11y pass. | "Is this accessible?", "Check contrast / labels / targets / Dynamic Type." |
| [`ux-review`](ux-review.md) | Heuristic + ergonomics + flow critique. | "Review the UX", "Is this usable one-handed?", "Rate this flow." |
| [`animation-review`](animation-review.md) | Motion correctness (timing, easing, reduce-motion). | "Check the animations", "Does this respect reduce-motion?" |

### Design-system & component generators
| Prompt | Purpose | When to use |
|---|---|---|
| [`design-system-generator`](design-system-generator.md) | Emit DTCG tokens + themes + Style Dictionary config. | "Make a design system / token set / theme from this brand." |
| [`component-generator`](component-generator.md) | One component with all variants, states, a11y. | "Build a `<button/card/input/…>` component." |

### Screen-pattern generators
| Prompt | Purpose | When to use |
|---|---|---|
| [`onboarding-generator`](onboarding-generator.md) | Value-first onboarding + progressive permission priming. | "Create an onboarding / intro / walkthrough flow." |
| [`settings-generator`](settings-generator.md) | Grouped, searchable settings screen. | "Build a settings / preferences screen." |
| [`dashboard-generator`](dashboard-generator.md) | Glanceable, responsive metrics dashboard. | "Create a dashboard / home / analytics overview." |
| [`chat-generator`](chat-generator.md) | Messaging UI with optimistic send + offline. | "Build a chat / messaging / conversation screen." |
| [`profile-generator`](profile-generator.md) | Account/profile screen with the deletion path. | "Create a profile / account screen." |
| [`checkout-generator`](checkout-generator.md) | Cart → address → pay → confirm with native Pay. | "Build a checkout / cart / payment flow." |
| [`authentication-generator`](authentication-generator.md) | Login/signup with passkeys, biometrics, paste-friendly fields. | "Create a login / signup / auth flow." |

## Choosing between overlapping prompts

- **Have nothing yet → `generate-screen`** (or a specific `*-generator` when the screen is a known
  pattern like checkout, chat, onboarding, settings, dashboard, profile, auth).
- **Have a screen, want it better → `improve-screen`** (returns a diff mapped to rule IDs).
- **Have a screen, want a verdict → `audit-screen`** (returns a scored report, no edits).
- **Want one narrow lens →** `accessibility-review`, `ux-review`, or `animation-review`.

The `*-generator` prompts are specializations of `generate-screen`: they preload the matching
`patterns/` recipe and `rules/domain/*` file so the output is idiomatic for that pattern out of the box.
