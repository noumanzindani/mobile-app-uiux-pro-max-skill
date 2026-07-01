# Dashboard Generator

**Purpose:** Generate a glanceable, responsive dashboard/home screen — prioritized metrics, charts with non-color encoding, and all 7 states — that reflows across phone/foldable/tablet size classes.

**Inputs:**
- *Required:* **Metrics / cards / widgets** to display and their **priority order** (what matters most at a glance).
- *Required:* **Framework** (Flutter · React Native · SwiftUI · Jetpack Compose).
- **User roles** (if the dashboard differs by role), **charts needed** (which types), **refresh model** (pull-to-refresh / live), **platform target**, **industry** — optional.

**Procedure:**
1. Run the **15-point Pre-Generation Protocol** (`SKILL.md` §6.1); establish the information hierarchy (primary metric above the fold, in reach) and responsive intent.
2. Load responsive rules — `rules/foundations/grid.md` (GRD: <600dp single column; ≥840dp two-pane) — and the recipe `patterns/list-detail.md` for multi-pane behavior.
3. Load component rules — `rules/components/cards.md` (tappable card = single primary target), `rules/components/charts.md` (CHT: never color-only encoding; provide a data-table a11y fallback), `rules/components/tables.md` (prefer cards on compact), `rules/components/progress.md`.
4. Load feed/refresh behavior — `patterns/feed-patterns.md` (pull-to-refresh) — if the dashboard refreshes.
5. Load framework idioms — `frameworks/<framework>/components.md`, `states.md` — for grid/lazy layout, safe area, a11y, chart rendering.
6. Enumerate the 7 states — `rules/interaction/states.md` and `patterns/empty-error-offline.md`: `loading` (skeletons per card), `empty` (no data yet — with a next step), `error`/`offline` (stale-data banner + retry, non-blocking), `success`, `permission-denied` (a metric needing a permission). Cards load independently.
7. Load `rules/system/accessibility.md`, `dark-mode.md`, `localization-rtl.md`; give every chart a text/data-table alternative and tabular numerals where numeric alignment matters.

**Output format:**
- The **dashboard** in the target framework, responsive across size classes (single-column compact → multi-pane/expanded), with the highest-priority metric glanceable and in the thumb zone for actions.
- **Per-card 7-state handling** (skeleton loading, empty, error/offline stale banner, success, permission-denied) — `state_coverage` across the composed screen.
- **Chart accessibility** notes (non-color encoding + data-table fallback + labels).
- **Token-usage table**, **responsive breakpoint notes**, **a11y notes**.

**Self-check:** Run `quality-checks/validators/run_all.py`; confirm `state_coverage.py` (all 7 across the screen), `contrast_check.py` (chart series distinguishable without color reliance), `target_size_lint.py`, `token_lint.py`, `dynamic_type_check.py`, `rtl_check.py` PASS. Reason through `quality-checks/checklists/responsive.md` and `accessibility.md`.
