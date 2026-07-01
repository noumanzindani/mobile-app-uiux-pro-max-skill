# Onboarding Generator

**Purpose:** Generate a value-first onboarding flow that demonstrates worth before asking for anything, with progressive, just-in-time permission priming — all 7 states, token-driven, accessible.

**Inputs:**
- *Required:* **App purpose / core value** (what the user gets, in one sentence).
- *Required:* **Framework** (Flutter · React Native · SwiftUI · Jetpack Compose).
- **Permissions the app needs** (notifications, location, camera, contacts, health…) and **when each is actually used** — drives priming order.
- **Auth requirement** (can the user try before signing up?), **number of value screens**, **platform target**, **industry** — optional.

**Procedure:**
1. Run the **15-point Pre-Generation Protocol** (`SKILL.md` §6.1); confirm the flow is skippable and shows value before any ask.
2. Load the recipe — `patterns/onboarding-patterns.md` (value-first, skippable, progressive permission priming).
3. Load the domain rules — `rules/domain/onboarding.md` (ONB) and `rules/system/permissions.md` (PERM: just-in-time, value-first, handle denied with a settings deep-link) and `rules/system/notifications.md` (NOTIF: prime before requesting).
4. Load framework idioms — `frameworks/<framework>/_index.md`, `components.md`, `states.md` (page view/carousel, safe area, a11y, animation) — and `rules/foundations/*` + `design-system/token-spec.md`.
5. Design the **permission priming** for each permission: a value-framed pre-prompt screen → the OS dialog only after the user opts in → a **`permission-denied`** recovery path with a deep-link to Settings.
6. Enumerate the 7 states for any data-backed step (e.g. account creation `loading`/`error`/`offline`/`success`) — `rules/interaction/states.md`.
7. Load `rules/system/accessibility.md`, `dark-mode.md`, `localization-rtl.md`; wire a11y and reduce-motion for any page transitions.

**Output format:**
- The **multi-screen flow** in the target framework (value screens → optional priming screens → completion), with a persistent **Skip** affordance and progress indicator.
- **All 7 states** for each interactive/data-backed step (explicitly including `permission-denied` with the Settings deep-link).
- A **permission-priming map** (permission → why-framed pre-prompt copy → trigger point → denied fallback).
- **Token-usage table**, **a11y notes**, and a **reduce-motion** note for transitions.

**Self-check:** Run `quality-checks/validators/run_all.py`; confirm `state_coverage.py` shows all 7 states (esp. `permission-denied`), `token_lint`/`contrast_check`/`target_size_lint`/`dynamic_type_check`/`rtl_check` PASS. Verify no permission is requested before its value is shown and that every denial has a recovery path. Reason through `quality-checks/checklists/states.md` and `accessibility.md`.
