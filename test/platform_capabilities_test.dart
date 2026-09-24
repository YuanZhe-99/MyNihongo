import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/shared/utils/platform_capabilities.dart';

/// Purpose: Pin every getter in `platform_capabilities.dart` at every target
/// platform.
/// Inputs: None.
/// Returns: None.
/// Side effects: Sets and clears `debugDefaultTargetPlatformOverride`.
/// Notes: That file is the single place the app branches on the platform, so
/// a wrong answer there is a wrong answer everywhere. Before this test the iOS
/// and macOS rows were never exercised: nothing in `test/` ran under either.
/// The table is written out in full rather than derived, so a change to any
/// one cell shows up as a one-line diff here.
void main() {
  // Columns: mobile, desktop, storage row, system speech settings, on-device
  // model, recognizes speech, OS-scheduled reminders, in-app reminders,
  // local-network prompt.
  const table = <TargetPlatform, List<bool>>{
    TargetPlatform.android: [
      true,
      false,
      false,
      true,
      true,
      true,
      true,
      false,
      false,
    ],
    TargetPlatform.iOS: [
      true,
      false,
      false,
      false,
      false,
      true,
      true,
      false,
      true,
    ],
    TargetPlatform.windows: [
      false,
      true,
      true,
      true,
      false,
      true,
      false,
      true,
      false,
    ],
    TargetPlatform.macOS: [
      false,
      true,
      true,
      false,
      false,
      true,
      false,
      true,
      true,
    ],
    TargetPlatform.linux: [
      false,
      true,
      true,
      false,
      false,
      false,
      false,
      true,
      false,
    ],
    TargetPlatform.fuchsia: [
      false,
      true,
      true,
      false,
      false,
      false,
      false,
      false,
      false,
    ],
  };

  List<bool> row() => [
    isMobilePlatform,
    isDesktopPlatform,
    showsStorageLocation,
    canOpenSystemSpeechSettings,
    platformMayHaveOnDeviceModel,
    platformMayRecognizeSpeech,
    platformSchedulesReminders,
    platformRemindsFromInsideTheApp,
    platformAsksForLocalNetwork,
  ];

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  for (final entry in table.entries) {
    test('${entry.key.name} answers every capability as documented', () {
      debugDefaultTargetPlatformOverride = entry.key;
      expect(row(), entry.value);
    });
  }

  test('every platform schedules reminders one way or the other, or none', () {
    // The reminder service picks its backend on these two getters, so they
    // must never both be true.
    for (final platform in TargetPlatform.values) {
      debugDefaultTargetPlatformOverride = platform;
      expect(
        platformSchedulesReminders && platformRemindsFromInsideTheApp,
        isFalse,
        reason: platform.name,
      );
    }
  });

  test('the table covers every target platform', () {
    expect(table.keys.toSet(), TargetPlatform.values.toSet());
  });
}
