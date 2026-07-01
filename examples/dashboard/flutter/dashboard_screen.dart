// dashboard_screen.dart
//
// A glanceable, responsive dashboard built to the spec in
// examples/dashboard/spec.md. Its defining rule: there is NO single global
// state — each tile loads, empties, errors, and goes stale INDEPENDENTLY
// (STATE-014). One failed metric never blanks the screen; the others stay live.
//
// RESPONSIVE (GRD-001..004): a grid of self-contained metric cards + a small
// CustomPaint chart + an activity list, re-flowed by width via LayoutBuilder and
// MediaQuery.sizeOf:
//   compact   < 600dp  -> 1 column  + bottom navigation bar
//   medium  600..839dp -> 2 columns + NavigationRail
//   expanded  >= 840dp -> 3-4 columns (the chart spans 2) + NavigationRail
// On very wide windows the content keeps a comfortable max measure (GRD-005) so a
// single column never stretches edge-to-edge. The selected drill-in survives a
// rotate / fold / split resize because layout is derived purely from width.
//
// PER-WIDGET STATE: every tile owns a `WidgetState` (loading, empty, error,
// offline, success, permissionDenied, ideal). Loading shows a SKELETON matching
// the tile's shape; error shows an INLINE compact message + Retry scoped to that
// tile; empty shows a first-use prompt + CTA; offline shows the CACHED value with
// a "last updated / stale" indicator. A GLOBAL, non-blocking offline banner sits
// above the grid (announced via a live region), separate from any tile.
//
// ACCESSIBILITY: each card is a grouped Semantics node with a coherent name
// ("Balance, $2,430, up 4% this week"); trend is icon + sign + text, never
// color-only (A11Y-012); numbers use tabular figures + intl locale formatting
// (TYP-006, L10N-005); the chart carries a screen-reader DATA-TABLE fallback
// (CHT-002); pull-to-refresh announces "Updated" via a live region (A11Y-019).
//
// Every color / spacing / radius / size / duration / text style comes from
// dashboard_tokens.dart — this file holds no raw design values (token_lint). All
// motion is transform/opacity only and collapses to Duration.zero under
// MediaQuery.disableAnimationsOf (reduce motion, MOT-004). Layout is RTL-safe
// throughout (EdgeInsetsDirectional / AlignmentDirectional / TextAlign.start-end).
//
// Drop-in: `DashboardScreen(onOpenMetric: (id) => context.go('/m/$id'))`. It runs
// a self-contained demo with no arguments. See README.

import 'dart:math' as math;

import 'package:flutter/material.dart' hide WidgetState;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'dashboard_tokens.dart';

/// The seven states a single tile can be in (spec "States map"). Modeled as an
/// explicit enum so each tile's switchboard is exhaustive and no state is ever
/// forgotten. The four data-backed states — loading, empty, error, offline —
/// plus success are what make a dashboard trustworthy rather than a demo.
enum WidgetState {
  /// Fetching this tile's data — a skeleton matching the tile's shape shows.
  loading,

  /// No data yet for this tile — a first-use prompt + optional CTA (never blank).
  empty,

  /// This tile's fetch failed — an inline, compact message + Retry, scoped here.
  error,

  /// No connectivity — the tile shows its CACHED value with a stale indicator.
  offline,

  /// Loaded and current — value + trend; the happy path (== ideal).
  success,

  /// A capability this tile needs (health/location) is denied — explain + fix.
  permissionDenied,

  /// Loaded, current, nothing pending — the fully-realized tile (alias of success).
  ideal,
}

/// Trend direction — conveyed by a vertical arrow + a signed value + text, so it
/// is never encoded by color alone (A11Y-012, COL-003).
enum TrendDir { up, down, flat }

/// How a metric's value is formatted (locale-aware, via intl).
enum _Unit { currency, count, steps }

/// A window size class derived from width (GRD-001..003).
enum _WindowClass { compact, medium, expanded }

/// A trend delta attached to a metric.
@immutable
class _Trend {
  const _Trend(this.dir, this.pct);
  final TrendDir dir;
  final int pct;
}

/// One point in the bar chart (a labeled bar).
@immutable
class _ChartPoint {
  const _ChartPoint(this.label, this.value);
  final String label;
  final double value;
}

/// One row in the activity feed.
@immutable
class _Activity {
  const _Activity({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amountCents,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final int amountCents;
}

/// A tile plus how many grid columns it spans (clamped to the live column count).
@immutable
class _GridChild {
  const _GridChild(this.span, this.child);
  final int span;
  final Widget child;
}

/// Copy. Kept as constants so layout code stays about layout; route through your
/// i18n layer in a real app (whole messages, no concatenation — L10N-002).
class _Strings {
  const _Strings._();

  static const String title = 'Dashboard';
  static const String greeting = 'Good morning';
  static const String overview = "Here's your overview";
  static const String dateRange = 'This week';
  static const String notifications = 'Notifications';
  static const String account = 'Account';
  static const String offlineBanner =
      "You're offline. Showing the last data we saved.";
  static const String dismiss = 'Dismiss';
  static const String refreshing = 'Refreshing dashboard';
  static const String updated = 'Updated';
  static const String retry = 'Retry';
  static const String revenueTitle = 'Revenue';
  static const String activityTitle = 'Recent activity';
  static const String viewTable = 'View data as table';
  static const String hideTable = 'Hide table';
  static const String colDay = 'Day';
  static const String colRevenue = 'Revenue';

  // Nav
  static const String navOverview = 'Overview';
  static const String navAnalytics = 'Analytics';
  static const String navWallet = 'Wallet';
  static const String navActivity = 'Activity';
  static const String navProfile = 'Profile';
}

/// A self-contained, responsive dashboard screen.
///
/// With no arguments it runs a demo that exercises every per-tile state. Wire the
/// callbacks to make it real; promote [DashColors] onto a `ThemeExtension` in
/// production (see `frameworks/flutter/tokens.md`).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.onOpenMetric,
    this.onRefresh,
    this.onOpenSettings,
    this.initialOffline = false,
  });

  /// Drill into a metric's detail (spec: one tap to detail — CRD-001).
  final void Function(String metricId)? onOpenMetric;

  /// Real refresh hook — return when the new data is ready. The demo simulates it.
  final Future<void> Function()? onRefresh;

  /// Deep-link to OS settings for a permission-denied tile (PERM-003).
  final VoidCallback? onOpenSettings;

  /// Start in the offline treatment (global banner + stale tiles).
  final bool initialOffline;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _navIndex = 0;
  int _refreshTick = 0;
  bool _offline = false;
  String _announce = '';

  static const List<_ChartPoint> _revenue = [
    _ChartPoint('Mon', 1200),
    _ChartPoint('Tue', 1850),
    _ChartPoint('Wed', 1500),
    _ChartPoint('Thu', 3400),
    _ChartPoint('Fri', 2600),
    _ChartPoint('Sat', 900),
    _ChartPoint('Sun', 2100),
  ];

  static const List<_Activity> _activity = [
    _Activity(
      icon: Icons.arrow_downward,
      title: 'Payout to bank',
      subtitle: 'Today, 09:24',
      amountCents: -84000,
    ),
    _Activity(
      icon: Icons.arrow_upward,
      title: 'Invoice #1043 paid',
      subtitle: 'Yesterday',
      amountCents: 126000,
    ),
    _Activity(
      icon: Icons.arrow_upward,
      title: 'New subscription',
      subtitle: 'Mon',
      amountCents: 2900,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _offline = widget.initialOffline;
  }

  @override
  Widget build(BuildContext context) {
    final colors = DashColors.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final width = MediaQuery.sizeOf(context).width;
    final windowClass = _windowClassFor(width);
    final body = _buildScrollBody(context, colors, reduceMotion);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: _buildAppBar(context, colors),
      body: SafeArea(
        child: windowClass == _WindowClass.compact
            ? body
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildRail(context, colors),
                  VerticalDivider(
                    width: DashSize.stroke,
                    thickness: DashSize.stroke,
                    color: colors.divider,
                  ),
                  Expanded(child: body),
                ],
              ),
      ),
      bottomNavigationBar: windowClass == _WindowClass.compact
          ? _buildBottomNav(context, colors)
          : null,
    );
  }

  // --- chrome ----------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(BuildContext context, DashColors colors) {
    return AppBar(
      backgroundColor: colors.surface,
      surfaceTintColor: colors.surface,
      title: Text(
        _Strings.title,
        style: DashType.section(context)?.copyWith(color: colors.onSurface),
      ),
      actions: [
        IconButton(
          onPressed: _toggleOffline,
          iconSize: DashSize.icon,
          tooltip: _offline ? 'Go online (demo)' : 'Go offline (demo)',
          icon: Icon(_offline ? Icons.cloud_off : Icons.cloud_done_outlined),
        ),
        IconButton(
          onPressed: () => _openMetric('notifications'),
          iconSize: DashSize.icon,
          tooltip: _Strings.notifications,
          icon: const Icon(Icons.notifications_outlined),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: DashSpace.xs,
            end: DashSpace.md,
          ),
          child: Semantics(
            label: _Strings.account,
            button: true,
            child: CircleAvatar(
              radius: DashSize.iconSm,
              backgroundColor: colors.primary,
              child: Text(
                'AJ',
                style: DashType.caption(context)
                    ?.copyWith(color: colors.onPrimary),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context, DashColors colors) {
    return NavigationBar(
      selectedIndex: _navIndex,
      backgroundColor: colors.surfaceContainer,
      onDestinationSelected: (i) => setState(() => _navIndex = i),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: _Strings.navOverview,
        ),
        NavigationDestination(
          icon: Icon(Icons.insights_outlined),
          selectedIcon: Icon(Icons.insights),
          label: _Strings.navAnalytics,
        ),
        NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: _Strings.navWallet,
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: _Strings.navActivity,
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: _Strings.navProfile,
        ),
      ],
    );
  }

  Widget _buildRail(BuildContext context, DashColors colors) {
    return NavigationRail(
      selectedIndex: _navIndex,
      backgroundColor: colors.surfaceContainer,
      labelType: NavigationRailLabelType.all,
      onDestinationSelected: (i) => setState(() => _navIndex = i),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text(_Strings.navOverview),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.insights_outlined),
          selectedIcon: Icon(Icons.insights),
          label: Text(_Strings.navAnalytics),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: Text(_Strings.navWallet),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: Text(_Strings.navActivity),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: Text(_Strings.navProfile),
        ),
      ],
    );
  }

  // --- body ------------------------------------------------------------------

  Widget _buildScrollBody(
    BuildContext context,
    DashColors colors,
    bool reduceMotion,
  ) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: colors.primary,
      backgroundColor: colors.surfaceContainer,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.all(DashSpace.edge),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: DashSize.maxContent),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Live region: refresh completion is spoken here (A11Y-019).
                _LiveAnnouncer(message: _announce),
                // GLOBAL non-blocking offline banner, separate from any tile.
                _OfflineBanner(
                  visible: _offline,
                  colors: colors,
                  reduceMotion: reduceMotion,
                  onDismiss: _toggleOffline,
                ),
                if (_offline) const SizedBox(height: DashSpace.gutter),
                _GreetingHeader(colors: colors),
                const SizedBox(height: DashSpace.gutter),
                _ResponsiveGrid(children: _tiles(context, colors, reduceMotion)),
                const SizedBox(height: DashSpace.gutter),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_GridChild> _tiles(
    BuildContext context,
    DashColors colors,
    bool reduceMotion,
  ) {
    return [
      // success / ideal — value + upward trend, one-tap to detail.
      _GridChild(
        1,
        _MetricCard(
          key: const ValueKey('balance'),
          colors: colors,
          reduceMotion: reduceMotion,
          refreshTick: _refreshTick,
          icon: Icons.account_balance_wallet_outlined,
          title: 'Balance',
          unit: _Unit.currency,
          baseValue: 243000,
          trend: const _Trend(TrendDir.up, 4),
          period: 'this week',
          initialState: WidgetState.success,
          onOpen: () => _openMetric('balance'),
        ),
      ),
      // offline — cached value + stale indicator (this tile follows global net).
      _GridChild(
        1,
        _MetricCard(
          key: const ValueKey('spending'),
          colors: colors,
          reduceMotion: reduceMotion,
          refreshTick: _refreshTick,
          icon: Icons.trending_down,
          title: 'Spending',
          unit: _Unit.currency,
          baseValue: 118000,
          trend: const _Trend(TrendDir.down, 3),
          period: 'this week',
          cachedNote: 'Updated 2h ago',
          initialState: WidgetState.offline,
          onOpen: () => _openMetric('spending'),
        ),
      ),
      // loading -> resolves to success on its own (per-tile skeleton, MOT-001).
      _GridChild(
        1,
        _MetricCard(
          key: const ValueKey('active'),
          colors: colors,
          reduceMotion: reduceMotion,
          refreshTick: _refreshTick,
          icon: Icons.bolt_outlined,
          title: 'Active now',
          unit: _Unit.count,
          baseValue: 128,
          trend: const _Trend(TrendDir.up, 12),
          period: 'vs. 1h ago',
          initialState: WidgetState.loading,
          onOpen: () => _openMetric('active'),
        ),
      ),
      // empty — first-use, with a CTA to fill it.
      _GridChild(
        1,
        _MetricCard(
          key: const ValueKey('customers'),
          colors: colors,
          reduceMotion: reduceMotion,
          refreshTick: _refreshTick,
          icon: Icons.group_add_outlined,
          title: 'New customers',
          unit: _Unit.count,
          emptyMessage: 'No new customers yet this month.',
          emptyCta: 'Invite',
          initialState: WidgetState.empty,
          onEmptyAction: () => _openMetric('customers'),
        ),
      ),
      // error — inline, compact, Retry scoped to THIS tile; others stay live.
      _GridChild(
        1,
        _MetricCard(
          key: const ValueKey('tasks'),
          colors: colors,
          reduceMotion: reduceMotion,
          refreshTick: _refreshTick,
          icon: Icons.task_alt_outlined,
          title: 'Open tasks',
          unit: _Unit.count,
          baseValue: 7,
          trend: const _Trend(TrendDir.flat, 0),
          period: 'today',
          initialState: WidgetState.error,
          onOpen: () => _openMetric('tasks'),
        ),
      ),
      // permission-denied — scoped explain + Settings link; rest is unaffected.
      _GridChild(
        1,
        _MetricCard(
          key: const ValueKey('steps'),
          colors: colors,
          reduceMotion: reduceMotion,
          refreshTick: _refreshTick,
          icon: Icons.directions_walk_outlined,
          title: 'Steps',
          unit: _Unit.steps,
          permissionMessage:
              'Turn on Health access to see your steps here.',
          initialState: WidgetState.permissionDenied,
          onPermissionSettings: _openSettings,
        ),
      ),
      // chart — spans 2 columns; CustomPaint bars + data-table fallback.
      _GridChild(
        2,
        _ChartCard(
          key: const ValueKey('chart'),
          colors: colors,
          reduceMotion: reduceMotion,
          refreshTick: _refreshTick,
          points: _revenue,
          onOpen: () => _openMetric('revenue'),
        ),
      ),
      // activity — spans 2 columns; a compact list, amounts end-aligned.
      _GridChild(
        2,
        _ActivityCard(
          key: const ValueKey('activity'),
          colors: colors,
          items: _activity,
          onOpen: () => _openMetric('activity'),
        ),
      ),
    ];
  }

  // --- behavior --------------------------------------------------------------

  _WindowClass _windowClassFor(double width) {
    if (width >= DashBreakpoint.expanded) return _WindowClass.expanded;
    if (width >= DashBreakpoint.compact) return _WindowClass.medium;
    return _WindowClass.compact;
  }

  Future<void> _handleRefresh() async {
    await HapticFeedback.selectionClick();
    setState(() => _announce = _Strings.refreshing);
    if (widget.onRefresh != null) {
      await widget.onRefresh!();
    } else {
      await Future<void>.delayed(DashMotion.demoLatency);
    }
    if (!mounted) return;
    // Bumping the tick lets each live tile update its value in place; stale /
    // error / empty tiles ignore it and stay put (STATE-014).
    setState(() {
      _refreshTick++;
      _announce = _Strings.updated;
    });
  }

  void _toggleOffline() => setState(() => _offline = !_offline);

  void _openMetric(String id) {
    if (widget.onOpenMetric != null) {
      widget.onOpenMetric!(id);
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text('Open $id')));
  }

  void _openSettings() {
    if (widget.onOpenSettings != null) {
      widget.onOpenSettings!();
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Open Settings')));
  }
}

// --- formatting --------------------------------------------------------------

String _formatValue(BuildContext context, num value, _Unit unit) {
  final locale = Localizations.localeOf(context).toString();
  switch (unit) {
    case _Unit.currency:
      return NumberFormat.simpleCurrency(locale: locale, decimalDigits: 0)
          .format(value / 100);
    case _Unit.count:
    case _Unit.steps:
      return NumberFormat.decimalPattern(locale).format(value);
  }
}

String _formatMoneyCents(BuildContext context, int cents) {
  final locale = Localizations.localeOf(context).toString();
  final sign = cents < 0 ? '-' : '+';
  final abs = NumberFormat.simpleCurrency(locale: locale)
      .format(cents.abs() / 100);
  return '$sign$abs';
}

String _compactMoney(BuildContext context, double value) {
  final locale = Localizations.localeOf(context).toString();
  return NumberFormat.compactSimpleCurrency(locale: locale).format(value);
}

String _trendDelta(_Trend trend) {
  switch (trend.dir) {
    case TrendDir.up:
      return '+${trend.pct}%';
    case TrendDir.down:
      return '-${trend.pct}%';
    case TrendDir.flat:
      return 'no change';
  }
}

String _trendPhrase(_Trend trend, String period) {
  switch (trend.dir) {
    case TrendDir.up:
      return 'up ${trend.pct}% $period';
    case TrendDir.down:
      return 'down ${trend.pct}% $period';
    case TrendDir.flat:
      return 'no change $period';
  }
}

// --- live region -------------------------------------------------------------

/// An off-screen live region: whenever [message] changes, assistive tech speaks
/// it. Used to announce "Updated" after a pull-to-refresh (A11Y-019).
class _LiveAnnouncer extends StatelessWidget {
  const _LiveAnnouncer({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      label: message,
      child: const SizedBox.shrink(),
    );
  }
}

// --- greeting ----------------------------------------------------------------

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.colors});
  final DashColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _Strings.greeting,
                style: DashType.caption(context)
                    ?.copyWith(color: colors.onSurfaceMuted),
              ),
              Text(
                _Strings.overview,
                style: DashType.display(context)
                    ?.copyWith(color: colors.onSurface),
              ),
            ],
          ),
        ),
        const SizedBox(width: DashSpace.md),
        // Date-range filter lives top, within thumb reach (spec thumb-zone).
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.calendar_today_outlined,
              size: DashSize.iconSm),
          label: const Text(_Strings.dateRange),
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.onSurface,
            side: BorderSide(color: colors.outline),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(DashRadius.chip)),
            ),
          ),
        ),
      ],
    );
  }
}

// --- responsive grid ---------------------------------------------------------

/// Lays tiles into a column grid whose column count is derived from the live
/// available width via LayoutBuilder (GRD-004). Each tile may span multiple
/// columns (the chart + activity span 2), clamped to the live count so the grid
/// re-flows cleanly across compact / medium / expanded and on resize (GRD-008).
class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({required this.children});
  final List<_GridChild> children;

  int _columnsFor(double available) {
    if (available >= DashBreakpoint.wide) return 4;
    if (available >= DashBreakpoint.expanded) return 3;
    if (available >= DashBreakpoint.compact) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final columns = _columnsFor(maxW);
        final colWidth =
            (maxW - DashSpace.gutter * (columns - 1)) / columns;

        // Greedily pack tiles into rows honoring each tile's span.
        final rows = <List<_GridChild>>[];
        var current = <_GridChild>[];
        var used = 0;
        for (final tile in children) {
          final span = tile.span.clamp(1, columns).toInt();
          if (used + span > columns) {
            rows.add(current);
            current = <_GridChild>[];
            used = 0;
          }
          current.add(_GridChild(span, tile.child));
          used += span;
        }
        if (current.isNotEmpty) rows.add(current);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var r = 0; r < rows.length; r++) ...[
              if (r > 0) const SizedBox(height: DashSpace.gutter),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _rowCells(rows[r], colWidth),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  List<Widget> _rowCells(List<_GridChild> row, double colWidth) {
    final cells = <Widget>[];
    for (var i = 0; i < row.length; i++) {
      if (i > 0) cells.add(const SizedBox(width: DashSpace.gutter));
      final tile = row[i];
      final cellWidth =
          colWidth * tile.span + DashSpace.gutter * (tile.span - 1);
      cells.add(SizedBox(width: cellWidth, child: tile.child));
    }
    return cells;
  }
}

// --- card shell --------------------------------------------------------------

/// The visual card chrome shared by every tile: rounded, level-1 elevated,
/// hairline-bordered, padded, and tappable to its detail (CRD-001). Semantics is
/// applied by each tile so the whole card reads as one coherent node.
class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.colors,
    required this.onOpen,
    required this.child,
  });
  final DashColors colors;
  final VoidCallback? onOpen;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: DashElevation.level1,
      color: colors.surfaceContainer,
      surfaceTintColor: colors.surfaceContainer,
      shadowColor: colors.shadow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(DashRadius.card)),
        side: BorderSide(color: colors.divider),
      ),
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(DashSpace.cardPadding),
          child: child,
        ),
      ),
    );
  }
}

/// A metric card's header: glyph + label. The label uses a scalable label role.
class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.colors, required this.icon, required this.title});
  final DashColors colors;
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: DashSize.icon, color: colors.onSurfaceMuted),
        const SizedBox(width: DashSpace.sm),
        Expanded(
          child: Text(
            title,
            style: DashType.label(context)
                ?.copyWith(color: colors.onSurfaceMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// A plain section title used by the chart / activity cards.
class _CardHeaderText extends StatelessWidget {
  const _CardHeaderText({required this.colors, required this.title});
  final DashColors colors;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        title,
        style: DashType.section(context)?.copyWith(color: colors.onSurface),
      ),
    );
  }
}

// --- metric card -------------------------------------------------------------

/// A self-contained metric tile that owns its [WidgetState]. Retry and the
/// loading resolve are LOCAL, so a failing tile never affects its neighbors
/// (STATE-014). success / offline render as one grouped Semantics node with a
/// coherent name; the interactive states keep their Retry / CTA reachable.
class _MetricCard extends StatefulWidget {
  const _MetricCard({
    super.key,
    required this.colors,
    required this.reduceMotion,
    required this.refreshTick,
    required this.icon,
    required this.title,
    required this.unit,
    required this.initialState,
    this.baseValue = 0,
    this.trend,
    this.period = '',
    this.cachedNote,
    this.emptyMessage,
    this.emptyCta,
    this.permissionMessage,
    this.onOpen,
    this.onEmptyAction,
    this.onPermissionSettings,
  });

  final DashColors colors;
  final bool reduceMotion;
  final int refreshTick;
  final IconData icon;
  final String title;
  final _Unit unit;
  final WidgetState initialState;
  final num baseValue;
  final _Trend? trend;
  final String period;
  final String? cachedNote;
  final String? emptyMessage;
  final String? emptyCta;
  final String? permissionMessage;
  final VoidCallback? onOpen;
  final VoidCallback? onEmptyAction;
  final VoidCallback? onPermissionSettings;

  @override
  State<_MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<_MetricCard> {
  late WidgetState _state;
  late num _value;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
    _value = widget.baseValue;
    if (_state == WidgetState.loading) _resolveSoon();
  }

  @override
  void didUpdateWidget(covariant _MetricCard old) {
    super.didUpdateWidget(old);
    // A global refresh updates the value of live tiles IN PLACE (animated); it
    // never disturbs a tile that is empty / error / permission-denied.
    if (widget.refreshTick != old.refreshTick &&
        (_state == WidgetState.success ||
            _state == WidgetState.ideal ||
            _state == WidgetState.offline)) {
      setState(() => _value = _nextValue(_value));
    }
  }

  num _nextValue(num v) {
    // A small deterministic wiggle so the number visibly changes on refresh.
    final step = (v * 3 / 100).round();
    return v + step;
  }

  Future<void> _resolveSoon() async {
    await Future<void>.delayed(DashMotion.demoLatency);
    if (!mounted) return;
    setState(() => _state = WidgetState.success);
  }

  void _retry() {
    setState(() => _state = WidgetState.loading);
    _reload();
  }

  Future<void> _reload() async {
    await Future<void>.delayed(DashMotion.demoLatency);
    if (!mounted) return;
    setState(() {
      _value = widget.baseValue == 0 ? 7 : widget.baseValue;
      _state = WidgetState.success;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case WidgetState.loading:
        return _CardShell(
          colors: widget.colors,
          onOpen: null,
          child: _skeleton(context),
        );
      case WidgetState.empty:
        return _grouped(
          context,
          interactive: false,
          child: _emptyContent(context),
        );
      case WidgetState.error:
        return _grouped(
          context,
          interactive: false,
          child: _errorContent(context),
        );
      case WidgetState.permissionDenied:
        return _grouped(
          context,
          interactive: false,
          child: _permissionContent(context),
        );
      case WidgetState.offline:
        return _valueTile(context, stale: true);
      case WidgetState.success:
      case WidgetState.ideal:
        return _valueTile(context, stale: false);
    }
  }

  /// A non-merged Semantics container: children (Retry / CTA) keep their own
  /// nodes so they stay reachable; the card is not tappable in these states.
  Widget _grouped(
    BuildContext context, {
    required bool interactive,
    required Widget child,
  }) {
    return Semantics(
      container: true,
      child: _CardShell(
        colors: widget.colors,
        onOpen: interactive ? widget.onOpen : null,
        child: child,
      ),
    );
  }

  /// success / offline: one coherent, tappable Semantics node with a spoken
  /// name like "Balance, $2,430, up 4% this week" (A11Y-014).
  Widget _valueTile(BuildContext context, {required bool stale}) {
    final colors = widget.colors;
    final valueLabel = _formatValue(context, _value, widget.unit);
    final trend = widget.trend;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _CardHeader(colors: colors, icon: widget.icon, title: widget.title),
        const SizedBox(height: DashSpace.rowGap),
        _AnimatedValue(
          value: valueLabel,
          colors: colors,
          reduceMotion: widget.reduceMotion,
        ),
        const SizedBox(height: DashSpace.sm),
        if (stale && widget.cachedNote != null)
          _StaleRow(colors: colors, note: widget.cachedNote!)
        else if (trend != null)
          _TrendRow(colors: colors, trend: trend, period: widget.period),
      ],
    );

    return Semantics(
      container: true,
      button: widget.onOpen != null,
      label: _semanticName(valueLabel, stale),
      onTap: widget.onOpen,
      child: ExcludeSemantics(
        child: _CardShell(
          colors: colors,
          onOpen: widget.onOpen,
          child: content,
        ),
      ),
    );
  }

  String _semanticName(String valueLabel, bool stale) {
    if (stale) {
      final note = widget.cachedNote ?? 'cached';
      return '${widget.title}, $valueLabel, $note, offline';
    }
    final trend = widget.trend;
    final phrase = trend == null ? '' : ', ${_trendPhrase(trend, widget.period)}';
    return '${widget.title}, $valueLabel$phrase';
  }

  Widget _skeleton(BuildContext context) {
    final colors = widget.colors;
    return Semantics(
      liveRegion: true,
      container: true,
      label: 'Loading ${widget.title}',
      child: _Shimmer(
        reduceMotion: widget.reduceMotion,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _SkelBox(
              width: DashSize.skelTitleW,
              height: DashSize.skelLine,
              color: colors.skeleton,
            ),
            const SizedBox(height: DashSpace.rowGap),
            _SkelBox(
              width: DashSize.skelValueW,
              height: DashSize.skelValue,
              color: colors.skeleton,
            ),
            const SizedBox(height: DashSpace.sm),
            _SkelBox(
              width: DashSize.skelTrendW,
              height: DashSize.skelLine,
              color: colors.skeleton,
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyContent(BuildContext context) {
    final colors = widget.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(widget.icon, size: DashSize.iconLg, color: colors.onSurfaceMuted),
        const SizedBox(height: DashSpace.rowGap),
        Text(
          widget.title,
          style: DashType.labelStrong(context)?.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: DashSpace.xs),
        Text(
          widget.emptyMessage ?? 'No data yet.',
          style: DashType.body(context)?.copyWith(color: colors.onSurfaceMuted),
        ),
        const SizedBox(height: DashSpace.rowGap),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton.tonal(
            onPressed: widget.onEmptyAction,
            child: Text(widget.emptyCta ?? 'Add'),
          ),
        ),
      ],
    );
  }

  Widget _errorContent(BuildContext context) {
    final colors = widget.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, size: DashSize.iconSm, color: colors.error),
            const SizedBox(width: DashSpace.sm),
            Expanded(
              child: Text(
                "Couldn't load ${widget.title}",
                style: DashType.body(context)?.copyWith(color: colors.onSurface),
              ),
            ),
          ],
        ),
        const SizedBox(height: DashSpace.rowGap),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            onPressed: _retry,
            icon: const Icon(Icons.refresh, size: DashSize.iconSm),
            label: const Text(_Strings.retry),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.primary,
              side: BorderSide(color: colors.outline),
            ),
          ),
        ),
      ],
    );
  }

  Widget _permissionContent(BuildContext context) {
    final colors = widget.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.lock_outline, size: DashSize.iconSm, color: colors.warning),
            const SizedBox(width: DashSpace.sm),
            Expanded(
              child: Text(
                widget.title,
                style: DashType.labelStrong(context)
                    ?.copyWith(color: colors.onSurface),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: DashSpace.sm),
        Text(
          widget.permissionMessage ?? 'Turn on access to see this metric.',
          style: DashType.body(context)?.copyWith(color: colors.onSurfaceMuted),
        ),
        const SizedBox(height: DashSpace.rowGap),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed: widget.onPermissionSettings,
            child: const Text('Open Settings'),
          ),
        ),
      ],
    );
  }
}

/// A metric value that cross-fades when it changes on refresh (<=300ms, MOT-005);
/// under reduce motion it swaps instantly. Tabular figures keep it from shifting.
class _AnimatedValue extends StatelessWidget {
  const _AnimatedValue({
    required this.value,
    required this.colors,
    required this.reduceMotion,
  });
  final String value;
  final DashColors colors;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : DashMotion.number,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: Text(
        value,
        key: ValueKey<String>(value),
        style: DashType.value(context)?.copyWith(color: colors.onSurfaceStrong),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Trend line: vertical arrow (mirror-safe) + signed value + text. Color is a
/// redundant cue only — the arrow and sign carry the meaning (A11Y-012).
class _TrendRow extends StatelessWidget {
  const _TrendRow({required this.colors, required this.trend, required this.period});
  final DashColors colors;
  final _Trend trend;
  final String period;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = switch (trend.dir) {
      TrendDir.up => (Icons.arrow_upward, colors.success),
      TrendDir.down => (Icons.arrow_downward, colors.error),
      TrendDir.flat => (Icons.remove, colors.onSurfaceMuted),
    };
    return Row(
      children: [
        Icon(icon, size: DashSize.iconSm, color: color),
        const SizedBox(width: DashSpace.xs),
        Text(
          _trendDelta(trend),
          style: DashType.trend(context)?.copyWith(color: color),
        ),
        const SizedBox(width: DashSpace.xs),
        Flexible(
          child: Text(
            period,
            style: DashType.caption(context)
                ?.copyWith(color: colors.onSurfaceMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// The offline "last updated / stale" indicator inside a tile (STATE-011).
class _StaleRow extends StatelessWidget {
  const _StaleRow({required this.colors, required this.note});
  final DashColors colors;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.history_outlined, size: DashSize.iconSm, color: colors.warning),
        const SizedBox(width: DashSpace.xs),
        Flexible(
          child: Text(
            note,
            style: DashType.caption(context)?.copyWith(color: colors.warning),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// --- skeleton primitives -----------------------------------------------------

/// A single non-text placeholder block. Fixed sizes are safe here — it renders
/// no text, so Dynamic Type never clips (A11Y-010).
class _SkelBox extends StatelessWidget {
  const _SkelBox({
    required this.width,
    required this.height,
    required this.color,
  });
  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.circular(DashRadius.chip)),
      ),
    );
  }
}

/// A gentle opacity pulse for skeletons; under reduce motion it holds a static
/// frame instead of animating (MOT-004, A11Y-011).
class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child, required this.reduceMotion});
  final Widget child;
  final bool reduceMotion;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: DashMotion.shimmer);
    if (!widget.reduceMotion) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _Shimmer old) {
    super.didUpdateWidget(old);
    if (widget.reduceMotion && _controller.isAnimating) {
      _controller.stop();
    } else if (!widget.reduceMotion && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reduceMotion) return widget.child;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}

// --- chart card --------------------------------------------------------------

/// A small bar chart drawn with CustomPaint. It is NEVER color-only: every bar
/// is labeled (day below, value above), the peak carries an outline cap, and a
/// screen-reader DATA-TABLE fallback is provided both as a spoken summary and as
/// an on-demand real [Table] (CHT-001, CHT-002).
class _ChartCard extends StatefulWidget {
  const _ChartCard({
    super.key,
    required this.colors,
    required this.reduceMotion,
    required this.refreshTick,
    required this.points,
    required this.onOpen,
  });
  final DashColors colors;
  final bool reduceMotion;
  final int refreshTick;
  final List<_ChartPoint> points;
  final VoidCallback? onOpen;

  @override
  State<_ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<_ChartCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _draw;
  bool _showTable = false;

  @override
  void initState() {
    super.initState();
    _draw = AnimationController(vsync: this, duration: DashMotion.chart);
    _play();
  }

  void _play() {
    if (widget.reduceMotion) {
      _draw.value = 1;
    } else {
      _draw.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(covariant _ChartCard old) {
    super.didUpdateWidget(old);
    if (widget.reduceMotion) {
      _draw.value = 1;
    } else if (widget.refreshTick != old.refreshTick) {
      _play();
    }
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final points = widget.points;
    final maxV =
        points.map((p) => p.value).fold<double>(0, (a, b) => math.max(a, b));
    final peak = points.reduce((a, b) => b.value > a.value ? b : a);

    return Semantics(
      container: true,
      label: _chartSemantics(context, points, peak),
      child: _CardShell(
        colors: colors,
        onOpen: widget.onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child:
                      _CardHeaderText(colors: colors, title: _Strings.revenueTitle),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _showTable = !_showTable),
                  icon: Icon(
                    _showTable ? Icons.bar_chart : Icons.table_chart_outlined,
                    size: DashSize.iconSm,
                  ),
                  label: Text(_showTable ? _Strings.hideTable : _Strings.viewTable),
                  style: TextButton.styleFrom(foregroundColor: colors.primary),
                ),
              ],
            ),
            const SizedBox(height: DashSpace.rowGap),
            // The painting itself is not read by SR — the label + table are.
            ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ChartRow(
                    colors: colors,
                    points: points,
                    builder: (p) => _compactMoney(context, p.value),
                    muted: false,
                  ),
                  const SizedBox(height: DashSpace.sm),
                  SizedBox(
                    height: DashSize.chartHeight,
                    child: AnimatedBuilder(
                      animation: _draw,
                      builder: (context, _) => CustomPaint(
                        painter: _BarChartPainter(
                          values: [for (final p in points) p.value],
                          maxValue: maxV,
                          peakValue: peak.value,
                          progress: _draw.value,
                          series: colors.chartSeries,
                          axis: colors.divider,
                          peakStroke: colors.onSurface,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                  const SizedBox(height: DashSpace.sm),
                  _ChartRow(
                    colors: colors,
                    points: points,
                    builder: (p) => p.label,
                    muted: true,
                  ),
                ],
              ),
            ),
            if (_showTable) ...[
              const SizedBox(height: DashSpace.rowGap),
              _ChartDataTable(colors: colors, points: points),
            ],
          ],
        ),
      ),
    );
  }

  String _chartSemantics(
    BuildContext context,
    List<_ChartPoint> points,
    _ChartPoint peak,
  ) {
    final parts = points
        .map((p) => '${p.label} ${_compactMoney(context, p.value)}')
        .join(', ');
    return '${_Strings.revenueTitle}, last ${points.length} days. '
        '$parts. Peak ${peak.label}.';
  }
}

/// A row of per-bar labels (values above, days below) aligned to the bars by
/// giving each an equal Expanded slot — the painter centers bars in equal slots.
class _ChartRow extends StatelessWidget {
  const _ChartRow({
    required this.colors,
    required this.points,
    required this.builder,
    required this.muted,
  });
  final DashColors colors;
  final List<_ChartPoint> points;
  final String Function(_ChartPoint) builder;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final p in points)
          Expanded(
            child: Text(
              builder(p),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (muted ? DashType.caption(context) : DashType.number(context))
                  ?.copyWith(
                color: muted ? colors.onSurfaceMuted : colors.onSurface,
              ),
            ),
          ),
      ],
    );
  }
}

/// The screen-reader / low-vision data-table fallback for the chart (CHT-002).
/// A real [Table], so it is navigable cell-by-cell; amounts are end-aligned.
class _ChartDataTable extends StatelessWidget {
  const _ChartDataTable({required this.colors, required this.points});
  final DashColors colors;
  final List<_ChartPoint> points;

  @override
  Widget build(BuildContext context) {
    TableRow row(String day, String amount, {required bool header}) {
      final style = (header ? DashType.labelStrong(context) : DashType.body(context))
          ?.copyWith(
        color: header ? colors.onSurface : colors.onSurfaceMuted,
      );
      final amountStyle = (header ? DashType.labelStrong(context) : DashType.number(context))
          ?.copyWith(
        color: header ? colors.onSurface : colors.onSurface,
      );
      return TableRow(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              vertical: DashSpace.xs,
            ),
            child: Text(day, style: style),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              vertical: DashSpace.xs,
            ),
            child: Text(amount, textAlign: TextAlign.end, style: amountStyle),
          ),
        ],
      );
    }

    return Table(
      columnWidths: const {0: FlexColumnWidth(), 1: IntrinsicColumnWidth()},
      border: TableBorder(
        horizontalInside: BorderSide(color: colors.divider),
      ),
      children: [
        row(_Strings.colDay, _Strings.colRevenue, header: true),
        for (final p in points)
          row(p.label, _compactMoney(context, p.value), header: false),
      ],
    );
  }
}

/// Paints labeled bars. Value is encoded by HEIGHT (not color); the peak also
/// gets an outline cap so it reads in grayscale. Draw-in scales by [progress];
/// under reduce motion the caller passes progress == 1 (final frame instantly).
class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.values,
    required this.maxValue,
    required this.peakValue,
    required this.progress,
    required this.series,
    required this.axis,
    required this.peakStroke,
  });

  final List<double> values;
  final double maxValue;
  final double peakValue;
  final double progress;
  final List<Color> series;
  final Color axis;
  final Color peakStroke;

  @override
  void paint(Canvas canvas, Size size) {
    final count = values.length;
    if (count == 0) return;
    final slotW = size.width / count;
    final barW = slotW * 0.56;
    final inset = (slotW - barW) / 2;
    final baseline = size.height;

    final axisPaint = Paint()
      ..color = axis
      ..strokeWidth = DashSize.stroke;
    canvas.drawLine(
      Offset(0, baseline),
      Offset(size.width, baseline),
      axisPaint,
    );

    for (var i = 0; i < count; i++) {
      final v = values[i];
      final ratio = maxValue <= 0 ? 0.0 : v / maxValue;
      final barH = ratio * size.height * progress;
      final startX = i * slotW + inset;
      final topY = baseline - barH;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(startX, topY, barW, barH),
        topLeft: const Radius.circular(DashRadius.bar),
        topRight: const Radius.circular(DashRadius.bar),
      );
      final fill = Paint()
        ..color = series[i % series.length]
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rect, fill);

      // Non-color peak cue: an outline cap on the tallest bar.
      if (v >= peakValue) {
        final cap = Paint()
          ..color = peakStroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = DashSize.stroke;
        canvas.drawRRect(rect, cap);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) =>
      old.progress != progress ||
      old.values != values ||
      old.maxValue != maxValue ||
      old.series != series;
}

// --- activity card -----------------------------------------------------------

/// A compact activity feed. Each row is its own grouped Semantics node; amounts
/// are end-aligned and tabular so they mirror and column-align in any locale.
class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    super.key,
    required this.colors,
    required this.items,
    required this.onOpen,
  });
  final DashColors colors;
  final List<_Activity> items;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: _Strings.activityTitle,
      child: _CardShell(
        colors: colors,
        onOpen: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _CardHeaderText(colors: colors, title: _Strings.activityTitle),
            const SizedBox(height: DashSpace.sm),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  vertical: DashSpace.rowGap,
                ),
                child: Text(
                  'Nothing here yet.',
                  style: DashType.body(context)
                      ?.copyWith(color: colors.onSurfaceMuted),
                ),
              )
            else
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) Divider(color: colors.divider, height: DashSpace.lg),
                _ActivityRow(colors: colors, item: items[i]),
              ],
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.colors, required this.item});
  final DashColors colors;
  final _Activity item;

  @override
  Widget build(BuildContext context) {
    final amount = _formatMoneyCents(context, item.amountCents);
    return Semantics(
      container: true,
      label: '${item.title}, ${item.subtitle}, $amount',
      child: ExcludeSemantics(
        child: Row(
          children: [
            Icon(item.icon, size: DashSize.iconSm, color: colors.onSurfaceMuted),
            const SizedBox(width: DashSpace.rowGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: DashType.body(context)
                        ?.copyWith(color: colors.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item.subtitle,
                    style: DashType.caption(context)
                        ?.copyWith(color: colors.onSurfaceMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: DashSpace.sm),
            Text(
              amount,
              textAlign: TextAlign.end,
              style: DashType.number(context)?.copyWith(color: colors.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

// --- offline banner ----------------------------------------------------------

/// The GLOBAL, non-blocking offline banner (STATE-008). It sits above the grid,
/// never covers content, and is announced once as a live region. Tiles continue
/// to show their cached values independently.
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({
    required this.visible,
    required this.colors,
    required this.reduceMotion,
    required this.onDismiss,
  });
  final bool visible;
  final DashColors colors;
  final bool reduceMotion;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: reduceMotion ? Duration.zero : DashMotion.standard,
      alignment: AlignmentDirectional.topStart,
      child: !visible
          ? const SizedBox.shrink()
          : Semantics(
              liveRegion: true,
              container: true,
              child: Material(
                color: colors.surfaceContainerHigh,
                elevation: DashElevation.level2,
                shadowColor: colors.shadow,
                borderRadius:
                    const BorderRadius.all(Radius.circular(DashRadius.control)),
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(DashSpace.rowGap),
                  child: Row(
                    children: [
                      Icon(Icons.cloud_off_outlined,
                          size: DashSize.iconSm, color: colors.onSurfaceMuted),
                      const SizedBox(width: DashSpace.sm),
                      Expanded(
                        child: Text(
                          _Strings.offlineBanner,
                          style: DashType.body(context)
                              ?.copyWith(color: colors.onSurface),
                        ),
                      ),
                      const SizedBox(width: DashSpace.sm),
                      TextButton(
                        onPressed: onDismiss,
                        child: const Text(_Strings.dismiss),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
