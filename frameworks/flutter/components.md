# Flutter — Idiomatic Components

**Purpose:** The correct Flutter widget + shape for each core UI job, with safe-area, accessibility, and animation baked in. Every value below resolves through the theme (see `tokens.md`); rules are referenced by ID. Copy-paste stubs live in `snippets/`.

## Table of contents
- [Buttons](#buttons)
- [Lists (virtualized)](#lists-virtualized)
- [Bottom sheets (detents)](#bottom-sheets-detents)
- [Navigation](#navigation)
- [Safe area & keyboard](#safe-area--keyboard)
- [Accessibility](#accessibility)
- [Animation](#animation)

## Buttons
Use the M3 button family by emphasis — **one primary action per view** (`BTN-*`): `FilledButton` (primary) › `FilledButton.tonal` › `OutlinedButton` › `TextButton`. Material buttons already meet 48dp height; for bare icons wrap in `IconButton` (48dp min) — never a raw `GestureDetector` on a 24dp glyph (`ICN-*`, `A11Y-*`).

```dart
FilledButton(
  onPressed: isLoading ? null : onSubmit,        // null → disabled state (BTN-*)
  child: isLoading
      ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
      : const Text('Continue'),
);
```
- Loading: swap child for a sized `CircularProgressIndicator`; keep width stable to avoid layout jump.
- Press feedback: Material ink + optional `HapticFeedback.selectionClick()` on primary/destructive (`MIC-*`, `HAP-*`).
- Destructive: color from `context.colors.error`; place out of the thumb-destruction arc + confirm (`DLG-*`).

## Lists (virtualized)
**Always** `ListView.builder` / `ListView.separated` / `SliverList.builder` — they build only visible rows. A `Column`/`SingleChildScrollView` of N children is a bug at scale (`LST-*`, `PERF-*`).
```dart
ListView.separated(
  padding: EdgeInsets.symmetric(vertical: context.space.sm),
  itemCount: items.length,
  separatorBuilder: (_, __) => const Divider(height: 1),
  itemBuilder: (context, i) => ListTile(
    title: Text(items[i].title),
    subtitle: Text(items[i].subtitle),
    onTap: () => open(items[i]),
    minVerticalPadding: 12,          // keeps row ≥48dp target (A11Y-*)
  ),
);
```
- Pull-to-refresh: wrap in `RefreshIndicator` (`OFF-*`).
- Loading: render a skeleton list of the same row shape (see `states.md`), not a bare spinner.
- Long/complex rows or huge datasets: prefer `SliverList` inside a `CustomScrollView` so headers/app-bars scroll cohesively.

## Bottom sheets (detents)
Modal picker/detail → `showModalBottomSheet` with `DraggableScrollableSheet` for snap points ("detents"). Respect the home-indicator inset and cap height below the status bar (`BSH-*`).
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,                 // required for tall / keyboard sheets
  showDragHandle: true,                      // M3 drag affordance
  builder: (context) => DraggableScrollableSheet(
    initialChildSize: 0.5, minChildSize: 0.25, maxChildSize: 0.95, // detents
    expand: false,
    builder: (context, controller) => SafeArea(          // bottom inset (BSH-*)
      top: false,
      child: ListView(controller: controller, children: const [/* … */]),
    ),
  ),
);
```
Full stub incl. keyboard handling in `snippets/sheet.md`.

## Navigation
- Bottom tabs (**≤5**, `NAV-*`): `NavigationBar` + `NavigationDestination`. Switch to `NavigationRail` at ≥600dp (`GRD-*`).
- Routing: `Navigator.pushNamed` for small apps; `go_router` for deep links, nested tabs, web URLs. **Never override the system back gesture** (`NAV-*`, `GES-*`) — Flutter's `Navigator` and predictive-back handle it.
```dart
Scaffold(
  body: pages[index],
  bottomNavigationBar: NavigationBar(
    selectedIndex: index,
    onDestinationSelected: (i) => setState(() => index = i),
    destinations: const [
      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
      NavigationDestination(icon: Icon(Icons.search),        label: 'Search'),
      NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
    ],
  ),
);
```

## Safe area & keyboard
Use the framework primitive — never hardcode notch/indicator insets (`A11Y-*`):
- `SafeArea` for the common case; disable edges a nav bar already pads (`SafeArea(top: false, …)`).
- `MediaQuery.paddingOf(context)` for manual inset math (cheaper than `MediaQuery.of` — no full rebuild).
- `MediaQuery.viewInsetsOf(context).bottom` for keyboard height; or wrap the sheet/form content and let `Scaffold(resizeToAvoidBottomInset: true)` (default) do it. See `snippets/safe-area.md`.

## Accessibility
Every interactive/meaningful element gets label + role + state (`A11Y-*`). Material widgets are semantic by default; annotate custom ones:
```dart
Semantics(
  label: 'Add to cart',
  button: true,
  enabled: !isLoading,
  child: InkWell(onTap: add, child: /* custom visual */),
);
```
- `MergeSemantics` to fuse an icon+label into one focus stop; `ExcludeSemantics` for decorative art.
- Announce async results to screen readers: `SemanticsService.announce('Item added', TextDirection.ltr)` (or a `liveRegion: true` Semantics for the offline/success banner).
- Respect Dynamic Type: use `textTheme` styles (they scale); never fixed-height text boxes (`dynamic_type_check.py`).

## Animation
- **Implicit** (state → state): `AnimatedContainer`, `AnimatedOpacity`, `AnimatedSwitcher` — the default for simple transitions.
- **Explicit** (orchestrated): `AnimationController` + `Tween`/`CurvedAnimation` inside a `State` with `SingleTickerProviderStateMixin`; drive with `AnimatedBuilder`.
- **Shared element:** `Hero(tag: …)` across routes.
- Durations/easing from motion tokens (`MOT-*`): micro 100ms, small 200–250, medium 300–400; never >500 for routine transitions.
- **Reduce motion:** gate non-essential animation on `MediaQuery.disableAnimationsOf(context)` (or `MediaQuery.of(context).accessibleNavigation`) and fall back to an instant/cross-fade path (`MOT-*`, `A11Y-*`).
```dart
final reduceMotion = MediaQuery.disableAnimationsOf(context);
AnimatedScale(
  scale: pressed ? 0.97 : 1.0,
  duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 120),
  child: child,
);
```
