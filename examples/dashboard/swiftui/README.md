# Dashboard — SwiftUI

A glanceable, **responsive** dashboard where **each widget owns its own state**.
Reference implementation for [`../spec.md`](../spec.md). Scores **100/100** on
`run_all.py` and typechecks under **both the iOS and macOS SDKs**.

## Files (one Xcode target / module)

| File | Role |
|---|---|
| [`DashboardTokens.swift`](DashboardTokens.swift) | Semantic design-token layer. The **only** file with raw values — every raw-number line ends `// ux:ignore`. Holds the cross-SDK `Color` shim. |
| [`DashboardScreen.swift`](DashboardScreen.swift) | The `DashboardScreen` view + self-contained tiles (`MetricTile`, `ChartTile`, `ActivityTile`). Zero literals — every value comes from `DashboardTokens`. |

> **Both files belong to ONE target/module.** `DashboardScreen.swift` references
> `DashboardTokens` directly (same module, no `import`). Drop both into the same
> app/framework target. In a shipping app the token colors map to asset-catalog
> Color sets generated from the DTCG tokens; here they resolve to Apple *semantic*
> system colors so light / dark / Increase-Contrast work automatically.

## What it demonstrates

**Responsive reflow (no device checks).** `@Environment(\.horizontalSizeClass)` +
a `GeometryReader` width feed a `DashboardLayout` built from **breakpoint tokens**
(`compact = 600`, `expanded = 840`):

| Window class | Grid | Navigation |
|---|---|---|
| Compact (< 600) | 1 column | bottom `TabView` |
| Medium (600–839) | 2 columns (`LazyVGrid` adaptive) | side rail (`NavigationSplitView`) |
| Expanded (≥ 840) | 3–4 columns (`LazyVGrid` adaptive) | side rail (`NavigationSplitView`) |

Adaptive `GridItem` reflows the column count to the actual pane width, so rotate /
fold / split-screen just work. Content measure is capped (`contentMaxWidth`) so a
single column never stretches edge-to-edge.

**Per-widget state.** Every tile owns a `WidgetState`
(`loading / empty / error / offline / success / permissionDenied / ideal`). There
is **no global spinner** — one failing tile shows a scoped inline error + **Retry**
while every other tile stays live:

- **loading** → a **shape-matched** skeleton (label line + number block).
- **empty** → first-use empty with a CTA.
- **error** → compact inline error + Retry (recovers on retry).
- **offline** → the **cached value** with a `Cached` stale indicator; refresh is
  disabled with a reason.
- **permissionDenied** → scoped explain + Open Settings (`#if os(iOS)`), rest of
  the dashboard unaffected.

**Trustworthy numbers.** Values use the `.monospacedDigit()` token font +
`.formatted(...)`. Trend is **icon + sign + text** (`arrow.up.right` + `+4.2%` +
period) — never color-only.

**Accessible chart.** A bar chart drawn with shapes, **each bar labeled**, plus a
**data-table fallback** reachable by VoiceOver — the chart element reads its full
series and a real `Grid` data table can be toggled (`View as table`).

**Refresh + announcements.** Pull-to-refresh reloads every tile independently
(`.task(id: refreshTick)`); completion announces "Updated" via
`AccessibilityNotification.Announcement`. A global offline banner rides
`.safeAreaInset(edge: .top)`.

**Motion.** Opacity/offset transitions only, each with an
`@Environment(\.accessibilityReduceMotion)` fallback baked into the motion tokens.

## Cross-SDK notes

- The **`Color` shim** in `DashboardTokens.swift` maps Apple semantic colors via
  `#if canImport(UIKit) … #elseif canImport(AppKit) … #endif` — no bare
  `Color(uiColor:)` at top level, so the token layer compiles on both toolchains.
- Every iOS-only modifier is guarded with **`#if os(iOS)`**
  (`.navigationBarTitleDisplayMode(.inline)`, `UIApplication.openSettingsURLString`).

## Verify

```bash
# Validators (expects 100/100)
python3 quality-checks/validators/run_all.py examples/dashboard/swiftui

# Typecheck under both SDKs
cd examples/dashboard/swiftui
xcrun -sdk macosx   swiftc -typecheck DashboardTokens.swift DashboardScreen.swift
xcrun -sdk iphoneos swiftc -typecheck -target arm64-apple-ios26.0 \
    DashboardTokens.swift DashboardScreen.swift
```

The `#Preview`s (default, plus dark + `.accessibility3` Dynamic Type) exercise the
responsive reflow, per-tile states, and text scaling. Use the toolbar **⋯ → Offline
(demo)** to drive the offline banner and per-tile cached/stale state.
