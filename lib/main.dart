import 'dart:async';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'features/progress/services/nihongo_storage.dart';
import 'features/reminders/services/reminder_service.dart';
import 'shared/services/auto_sync_service.dart';
import 'shared/services/backup_service.dart';
import 'shared/widgets/shell_scaffold.dart';

/// Purpose: Initialize startup services and launch the app entry point.
/// Inputs: None.
/// Returns: None.
/// Side effects: Starts the daily auto-backup check and the auto-sync
/// lifecycle observer, then runs the app.
/// Notes: Both services are no-ops until the user enables them in Settings.
/// `DevicePreview` is compiled in but only enabled in debug builds, where it
/// is the quickest way to try the foldable geometries listed in
/// `doc/en-us/adaptive-layout.md`.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Run auto-backup if enabled (once per day, fire-and-forget).
  BackupService.runAutoBackupIfNeeded();

  // Start the auto-sync lifecycle observer.
  AutoSyncService.instance.start();

  // Prepare the notification machinery without asking the learner for
  // anything. A device whose owner has never turned reminders on is never
  // shown a permission dialog; the request lives in the Settings switch.
  unawaited(ReminderService.instance.init());

  // Read the last tab before the first frame, so the app opens where the user
  // left it rather than showing Learn and jumping.
  final lastTab = await NihongoStorage.getLastTab();
  final candidate = '/$lastTab';
  final initialLocation = ShellScaffold.routes.contains(candidate)
      ? candidate
      : '/learn';

  runApp(
    DevicePreview(
      enabled: kDebugMode,
      builder: (_) =>
          ProviderScope(child: MyNihongoApp(initialLocation: initialLocation)),
    ),
  );
}
