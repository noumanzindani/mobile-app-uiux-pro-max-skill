# Settings — SwiftUI

A grouped, **searchable** settings screen with **isolated destructive actions** and
a reachable, **multi-step account-deletion** path. Reference implementation for
[`../spec.md`](../spec.md). Scores **100/100** on `run_all.py` and typechecks under
**both the iOS and macOS SDKs**.

## Files (one Xcode target / module)

| File | Role |
|---|---|
| [`SettingsTokens.swift`](SettingsTokens.swift) | Semantic design-token layer. The **only** file with raw values — every raw-number line ends `// ux:ignore`. Holds the cross-SDK `Color` shim. |
| [`SettingsScreen.swift`](SettingsScreen.swift) | The `SettingsScreen` view + its rows, banners, model, and sub-page detail. Zero literals — every value comes from `SettingsTokens`. |

> **Both files belong to ONE target/module.** `SettingsScreen.swift` references
> `SettingsTokens` directly (same module, no `import`). Drop both into the same app
> or framework target. In a shipping app the token colors map to asset-catalog Color
> sets generated from the DTCG tokens; here they resolve to Apple *semantic* system
> colors so light / dark / Increase-Contrast work automatically.

## What it demonstrates

**Grouped, platform-correct layout.** A `Form` + `Section` (`.formStyle(.grouped)` →
iOS grouped inset style) grouped by concern, with section headers exposed as
accessibility **headers**:

`Account · Notifications · Privacy & Security · Appearance · About & Help`

**Search across everything.** `.searchable` filters every setting by title, section,
and keyword. Empty sections disappear while typing, and a **zero-results** state
shows a distinct `ContentUnavailableView.search` — the list itself is never empty.

**Four row types.**

| Row type | Control | Notes |
|---|---|---|
| Toggle | `Toggle` | Announces role + on/off; server toggles disable offline |
| Disclosure | `NavigationLink` | Chevron auto-mirrors in RTL; whole row is tappable |
| Value + picker | native `Picker` (`.menu`) | Sync frequency (server) + Theme (light/dark/system) |
| Action | `Button` | Clear cache · Contact support |

**Isolated destructive zone.** Sign out and Delete account live in their **own
section at the very bottom**, out of the accidental-tap arc, drawn in the error
color (paired with an icon **and** a confirm — never color alone). Each sits behind
a confirmation:

- **Sign out** → single `.confirmationDialog` (`role: .destructive`).
- **Delete account** → **multi-step**: a `.confirmationDialog` (step 1) then an
  `.alert` with a **typed-DELETE** gate (step 2), so account deletion is reachable
  in-app per store policy. The delete button stays `.disabled` until you type `DELETE`.

**Responsive (breakpoint tokens, no device checks).** A `GeometryReader` width +
`@Environment(\.horizontalSizeClass)` feed a `SettingsLayout` built from the
`compact = 600` / `expanded = 840` tokens:

| Window class | Layout |
|---|---|
| Compact (< 840, or any compact width class) | single push `NavigationStack` |
| Expanded (≥ 840, regular width) | two-pane `NavigationSplitView` — group list (leading) + selected group (detail) |

**States (`SettingsState`: ideal · loading · empty · error · offline · success · permissionDenied).**

- **empty** — search with no match → `ContentUnavailableView.search`.
- **loading** — server-synced values (sync frequency) show a **shape-matched
  skeleton** (`.redacted(reason: .placeholder)`) until they hydrate; local toggles
  are instant.
- **error** — a toggle that fails to save **REVERTS** to its previous value and
  surfaces "Couldn't save … Try again." — never a silent false success.
- **offline** — a non-blocking banner rides `.safeAreaInset(edge: .top)`; server
  toggles/pickers disable with a reason while local prefs keep working.
- **success** — saved changes confirm inline via a bottom banner + a VoiceOver
  announcement.
- **permissionDenied** — the notification row reflects the **real** OS permission
  (`UNUserNotificationCenter`) and deep-links to Settings when denied
  (`UIApplication.openSettingsURLString`, guarded `#if os(iOS)`).

**Accessibility.** Toggles announce role + value; section headers carry
`.isHeader`; the destructive label is icon + text + confirm, not color-only; rows
are ≥ `rowMinHeight` (48pt); labels `.fixedSize(...vertical: true)` so Dynamic Type
grows rows and **wraps** long/localized text instead of clipping.

**Motion.** Opacity / position transitions only, each with an
`@Environment(\.accessibilityReduceMotion)` fallback baked into the motion token.

## Cross-SDK notes

- The **`Color` shim** in `SettingsTokens.swift` maps Apple semantic colors via
  `#if canImport(UIKit) … #elseif canImport(AppKit) … #endif` — no bare
  `Color(uiColor:)` at top level, so the token layer compiles on both toolchains.
- Every iOS-only API is guarded with **`#if os(iOS)`**
  (`.navigationBarTitleDisplayMode(.inline)`, `UIApplication.openSettingsURLString`,
  `UIApplication.shared.open`).

## Verify

```bash
# Validators (expects 100/100)
python3 quality-checks/validators/run_all.py examples/settings/swiftui

# Typecheck under both SDKs
cd examples/settings/swiftui
xcrun --sdk macosx  swiftc -typecheck SettingsTokens.swift SettingsScreen.swift
xcrun --sdk iphoneos swiftc -target arm64-apple-ios17.0 -typecheck SettingsTokens.swift SettingsScreen.swift
```
