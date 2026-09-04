import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/speech/services/speech_backend.dart';
import 'package:my_nihongo/features/speech/services/speech_recognition_service.dart';
import 'package:my_nihongo/features/speech/services/tts_backend.dart';
import 'package:my_nihongo/features/speech/services/tts_service.dart';
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

/// A speech engine with whatever voices and engines a test needs.
class _FakeTts implements TtsBackend {
  _FakeTts({this.voiceList = const [], this.engineList = const []});

  final List<Map<String, String>> voiceList;
  final List<String> engineList;
  final List<String> spoken = [];
  final List<Map<String, String>> selectedVoices = [];

  @override
  Future<bool> setLanguage(String language) async => voiceList.isNotEmpty;

  @override
  Future<bool> isLanguageAvailable(String language) async =>
      voiceList.isNotEmpty;

  @override
  Future<void> setSpeechRate(double rate) async {}

  @override
  Future<List<Map<String, String>>> voices() async => voiceList;

  @override
  Future<bool> setVoice(Map<String, String> voice) async {
    selectedVoices.add(voice);
    return true;
  }

  @override
  Future<List<String>> engines() async => engineList;

  @override
  Future<String?> defaultEngine() async =>
      engineList.isEmpty ? null : engineList.first;

  @override
  Future<bool> setEngine(String engine) async => true;

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<_FakeSpeechBackend> pump(
    WidgetTester tester, {
    required bool permitted,
    _FakeTts? tts,
  }) async {
    final ttsBackend = tts ?? _FakeTts();
    final service = TtsService(ttsBackend);
    await service.init();
    TtsService.setInstanceForTesting(service);
    addTearDown(
      () => TtsService.setInstanceForTesting(TtsService(FlutterTtsBackend())),
    );
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

  testWidgets('the voice row names the voice rather than its identifier', (
    tester,
  ) async {
    await pump(
      tester,
      permitted: false,
      tts: _FakeTts(
        voiceList: const [
          {
            'name': 'ja-jp-x-jab#male_1-local',
            'locale': 'ja-JP',
            'quality': 'normal',
            'network_required': '0',
          },
          {
            'name': 'ja-jp-x-jac#female_2-local',
            'locale': 'ja-JP',
            'quality': 'very high',
            'network_required': '0',
          },
        ],
      ),
    );

    // The engine names are identifiers; the row has to say something a learner
    // can act on, and the identifier belongs in the picker where a bug report
    // can find it.
    expect(find.text('Japanese voice'), findsOneWidget);
    expect(find.textContaining('Japanese voice 1'), findsOneWidget);
    expect(find.text('ja-jp-x-jac#female_2-local'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the picker lists every voice with a sample button', (
    tester,
  ) async {
    final tts = _FakeTts(
      voiceList: const [
        {'name': 'first', 'locale': 'ja-JP', 'network_required': '0'},
        {'name': 'second', 'locale': 'ja-JP', 'network_required': '1'},
      ],
    );
    await pump(tester, permitted: false, tts: tts);

    await tester.tap(find.text('Japanese voice'));
    await tester.pumpAndSettle();

    expect(find.text('Japanese voice 1'), findsOneWidget);
    expect(find.text('Japanese voice 2'), findsOneWidget);
    expect(find.text('On this device'), findsOneWidget);
    expect(find.text('Needs the network'), findsOneWidget);
    expect(find.text('first'), findsOneWidget, reason: 'the raw engine name');

    await tester.tap(find.byIcon(Icons.play_circle_outline).last);
    await tester.pumpAndSettle();
    expect(tts.spoken, [SpeechSettingsTiles.previewText]);
    expect(
      tts.selectedVoices.last['name'],
      'first',
      reason: 'auditioning a voice must not silently choose it',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the engine row appears only when there is a choice to make', (
    tester,
  ) async {
    await pump(
      tester,
      permitted: false,
      tts: _FakeTts(
        voiceList: const [
          {'name': 'a', 'locale': 'ja-JP'},
        ],
        engineList: const ['com.google.android.tts'],
      ),
    );
    expect(find.text('Speech engine'), findsNothing);
  });

  testWidgets('two engines are offered by name, not by package', (
    tester,
  ) async {
    await pump(
      tester,
      permitted: false,
      tts: _FakeTts(
        voiceList: const [
          {'name': 'a', 'locale': 'ja-JP'},
        ],
        engineList: const ['com.google.android.tts', 'com.samsung.SMT'],
      ),
    );
    expect(find.text('Speech engine'), findsOneWidget);
    await tester.tap(find.text('System default'));
    await tester.pumpAndSettle();
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Samsung'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
