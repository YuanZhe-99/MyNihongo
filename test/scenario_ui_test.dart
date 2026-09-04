import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/lessons/models/lesson_path.dart';
import 'package:my_nihongo/features/lessons/models/scenario.dart';
import 'package:my_nihongo/features/lessons/views/scenario_page.dart';
import 'package:my_nihongo/l10n/app_localizations.dart';

/// Purpose: Test the scripted-conversation page at the geometries the app
/// supports, and the one rule that makes it a lesson rather than a quiz.
/// Inputs: None.
/// Returns: None.
/// Side effects: None; the page reads no files.
/// Notes: Driven in Simplified Chinese like the other layout tests, because
/// square CJK glyphs measure the real layout while the test font inflates
/// Latin and reports overflows a device would never show.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, Object?> line(String ja, String zh) => {
    'speaker': 'A',
    'ja': ja,
    'reading': ja,
    'en': 'x',
    'zh': zh,
  };

  final scenario = Scenario.fromJson({
    'title': {'en': 'At the station', 'zh': '在车站'},
    'dialogue': [
      line('こんにちは。', '你好。'),
      line('はい、どうぞ。', '好的，请。'),
      line('ありがとう。', '谢谢。'),
      line('さようなら。', '再见。'),
    ],
    'branches': [
      {
        'after': 2,
        'choices': [
          {
            'ja': 'はい、そうです。',
            'reading': 'はい、そうです。',
            'en': 'Yes',
            'zh': '是的。',
            'correct': true,
          },
          {
            'ja': 'いいえ。',
            'reading': 'いいえ。',
            'en': 'No',
            'zh': '不是。',
          },
        ],
      },
    ],
  })!;

  final unit = LessonUnit.fromJson({
    'id': 'unit:n5-1',
    'title': {'en': 'One', 'zh': '第一单元'},
  })!;

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
          home: ScenarioPage(
            args: ScenarioArgs(scenario: scenario, unit: unit),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  for (final geometry in const [
    (412.0, 915.0, 'a phone in portrait'),
    (915.0, 412.0, 'a phone in landscape'),
    (933.0, 704.0, 'a Z Fold 8 unfolded'),
    (704.0, 933.0, 'a Z Fold 8 folded'),
    (791.0, 820.0, 'a Pixel 10 Pro Fold'),
    (659.0, 791.0, 'a Z Fold 5'),
    (1024.0, 768.0, 'a tablet in landscape'),
    (768.0, 1024.0, 'a tablet in portrait'),
  ]) {
    testWidgets('${geometry.$3} shows the first line without errors', (
      tester,
    ) async {
      await pumpAt(tester, geometry.$1, geometry.$2);
      expect(find.text('在车站'), findsOneWidget);
      expect(find.text('你好。'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the script advances one line at a time', (tester) async {
    await pumpAt(tester, 412, 915);
    expect(find.text('好的，请。'), findsNothing);
    await tester.tap(find.byType(FilledButton).first);
    await tester.pump();
    expect(find.text('好的，请。'), findsOneWidget);
  });

  testWidgets('a wrong reply does not end the conversation', (tester) async {
    await pumpAt(tester, 412, 915);
    // Two lines in, the branch is asked.
    await tester.tap(find.byType(FilledButton).first);
    await tester.pump();
    expect(find.text('你要说什么？'), findsOneWidget);

    // Pick the wrong one. The script carries on regardless, and the reply
    // stays in the transcript where it was said.
    await tester.tap(find.byType(OutlinedButton).last);
    await tester.pump();
    expect(find.text('你要说什么？'), findsNothing);
    expect(find.text('不是。'), findsOneWidget);
    expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
    await tester.tap(find.byType(FilledButton).first);
    await tester.pump();
    expect(find.text('谢谢。'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the tally at the end counts the right replies', (tester) async {
    await pumpAt(tester, 412, 915);
    await tester.tap(find.byType(FilledButton).first);
    await tester.pump();
    await tester.tap(find.byType(OutlinedButton).first); // the correct one
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      final next = find.byType(FilledButton);
      if (next.evaluate().isEmpty) break;
      await tester.tap(next.first);
      await tester.pump();
    }
    expect(find.textContaining('1 次'), findsOneWidget);
  });
}
