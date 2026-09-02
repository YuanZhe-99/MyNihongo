import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/app_settings.dart';
import '../../../shared/utils/adaptive_layout.dart';
import '../../progress/services/nihongo_storage.dart';
import 'license_page.dart' as app_license;
import 'privacy_policy_page.dart';

/// The settings rows that lead to a second-level page.
///
/// Only these participate in the two-pane layout. Everything else on the page
/// is an inline control. WebDAV and backup join this list when their pages
/// are ported (see `PLAN.md`, M1.2).
enum _SettingsDetail { privacy, license }

class SettingsPage extends ConsumerStatefulWidget {
  /// Purpose: Create a settings page instance.
  /// Inputs: None.
  /// Returns: A new `SettingsPage` instance.
  /// Side effects: None.
  /// Notes: None.
  const SettingsPage({super.key});

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new state object.
  /// Side effects: None.
  /// Notes: Flutter lifecycle override.
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String _version = '';
  String _storagePath = '';

  // Which second-level page the detail pane is showing, when there is one.
  // Kept when the window narrows back to one pane rather than cleared, so
  // folding a device shut and opening it again restores the selection.
  _SettingsDetail? _detail;
  bool _twoPane = false;

  /// Purpose: Kick off the asynchronous loads the page shows.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Starts reading the package version and storage path.
  /// Notes: Flutter lifecycle override.
  @override
  void initState() {
    super.initState();
    _loadVersion();
    _loadStoragePath();
  }

  /// Purpose: Read the app version for the About section.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Rebuilds with the version string.
  /// Notes: Internal helper used within this file only. Never hand-edit a
  /// version string here; this reads `PackageInfo.fromPlatform()`.
  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _version = '${info.version}+${info.buildNumber}');
    }
  }

  /// Purpose: Read the active storage directory for display.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Rebuilds with the path.
  /// Notes: Internal helper used within this file only.
  Future<void> _loadStoragePath() async {
    final path = await NihongoStorage.getStoragePath();
    if (mounted) setState(() => _storagePath = path);
  }

  /// Purpose: Build the second-level page a settings row leads to.
  /// Inputs: `detail`.
  /// Returns: `Widget` — the page, a `Scaffold` with its own app bar.
  /// Side effects: None beyond building widgets.
  /// Notes: Internal helper used within this file only. The same widget serves
  /// both modes: pushed full-screen on a narrow window, and hosted in the
  /// detail pane on a wide one. A nested `Navigator` holding one route reports
  /// `canPop == false`, so the hosted page's app bar grows no back arrow.
  Widget _detailPage(_SettingsDetail detail) {
    return switch (detail) {
      _SettingsDetail.privacy => const PrivacyPolicyPage(),
      _SettingsDetail.license => const app_license.LicensePage(),
    };
  }

  /// Purpose: Open a second-level page the way the current layout calls for.
  /// Inputs: `detail`.
  /// Returns: None.
  /// Side effects: Either selects the detail pane's page or pushes a route on
  /// the root navigator.
  /// Notes: Internal helper used within this file only. Every row goes through
  /// here, so the two modes cannot drift apart.
  void _open(_SettingsDetail detail) {
    if (_twoPane) {
      setState(() => _detail = detail);
      return;
    }
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (_) => _detailPage(detail)));
  }

  /// Purpose: Build the right-hand pane of the two-pane settings layout.
  /// Inputs: `l10n`.
  /// Returns: `Widget`.
  /// Side effects: None beyond building widgets.
  /// Notes: Internal helper used within this file only. The nested `Navigator`
  /// gives the hosted page a real route. Keying it on the selection disposes
  /// and rebuilds on every change.
  Widget _buildDetailPane(AppLocalizations l10n) {
    final detail = _detail;
    if (detail == null) {
      final theme = Theme.of(context);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_outlined,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.settingsSelectItem,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Navigator(
      key: ValueKey(detail),
      onGenerateRoute: (_) =>
          MaterialPageRoute(builder: (_) => _detailPage(detail)),
    );
  }

  /// Purpose: Render a section heading above a run of settings rows.
  /// Inputs: `title`, `children`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  /// Purpose: Build the settings page in one or two panes.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often. The
  /// split is gated on [canSplitLayout] against the whole screen; the left
  /// pane's width comes from [settingsLeftPaneWidth] against the content
  /// width, which is the screen less the navigation rail.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);

    final screen = MediaQuery.sizeOf(context);
    _twoPane = canSplitLayout(screen.width, screen.height);
    final list = _buildSettingsList(l10n, settings, notifier);

    if (!_twoPane) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settingsTitle)),
        body: list,
      );
    }

    final contentWidth = shellContentWidth(screen.width);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: Row(
        children: [
          SizedBox(width: settingsLeftPaneWidth(contentWidth), child: list),
          const VerticalDivider(width: 1),
          Expanded(child: _buildDetailPane(l10n)),
        ],
      ),
    );
  }

  /// Purpose: Build the scrolling list of settings sections.
  /// Inputs: `l10n`, `settings`, `notifier`.
  /// Returns: `Widget`.
  /// Side effects: None beyond building widgets.
  /// Notes: Internal helper used within this file only.
  Widget _buildSettingsList(
    AppLocalizations l10n,
    AppSettings settings,
    AppSettingsNotifier notifier,
  ) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        // ── General ──
        _buildSection(l10n.settingsGeneral, [
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(l10n.settingsTheme),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: const Icon(Icons.brightness_auto, size: 18),
                  label: Text(l10n.settingsThemeSystem),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: const Icon(Icons.light_mode, size: 18),
                  label: Text(l10n.settingsThemeLight),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: const Icon(Icons.dark_mode, size: 18),
                  label: Text(l10n.settingsThemeDark),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) => notifier.setThemeMode(s.first),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.settingsLanguage),
            trailing: DropdownButton<Locale?>(
              alignment: AlignmentDirectional.centerEnd,
              value: settings.locale,
              underline: const SizedBox.shrink(),
              items: [
                DropdownMenuItem(
                  alignment: AlignmentDirectional.centerEnd,
                  value: null,
                  child: Text(l10n.settingsLanguageSystem),
                ),
                const DropdownMenuItem(
                  alignment: AlignmentDirectional.centerEnd,
                  value: Locale('en'),
                  child: Text('English'),
                ),
                const DropdownMenuItem(
                  alignment: AlignmentDirectional.centerEnd,
                  value: Locale('zh'),
                  child: Text('简体中文'),
                ),
              ],
              onChanged: (locale) => notifier.setLocale(locale),
            ),
          ),
        ]),

        // ── Data ──
        _buildSection(l10n.settingsData, [
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: Text(l10n.settingsStorageLocation),
            subtitle: Text(
              _storagePath,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ]),

        // ── About ──
        _buildSection(l10n.settingsAbout, [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.settingsVersion),
            trailing: Text(
              _version,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.settingsPrivacyPolicy),
            trailing: const Icon(Icons.chevron_right),
            selected: _twoPane && _detail == _SettingsDetail.privacy,
            onTap: () => _open(_SettingsDetail.privacy),
          ),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: Text(l10n.settingsLicense),
            trailing: const Icon(Icons.chevron_right),
            selected: _twoPane && _detail == _SettingsDetail.license,
            onTap: () => _open(_SettingsDetail.license),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.settingsLicenses),
            onTap: () => showLicensePage(
              context: context,
              applicationName: l10n.appTitle,
              applicationVersion: _version,
            ),
          ),
        ]),

        const SizedBox(height: 24),
      ],
    );
  }
}
