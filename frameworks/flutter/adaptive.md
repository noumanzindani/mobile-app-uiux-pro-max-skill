# Flutter — Platform-Adaptive Guidance

**Purpose:** Flutter renders its own widgets, so "feels native on both OSes" is work you author. This file shows the three cheap-to-expensive levers for platform correctness (`PLAT-*`). Decide the paradigm in `_index.md` first; this is the *how*.

## Table of contents
- [Detect the platform](#detect-the-platform)
- [Lever 1 — .adaptive constructors](#lever-1--adaptive-constructors-cheapest)
- [Lever 2 — branch the divergent widgets](#lever-2--branch-the-divergent-widgets)
- [Lever 3 — whole-paradigm switch](#lever-3--whole-paradigm-switch)
- [What to branch vs share](#what-to-branch-vs-share)
- [Responsive is orthogonal](#responsive-is-orthogonal)

## Detect the platform
```dart
// Reactive to the widget tree's theme (respects overrides in tests/desktop):
final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
// Or the global default (no context):
final isCupertino = defaultTargetPlatform == TargetPlatform.iOS ||
                    defaultTargetPlatform == TargetPlatform.macOS;
```
Prefer `Theme.of(context).platform` — it's overridable, so widget tests and adaptive previews work.

## Lever 1 — `.adaptive` constructors (cheapest)
Several Material widgets ship a constructor that renders the Cupertino look on Apple platforms automatically — zero branching:
```dart
Switch.adaptive(value: on, onChanged: setOn);                 // iOS toggle vs Material
Slider.adaptive(value: v, onChanged: setV);
CircularProgressIndicator.adaptive();                         // iOS spinner vs Material
showAdaptiveDialog(context: context, builder: …);            // CupertinoAlertDialog vs AlertDialog
Checkbox.adaptive(value: c, onChanged: setC);
const Icon(Icons.share).adaptiveIcon /* choose SF-like glyphs manually */;
```
Use these first — they cover the most-noticed small controls for free.

## Lever 2 — branch the divergent widgets
Where no `.adaptive` exists but the platforms visibly diverge, fork just that widget:
```dart
Widget primaryButton(BuildContext c, String label, VoidCallback onTap) =>
    Theme.of(c).platform == TargetPlatform.iOS
        ? CupertinoButton.filled(onPressed: onTap, child: Text(label))
        : FilledButton(onPressed: onTap, child: Text(label));
```
Common branch points: **nav bar** (`CupertinoNavigationBar` vs `AppBar`), **sheets** (`CupertinoSheetRoute` / `showCupertinoModalPopup` vs `showModalBottomSheet`), **date/time pickers** (`CupertinoDatePicker` vs Material pickers), **swipe-back** (Cupertino gives it free; Material uses predictive back).

## Lever 3 — whole-paradigm switch
For a true native-per-OS feel, branch at the app root and keep two idiomatic trees for the shell (nav, scaffolds), sharing leaf content:
```dart
Widget build(BuildContext context) => defaultTargetPlatform == TargetPlatform.iOS
    ? CupertinoApp(theme: cupertinoTheme, home: const CupertinoShell())
    : MaterialApp(theme: materialLight, darkTheme: materialDark, home: const MaterialShell());
```
Reserve this for products with a hard "indistinguishable from native" requirement — it doubles shell maintenance. Most apps are best served by Lever 1 + 2 on a single Material base.

## What to branch vs share
| Diverges most → branch | Safe to share |
|---|---|
| Navigation bar / tab bar chrome | Business logic, providers, models |
| Modal sheets & their gestures | Token-driven content widgets |
| Alert/action dialogs (button order!) | Lists, cards, forms body |
| Switches / sliders / pickers | Icons (choose per-platform glyphs) |
| Back/swipe behavior | Typography scale (still respect Dynamic Type) |

Dialog button placement is platform-specific (`DLG-*`, `PLAT-*`): iOS destructive/confirm ordering differs from Material — `showAdaptiveDialog` handles it; if you hand-roll, get it right per OS.

## Responsive is orthogonal
Adaptive (which OS) ≠ responsive (how big). Do both (`GRD-*`):
```dart
final w = MediaQuery.sizeOf(context).width;
if (w >= 840) return TwoPaneListDetail();     // ≥840dp two-pane
if (w >= 600) return ScaffoldWithRail();      // 600–839dp NavigationRail
return ScaffoldWithBottomBar();               // <600dp bottom nav
```
Use `MediaQuery.sizeOf`/`LayoutBuilder`; NavigationRail ≥600dp, list-detail ≥840dp. Reduce-motion, RTL (`L10N-*`), and Dynamic Type all still apply in every branch.
