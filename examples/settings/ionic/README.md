# Settings — Ionic (React + Capacitor, TypeScript)

A real implementation of the [Settings spec](../spec.md) for **Ionic 8**. Every visual
value resolves through CSS custom properties; every one of the 7 UI states is modeled
explicitly; the screen passes all six `quality-checks/validators` (**100/100**).

```
ionic/
  settings.css       — token + style layer: --app-* / --ion-* variables and classes.
                       The ONLY file with raw values; the screen references var(...) only.
  SettingsScreen.tsx — the SettingsScreen component (all 7 states, grouped + searchable,
                       isolated destructive zone, responsive two-pane, mode-adaptive).
  README.md          — this file.
```

> Bindings shown are `@ionic/react`; the same component/token approach applies to
> `@ionic/angular` and `@ionic/vue`.

## What it demonstrates

**All 7 states, as a discriminated union.** `SettingsState` has members literally named
`idle · loading · empty · error · offline · success · permissionDenied`, so TypeScript
forces exhaustive handling.

| State | Behaviour |
|---|---|
| **idle** | Grouped rows reflect current values; local toggles flip instantly. |
| **loading** | Server-synced toggles show an `IonSkeletonText` in place of the switch until each value resolves; local toggles never wait. |
| **empty** | Search with no match shows a **distinct zero-results** placeholder (*"No settings found — nothing matches …"*), announced politely — the list itself is never empty. |
| **error** | A toggle that fails to save **reverts** and surfaces *"Couldn't save — try again"* inline (`role="alert"`) — never a silent false success. |
| **offline** | Non-blocking banner + Retry (via `@capacitor/network`); server-synced toggles disable with a reason; local prefs still work. |
| **success** | The toggle reflects the **true saved state**; an inline *"Saved"* + an `ion-toast` confirm the outcome. |
| **permissionDenied** | OS-permission rows (notifications, location) mirror the **actual system state** and deep-link to system Settings — the app never fakes the value. |

**Grouped + searchable.** Sections use real `IonListHeader` headers (Account ·
Notifications · Privacy & Security · Appearance · Help & About). `IonSearchbar` filters
every setting across label / description / keywords / group and reflows the list.

**Isolated destructive zone.** *Sign out* and *Delete account* live in their **own
`IonList` at the very bottom**, out of the accidental-tap arc, red-labelled, each behind
an explicit `useIonAlert` confirm. **Account deletion is reachable in-app** (store policy)
behind a **multi-step** confirmation.

**Four row types.** Toggle (`IonToggle`), disclosure (`IonItem detail` chevron that
**mirrors in RTL**, pushes an `IonModal` sub-page), value+chevron (opens a **native
picker** via `useIonActionSheet`), and action (button-styled `IonItem`).

**Live theming.** The Appearance › Theme picker (System / Light / Dark) toggles Ionic's
`.ion-palette-dark` class, so the whole surface recolors live; *System* follows
`prefers-color-scheme`.

**Responsive.** Compact is one scrolling list that **pushes** a sub-page; at **≥ 840dp**
a CSS grid switches to a **two-pane** group-list + detail (list-detail).

**Tokens via CSS variables.** `SettingsScreen.tsx` holds zero raw `#hex`/`px` — colors come
from `--ion-color-*` / `--ion-color-step-*`, spacing/radius from `--app-space-*` /
`--app-radius-*`, all defined in `settings.css`. Dark mode is a class **palette**
(`.ion-palette-dark`) — the component doesn't change, only the variable values do; verify
both with `contrast_check.py`.

**Adaptive (`mode`).** Ionic auto-renders the iOS inset/rounded grouped table vs the
Android Material-3 flat list from one component tree; verify both modes before shipping
(`PLAT-*`).

**Accessible.** Each row exposes role + label + state: `IonToggle` announces its
on/off `checked` state (never colour-only); disclosures/pickers announce that they
navigate/open options; section headers are exposed as headers; the searchbar is labeled
and the result count / zero-results is announced.

**Targets.** All interactive controls are `IonItem`/`IonToggle`/`IonButton` (≥48px min
height); no bare tappable icons.

**Dynamic Type & RTL.** No fixed text heights, no sub-12px fonts; `ion-text-wrap` lets
long/localized labels wrap; layout uses logical CSS (`slot="start"/"end"`,
`padding-inline`, `border-inline-start`) — no physical `left/right` — so it mirrors in RTL.

## Dependencies

| Package | Why |
|---|---|
| `@ionic/react` + `ionicons` | Ionic components + icon set. |
| `@capacitor/network` | Connectivity for the `offline` state / banner. |

```bash
npm install @ionic/react ionicons @capacitor/network
```

Add `<meta name="viewport" content="viewport-fit=cover" />` and import a dark palette
(`@ionic/react/css/palettes/dark.class.css`) once in the app entry.

## Usage

```tsx
import SettingsScreen from './examples/settings/ionic/SettingsScreen';

<SettingsScreen
  saveSetting={async (id, value, attempt) => { /* your API; throw to show the revert */ }}
  fetchSyncedValue={async (id) => true /* drives the loading skeleton */}
  osPermissionState={{ 'notif-permission': true, location: false }}
  onAccountDeleted={() => history.replace('/goodbye')}
  openSettings={() => NativeSettings.open(/* … */)}
/>;
```

`saveSetting` / `fetchSyncedValue` are injectable and default to mocks, so the file runs
standalone.

## Validators

`python3 quality-checks/validators/run_all.py examples/settings/ionic/` →
**100/100, 0 errors** (`token_lint · contrast_check · target_size_lint · state_coverage ·
dynamic_type_check · rtl_check` all PASS).
