import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../shared/providers/app_settings.dart';
import 'locale_resolution.dart';
import 'router.dart';
import 'theme.dart';

class MyNihongoApp extends ConsumerStatefulWidget {
  /// Which tab to open on, read from the device preferences before `runApp`.
  final String initialLocation;

  /// Purpose: Create the root app widget.
  /// Inputs: `initialLocation`.
  /// Returns: A new `MyNihongoApp` instance.
  /// Side effects: None.
  /// Notes: None.
  const MyNihongoApp({super.key, this.initialLocation = '/learn'});

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new state object.
  /// Side effects: None.
  /// Notes: Flutter lifecycle override.
  @override
  ConsumerState<MyNihongoApp> createState() => _MyNihongoAppState();
}

class _MyNihongoAppState extends ConsumerState<MyNihongoApp> {
  /// The router, built once.
  ///
  /// A `GoRouter` owns navigation history, so rebuilding one on a theme or
  /// locale change would send the app back to its initial tab.
  late final GoRouter _router = buildAppRouter(
    initialLocation: widget.initialLocation,
  );

  /// Purpose: Build the `MaterialApp.router` with theme, locale, and routes.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);

    return MaterialApp.router(
      title: 'MyNihongo!!!!!',
      debugShowCheckedModeBanner: false,

      // No scrollBehavior: the SDK default already scrolls with the wheel and
      // draws scrollbars on desktop, and it keeps stylus and accessibility
      // (`unknown`) drags working on Android, which a custom dragDevices set
      // silently dropped. See doc/en-us/platform-notes.md.

      // Theme
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,

      // Localization
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeListResolutionCallback: resolveAppLocale,

      // DevicePreview
      builder: DevicePreview.appBuilder,

      // Routing
      routerConfig: _router,
    );
  }
}
