import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/speech/services/speech_backend.dart';
import 'package:my_nihongo/features/speech/services/speech_recognition_service.dart';
import 'package:my_nihongo/features/speech/widgets/pronunciation_practice_sheet.dart';
import 'package:my_nihongo/l10n/app_localizations.dart';

/// Purpose: Render the pronunciation practice sheet at the named geometries
/// and walk one attempt from idle to a scored result.
/// Inputs: None.
/// Returns: None.
/// Side effects: Replaces the app-wide recognizer for the duration.
/// Notes: Driven in Simplified Chinese for the same font reason as the other
/// layout tests. The sheet is one column at every size — it holds a target, a
/// button and a row of mora chips — so what is checked here is that it renders
/// without overflow at the narrowest and widest geometries the app supports,
/// and that the three states each reach the screen.
class _FakeSpeechBackend implements SpeechBackend {
  void Function(SpeechHeard)? _onHeard;
  void Function(SpeechFailure)? _onFailure;

  void deliver(String text, {bool isFinal = true}) =>
      _onHeard?.call(SpeechHeard(text: text, isFinal: isFinal));

  void raise(SpeechFailure failure) => _onFailure?.call(failure);

  @override
  Future<bool> initialize({
    required void Function(SpeechFailure) onFailure,
  }) async {
    _onFailure = onFailure;
    return true;
  }

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<List<String>> localeIds() async => const ['ja_JP'];

  @override
  Future<void> listen({
    required String localeId,
    required bool onDevice,
    required void Function(SpeechHeard) onHeard,
  }) async {
    _onHeard = onHeard;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeSpeechBackend backend;

  setUp(() {
    backend = _FakeSpeechBackend();
    SpeechRecognitionService.setInstanceForTesting(
      SpeechRecognitionService(backend),
    );
  });

  Future<void> pumpAt(WidgetTester tester, double width, double height) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showPronunciationPracticeSheet(
                    context,
                    const PracticeTarget(display: '学生', reading: 'がくせい'),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('the sheet opens on a phone showing the target and the button', (
    tester,
  ) async {
    await pumpAt(tester, 412, 915);
    expect(find.text('学生'), findsOneWidget);
    expect(find.text('がくせい'), findsOneWidget);
    expect(find.text('点击开始朗读'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a scored attempt shows the mora chips and the score', (
    tester,
  ) async {
    await pumpAt(tester, 412, 915);
    await tester.tap(find.text('点击开始朗读'));
    await tester.pumpAndSettle();
    backend.deliver('がくせえ');
    await tester.pumpAndSettle();
    // Three of four morae matched, so the score is 75 and the legend appears.
    expect(find.text('75 / 100'), findsOneWidget);
    expect(find.text('正确'), findsOneWidget);
    expect(find.text('缺少'), findsOneWidget);
    expect(find.text('再试一次'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a perfect attempt says so instead of showing a score', (
    tester,
  ) async {
    await pumpAt(tester, 412, 915);
    await tester.tap(find.text('点击开始朗读'));
    await tester.pumpAndSettle();
    backend.deliver('ガクセイ。');
    await tester.pumpAndSettle();
    expect(find.text('每个音拍都对上了。'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a missing offline model explains both ways to fix it', (
    tester,
  ) async {
    await pumpAt(tester, 412, 915);
    await tester.tap(find.text('点击开始朗读'));
    await tester.pumpAndSettle();
    backend.raise(SpeechFailure.languageUnavailable);
    await tester.pumpAndSettle();
    expect(find.textContaining('没有离线日语识别'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the sheet renders on an unfolded Z Fold 8', (tester) async {
    await pumpAt(tester, 933, 704);
    expect(find.text('学生'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the sheet renders on a tablet', (tester) async {
    await pumpAt(tester, 1024, 768);
    expect(find.text('学生'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
