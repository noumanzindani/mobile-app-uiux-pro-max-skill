# Settings — Flutter reference implementation

A real, compiling Flutter build of the settings spec in [`../spec.md`](../spec.md).
A platform-correct, **grouped**, **searchable** preferences surface with an
**isolated destructive zone**, a reachable **account-deletion** path, and a
light/dark/system theme switch — **responsive** (single list ⇄ two-pane) and
**100 % token driven**, so a rebrand or a dark-mode swap is a token change, not a
refactor.

| File | Role |
|---|---|
| `settings_tokens.dart` | The semantic token layer — surface / container, `outline.variant` divider, on-surface + on-surface-variant, action.primary + on, `status.error` destructive, spacing (incl. the 16dp row leading keyline + 24dp group spacing), radius, size (row min height ≥ 48), typography, motion, breakpoints (compact 600 / expanded 840). The **only** file allowed raw values (each raw line ends with `// ux:ignore`); resolves light/dark per `Brightness`. |
| `settings_screen.dart` | The `SettingsScreen` widget — grouped sections, the search + zero-results state, all four row types, the destructive zone with confirm dialogs, the multi-step account deletion, the theme switch, the responsive layout, and the `SettingsState` machine. References tokens only. |

Verified on **Flutter 3.41 / Dart 3** (`flutter analyze` clean) and scores
**100/100** on `quality-checks/validators/run_all.py`.

> **Zero extra dependencies** — pure `flutter/material` (adaptive Material /
> Cupertino via `Switch.adaptive`, `AlertDialog.adaptive`, `showAdaptiveDialog`).

## What it demonstrates

**Grouped sections with headings** — Account · Notifications · Privacy &
Security · Appearance · About & Help (`SET-001`). Each header is exposed as a
heading landmark (`Semantics(header: true)`) so screen readers can jump between
groups (`A11Y-017`). Rows sit in grouped inset cards with hairline
`outline.variant` dividers.

**Search across all settings** (`SET-002`) with a **distinct zero-results empty
state** — the searched term is echoed ("No settings match 'foo'"), the result
count / zero-results is announced via a live region, and the list is never simply
blank (`STATE-004`, `A11Y-019`).

**Four row types** (`_RowKind`):

- **toggle** — `Switch.adaptive`; the whole row toggles; announces *"Notifications,
  on/off"*; state is carried by the **switch shape/position, not color**
  (`A11Y-012`).
- **disclosure** — the whole row navigates; a **chevron that mirrors in RTL**
  (Directionality-aware glyph); on compact it **pushes a sub-page**.
- **value + chevron** — shows the current value and **opens a picker**
  (`PLAT-006`); the selected option shows a check (not color-only).
- **action** — a button-styled row (Download my data, Contact support).

**Isolated destructive zone at the very bottom** (`SET-003`) — a "Danger zone"
heading + **red-labelled** *Sign out* and *Delete account*, out of the
accidental-tap arc, each behind an **explicit confirm dialog** (`DLG-001`). The
red is a redundant cue; the label names the action.

**Account deletion is reachable and multi-step** (store policy, `SET-004` /
`PROF-001`): an explaining first dialog, then a **typed-confirmation** gate —
"Delete permanently" stays disabled until you type `DELETE`, so the irreversible
action can't fire on a stray tap.

**Light/dark/system theme switch** (`DRK-001`) — a value+chevron row whose picker
offers System / Light / Dark; drive your `MaterialApp.themeMode` from
`onThemeChanged`.

**All seven states** via an explicit `enum SettingsState { ideal, loading, empty,
error, offline, success, permissionDenied }` on the data-backed parts (Settings
is otherwise local/instant):

- **loading** — a server-synced value (the account **Plan**) shows a **skeleton**
  matching its shape, then resolves.
- **empty** — search zero-results (above).
- **error** — a toggle that fails to save (**Product updates**) flips
  optimistically, then **REVERTS with a message** ("Couldn't save — try again" +
  Retry) — never a silent false success (`STATE-007`).
- **offline** — a non-blocking banner; **server-synced toggles disable with a
  spoken reason** and synced values show a "queued" note; local prefs still work
  (`OFF-002`).
- **success** — a change is confirmed inline ("Saved") and announced.
- **permissionDenied** — the **Push notifications** row **mirrors the true OS
  permission**: when denied it reflects "off" and **deep-links to system
  Settings** rather than a toggle that silently does nothing (`PERM-003`,
  `STATE-010`).

**Responsive** (`GRD-003`, `NAV-005`) driven by `MediaQuery.sizeOf` against named
breakpoint tokens:

| Window class | Width | Layout |
|---|---|---|
| Compact | `< 840dp` | A **single scrolling list**; a disclosure **pushes a sub-page**. |
| Expanded | `≥ 840dp` | **Two-pane**: a group list (leading) + the selected group's settings (detail), updated **in place**. |

Searching collapses either layout to one results list. The content keeps a
comfortable **max measure** (`SettingsSize.maxContent`) so rows never stretch
edge-to-edge on a wide window.

**Accessible & motion-safe:**

- Every row exposes **role + label + value/state** via `Semantics` — a toggle is
  *"label, on/off"*, a disclosure announces it **navigates**, a value row reads
  *"label, value"*; the destructive confirms are fully labelled (`A11Y-004/5/6`).
- Full-width rows are **≥ 48dp** tap targets with a **16dp leading keyline**; the
  **whole row is tappable** where it navigates (`SPC-008`, `SPC-015`).
- Text uses `Theme` text styles (no fixed heights, no sub-12 fonts); **long /
  localized labels wrap** rather than clip, so rows grow with Dynamic Type
  (`A11Y-010`, `L10N-003`).
- **RTL-safe** throughout — `EdgeInsetsDirectional`, `AlignmentDirectional`,
  `TextAlign.start/end`; **chevrons mirror**.
- **Motion** is transform/opacity only (search reflow, banner reveal, skeleton
  pulse), all collapsed to `Duration.zero` under `MediaQuery.disableAnimationsOf`
  (reduce motion, `MOT-004`).

## Drop into an app

`SettingsScreen` is self-contained — with no arguments it runs a demo that
exercises the search zero-results, the server-synced skeleton, the failed-save
revert, offline queueing, and the OS-permission-denied row. Wire the callbacks to
make it real:

```dart
import 'settings_screen.dart';

SettingsScreen(
  // Reached only after an explicit / multi-step confirm dialog.
  onSignOut: () => auth.signOut(),
  onDeleteAccount: () => account.deleteForever(),
  // Persist + apply the theme; drive MaterialApp.themeMode from this.
  onThemeChanged: (choice) => themeController.set(choice),
  initialThemeChoice: themeController.current,
  // Deep-link to the OS system-settings page for a permission-linked row.
  onOpenSystemSettings: () => AppSettings.openAppSettings(),
  // Push a disclosure row's sub-page (defaults to a placeholder page).
  onOpenSubPage: (title) => context.push('/settings/$title'),
  // From connectivity_plus / permission_handler.
  initialOffline: connectivity.isOffline,
  notificationsGranted: await Permission.notification.isGranted,
);
```

Notes:

- **Try the states** in the demo: type in **search** to see live filtering and,
  with a nonsense term, the **zero-results** state; the **cloud** button in the
  app bar toggles the offline banner (watch synced toggles disable and the Plan
  value queue); toggle **Product updates** to watch it revert with a message;
  **Push notifications** starts denied — tap **Open Settings** to grant it; open
  **Delete account** to walk the multi-step, typed-confirmation flow.
- **Colors** resolve through `SettingsColors.of(context)` off `Theme.brightness`.
  In production, promote `settings_tokens.dart` onto a `ThemeExtension<T>` (see
  `frameworks/flutter/tokens.md`) and read via `Theme.of(context)`.
- **Localization:** copy lives in the private `_Strings` class as a placeholder —
  route it through your i18n layer (whole messages, no concatenation).
- The demo-only offline toggle and `SnackBar` / placeholder sub-page fallbacks
  should be removed in production — connectivity, permissions, and navigation come
  from the platform / router.

## Validate

```bash
python3 quality-checks/validators/run_all.py examples/settings/flutter
# → Readiness score: 100/100 — PASS — clean
```
