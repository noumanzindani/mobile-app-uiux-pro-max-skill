// settings_screen.dart
//
// A platform-correct, grouped, searchable Settings surface built to the spec in
// examples/settings/spec.md. Grouped sections with headers, a search field that
// filters across all settings (with a distinct zero-results empty state), four
// row types (toggle / disclosure / value+chevron / action), an ISOLATED
// destructive zone at the very bottom (Sign out · Delete account), and a
// light/dark/system theme switch.
//
// RESPONSIVE:
//   compact  < 600dp  -> a single scrolling list; a disclosure pushes a sub-page.
//   expanded >= 840dp -> two-pane: a group list (leading) + the selected group's
//                        settings (detail), updated in place.
//
// STATES: an explicit `enum SettingsState { ideal, loading, empty, error,
// offline, success, permissionDenied }` drives the parts of Settings that are
// data-backed rather than purely local:
//   - loading          -> a server-synced value shows a brief skeleton.
//   - empty            -> search with no match shows a distinct zero-results view.
//   - error            -> a toggle that fails to save REVERTS with a message —
//                         never a silent false success.
//   - offline          -> a non-blocking banner; server-synced toggles disable /
//                         queue with a spoken reason; local prefs still work.
//   - success          -> a change is confirmed inline ("Saved").
//   - permissionDenied -> an OS-permission-linked row reflects the true system
//                         state and deep-links to system Settings.
//   - ideal            -> groups + toggles reflect current values; search works.
//
// ACCESSIBILITY: each row exposes role + label + value/state via Semantics
// ("Notifications, on" / "off"); section headers are headings; toggle state is
// carried by the switch shape/position (not color-only); the destructive confirm
// dialogs are fully labeled. Targets are >= 48dp with a 16dp leading keyline; the
// whole row is tappable where it navigates. Layout is RTL-safe throughout
// (EdgeInsetsDirectional / AlignmentDirectional / TextAlign.start-end); chevrons
// mirror. All motion is transform/opacity only and collapses to Duration.zero
// under MediaQuery.disableAnimationsOf (reduce motion, MOT-004).
//
// Every color / spacing / radius / size / duration / text style comes from
// settings_tokens.dart — this file holds no raw design values (token_lint).
//
// Drop-in: `SettingsScreen(onSignOut: …, onDeleteAccount: …, onThemeChanged: …)`.
// It runs a self-contained demo with no arguments. See README.

import 'package:flutter/material.dart';

import 'settings_tokens.dart';

/// The seven UI states of the Settings surface (spec "States map"). Settings is
/// mostly interactive, but the data-backed parts still handle every state, so the
/// switchboard is exhaustive and no state is ever silently skipped.
enum SettingsState {
  /// Groups + toggles reflect current values; search works (the happy path).
  ideal,

  /// A server-synced value is being fetched — a skeleton matching its shape shows.
  loading,

  /// Search returned no match — a distinct zero-results view ("No settings match").
  empty,

  /// A save failed — the control REVERTS and a message is shown (never a silent
  /// false success).
  error,

  /// No connectivity — a non-blocking banner; server-synced toggles disable/queue.
  offline,

  /// A change was confirmed and persisted ("Saved").
  success,

  /// An OS-permission-linked setting is denied — reflect the true system state and
  /// deep-link to system Settings.
  permissionDenied,
}

/// The theme preference — the light/dark/system switch (spec Appearance, DRK-001).
enum ThemeChoice { system, light, dark }

/// The four row types (spec "Structure & grouping").
enum _RowKind {
  /// A `Switch.adaptive`; announces "on"/"off".
  toggle,

  /// Navigates to a sub-page; a chevron that mirrors in RTL.
  disclosure,

  /// Shows the current value + a chevron; opens a picker.
  value,

  /// A button-styled action row.
  action,
}

/// Copy. Kept as constants so layout code stays about layout; route through your
/// i18n layer in a real app (whole messages, no concatenation — L10N-002).
class _Strings {
  const _Strings._();

  static const String title = 'Settings';
  static const String searchHint = 'Search settings';
  static const String searchLabel = 'Search settings';
  static const String clearSearch = 'Clear search';
  static const String noResultsTitle = 'No settings match';
  static const String noResultsBody =
      'Try a different word, or browse the groups below.';
  static const String resultsHeader = 'Results';

  static const String offlineBanner =
      "You're offline. Local changes save now; synced ones will queue.";
  static const String offlineReason = 'Unavailable offline — will sync later';
  static const String queued = 'Queued — will sync when you\'re back online';
  static const String saveFailed = "Couldn't save — try again";
  static const String retry = 'Retry';
  static const String saved = 'Saved';
  static const String openSettings = 'Open Settings';
  static const String on = 'on';
  static const String off = 'off';
  static const String couldntLoad = "Couldn't load";
  static const String calculating = 'Calculating…';

  // Group titles
  static const String account = 'Account';
  static const String notifications = 'Notifications';
  static const String privacy = 'Privacy & Security';
  static const String appearance = 'Appearance';
  static const String about = 'About & Help';

  // Theme picker
  static const String theme = 'Theme';
  static const String themeSystem = 'System';
  static const String themeLight = 'Light';
  static const String themeDark = 'Dark';

  // Notifications permission
  static const String pushNotifications = 'Push notifications';
  static const String pushDeniedReason = 'Turned off in system settings';

  // Destructive zone
  static const String signOut = 'Sign out';
  static const String signOutConfirmTitle = 'Sign out?';
  static const String signOutConfirmBody =
      "You'll need to sign in again to use your account.";
  static const String deleteAccount = 'Delete account';
  static const String deleteStep1Title = 'Delete your account?';
  static const String deleteStep1Body =
      'This permanently removes your profile, settings, and history. This can '
      'take a few minutes to complete.';
  static const String deleteStep2Title = 'This cannot be undone';
  static const String deleteStep2Body =
      'To confirm, type DELETE. Your data will be erased and cannot be recovered.';
  static const String deleteConfirmWord = 'DELETE';
  static const String deleteFieldLabel = 'Type DELETE to confirm';
  static const String cancel = 'Cancel';
  static const String continueLabel = 'Continue';
  static const String deletePermanently = 'Delete permanently';
  static const String dangerZone = 'Danger zone';
  static const String demoOffline = 'Go offline (demo)';
  static const String demoOnline = 'Go online (demo)';
}

/// A single settings row, described as data so search can filter it and both
/// layouts can render it consistently. Mutable values (toggle on/off, current
/// selection) live in the parent state, keyed by [id].
@immutable
class _RowSpec {
  const _RowSpec({
    required this.id,
    required this.kind,
    required this.icon,
    required this.label,
    this.subtitle,
    this.keywords = const <String>[],
    this.serverSynced = false,
    this.permissionLinked = false,
    this.failsToSave = false,
    this.actionLabel,
    this.info = false,
  });

  final String id;
  final _RowKind kind;
  final IconData icon;
  final String label;
  final String? subtitle;
  final List<String> keywords;

  /// This preference lives on the server: offline it disables / queues; it can
  /// show a loading skeleton or an error on save.
  final bool serverSynced;

  /// This preference mirrors an OS permission: it reflects the true system state
  /// and deep-links to system Settings when denied.
  final bool permissionLinked;

  /// Demo: toggling this row simulates a failed save that reverts with a message.
  final bool failsToSave;

  /// For [_RowKind.action] — the button label.
  final String? actionLabel;

  /// For [_RowKind.value] — display-only (no picker, e.g. Version).
  final bool info;

  bool matches(String query, String groupTitle) {
    final hay = <String>[
      label,
      subtitle ?? '',
      groupTitle,
      ...keywords,
    ].join(' ').toLowerCase();
    return hay.contains(query.toLowerCase());
  }
}

/// A named group of rows, rendered under a heading and as a grouped inset card.
@immutable
class _GroupSpec {
  const _GroupSpec({
    required this.id,
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String id;
  final String title;
  final IconData icon;
  final List<_RowSpec> rows;
}

/// A grouped, searchable, responsive Settings surface.
///
/// With no arguments it runs a demo that exercises search zero-results, a
/// server-synced skeleton, a failed-save revert, offline queueing, and an
/// OS-permission-denied row. Wire the callbacks to make it real.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.onSignOut,
    this.onDeleteAccount,
    this.onThemeChanged,
    this.onOpenSystemSettings,
    this.onOpenSubPage,
    this.initialThemeChoice = ThemeChoice.system,
    this.initialOffline = false,
    this.notificationsGranted = false,
  });

  /// Sign the user out — reached only after an explicit confirm dialog (DLG-001).
  final VoidCallback? onSignOut;

  /// Delete the account — reached only after a multi-step confirm (store policy,
  /// SET-004 / PROF-001).
  final VoidCallback? onDeleteAccount;

  /// Persist and apply the light/dark/system theme choice (DRK-001).
  final ValueChanged<ThemeChoice>? onThemeChanged;

  /// Deep-link to the OS system-settings page for a permission-linked row
  /// (PERM-003). The demo default flips the in-app mirror to "granted".
  final VoidCallback? onOpenSystemSettings;

  /// Push a disclosure row's sub-page. The demo default pushes a placeholder page.
  final void Function(String title)? onOpenSubPage;

  /// The current theme preference (drive your `MaterialApp.themeMode` from this).
  final ThemeChoice initialThemeChoice;

  /// Start in the offline treatment (e.g. from `connectivity_plus`).
  final bool initialOffline;

  /// The true OS notifications-permission state, mirrored by the Notifications
  /// row. Drive from `permission_handler`; the demo starts denied to show it.
  final bool notificationsGranted;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  // Local (instant) toggle values, keyed by row id.
  final Map<String, bool> _toggles = <String, bool>{
    'email_digests': true,
    'product_updates': false,
    'two_factor': true,
    'personalized_ads': false,
    'reduce_motion': false,
    'push': false,
  };

  // Current picker selections, keyed by row id.
  final Map<String, String> _values = <String, String>{
    'sound': 'Chime',
    'text_size': 'Default',
    'language': 'English',
  };

  ThemeChoice _themeChoice = ThemeChoice.system;
  late bool _offline;
  late bool _notifGranted;

  // A server-synced value (the account plan) that must fetch: loading -> success.
  SettingsState _planState = SettingsState.loading;
  String _plan = '';

  // The most recent outcome, mirrored to an off-screen live region for a11y.
  String _announce = '';

  // Expanded (two-pane) selected group index.
  int _selectedGroup = 0;

  bool get _searching => _search.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _themeChoice = widget.initialThemeChoice;
    _offline = widget.initialOffline;
    _notifGranted = widget.notificationsGranted;
    _toggles['push'] = _notifGranted;
    _search.addListener(_onSearchChanged);
    _loadPlan();
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // --- data ------------------------------------------------------------------

  List<_GroupSpec> get _groups => <_GroupSpec>[
        _GroupSpec(
          id: 'account',
          title: _Strings.account,
          icon: Icons.person_outline,
          rows: const <_RowSpec>[
            _RowSpec(
              id: 'name',
              kind: _RowKind.value,
              icon: Icons.badge_outlined,
              label: 'Name',
              keywords: <String>['profile', 'display name'],
            ),
            _RowSpec(
              id: 'email',
              kind: _RowKind.disclosure,
              icon: Icons.alternate_email,
              label: 'Email',
              subtitle: 'alex@example.com',
              keywords: <String>['address', 'login'],
            ),
            _RowSpec(
              id: 'connected',
              kind: _RowKind.disclosure,
              icon: Icons.link_outlined,
              label: 'Connected accounts',
              keywords: <String>['google', 'apple', 'sso'],
            ),
            _RowSpec(
              id: 'plan',
              kind: _RowKind.value,
              icon: Icons.workspace_premium_outlined,
              label: 'Plan',
              serverSynced: true,
              keywords: <String>['subscription', 'billing', 'pro'],
            ),
          ],
        ),
        _GroupSpec(
          id: 'notifications',
          title: _Strings.notifications,
          icon: Icons.notifications_outlined,
          rows: const <_RowSpec>[
            _RowSpec(
              id: 'push',
              kind: _RowKind.toggle,
              icon: Icons.notifications_active_outlined,
              label: _Strings.pushNotifications,
              permissionLinked: true,
              keywords: <String>['alerts', 'system'],
            ),
            _RowSpec(
              id: 'email_digests',
              kind: _RowKind.toggle,
              icon: Icons.mark_email_read_outlined,
              label: 'Email digests',
              subtitle: 'A weekly summary in your inbox',
              keywords: <String>['newsletter', 'summary'],
            ),
            _RowSpec(
              id: 'product_updates',
              kind: _RowKind.toggle,
              icon: Icons.campaign_outlined,
              label: 'Product updates',
              serverSynced: true,
              failsToSave: true,
              keywords: <String>['announcements', 'news'],
            ),
            _RowSpec(
              id: 'sound',
              kind: _RowKind.value,
              icon: Icons.volume_up_outlined,
              label: 'Notification sound',
              keywords: <String>['tone', 'chime', 'ringtone'],
            ),
          ],
        ),
        _GroupSpec(
          id: 'privacy',
          title: _Strings.privacy,
          icon: Icons.lock_outline,
          rows: const <_RowSpec>[
            _RowSpec(
              id: 'two_factor',
              kind: _RowKind.toggle,
              icon: Icons.verified_user_outlined,
              label: 'Two-factor authentication',
              keywords: <String>['2fa', 'security', 'login'],
            ),
            _RowSpec(
              id: 'blocked',
              kind: _RowKind.disclosure,
              icon: Icons.block_outlined,
              label: 'Blocked users',
              keywords: <String>['mute', 'privacy'],
            ),
            _RowSpec(
              id: 'personalized_ads',
              kind: _RowKind.toggle,
              icon: Icons.ads_click_outlined,
              label: 'Personalized ads',
              serverSynced: true,
              keywords: <String>['advertising', 'tracking'],
            ),
            _RowSpec(
              id: 'download_data',
              kind: _RowKind.action,
              icon: Icons.download_outlined,
              label: 'Download my data',
              actionLabel: 'Request',
              keywords: <String>['export', 'gdpr'],
            ),
          ],
        ),
        _GroupSpec(
          id: 'appearance',
          title: _Strings.appearance,
          icon: Icons.palette_outlined,
          rows: const <_RowSpec>[
            _RowSpec(
              id: 'theme',
              kind: _RowKind.value,
              icon: Icons.brightness_6_outlined,
              label: _Strings.theme,
              keywords: <String>['dark mode', 'light', 'appearance'],
            ),
            _RowSpec(
              id: 'text_size',
              kind: _RowKind.value,
              icon: Icons.format_size_outlined,
              label: 'Text size',
              keywords: <String>['font', 'dynamic type', 'accessibility'],
            ),
            _RowSpec(
              id: 'reduce_motion',
              kind: _RowKind.toggle,
              icon: Icons.motion_photos_off_outlined,
              label: 'Reduce motion',
              keywords: <String>['animation', 'accessibility'],
            ),
          ],
        ),
        _GroupSpec(
          id: 'about',
          title: _Strings.about,
          icon: Icons.info_outline,
          rows: const <_RowSpec>[
            _RowSpec(
              id: 'help',
              kind: _RowKind.disclosure,
              icon: Icons.help_outline,
              label: 'Help center',
              keywords: <String>['support', 'faq'],
            ),
            _RowSpec(
              id: 'contact',
              kind: _RowKind.action,
              icon: Icons.mail_outline,
              label: 'Contact support',
              actionLabel: 'Email',
              keywords: <String>['help', 'feedback'],
            ),
            _RowSpec(
              id: 'version',
              kind: _RowKind.value,
              icon: Icons.tag_outlined,
              label: 'Version',
              subtitle: '4.2.0 (build 512)',
              info: true,
              keywords: <String>['about', 'build'],
            ),
          ],
        ),
      ];

  /// The value shown on a value+chevron row (resolved live).
  String _valueFor(String id) {
    switch (id) {
      case 'name':
        return _values['name'] ?? 'Alex Johnson';
      case 'theme':
        return _themeLabel(_themeChoice);
      case 'plan':
        return _plan;
      default:
        return _values[id] ?? '';
    }
  }

  String _themeLabel(ThemeChoice choice) {
    switch (choice) {
      case ThemeChoice.system:
        return _Strings.themeSystem;
      case ThemeChoice.light:
        return _Strings.themeLight;
      case ThemeChoice.dark:
        return _Strings.themeDark;
    }
  }

  // --- behavior --------------------------------------------------------------

  void _onSearchChanged() => setState(() {});

  Future<void> _loadPlan() async {
    setState(() => _planState = SettingsState.loading);
    await Future<void>.delayed(SettingsMotion.demoLatency);
    if (!mounted) return;
    setState(() {
      _plan = 'Pro';
      _planState = _offline ? SettingsState.offline : SettingsState.success;
    });
  }

  void _toggleOfflineDemo() => setState(() => _offline = !_offline);

  void _announceSaved(String what) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('$what · ${_Strings.saved}'),
        behavior: SnackBarBehavior.floating,
      ));
    setState(() => _announce = _Strings.saved);
  }

  /// Toggle handler. Local rows flip instantly (success). Server-synced rows
  /// that are offline never flip silently — the caller keeps them disabled. The
  /// demo's `failsToSave` row flips optimistically, then REVERTS with a message
  /// (error, never a silent false success — STATE-007).
  void _onToggle(_RowSpec spec, bool next) {
    if (spec.failsToSave) {
      _optimisticThenRevert(spec, next);
      return;
    }
    setState(() => _toggles[spec.id] = next);
    final state = next ? _Strings.on : _Strings.off;
    _announceSaved('${spec.label} $state');
  }

  Future<void> _optimisticThenRevert(_RowSpec spec, bool next) async {
    setState(() => _toggles[spec.id] = next); // optimistic
    await Future<void>.delayed(SettingsMotion.demoLatency);
    if (!mounted) return;
    setState(() {
      _toggles[spec.id] = !next; // revert to the true saved value
      _announce = _Strings.saveFailed;
    });
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: const Text(_Strings.saveFailed),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: _Strings.retry,
          onPressed: () => _optimisticThenRevert(spec, next),
        ),
      ));
  }

  void _openSubPage(String title) {
    if (widget.onOpenSubPage != null) {
      widget.onOpenSubPage!(title);
      return;
    }
    // Compact push transition (platform-native); the detail owns its own back.
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => _SubPage(title: title)),
    );
  }

  Future<void> _openValuePicker(_RowSpec spec) async {
    if (spec.id == 'theme') {
      await _openThemePicker();
      return;
    }
    final options = _optionsFor(spec.id);
    final current = _valueFor(spec.id);
    final chosen = await _showSheet<String>(
      title: spec.label,
      builder: (sheetContext) => _PickerSheet<String>(
        title: spec.label,
        options: options,
        selected: current,
        labelOf: (o) => o,
        colors: SettingsColors.of(sheetContext),
      ),
    );
    if (chosen == null || !mounted) return;
    setState(() => _values[spec.id] = chosen);
    _announceSaved('${spec.label}: $chosen');
  }

  Future<void> _openThemePicker() async {
    final chosen = await _showSheet<ThemeChoice>(
      title: _Strings.theme,
      builder: (sheetContext) => _PickerSheet<ThemeChoice>(
        title: _Strings.theme,
        options: ThemeChoice.values,
        selected: _themeChoice,
        labelOf: _themeLabel,
        colors: SettingsColors.of(sheetContext),
      ),
    );
    if (chosen == null || !mounted) return;
    setState(() => _themeChoice = chosen);
    widget.onThemeChanged?.call(chosen);
    _announceSaved('${_Strings.theme}: ${_themeLabel(chosen)}');
  }

  List<String> _optionsFor(String id) {
    switch (id) {
      case 'sound':
        return const <String>['Chime', 'Ping', 'Bell', 'None'];
      case 'text_size':
        return const <String>['Small', 'Default', 'Large', 'Larger'];
      default:
        return const <String>['English', 'Español', 'Français', 'العربية'];
    }
  }

  void _onAction(_RowSpec spec) {
    _announceSaved(spec.label);
  }

  /// A permission-linked row deep-links to system Settings. The demo default
  /// simulates returning with permission granted, so the mirror flips true.
  void _openSystemSettings() {
    if (widget.onOpenSystemSettings != null) {
      widget.onOpenSystemSettings!();
      return;
    }
    setState(() {
      _notifGranted = true;
      _toggles['push'] = true;
    });
    _announceSaved(_Strings.pushNotifications);
  }

  Future<void> _confirmSignOut() async {
    final colors = SettingsColors.of(context);
    final ok = await showAdaptiveDialog<bool>(
      context: context,
      builder: (dialogContext) => _ConfirmDialog(
        title: _Strings.signOutConfirmTitle,
        body: _Strings.signOutConfirmBody,
        confirmLabel: _Strings.signOut,
        destructive: true,
        colors: colors,
      ),
    );
    if (ok == true) {
      widget.onSignOut?.call();
      if (mounted) _announceSaved(_Strings.signOut);
    }
  }

  /// Account deletion is a MULTI-STEP confirm (store policy — SET-004): an
  /// explaining first step, then a typed-confirmation second step.
  Future<void> _confirmDeleteAccount() async {
    final colors = SettingsColors.of(context);
    final proceed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (dialogContext) => _ConfirmDialog(
        title: _Strings.deleteStep1Title,
        body: _Strings.deleteStep1Body,
        confirmLabel: _Strings.continueLabel,
        destructive: true,
        colors: colors,
      ),
    );
    if (proceed != true || !mounted) return;

    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (dialogContext) => _DeleteConfirmDialog(colors: colors),
    );
    if (confirmed == true) {
      widget.onDeleteAccount?.call();
      if (mounted) _announceSaved(_Strings.deleteAccount);
    }
  }

  Future<T?> _showSheet<T>({
    required String title,
    required WidgetBuilder builder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: SettingsColors.of(context).surface,
      builder: (sheetContext) =>
          SafeArea(top: false, child: builder(sheetContext)),
    );
  }

  // --- build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colors = SettingsColors.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final width = MediaQuery.sizeOf(context).width;
    final twoPane = width >= SettingsBreakpoint.expanded;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: colors.surface,
        title: Semantics(
          header: true,
          child: Text(
            _Strings.title,
            style: SettingsType.title(context)?.copyWith(color: colors.onSurface),
          ),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: _toggleOfflineDemo,
            iconSize: SettingsSize.icon,
            tooltip: _offline ? _Strings.demoOnline : _Strings.demoOffline,
            icon: Icon(_offline ? Icons.cloud_off : Icons.cloud_done_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _LiveAnnouncer(message: _announce),
            _OfflineBanner(
              visible: _offline,
              colors: colors,
              reduceMotion: reduceMotion,
            ),
            _SearchField(
              controller: _search,
              focusNode: _searchFocus,
              colors: colors,
              onClear: () {
                _search.clear();
                _searchFocus.unfocus();
              },
            ),
            Expanded(
              child: twoPane
                  ? _buildTwoPane(context, colors)
                  : _buildSinglePane(context, colors),
            ),
          ],
        ),
      ),
    );
  }

  // Compact: a single scrolling list of grouped sections (or search results),
  // with the isolated destructive zone at the very bottom.
  Widget _buildSinglePane(BuildContext context, SettingsColors colors) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: SettingsSize.maxContent),
        child: ListView(
          padding: const EdgeInsetsDirectional.only(bottom: SettingsSpace.xl),
          children: <Widget>[
            if (_searching)
              _buildSearchResults(context, colors)
            else ...<Widget>[
              for (final group in _groups) ...<Widget>[
                _GroupSection(
                  group: group,
                  colors: colors,
                  rowBuilder: _buildRow,
                ),
                const SizedBox(height: SettingsSpace.groupGap),
              ],
            ],
            _DestructiveZone(
              colors: colors,
              onSignOut: _confirmSignOut,
              onDeleteAccount: _confirmDeleteAccount,
            ),
          ],
        ),
      ),
    );
  }

  // Expanded: a leading group list + a detail pane for the selected group,
  // updated in place. The destructive zone is a full-width footer at the bottom.
  Widget _buildTwoPane(BuildContext context, SettingsColors colors) {
    final groups = _groups;
    final selected = groups[_selectedGroup.clamp(0, groups.length - 1)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                width: SettingsSize.paneWidth,
                child: _GroupNavList(
                  groups: groups,
                  selectedIndex: _selectedGroup,
                  colors: colors,
                  onSelect: (i) => setState(() => _selectedGroup = i),
                ),
              ),
              VerticalDivider(
                width: SettingsSize.stroke,
                thickness: SettingsSize.stroke,
                color: colors.outlineVariant,
              ),
              Expanded(
                child: _searching
                    ? ListView(
                        padding: const EdgeInsetsDirectional.only(
                          bottom: SettingsSpace.xl,
                        ),
                        children: <Widget>[_buildSearchResults(context, colors)],
                      )
                    : ListView(
                        padding: const EdgeInsetsDirectional.only(
                          top: SettingsSpace.md,
                          bottom: SettingsSpace.xl,
                        ),
                        children: <Widget>[
                          _GroupSection(
                            group: selected,
                            colors: colors,
                            rowBuilder: _buildRow,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
        Divider(
          height: SettingsSize.stroke,
          thickness: SettingsSize.stroke,
          color: colors.outlineVariant,
        ),
        _DestructiveZone(
          colors: colors,
          onSignOut: _confirmSignOut,
          onDeleteAccount: _confirmDeleteAccount,
        ),
      ],
    );
  }

  // --- search ----------------------------------------------------------------

  List<(_GroupSpec, _RowSpec)> _filteredRows() {
    final query = _search.text.trim();
    final out = <(_GroupSpec, _RowSpec)>[];
    for (final group in _groups) {
      for (final row in group.rows) {
        if (row.matches(query, group.title)) out.add((group, row));
      }
    }
    return out;
  }

  Widget _buildSearchResults(BuildContext context, SettingsColors colors) {
    final results = _filteredRows();
    final query = _search.text.trim();

    // Zero-results EMPTY state — distinct, announced, never a blank list.
    if (results.isEmpty) {
      final state = SettingsState.empty;
      return _ZeroResults(
        key: ValueKey<SettingsState>(state),
        query: query,
        colors: colors,
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < results.length; i++) {
      final (group, row) = results[i];
      if (i > 0) {
        rows.add(_RowDivider(colors: colors));
      }
      rows.add(_buildRow(context, group, row));
    }

    return Padding(
      padding: const EdgeInsetsDirectional.only(top: SettingsSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              SettingsSpace.edge,
              SettingsSpace.xs,
              SettingsSpace.edge,
              SettingsSpace.sm,
            ),
            child: Semantics(
              liveRegion: true,
              header: true,
              child: Text(
                '${results.length} ${_Strings.resultsHeader.toLowerCase()}',
                style: SettingsType.header(context)
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
          ),
          _SettingsCard(colors: colors, children: rows),
        ],
      ),
    );
  }

  // --- row dispatch ----------------------------------------------------------

  Widget _buildRow(BuildContext context, _GroupSpec group, _RowSpec spec) {
    final colors = SettingsColors.of(context);
    switch (spec.kind) {
      case _RowKind.toggle:
        if (spec.permissionLinked && !_notifGranted) {
          // OS-permission-denied: reflect the true system state + deep-link.
          return _PermissionRow(
            spec: spec,
            colors: colors,
            reason: _Strings.pushDeniedReason,
            onOpenSettings: _openSystemSettings,
          );
        }
        final disabled = spec.serverSynced && _offline;
        return _ToggleRow(
          spec: spec,
          value: _toggles[spec.id] ?? false,
          colors: colors,
          disabled: disabled,
          disabledReason: disabled ? _Strings.offlineReason : null,
          onChanged: disabled ? null : (v) => _onToggle(spec, v),
        );
      case _RowKind.disclosure:
        return _DisclosureRow(
          spec: spec,
          colors: colors,
          onTap: () => _openSubPage(spec.label),
        );
      case _RowKind.value:
        if (spec.serverSynced) {
          return _ServerValueRow(
            spec: spec,
            state: _offline ? SettingsState.offline : _planState,
            value: _valueFor(spec.id),
            colors: colors,
            reduceMotion: MediaQuery.disableAnimationsOf(context),
            onRetry: _loadPlan,
            onOpenSettings: _openSystemSettings,
          );
        }
        return _ValueRow(
          spec: spec,
          value: _valueFor(spec.id),
          colors: colors,
          onTap: spec.info ? null : () => _openValuePicker(spec),
        );
      case _RowKind.action:
        return _ActionRow(
          spec: spec,
          colors: colors,
          onPressed: () => _onAction(spec),
        );
    }
  }
}

// --- section + card shells ---------------------------------------------------

/// A named group: a heading (exposed as a heading landmark) + a grouped inset
/// card of rows separated by hairline dividers.
class _GroupSection extends StatelessWidget {
  const _GroupSection({
    required this.group,
    required this.colors,
    required this.rowBuilder,
  });

  final _GroupSpec group;
  final SettingsColors colors;
  final Widget Function(BuildContext, _GroupSpec, _RowSpec) rowBuilder;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < group.rows.length; i++) {
      if (i > 0) rows.add(_RowDivider(colors: colors));
      rows.add(rowBuilder(context, group, group.rows[i]));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SectionHeader(icon: group.icon, title: group.title, colors: colors),
        _SettingsCard(colors: colors, children: rows),
      ],
    );
  }
}

/// A section heading (Account, Notifications, …). Exposed as a heading so screen
/// readers can jump between groups (A11Y-017).
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.colors,
  });

  final IconData icon;
  final String title;
  final SettingsColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        SettingsSpace.edge,
        SettingsSpace.md,
        SettingsSpace.edge,
        SettingsSpace.sm,
      ),
      child: Semantics(
        header: true,
        child: Row(
          children: <Widget>[
            Icon(icon, size: SettingsSize.iconSm, color: colors.onSurfaceVariant),
            const SizedBox(width: SettingsSpace.sm),
            Flexible(
              child: Text(
                title,
                style: SettingsType.header(context)
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The grouped inset card that holds a run of rows (iOS grouped-table feel;
/// Material 3 preference container). Rounded, hairline-bordered, edge-inset.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.colors, required this.children});

  final SettingsColors colors;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    const shape =
        BorderRadius.all(Radius.circular(SettingsRadius.md));
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: SettingsSpace.edge,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: shape,
          border: Border.all(color: colors.outlineVariant),
        ),
        // A Material gives the row InkWells an ancestor to splash on and clips
        // them to the grouped-card radius.
        child: Material(
          color: colors.surfaceContainer,
          borderRadius: shape,
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// A hairline divider between rows, inset past the leading keyline so it aligns
/// under the label. RTL-safe (Divider uses directional indents).
class _RowDivider extends StatelessWidget {
  const _RowDivider({required this.colors});
  final SettingsColors colors;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: SettingsSize.stroke,
      thickness: SettingsSize.stroke,
      indent: SettingsSpace.rowLeadingInset,
      color: colors.outlineVariant,
    );
  }
}

/// The shared row scaffold: a >= 48dp min-height tap target with a 16dp leading
/// keyline, a leading glyph, a flexible label column that WRAPS long / localized
/// labels, and a trailing control. The whole row is tappable when [onTap] is set.
class _RowScaffold extends StatelessWidget {
  const _RowScaffold({
    required this.icon,
    required this.colors,
    required this.child,
    this.onTap,
    this.iconColor,
    this.enabled = true,
  });

  final IconData icon;
  final SettingsColors colors;
  final Widget child;
  final VoidCallback? onTap;
  final Color? iconColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: SettingsSize.rowMinHeight),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          SettingsSpace.rowLeadingInset,
          SettingsSpace.rowVertical,
          SettingsSpace.md,
          SettingsSpace.rowVertical,
        ),
        child: Row(
          children: <Widget>[
            Icon(
              icon,
              size: SettingsSize.icon,
              color: iconColor ??
                  (enabled ? colors.onSurfaceVariant : colors.outlineVariant),
            ),
            const SizedBox(width: SettingsSpace.md),
            Expanded(child: child),
          ],
        ),
      ),
    );
    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }
}

/// A label + optional subtitle column. The label wraps (no fixed height, no
/// clipping) so it survives Dynamic Type and text expansion (L10N-003).
class _RowLabel extends StatelessWidget {
  const _RowLabel({
    required this.label,
    required this.colors,
    this.subtitle,
    this.enabled = true,
    this.labelColor,
  });

  final String label;
  final SettingsColors colors;
  final String? subtitle;
  final bool enabled;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: SettingsType.rowLabel(context)?.copyWith(
            color: labelColor ??
                (enabled ? colors.onSurface : colors.onSurfaceVariant),
          ),
        ),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: SettingsSpace.xs),
          Text(
            subtitle!,
            style: SettingsType.caption(context)
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

// --- row types ---------------------------------------------------------------

/// A toggle row (`Switch.adaptive`). Exposes "label, on/off" to assistive tech;
/// the switch shape/position carries the state (not color-only — A11Y-012).
/// The whole row toggles; when server-synced and offline it is disabled with a
/// spoken reason (OFF-002) rather than silently flipping.
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.spec,
    required this.value,
    required this.colors,
    required this.onChanged,
    this.disabled = false,
    this.disabledReason,
  });

  final _RowSpec spec;
  final bool value;
  final SettingsColors colors;
  final ValueChanged<bool>? onChanged;
  final bool disabled;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final stateWord = value ? _Strings.on : _Strings.off;
    final subtitle = disabled ? disabledReason : spec.subtitle;
    return Semantics(
      container: true,
      toggled: value,
      enabled: !disabled,
      label: '${spec.label}, $stateWord',
      hint: disabled ? disabledReason : null,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: ExcludeSemantics(
        child: _RowScaffold(
          icon: spec.icon,
          colors: colors,
          enabled: !disabled,
          onTap: onChanged == null ? null : () => onChanged!(!value),
          child: Row(
            children: <Widget>[
              Expanded(
                child: _RowLabel(
                  label: spec.label,
                  subtitle: subtitle,
                  colors: colors,
                  enabled: !disabled,
                ),
              ),
              const SizedBox(width: SettingsSpace.md),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeTrackColor: colors.primary, // on-track = action.primary
                activeThumbColor: colors.onPrimary, // thumb = on.action.primary
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A disclosure row: the whole row navigates to a sub-page. The trailing chevron
/// mirrors in RTL (Directionality-aware). Announced as a button that navigates.
class _DisclosureRow extends StatelessWidget {
  const _DisclosureRow({
    required this.spec,
    required this.colors,
    required this.onTap,
  });

  final _RowSpec spec;
  final SettingsColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: spec.label,
      value: spec.subtitle,
      hint: 'Opens ${spec.label}',
      onTap: onTap,
      child: ExcludeSemantics(
        child: _RowScaffold(
          icon: spec.icon,
          colors: colors,
          onTap: onTap,
          child: Row(
            children: <Widget>[
              Expanded(
                child: _RowLabel(
                  label: spec.label,
                  subtitle: spec.subtitle,
                  colors: colors,
                ),
              ),
              const SizedBox(width: SettingsSpace.sm),
              _Chevron(colors: colors),
            ],
          ),
        ),
      ),
    );
  }
}

/// A value+chevron row: shows the current value and opens a picker. When [onTap]
/// is null (display-only, e.g. Version) it reads as static text with no chevron.
class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.spec,
    required this.value,
    required this.colors,
    required this.onTap,
  });

  final _RowSpec spec;
  final String value;
  final SettingsColors colors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final interactive = onTap != null;
    return Semantics(
      button: interactive,
      label: spec.label,
      value: value.isEmpty ? spec.subtitle : value,
      hint: interactive ? 'Opens ${spec.label} options' : null,
      onTap: onTap,
      child: ExcludeSemantics(
        child: _RowScaffold(
          icon: spec.icon,
          colors: colors,
          onTap: onTap,
          child: Row(
            children: <Widget>[
              Expanded(
                child: _RowLabel(
                  label: spec.label,
                  subtitle: value.isEmpty ? spec.subtitle : null,
                  colors: colors,
                ),
              ),
              const SizedBox(width: SettingsSpace.md),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: SettingsType.value(context)
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
              if (interactive) ...<Widget>[
                const SizedBox(width: SettingsSpace.sm),
                _Chevron(colors: colors),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A server-synced value row. It renders the full [SettingsState] machine: a
/// loading SKELETON while it fetches, the value on success/ideal, a compact
/// error + Retry on failure, a cached value + reason when offline, and a
/// deep-link when a linked permission is denied. Never a silent false value.
class _ServerValueRow extends StatelessWidget {
  const _ServerValueRow({
    required this.spec,
    required this.state,
    required this.value,
    required this.colors,
    required this.reduceMotion,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final _RowSpec spec;
  final SettingsState state;
  final String value;
  final SettingsColors colors;
  final bool reduceMotion;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case SettingsState.loading:
        return _RowScaffold(
          icon: spec.icon,
          colors: colors,
          child: Row(
            children: <Widget>[
              Expanded(
                child: _RowLabel(label: spec.label, colors: colors),
              ),
              const SizedBox(width: SettingsSpace.md),
              Semantics(
                liveRegion: true,
                label: '${_Strings.calculating} ${spec.label}',
                child: _ValueSkeleton(colors: colors, reduceMotion: reduceMotion),
              ),
            ],
          ),
        );
      case SettingsState.error:
        return _RowScaffold(
          icon: spec.icon,
          colors: colors,
          child: Row(
            children: <Widget>[
              Expanded(
                child: _RowLabel(
                  label: spec.label,
                  subtitle: '${_Strings.couldntLoad} ${spec.label.toLowerCase()}',
                  colors: colors,
                ),
              ),
              const SizedBox(width: SettingsSpace.sm),
              TextButton(
                onPressed: onRetry,
                style: _compactButtonStyle(colors),
                child: const Text(_Strings.retry),
              ),
            ],
          ),
        );
      case SettingsState.offline:
        return Semantics(
          container: true,
          label: '${spec.label}, $value, ${_Strings.queued}',
          child: ExcludeSemantics(
            child: _RowScaffold(
              icon: spec.icon,
              colors: colors,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _RowLabel(
                      label: spec.label,
                      subtitle: _Strings.queued,
                      colors: colors,
                    ),
                  ),
                  const SizedBox(width: SettingsSpace.md),
                  Flexible(
                    child: Text(
                      value,
                      textAlign: TextAlign.end,
                      style: SettingsType.value(context)
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      case SettingsState.permissionDenied:
        return _PermissionRow(
          spec: spec,
          colors: colors,
          reason: _Strings.pushDeniedReason,
          onOpenSettings: onOpenSettings,
        );
      case SettingsState.empty:
      case SettingsState.success:
      case SettingsState.ideal:
        return Semantics(
          container: true,
          label: '${spec.label}, $value',
          child: ExcludeSemantics(
            child: _RowScaffold(
              icon: spec.icon,
              colors: colors,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _RowLabel(label: spec.label, colors: colors),
                  ),
                  const SizedBox(width: SettingsSpace.md),
                  Flexible(
                    child: Text(
                      value,
                      textAlign: TextAlign.end,
                      style: SettingsType.value(context)
                          ?.copyWith(color: colors.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }
}

/// An action row: a button-styled control (spec "action" row type). The label is
/// the row; the trailing button carries the verb. Whole row triggers the action.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.spec,
    required this.colors,
    required this.onPressed,
  });

  final _RowSpec spec;
  final SettingsColors colors;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: spec.label,
      onTap: onPressed,
      child: ExcludeSemantics(
        child: _RowScaffold(
          icon: spec.icon,
          colors: colors,
          onTap: onPressed,
          iconColor: colors.primary,
          child: Row(
            children: <Widget>[
              Expanded(
                child: _RowLabel(
                  label: spec.label,
                  colors: colors,
                  labelColor: colors.primary,
                ),
              ),
              const SizedBox(width: SettingsSpace.md),
              FilledButton.tonal(
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  minimumSize:
                      const Size(SettingsSize.targetMin, SettingsSize.targetMin),
                  textStyle: SettingsType.button(context),
                ),
                child: Text(spec.actionLabel ?? spec.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An OS-permission-linked row that is currently DENIED. It reflects the true
/// system state and offers a deep-link to system Settings — never a toggle that
/// silently does nothing (PERM-003, STATE-010).
class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.spec,
    required this.colors,
    required this.reason,
    required this.onOpenSettings,
  });

  final _RowSpec spec;
  final SettingsColors colors;
  final String reason;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${spec.label}, ${_Strings.off}, $reason',
      hint: _Strings.openSettings,
      onTap: onOpenSettings,
      child: ExcludeSemantics(
        child: _RowScaffold(
          icon: spec.icon,
          colors: colors,
          onTap: onOpenSettings,
          child: Row(
            children: <Widget>[
              Expanded(
                child: _RowLabel(
                  label: spec.label,
                  subtitle: reason,
                  colors: colors,
                ),
              ),
              const SizedBox(width: SettingsSpace.sm),
              TextButton(
                onPressed: onOpenSettings,
                style: _compactButtonStyle(colors),
                child: const Text(_Strings.openSettings),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A trailing chevron that mirrors in RTL by choosing the direction-appropriate
/// glyph from the ambient [Directionality] (L10N-001, L10N-004).
class _Chevron extends StatelessWidget {
  const _Chevron({required this.colors});
  final SettingsColors colors;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final glyph = isRtl ? Icons.chevron_left : Icons.chevron_right;
    return Icon(glyph, size: SettingsSize.icon, color: colors.onSurfaceVariant);
  }
}

// --- search field ------------------------------------------------------------

/// The labeled search field that filters across all settings. Its clear button
/// is a >= 48dp target. Result count / zero-results are announced elsewhere.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.colors,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final SettingsColors colors;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final radius = const BorderRadius.all(Radius.circular(SettingsRadius.md));
    final base = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: colors.outlineVariant),
    );
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        SettingsSpace.edge,
        SettingsSpace.sm,
        SettingsSpace.edge,
        SettingsSpace.sm,
      ),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final hasText = controller.text.isNotEmpty;
          return TextField(
            controller: controller,
            focusNode: focusNode,
            textInputAction: TextInputAction.search,
            style: SettingsType.rowLabel(context)
                ?.copyWith(color: colors.onSurface),
            decoration: InputDecoration(
              labelText: _Strings.searchLabel, // programmatic label (A11Y-004)
              hintText: _Strings.searchHint,
              filled: true,
              fillColor: colors.surfaceContainer,
              prefixIcon: ExcludeSemantics(
                child: Icon(Icons.search,
                    size: SettingsSize.icon, color: colors.onSurfaceVariant),
              ),
              suffixIcon: hasText
                  ? IconButton(
                      onPressed: onClear,
                      tooltip: _Strings.clearSearch,
                      padding: const EdgeInsets.all(SettingsSpace.sm),
                      constraints: const BoxConstraints(
                        minWidth: SettingsSize.targetMin,
                        minHeight: SettingsSize.targetMin,
                      ),
                      iconSize: SettingsSize.icon,
                      color: colors.onSurfaceVariant,
                      icon: const Icon(Icons.close),
                    )
                  : null,
              labelStyle: SettingsType.value(context)
                  ?.copyWith(color: colors.onSurfaceVariant),
              hintStyle: SettingsType.value(context)
                  ?.copyWith(color: colors.onSurfaceVariant),
              border: base,
              enabledBorder: base,
              focusedBorder: base.copyWith(
                borderSide:
                    BorderSide(color: colors.focus, width: SettingsSize.stroke),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The distinct zero-results EMPTY state (spec STATE-004): the searched term is
/// echoed, announced as a live region, and the list is never simply blank.
class _ZeroResults extends StatelessWidget {
  const _ZeroResults({
    super.key,
    required this.query,
    required this.colors,
  });

  final String query;
  final SettingsColors colors;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(SettingsSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.search_off_outlined,
                size: SettingsSize.iconLg, color: colors.onSurfaceVariant),
            const SizedBox(height: SettingsSpace.md),
            Text(
              '${_Strings.noResultsTitle} "$query"',
              textAlign: TextAlign.center,
              style: SettingsType.rowLabel(context)
                  ?.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: SettingsSpace.sm),
            Text(
              _Strings.noResultsBody,
              textAlign: TextAlign.center,
              style: SettingsType.body(context)
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// --- skeleton ----------------------------------------------------------------

/// A non-text placeholder block for a value being fetched. It renders no text,
/// so a fixed size never clips Dynamic Type (A11Y-010). Pulses opacity only, and
/// holds a static frame under reduce motion (MOT-004).
class _ValueSkeleton extends StatefulWidget {
  const _ValueSkeleton({required this.colors, required this.reduceMotion});
  final SettingsColors colors;
  final bool reduceMotion;

  @override
  State<_ValueSkeleton> createState() => _ValueSkeletonState();
}

class _ValueSkeletonState extends State<_ValueSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: SettingsMotion.standard);
    if (!widget.reduceMotion) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _ValueSkeleton old) {
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
    final block = Container(
      width: SettingsSize.skelBlockW,
      height: SettingsSize.skelBlockH,
      decoration: BoxDecoration(
        color: widget.colors.skeleton,
        borderRadius: const BorderRadius.all(Radius.circular(SettingsRadius.sm)),
      ),
    );
    if (widget.reduceMotion) return block;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: block,
    );
  }
}

// --- offline banner + live region --------------------------------------------

/// The non-blocking offline banner (STATE-008). It sits above the content, never
/// covers it, and is announced once as a live region. Local prefs keep working.
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({
    required this.visible,
    required this.colors,
    required this.reduceMotion,
  });

  final bool visible;
  final SettingsColors colors;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: reduceMotion ? Duration.zero : SettingsMotion.standard,
      alignment: AlignmentDirectional.topStart,
      child: !visible
          ? const SizedBox.shrink()
          : Semantics(
              liveRegion: true,
              container: true,
              child: Container(
                color: colors.surfaceContainerHigh,
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: SettingsSpace.edge,
                  vertical: SettingsSpace.sm,
                ),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.cloud_off_outlined,
                        size: SettingsSize.iconSm,
                        color: colors.onSurfaceVariant),
                    const SizedBox(width: SettingsSpace.sm),
                    Expanded(
                      child: Text(
                        _Strings.offlineBanner,
                        style: SettingsType.caption(context)
                            ?.copyWith(color: colors.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// An off-screen live region: whenever [message] changes, assistive tech speaks
/// it. Used to announce "Saved" / "Couldn't save" outcomes (A11Y-019).
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

// --- expanded: leading group list --------------------------------------------

/// The leading pane on expanded windows: a selectable list of groups. Selecting
/// a group updates the detail pane in place (no push — spec two-pane, NAV-005).
class _GroupNavList extends StatelessWidget {
  const _GroupNavList({
    required this.groups,
    required this.selectedIndex,
    required this.colors,
    required this.onSelect,
  });

  final List<_GroupSpec> groups;
  final int selectedIndex;
  final SettingsColors colors;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surface,
      child: ListView.builder(
        padding: const EdgeInsetsDirectional.symmetric(
          vertical: SettingsSpace.sm,
        ),
        itemCount: groups.length,
        itemBuilder: (context, i) {
          final group = groups[i];
          final selected = i == selectedIndex;
          return Semantics(
          button: true,
          selected: selected,
          label: group.title,
          onTap: () => onSelect(i),
          child: ExcludeSemantics(
            child: InkWell(
              onTap: () => onSelect(i),
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: SettingsSize.rowMinHeight,
                ),
                color: selected
                    ? colors.surfaceContainerHigh
                    : Colors.transparent,
                padding: const EdgeInsetsDirectional.fromSTEB(
                  SettingsSpace.rowLeadingInset,
                  SettingsSpace.rowVertical,
                  SettingsSpace.md,
                  SettingsSpace.rowVertical,
                ),
                child: Row(
                  children: <Widget>[
                    Icon(group.icon,
                        size: SettingsSize.icon,
                        color: selected
                            ? colors.primary
                            : colors.onSurfaceVariant),
                    const SizedBox(width: SettingsSpace.md),
                    Expanded(
                      child: Text(
                        group.title,
                        style: SettingsType.rowLabel(context)?.copyWith(
                          color:
                              selected ? colors.primary : colors.onSurface,
                        ),
                      ),
                    ),
                    _Chevron(colors: colors),
                  ],
                ),
              ),
            ),
          ),
        );
        },
      ),
    );
  }
}

// --- destructive zone --------------------------------------------------------

/// The ISOLATED destructive zone at the very bottom (SET-003): visually distinct
/// (a "Danger zone" heading + red labels), out of the accidental-tap arc, each
/// action behind an explicit confirm dialog (DLG-001).
class _DestructiveZone extends StatelessWidget {
  const _DestructiveZone({
    required this.colors,
    required this.onSignOut,
    required this.onDeleteAccount,
  });

  final SettingsColors colors;
  final VoidCallback onSignOut;
  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        SettingsSpace.edge,
        SettingsSpace.lg,
        SettingsSpace.edge,
        SettingsSpace.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: SettingsSpace.xs,
              bottom: SettingsSpace.sm,
            ),
            child: Semantics(
              header: true,
              child: Text(
                _Strings.dangerZone,
                style: SettingsType.header(context)
                    ?.copyWith(color: colors.error),
              ),
            ),
          ),
          _DangerButton(
            icon: Icons.logout,
            label: _Strings.signOut,
            colors: colors,
            onPressed: onSignOut,
          ),
          const SizedBox(height: SettingsSpace.sm),
          _DangerButton(
            icon: Icons.delete_forever_outlined,
            label: _Strings.deleteAccount,
            colors: colors,
            onPressed: onDeleteAccount,
          ),
        ],
      ),
    );
  }
}

/// A destructive action button: red label + outline, full-width, >= 48dp. The
/// red is a redundant cue — the label text names the action (A11Y-012).
class _DangerButton extends StatelessWidget {
  const _DangerButton({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final SettingsColors colors;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: SettingsSize.iconSm),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, SettingsSize.targetMin),
        foregroundColor: colors.error,
        textStyle: SettingsType.button(context),
        side: BorderSide(color: colors.error),
        alignment: AlignmentDirectional.centerStart,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(SettingsRadius.md)),
        ),
      ),
    );
  }
}

// --- confirm dialogs ---------------------------------------------------------

/// A labeled confirm dialog. The destructive/primary action is styled per
/// platform via `showAdaptiveDialog`; copy names the outcome (DLG-002, A11Y-005).
class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.destructive,
    required this.colors,
  });

  final String title;
  final String body;
  final String confirmLabel;
  final bool destructive;
  final SettingsColors colors;

  @override
  Widget build(BuildContext context) {
    return AlertDialog.adaptive(
      title: Text(title),
      content: Text(body),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(_Strings.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: destructive ? colors.error : colors.primary,
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

/// The second step of account deletion: a typed-confirmation gate. "Delete
/// permanently" stays disabled until the user types the confirm word, so the
/// irreversible action cannot be triggered by a stray tap (SET-004, PROF-001).
class _DeleteConfirmDialog extends StatefulWidget {
  const _DeleteConfirmDialog({required this.colors});
  final SettingsColors colors;

  @override
  State<_DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<_DeleteConfirmDialog> {
  final TextEditingController _confirm = TextEditingController();
  bool _matches = false;

  @override
  void initState() {
    super.initState();
    _confirm.addListener(() {
      final next = _confirm.text.trim().toUpperCase() ==
          _Strings.deleteConfirmWord;
      if (next != _matches) setState(() => _matches = next);
    });
  }

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return AlertDialog.adaptive(
      title: const Text(_Strings.deleteStep2Title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(_Strings.deleteStep2Body,
              style: SettingsType.body(context)
                  ?.copyWith(color: colors.onSurface)),
          const SizedBox(height: SettingsSpace.md),
          TextField(
            controller: _confirm,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: _Strings.deleteFieldLabel,
              border: const OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide:
                    BorderSide(color: colors.error, width: SettingsSize.stroke),
              ),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(_Strings.cancel),
        ),
        TextButton(
          onPressed: _matches ? () => Navigator.of(context).pop(true) : null,
          style: TextButton.styleFrom(foregroundColor: colors.error),
          child: const Text(_Strings.deletePermanently),
        ),
      ],
    );
  }
}

// --- picker sheet ------------------------------------------------------------

/// A native-feeling option picker (spec value+chevron opens a picker, PLAT-006).
/// Each option is a >= 48dp row; the selected one shows a check (not color-only).
class _PickerSheet<T> extends StatelessWidget {
  const _PickerSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.colors,
  });

  final String title;
  final List<T> options;
  final T selected;
  final String Function(T) labelOf;
  final SettingsColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        SettingsSpace.edge,
        SettingsSpace.sm,
        SettingsSpace.edge,
        SettingsSpace.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              title,
              style: SettingsType.title(context)
                  ?.copyWith(color: colors.onSurface),
            ),
          ),
          const SizedBox(height: SettingsSpace.sm),
          for (final option in options)
            _PickerOption(
              label: labelOf(option),
              isSelected: option == selected,
              colors: colors,
              onTap: () => Navigator.of(context).pop(option),
            ),
        ],
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  const _PickerOption({
    required this.label,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final SettingsColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(minHeight: SettingsSize.rowMinHeight),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                vertical: SettingsSpace.rowVertical,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      label,
                      style: SettingsType.rowLabel(context)
                          ?.copyWith(color: colors.onSurface),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check,
                        size: SettingsSize.icon, color: colors.primary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- pushed sub-page ---------------------------------------------------------

/// A minimal detail sub-page pushed by a disclosure row on compact windows
/// (spec: a group's detail pushes a sub-page). Its AppBar owns the back button,
/// which mirrors in RTL automatically.
class _SubPage extends StatelessWidget {
  const _SubPage({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = SettingsColors.of(context);
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: colors.surface,
        title: Text(
          title,
          style: SettingsType.title(context)?.copyWith(color: colors.onSurface),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsetsDirectional.all(SettingsSpace.xl),
            child: Text(
              '$title detail',
              textAlign: TextAlign.center,
              style: SettingsType.body(context)
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }
}

// --- shared button style -----------------------------------------------------

ButtonStyle _compactButtonStyle(SettingsColors colors) => TextButton.styleFrom(
      minimumSize: const Size(SettingsSize.targetMin, SettingsSize.targetMin),
      padding:
          const EdgeInsetsDirectional.symmetric(horizontal: SettingsSpace.sm),
      foregroundColor: colors.primary,
      tapTargetSize: MaterialTapTargetSize.padded,
    );
