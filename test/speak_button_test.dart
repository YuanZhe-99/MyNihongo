import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/speech/services/tts_backend.dart';
import 'package:my_nihongo/features/speech/services/tts_service.dart';
import 'package:my_nihongo/features/speech/widgets/speak_button.dart';
import 'package:my_nihongo/l10n/app_localizations.dart';

/// Purpose: Test the speak button's three states against a fake engine.
/// Inputs: None.
/// Returns: None.
/// Side effects: Replaces the app-wide `TtsService` for the duration.
/// Notes: The states are: enabled and idle, enabled and playing this text, and
/// disabled because the device has no Japanese voice. The last one is the one
/// worth a test — it is what every device without a Japanese voice sees, this
/// development host included.
class _FakeBackend implements TtsBackend {
  _FakeBackend({this.japanese = true});
  final bool japanese;
  final List<String> spoken = [];

  @override
  Future<bool> setLanguage(String language) async => japanese;
  @override
  Future<bool> isLanguageAvailable(String language) async => japanese;
  @override
  Future<void> setSpeechRate(double rate) async {}
  @override
  Future<List<Map<String, String>>> voices() async => japanese
      ? const [
          {'name': 'Kyoko', 'locale': 'ja-JP'},
        ]
      : const [];
  @override
  Future<bool> setVoice(Map<String, String> voice) async => true;

  @override
  Future<List<String>> engines() async => const [];

  @override
  Future<String?> defaultEngine() async => null;

  @override
  Future<bool> setEngine(String engine) async => true;
  @override
  Future<void> speak(String text) async => spoken.add(text);
  @override
  Future<void> stop() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => TtsService.setInstanceForTesting(TtsService(_FakeBackend())));

  Future<TtsService> pump(WidgetTester tester, {bool japanese = true}) async {
    final service = TtsService(_FakeBackend(japanese: japanese));
    await service.init();
    TtsService.setInstanceForTesting(service);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const Scaffold(body: SpeakButton(text: 'こんにちは')),
      ),
    );
    return service;
  }

  testWidgets('tapping speaks the button\'s text', (tester) async {
    final service = await pump(tester);
    await tester.tap(find.byType(IconButton));
    await tester.pump();
    expect((service.speaking.value ?? ''), anyOf('', 'こんにちは'));
    expect(find.byIcon(Icons.volume_up_outlined), findsOneWidget);
  });

  testWidgets('the button is disabled without a Japanese voice', (
    tester,
  ) async {
    await pump(tester, japanese: false);
    final button = tester.widget<IconButton>(find.byType(IconButton));
    expect(button.onPressed, isNull);
    expect(button.tooltip, 'No Japanese voice installed');
  });

  testWidgets('the icon becomes stop while this text is playing', (
    tester,
  ) async {
    final service = await pump(tester);
    service.speaking.value = 'こんにちは';
    await tester.pump();
    expect(find.byIcon(Icons.stop_circle_outlined), findsOneWidget);
    service.speaking.value = null;
    await tester.pump();
    expect(find.byIcon(Icons.volume_up_outlined), findsOneWidget);
  });
}
