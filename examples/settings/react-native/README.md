# Settings — React Native (TypeScript)

A real, compiling implementation of the [Settings spec](../spec.md) for React Native.
Every visual value resolves through semantic tokens; all seven UI states are modeled;
platform conventions, an isolated destructive zone, a reachable multi-step account
deletion, and a responsive compact/two-pane layout are all in place. Passes the
`quality-checks/validators` at **100/100**.

```
react-native/
  settingsTokens.ts  — semantic tokens (color/spacing/radius/size/typography/motion/
                       breakpoints). The ONLY file allowed raw literals; each `// ux:ignore`.
  SettingsScreen.tsx — the SettingsScreen component (grouped, searchable, responsive,
                       all states, accessible, platform-correct).
  README.md          — this file.
```

## What it demonstrates

**Grouped, platform-correct rows.** Settings are grouped by concern (Account ·
Notifications · Privacy & Security · Appearance · Help & About), each with a real
`accessibilityRole="header"`. Row groups render per-OS via `Platform.select`: an
iOS-style inset, rounded, hairline-bordered table vs. an Android Material-3 flat list.
Section headers follow suit (iOS small-caps muted vs. Android primary-colored label).

**Four row types.**

| Type | Behaviour |
|---|---|
| **toggle** | Native `Switch`. The whole row is the accessible control (`accessibilityRole="switch"` + `accessibilityState={{ checked }}`); the `Switch` is `accessible={false}` so a screen reader hears one coherent *"Label, switch, on/off"*. State is conveyed by the switch's shape/position (never color alone). |
| **disclosure** | Chevron that **mirrors in RTL** (`transform: scaleX(-1)`); tapping **pushes a sub-page** (compact) or opens it in the detail pane (expanded). External items (Help, Terms) open out instead. |
| **value + chevron** | Opens a **native picker** — `ActionSheetIOS` on iOS, a Material bottom-sheet on Android. Drives the live **Theme** (System / Light / Dark), text size, and digest choices. |
| **action** | Button-styled row (e.g. *Unblock all*), and the destructive actions below. |

**Isolated, confirmed destructive zone.** *Sign out* and *Delete account* live in
their own group at the very bottom — pushed out of the accidental-tap arc with a
`space.8` gap and a red (`color.status.error`) label. Each is behind an explicit
`Alert` confirm. **Account deletion is reachable in-app** (store-policy requirement)
behind a **multi-step** confirmation (warn → final "Delete permanently").

**All seven states (`SettingsState`).**

| State | Behaviour in this screen |
|---|---|
| **ideal** | Groups render current values; search works. |
| **loading** | Server-synced toggles show a pulsing **skeleton** in place of the switch until their value fetches (local toggles are instant). |
| **empty** | Search with no match shows a **distinct zero-results** state (*"Nothing matches 'foo'"*), announced politely — the list itself is never empty. |
| **error** | A failed save **reverts the toggle** and shows *"Couldn't save — try again"* inline with an assertive announcement — **never a silent false success**. (Seeded on *Product updates*, which fails the first attempt then succeeds.) |
| **offline** | A non-blocking banner appears; server-synced toggles are **disabled with a reason** (*"Unavailable offline"*) while local prefs keep working. |
| **success** | A successful save confirms inline (*"Saved"* ✓) and announces, then settles back. |
| **permissionDenied** | Rows that mirror an OS permission (notifications, location) reflect the **true system state** and **deep-link** to system Settings via `Linking.openSettings()` — the app never fakes the value. (*Location* is seeded denied.) |

**Responsive layout (`useWindowDimensions`).** Compact (`< 600`) is a single
scrolling list where a disclosure **pushes a sub-page**; expanded (`>= 840`) is a
**two-pane** group-list + detail. Breakpoints are tokens (`compact = 600`,
`expanded = 840`).

**Accessibility.** Every row exposes role + label + state; section headers are
headings; the search field is labeled and result counts / zero-results are announced;
targets are `>= 48dp` with a `16dp` leading keyline; text uses scalable roles
(`fontSize >= 12`, `allowFontScaling` default `true`, no fixed text heights) so it
grows and wraps under Dynamic Type; layout uses logical `start/end` (no `left/right`)
and chevrons mirror in RTL.

**Motion & reduce-motion.** The only motion is the sub-page push (`translateX`) and a
subtle search-reflow (`opacity`), each `<= 150ms` and **transform/opacity only**. All
of it collapses to an instant state when
`AccessibilityInfo.isReduceMotionEnabled()` is on.

**Tokens only.** `SettingsScreen.tsx` contains zero raw hex/spacing literals — colors,
spacing (4/8 grid), radius, target sizes, type roles, motion, and breakpoints all come
from `settingsTokens.ts`. Dark mode is automatic via `useColorScheme()`, and the
in-app **Theme** picker overrides it (System / Light / Dark) live.

## Dependencies

Beyond `react` / `react-native`:

| Package | Why |
|---|---|
| [`react-native-safe-area-context`](https://github.com/th3rdwave/react-native-safe-area-context) | `SafeAreaView` + `useSafeAreaInsets()` — precise per-edge insets so scroll content and the picker sheet clear the home indicator (never hardcode `34`/`44`). |
| [`@react-native-community/netinfo`](https://github.com/react-native-netinfo/react-native-netinfo) | Connectivity detection that drives the `offline` banner and disables/queues server-synced toggles. |

```bash
npm install react-native-safe-area-context @react-native-community/netinfo
# or: yarn add react-native-safe-area-context @react-native-community/netinfo
```

Wrap the app once in `<SafeAreaProvider>` (from `react-native-safe-area-context`) so
`useSafeAreaInsets()` resolves.

## Usage

```tsx
import SettingsScreen from './examples/settings/react-native/SettingsScreen';

<SettingsScreen
  onSignedOut={() => navigation.replace('Intro')}
  onAccountDeleted={() => navigation.replace('Intro')}      // after the multi-step confirm
  onOpenHelp={() => Linking.openURL('https://help.example.com')}
  onOpenLegal={(which) => navigation.navigate('Legal', { which })}
  saveSetting={async (id, value) => { /* your API; throw to show the revert path */ }}
  fetchSyncedValue={async (id) => { /* return the stored value; drives the skeleton */ return true; }}
  osPermissionState={{ 'notif-permission': true, location: false }}  // true OS state
/>;
```

Every handler is injectable and defaults to a light mock, so the file compiles and
runs standalone. Reject `saveSetting` to exercise the **error/revert** path, seed
`osPermissionState.location = false` to exercise **permissionDenied**, and toggle
airplane mode to see the **offline** banner and disabled server toggles.

## Validators

`python3 quality-checks/validators/run_all.py examples/settings/react-native/` →
**100/100, 0 errors** (`token_lint · contrast_check · target_size_lint ·
state_coverage · dynamic_type_check · rtl_check` all PASS).
