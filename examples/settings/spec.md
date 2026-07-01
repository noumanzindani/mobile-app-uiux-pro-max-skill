# Example Spec — Settings

> Purpose: Reference specification for a platform-correct, grouped, searchable settings screen with isolated destructive actions and a reachable account-deletion path. This is a spec, not code — it defines intent, the applicable states, layout/thumb-zone, accessibility, tokens, motion, and the validator-backed acceptance gate. Implementations live in `settings/<framework>/`.

## Contents
- [Intent / user goal](#intent--user-goal)
- [Platforms & frameworks](#platforms--frameworks)
- [Patterns & rules used](#patterns--rules-used)
- [Layout & thumb-zone (responsive)](#layout--thumb-zone-responsive)
- [Structure & grouping](#structure--grouping)
- [States map](#states-map)
- [Accessibility](#accessibility)
- [Token usage](#token-usage)
- [Motion](#motion)
- [Acceptance checklist](#acceptance-checklist)

---

## Intent / user goal

"Find and change a setting quickly, and trust I won't destroy anything by accident." The user scans grouped sections (or searches), toggles preferences, and occasionally performs high-stakes actions (sign out, delete account) that must be clearly separated and confirmed.

**Success = any setting is findable in seconds; changes save reliably; destructive actions are isolated, confirmed, and reversible where possible.**

## Platforms & frameworks

- **Paradigm:** Platform-native (this example proves platform conventions, [[PLAT-001]]). iOS: grouped inset table style, `Switch`/`Toggle`, disclosure chevrons, native pickers. Android: Material 3 preference list, `Switch`, category headers.
- **Frameworks (v1, flagship = all four):** Flutter (adaptive Material/Cupertino), React Native (`Platform.select` for row style), SwiftUI (`Form` + `Section`), Jetpack Compose (M3 preference list).

## Patterns & rules used

- Patterns: [`navigation-patterns.md`](../../patterns/navigation-patterns.md), [`list-detail.md`](../../patterns/list-detail.md) (settings groups → sub-pages on wide screens).
- Rules: [[SET-001]] (grouped), [[SET-002]] (searchable), [[SET-003]] (destructive isolated), [[SET-004]] (account deletion reachable), [[PLAT-002]] (nav per OS), [[PLAT-004]] (typography per OS), [[PLAT-006]] (native pickers), [[DLG-001]] (destructive confirm), [[PROF-001]] (deletion path), [[DRK-001]] (dark mode), [[L10N-003]] (text expansion).

## Layout & thumb-zone (responsive)

| Window class | Width | Layout |
|---|---|---|
| Compact | < 600dp | Single scrolling list; a group's detail **pushes** a sub-page ([[GRD-001]], [[NAV-005]]) |
| Expanded | ≥ 840dp | **Two-pane**: group list (leading) + selected group's settings (detail) ([[GRD-003]], see list-detail) |

```
Top:     "Settings" title + search field                     [[SET-002]]
Middle:  Grouped rows (Account · Notifications · Privacy · Appearance · Help)
Bottom:  Isolated destructive zone (Sign out · Delete account) [[SET-003]]
```

| Zone | Contents |
|---|---|
| Bottom arc | Frequently-changed toggles land within reach as the list scrolls; **destructive actions live at the very bottom, out of the accidental-tap arc**, and require confirmation ([[SET-003]], [[DLG-001]]) |
| Middle | Grouped setting rows, disclosure to sub-pages |
| Top | Title + search |

Rows are full-width ≥44pt/48dp tap targets with a 16dp leading keyline; the whole row (not just the control) is tappable where it navigates ([[SPC-008]], [[SPC-015]]).

## Structure & grouping

- **Group by concern** with section headers (Account, Notifications, Privacy & Security, Appearance, About/Help) ([[SET-001]]).
- **Search** filters across all settings and returns a distinct zero-results state ([[SET-002]], [[STATE-004]]).
- Row types: toggle (`Switch`), disclosure (navigates), value+chevron (opens a native picker, [[PLAT-006]]), and action (button-styled).
- **Destructive actions isolated** at the bottom in their own group, visually distinct (e.g., red label), each behind an explicit confirm ([[SET-003]], [[DLG-001]], [[BTN-005]]).
- **Account deletion is reachable** in-app (store-policy requirement) with a clear, multi-step confirmation ([[SET-004]], [[PROF-001]]).

## States map

Settings is mostly interactive rather than data-loaded, but still handles states ([[STATE-001]]):

| State | Applies? | Behavior |
|---|---|---|
| **Ideal** | ✅ | Groups + toggles reflect current values; search works. |
| **Empty** | ⚠️ (search) | Search with no match shows a distinct zero-results ("No settings match 'foo'") ([[STATE-004]]); the list itself is never empty. |
| **Loading** | ⚠️ | Server-synced settings show a brief skeleton for values that must fetch; local toggles are instant ([[STATE-005]]). |
| **Error** | ✅ | A toggle that fails to save **reverts with a message** ("Couldn't save — try again"), never a silent false-success ([[STATE-007]], [[OFF-001]]). |
| **Offline** | ✅ | Local prefs still work; server-synced toggles queue or disable with a reason; offline banner non-blocking ([[STATE-008]], [[OFF-002]]). |
| **Success** | ✅ | Change confirmed inline (the toggle reflects the true saved state); destructive actions confirm the outcome ([[STATE-009]]). |
| **Permission-denied** | ⚠️ | A setting mirroring an OS permission (notifications, location) reflects the **actual system state** and deep-links to system Settings to change it ([[STATE-010]], [[PERM-003]], [[NOTIF-002]]). |

## Accessibility

- Each row exposes **role + label + value/state**: a toggle announces "Notifications, on/off"; a disclosure announces it navigates ([[A11Y-005]], [[A11Y-006]], [[A11Y-004]]).
- Section headers are exposed as headings/landmarks for navigation ([[A11Y-017]]).
- Toggle state is **not color-only** — the platform switch shape/position conveys it; custom controls add text/icon ([[A11Y-012]]).
- Search field labeled; result count / zero-results announced ([[A11Y-004]], [[A11Y-019]]).
- Destructive confirm dialogs place the primary/destructive action per platform convention and are fully labeled ([[DLG-002]], [[A11Y-005]]).
- Contrast ≥4.5:1 for row text (incl. the red destructive label), ≥3:1 for switch tracks/dividers, both themes ([[A11Y-001]], [[A11Y-002]], [[DRK-004]]).
- Targets ≥44pt/48dp; **Dynamic Type to 200%** grows rows and wraps long labels (esp. after localization) without clipping ([[A11Y-003]], [[A11Y-010]], [[L10N-003]]).
- RTL mirrors chevrons and row layout ([[L10N-001]], [[L10N-004]]).

## Token usage

| Element | Token |
|---|---|
| Screen / grouped background | `color.surface` / `color.surface.container` |
| Row divider / group inset | `color.outline.variant` |
| Row label / value / header | `type.body.md` / `type.body.md` (`color.on.surface.variant`) / `type.label.md` |
| Switch on-track / thumb | `color.action.primary` / `color.on.action.primary` |
| Destructive label | `color.status.error` (paired with confirm, [[COL-003]]) |
| Row height / leading inset | `size.target.min` / `space.4` ([[SPC-008]], [[SPC-015]]) |
| Group spacing | `space.6` between groups ([[SPC-006]]) |
| Row radius (iOS grouped) | `radius.md` ([[SHP-003]] concentric on iOS) |

Zero literals; resolves light/dark ([[COL-001]], [[DRK-001]]); `token_lint.py` clean.

## Motion

- Toggle: platform switch animation (thumb slide) ≤200ms; reduce-motion → instant state change ([[MIC-001]], [[MOT-004]]).
- Row → sub-page: platform push transition; two-pane updates detail in place ([[MOT-001]], [[NAV-005]]).
- Destructive confirm: standard dialog present/dismiss; no playful motion on a serious action ([[MOT-005]]).
- Search filter: rows fade/reflow, not a hard swap ([[MOT-001]]).
- Only transform/opacity ([[PERF-001]]).

## Acceptance checklist

Validators (`run_all.py`):

- [ ] `token_lint.py` PASS — tokens only ([[COL-001]]).
- [ ] `contrast_check.py` PASS — row/destructive text ≥4.5:1, switches/dividers ≥3:1, both themes ([[A11Y-001]]).
- [ ] `target_size_lint.py` PASS — rows/switches ≥44pt/48dp, ≥8dp apart ([[A11Y-003]], [[SPC-008]]).
- [ ] `state_coverage.py` PASS — error/offline/success + search zero-results handled ([[STATE-001]]).
- [ ] `dynamic_type_check.py` PASS — rows grow, long/localized labels wrap, no clipping ([[A11Y-010]], [[L10N-003]]).
- [ ] `rtl_check.py` PASS — chevrons + row layout mirror ([[L10N-001]]).

Manual / prose:

- [ ] Platform-correct row style, switches, pickers, and nav per OS ([[PLAT-002]], [[PLAT-004]], [[PLAT-006]]).
- [ ] Grouped by concern with headers; search filters all settings ([[SET-001]], [[SET-002]]).
- [ ] Destructive actions isolated at the bottom, visually distinct, and confirmed ([[SET-003]], [[DLG-001]]).
- [ ] Account deletion reachable in-app with clear confirmation (store policy) ([[SET-004]], [[PROF-001]]).
- [ ] Failed saves revert with a message — no silent false success ([[STATE-007]]).
- [ ] OS-permission-linked settings reflect true system state + deep-link to Settings ([[PERM-003]]).
- [ ] Two-pane at ≥840dp; single-pane push on compact ([[GRD-003]]).
- [ ] Toggle state announced (role+value), not color-only ([[A11Y-006]], [[A11Y-012]]).
- [ ] Reduce-motion fallback for toggles/transitions ([[MOT-004]]).
