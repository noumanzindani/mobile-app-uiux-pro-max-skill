# Patterns — Composed UX Recipes

> Purpose: Patterns are the layer above rules. A single rule is atomic ("targets ≥44pt"); a pattern is a **composed recipe** that shows HOW many rules combine into a working screen or flow (a feed, a checkout, a search). Read a pattern when you are building a whole surface, not tuning one property. Every pattern references the rules it depends on by ID (`[[NAV-001]]`) so the rule stays the single source of truth and the pattern never restates it.

## How to use this pack

1. Identify the surface you are building (navigation shell, list-detail, form flow, feed, search, onboarding, checkout, or a bare state screen).
2. Open the matching pattern file below. Each one gives you: **decision fork → anatomy → thumb-zone layout → the 7-state map → accessibility → motion → applied-rules table → anti-patterns → acceptance checklist.**
3. Follow the applied-rules table into `rules/` only for the specific rule you need to implement.
4. Before shipping, run the acceptance checklist at the foot of the pattern and the validators in `quality-checks/`.

Patterns are **framework-agnostic**. Where a construct differs by framework (sheet, safe-area, list virtualization), the pattern names the concept and points to `frameworks/<x>/` for the idiomatic API.

## The 7 UI states (referenced everywhere)

Every data-backed surface must design all seven. This is the vocabulary used across all patterns and examples:

| # | State | One-line intent | Anchor rule |
|---|---|---|---|
| 1 | **Ideal** | Content loaded, everything works | — |
| 2 | **Empty** | No data yet — first-use, user-cleared, or no-results (three sub-flavors) | [[STATE-002]] |
| 3 | **Loading** | Fetching — skeleton for content, progress for known duration | [[STATE-005]] |
| 4 | **Error** | Request failed — explain + retry, preserve input | [[STATE-007]] |
| 5 | **Offline** | No connectivity — non-blocking banner + cached content | [[STATE-008]] |
| 6 | **Success** | Action completed — confirm + next step | [[STATE-009]] |
| 7 | **Permission-denied** | System permission refused — explain value + deep-link to Settings | [[STATE-010]] |

## Pattern registry

| Pattern | File | Use when | Load-bearing rules |
|---|---|---|---|
| **Navigation** | [navigation-patterns.md](navigation-patterns.md) | Choosing/structuring the app shell: bottom nav vs rail vs drawer, tab+stack, deep links, ≥840dp adaptation | [[NAV-001]] [[NAV-003]] [[NAV-005]] [[NAV-008]] [[GRD-003]] |
| **List-Detail** | [list-detail.md](list-detail.md) | A browse list that opens a detail; making it responsive from phone to foldable to tablet | [[GRD-001]] [[GRD-003]] [[LST-001]] [[NAV-005]] |
| **Form Flows** | [form-flows.md](form-flows.md) | Single or multi-step data entry: validation, keyboard avoidance, review-before-submit | [[FRM-001]] [[FRM-003]] [[FRM-012]] [[A11Y-018]] |
| **Feed** | [feed-patterns.md](feed-patterns.md) | An infinite/paginated stream with pull-to-refresh and optimistic like/save/post | [[LST-004]] [[LST-003]] [[OFF-001]] [[STATE-005]] |
| **Search** | [search-patterns.md](search-patterns.md) | Instant search, filters, recent/suggested, and the zero-results state | [[SRCH-001]] [[SRCH-002]] [[SRCH-003]] [[CHP-001]] |
| **Onboarding** | [onboarding-patterns.md](onboarding-patterns.md) | First-run value delivery and just-in-time, value-first permission priming | [[ONB-001]] [[PERM-002]] [[NOTIF-001]] |
| **Checkout** | [checkout-patterns.md](checkout-patterns.md) | Cart → address → pay → confirm, guest checkout, native Pay, no-double-charge | [[PAY-001]] [[PAY-002]] [[PAY-003]] [[PAY-007]] |
| **Empty / Error / Offline** | [empty-error-offline.md](empty-error-offline.md) | The state-design playbook: how to design each of the 7 states well, everywhere | [[STATE-001]]…[[STATE-014]] |

## Conventions used in every pattern file

- **Thumb-zone map** — every layout notes what belongs in the bottom reachable arc (primary/frequent), the middle (content), and the top (titles, low-frequency/destructive). Grounded in [[GES-002]] and thumb-reach ergonomics (treated as directional, not law).
- **Applied-rules table** — a compact map of `intent → rule ID` so the pattern is auditable and never duplicates rule text.
- **Acceptance checklist** — the pattern's own PASS gate, aligned with `quality-checks/validators/run_all.py`.
- **Rule IDs are stable links** — `[[PREFIX-NNN]]` resolves through `rules/_index.md`.
