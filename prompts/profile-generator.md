# Profile Generator

**Purpose:** Generate an account/profile screen with editable fields, optimistic save, and a reachable account-deletion path (store-policy requirement) — all 7 states, token-driven and accessible.

**Inputs:**
- *Required:* **Profile fields** shown/editable (name, avatar, email, bio, preferences…).
- *Required:* **Framework** (Flutter · React Native · SwiftUI · Jetpack Compose).
- **Editable in-place vs edit screen**, **avatar upload?**, **linked accounts / auth methods**, **platform target**, **industry** — optional.

**Procedure:**
1. Run the **15-point Pre-Generation Protocol** (`SKILL.md` §6.1); note field hierarchy and where the destructive delete-account action belongs (out of the thumb arc, isolated, confirmed).
2. Load the domain rules — `rules/domain/profile.md` (PROF: account deletion reachable per store policy; edit with optimistic save).
3. Load component rules — `rules/components/forms.md` (inline validation 150–200ms; keyboard type), `rules/components/avatars.md` (fallback initials/icon; alt text), `rules/components/lists.md` (grouped rows), `rules/components/dialogs.md` (delete confirmation).
4. Load save/offline behavior — `rules/system/offline.md` (optimistic save + visible rollback on failure) and `patterns/form-flows.md`.
5. Load framework idioms — `frameworks/<framework>/components.md`, `states.md` — for form controls, image picker, theming, safe area, a11y.
6. Enumerate the 7 states — `rules/interaction/states.md`: `loading` (fetching profile), `empty` (incomplete profile prompting completion), `error`/`offline` (save failed → rollback + retry), `success` (saved confirmation), `permission-denied` (photo library for avatar).
7. Load `rules/system/accessibility.md`, `dark-mode.md`, `localization-rtl.md`; label every field/control; the avatar has alt text; delete-account is clearly destructive and confirmed.

**Output format:**
- The **profile screen** in the target framework: viewable + editable fields with optimistic save, avatar with fallback, and an **isolated, confirmed account-deletion path**.
- **All 7 states** (incl. save `error`/`offline` rollback and avatar `permission-denied`).
- **Token-usage table**, **a11y notes** (field labels/roles, avatar alt text, destructive-action semantics), **platform-convention notes**.

**Self-check:** Run `quality-checks/validators/run_all.py`; confirm `state_coverage.py` (all 7), `target_size_lint`, `contrast_check`, `token_lint`, `dynamic_type_check`, `rtl_check` PASS. Verify the account-deletion path is present, isolated, and confirmed (store-policy check). Reason through `quality-checks/checklists/accessibility.md` and `platform-conventions.md`.
