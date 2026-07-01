# Component Generator

**Purpose:** Produce a single reusable component with all its variants, interaction states, and accessibility wired in — token-bound and idiomatic for the target framework.

**Inputs:**
- *Required:* **Component** (e.g. button, card, list row, input, chip, bottom sheet, dialog, badge, avatar, slider).
- *Required:* **Framework** (Flutter · React Native · SwiftUI · Jetpack Compose).
- **Variants** needed (e.g. primary/secondary/tertiary/destructive; filled/outlined/text; sizes). If omitted, generate the standard variant set for that component.
- **Platform target** (adaptive by default), **token source** (else bind to the generated semantic tokens), and **industry** — optional.

**Procedure:**
1. Run the relevant **Pre-Generation Protocol** points (`SKILL.md` §6.1): touch targets, states, a11y, tokens, dark mode, RTL.
2. Load the component's rule file — `rules/components/<component>.md` (e.g. `buttons.md`: one primary action per view, min 44pt/48dp, loading + disabled states) — and enumerate its required variants and states.
3. Load interaction states — `rules/interaction/states.md` — and the **interaction states** the component must express: `default`, `hover`(where relevant), `pressed`, `focused`, `disabled`, `loading`, `error`/`selected` as applicable. (A component embedded in a screen participates in that screen's 7 UI states.)
4. Load framework idioms — `frameworks/<framework>/components.md` and `frameworks/<framework>/snippets/` — for the correct widget, theming binding, a11y API, and animation primitive.
5. Load micro-interaction + motion rules — `rules/interaction/micro-interactions.md` (press scale + haptic) and `design-system/motion-system.md` (token-bound durations).
6. Load foundations — `rules/foundations/spacing.md`, `shape.md`, `color.md`, `icon.md` (pad icon glyphs to ≥44pt/48dp hit area) and `design-system/token-spec.md`.
7. Generate the component: every color/space/radius/duration bound to a semantic or component token; each variant × each interaction state defined; a11y label+role+state attached; icon-only variants given accessible labels; selected/error state carries a non-color cue.

**Output format:**
- **Component code** in the target framework (props/parameters for all variants; state handled via the framework's idiomatic mechanism).
- A **variant × state matrix** showing every combination is covered.
- A **token-usage table** (token → property) proving no magic values.
- **Accessibility notes** (role, label strategy for icon-only, focus behavior, state announcements, min hit area).
- A **usage snippet** showing correct invocation.

**Self-check:** Run `quality-checks/validators/token_lint.py` (zero magic values), `contrast_check.py` (every variant/state foreground-background pair in both themes), and `target_size_lint.py` (44pt/48dp + 8dp). Confirm every interaction state (incl. `disabled` and `loading`) is present, and reason through `quality-checks/checklists/consistency.md` so the component matches the system.
