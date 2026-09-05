import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/models/localized_strings.dart';
import 'package:my_nihongo/features/drills/models/drill_file.dart';
import 'package:my_nihongo/features/drills/models/drill_section.dart';
import 'package:my_nihongo/features/drills/widgets/listening_script_player.dart';
import 'package:my_nihongo/features/lessons/models/scenario.dart';
import 'package:my_nihongo/features/speech/services/tts_backend.dart';
import 'package:my_nihongo/features/speech/services/tts_service.dart';
import 'package:my_nihongo/l10n/app_localizations.dart';

/// Purpose: Test that a listening script is played in order, from the reading,
/// and that the transcript stays hidden while it is still the answer.
/// Inputs: None.
/// Returns: None.
/// Side effects: Replaces the app-wide `TtsService` for the duration.
/// Notes: The transcript rule is the one worth the test. A 聴解 question whose
/// script is on screen is not a listening question, and the failure would be
/// invisible on a device with no Japanese voice — where every question would
/// look answerable and none of them would have been heard.
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

  final passage = DrillPassage(
    id: 'p:n5-l-001',
    type: DrillType.task,
    lines: const [
      DialogueLine(
        speaker: '男',
        ja: '今日は何時に帰りますか。',
        reading: 'きょうはなんじにかえりますか。',
        translations: LocalizedStrings.empty,
      ),
      DialogueLine(
        speaker: '女',
        ja: '六時です。',
        reading: 'ろくじです。',
        translations: LocalizedStrings.empty,
      ),
      DialogueLine(
        speaker: '女',
        ja: '六時です。',
        reading: 'ろくじです。',
        translations: LocalizedStrings.empty,
      ),
    ],
  );

  tearDown(() => TtsService.setInstanceForTesting(TtsService(_FakeBackend())));

  Future<_FakeBackend> pump(
    WidgetTester tester, {
    bool japanese = true,
    bool revealed = false,
    int? maxPlays,
  }) async {
    final backend = _FakeBackend(japanese: japanese);
    final service = TtsService(backend);
    await service.init();
    TtsService.setInstanceForTesting(service);
    await tester.pumpWidget(
      // FuriganaText reads the furigana preference, so the transcript needs a
      // scope even though nothing here changes one.
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            // Scrolled, as every real caller has it: the runner puts this in a
            // ListView or a SingleChildScrollView, and a transcript is taller
            // than a phone.
            body: SingleChildScrollView(
              child: ListeningScriptPlayer(
                passage: passage,
                revealed: revealed,
                maxPlays: maxPlays,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return backend;
  }

  testWidgets('the lines are spoken in order, from their readings', (
    tester,
  ) async {
    // The reading, never the surface: an engine handed 一日 has to guess
    // between ついたち and いちにち, and a question whose audio guessed wrong
    // is unanswerable.
    final backend = await pump(tester);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(backend.spoken, ['きょうはなんじにかえりますか。', 'ろくじです。', 'ろくじです。']);
  });

  testWidgets('a repeated line is still spoken', (tester) async {
    // `TtsService.speak` treats a repeat of what it is already speaking as a
    // request to stop, so a script with two identical lines went silent on
    // the second until the player learnt to stop first.
    final backend = await pump(tester);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(backend.spoken.where((s) => s == 'ろくじです。').length, 2);
  });

  testWidgets('the transcript is hidden until the question is answered', (
    tester,
  ) async {
    await pump(tester);
    expect(find.textContaining('六時です'), findsNothing);
    expect(find.text('Transcript'), findsNothing);
  });

  testWidgets('the transcript appears once the answer is in', (tester) async {
    await pump(tester, revealed: true);
    expect(find.text('Transcript'), findsOneWidget);
    expect(find.text('男'), findsOneWidget);
  });

  testWidgets('a mock allows one play and then says so', (tester) async {
    final backend = await pump(tester, maxPlays: 1);
    expect(find.text('1 play left'), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('no plays left'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(backend.spoken, hasLength(3), reason: 'one play, three lines');
  });

  testWidgets('practice offers no play limit at all', (tester) async {
    await pump(tester);
    expect(find.textContaining('play left'), findsNothing);
    expect(find.textContaining('plays left'), findsNothing);
  });

  testWidgets('without a Japanese voice the control is disabled, not gone', (
    tester,
  ) async {
    // A listening question with no visible way to listen looks like a bug.
    // The same rule `SpeakButton` follows.
    await pump(tester, japanese: false);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(
      find.text('This device has no Japanese voice, so this cannot be played.'),
      findsOneWidget,
    );
  });
}
