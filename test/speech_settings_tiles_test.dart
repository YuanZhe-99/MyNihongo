import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/speech/services/speech_backend.dart';
import 'package:my_nihongo/features/speech/services/speech_recognition_service.dart';
import 'package:my_nihongo/features/speech/widgets/speech_settings_tiles.dart';
import 'package:my_nihongo/l10n/app_localizations.dart';

/// Purpose: Test that opening Settings never asks for the microphone.
/// Inputs: None.
/// Returns: None.
/// Side effects: Replaces the speech singleton.
/// Notes: This exists because of a bug a device found and this host could not:
/// the recognition row used to call `ensureAvailable()` unconditionally, and
/// initializing the recognizer is what makes Android raise the microphone
/// prompt — so merely opening Settings produced a system dialog with no
/// explanation in front of it, which is exactly what
/// `doc/en-us/features/pronunciation.md` promises never happens. The assertion
/// that matters is `initializes`: while the permission is not granted, the
/// backend must not be initialized at all.
class _FakeSpeechBackend implements SpeechBackend {
  _FakeSpeechBackend({this.permitted = false});

  final bool permitted;
  int initializes = 0;
  int permissionChecks = 0;

  @override
  Future<bool> initialize({
    required void Function(SpeechFailure) onFailure,
  }) async {
    initializes++;
    return true;
  }

  @override
  Future<bool> hasPermission() async {
    permissionChecks++;
    return permitted;
  }

  @override
  Future<List<String>> localeIds() async => const ['en_US', 'ja_JP'];

  @override
  Future<void> listen({
    required String localeId,
    required bool onDevice,
    required void Function(SpeechHeard) onHeard,
  }) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<_FakeSpeechBackend> pump(
    WidgetTester tester, {
    required bool permitted,
  }) async {
    final backend = _FakeSpeechBackend(permitted: permitted);
    SpeechRecognitionService.setInstanceForTesting(
      SpeechRecognitionService(backend),
    );
    addTearDown(
      () => SpeechRecognitionService.setInstanceForTesting(
        SpeechRecognitionService(SpeechToTextBackend()),
      ),
    );
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(
            body: SingleChildScrollView(child: SpeechSettingsTiles()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return backend;
  }

  testWidgets('opening Settings does not initialize the recognizer', (
    tester,
  ) async {
    final backend = await pump(tester, permitted: false);

    expect(
      backend.initializes,
      0,
      reason: 'initializing is what raises the microphone prompt',
    );
    expect(backend.permissionChecks, 1);
    expect(
      find.text('Speech recognition is checked the first time you practise'),
      findsOneWidget,
      reason: 'not yet checked is a different claim from missing',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('an already-granted microphone lets the row say more', (
    tester,
  ) async {
    final backend = await pump(tester, permitted: true);

    expect(
      backend.initializes,
      1,
      reason: 'no prompt can appear once the permission is granted',
    );
    expect(find.text('Speech recognition is available'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the network fallback switch is offered either way', (
    tester,
  ) async {
    await pump(tester, permitted: false);

    expect(find.text('Allow network recognition'), findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });
}
