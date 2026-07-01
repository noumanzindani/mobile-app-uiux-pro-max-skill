# Settings Generator

**Purpose:** Generate a grouped, searchable settings screen following platform conventions, with destructive actions isolated and all 7 states handled — token-driven and accessible.

**Inputs:**
- *Required:* **Settings sections & items** (e.g. Account, Notifications, Privacy, Appearance, About) with each item's control type (toggle, selector, navigation row, action).
- *Required:* **Framework** (Flutter · React Native · SwiftUI · Jetpack Compose).
- **Platform target** (iOS grouped-inset lists vs Android/Material preference layout — affects visual grammar), **destructive actions present** (sign-out, delete account), **searchable?**, **industry** — optional.

**Procedure:**
1. Run the **15-point Pre-Generation Protocol** (`SKILL.md` §6.1); note grouping, hierarchy, and where destructive actions belong.
2. Load the domain rules — `rules/system/settings.md` (SET: grouped, searchable; destructive actions isolated) and `rules/system/platform-conventions.md` (iOS grouped-inset vs Material preferences, correct row/switch grammar).
3. Load component rules — `rules/components/lists.md` (grouped/section lists), `rules/components/forms.md` (toggles/selectors), `rules/components/search.md` (if searchable: debounce, zero-results), `rules/components/dialogs.md` (destructive confirm).
4. Load framework idioms — `frameworks/<framework>/components.md` and `states.md` — for the idiomatic grouped-list/preference widget, theming, safe area, a11y.
5. Handle theming controls — `rules/system/dark-mode.md` (light/dark/system selector persists) — and `rules/system/localization-rtl.md` for a language selector.
6. Enumerate the 7 states — `rules/interaction/states.md`: `loading` (fetching remote settings), `error`/`offline` (can't load/save — with retry), `success` (saved confirmation), `permission-denied` (a setting gated by a permission), plus `empty` for search zero-results.
7. Load `rules/system/accessibility.md`; wire label+role+state on every control (toggles announce on/off; destructive actions clearly labeled).

**Output format:**
- The **settings screen** in the target framework: grouped sections with headers, correct platform row/switch grammar, optional search field, and **destructive actions isolated** at the bottom / in a separate group with confirm dialogs.
- **All 7 states** (esp. save `error`/`offline`/`success` and search `empty`).
- **Token-usage table**, **a11y notes** (each control's role/label/state), **platform-convention notes**.

**Self-check:** Run `quality-checks/validators/run_all.py`; confirm `target_size_lint.py` (rows/switches ≥44pt/48dp), `contrast_check.py`, `token_lint.py`, `state_coverage.py` (all 7), `rtl_check.py` PASS. Verify destructive actions are isolated and confirmed. Reason through `quality-checks/checklists/platform-conventions.md` and `accessibility.md`.
