import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/services/content_repository.dart';
import 'package:my_nihongo/features/kana/models/kana.dart';
import 'package:my_nihongo/features/quiz/models/quiz_config.dart';
import 'package:my_nihongo/features/quiz/models/quiz_question.dart';
import 'package:my_nihongo/features/quiz/views/quiz_modes_page.dart';
import 'package:my_nihongo/features/quiz/views/quiz_page.dart';
import 'package:my_nihongo/l10n/app_localizations.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Purpose: Test the quiz page and the quiz-mode switches at the geometries the
/// app supports.
/// Inputs: None.
/// Returns: None.
/// Side effects: Reads the shipped content assets; writes into a temporary
/// directory.
/// Notes: Driven in Simplified Chinese, like the other layout tests: square CJK
/// glyphs measure the real layout, while the test font inflates Latin and
/// reports overflows a device would not show. The split is the thing worth
/// checking across geometries — question pane fixed, answers beside it — and the
/// narrow case has to stack rather than squeeze.
class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.documentsPath);
  final String documentsPath;
  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;

  setUpAll(() => ContentRepository.parseInIsolate = false);
  tearDownAll(() => ContentRepository.parseInIsolate = true);

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('mynihongo_quiz_');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
    await Directory(p.join(temp.path, 'MyNihongo')).create(recursive: true);
  });

  tearDown(() async {
    if (temp.existsSync()) await temp.delete(recursive: true);
  });

  /// A kana quiz over the first basic row, which every device can answer: no
  /// voice needed, and the kana table is not level-gated.
  QuizConfig kanaQuiz() => const QuizConfig(
    source: KanaRows(basic: [0], script: KanaScript.hiragana),
    modes: {QuizMode.kanaToRomaji},
    maxQuestions: 5,
  );

  Future<void> pumpAt(
    WidgetTester tester,
    double width,
    double height, {
    Widget? home,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.reset);
    // The page reads the catalog and the progress file through real dart:io,
    // which never completes inside the binding's fake-async zone.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),
            home: home ?? QuizPage(config: kanaQuiz()),
          ),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
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
    testWidgets('${geometry.$3} renders a question without errors', (
      tester,
    ) async {
      await pumpAt(tester, geometry.$1, geometry.$2);
      expect(find.text('测验'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a wide window splits question from answers', (tester) async {
    await pumpAt(tester, 1024, 768);
    expect(find.byType(VerticalDivider), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a narrow window stacks them instead of squeezing', (
    tester,
  ) async {
    await pumpAt(tester, 412, 915);
    expect(
      find.byType(VerticalDivider),
      findsNothing,
      reason: 'a 412 dp answer pane beside a question is worse than stacking',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('an answer has to be chosen before it can be checked', (
    tester,
  ) async {
    await pumpAt(tester, 412, 915);
    final check = find.widgetWithText(FilledButton, '检查');
    expect(check, findsOneWidget);
    expect(
      tester.widget<FilledButton>(check).onPressed,
      isNull,
      reason: 'nothing is chosen yet',
    );

    await tester.tap(find.byType(OutlinedButton).first);
    await tester.pump();
    expect(tester.widget<FilledButton>(check).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('checking an answer shows the verdict and then continues', (
    tester,
  ) async {
    await pumpAt(tester, 412, 915);
    await tester.tap(find.byType(OutlinedButton).first);
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(FilledButton, '检查'));
      for (var i = 0; i < 6; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });

    // One of the two verdicts, whichever option the first button happened to be.
    expect(
      find.text('正确').evaluate().isNotEmpty ||
          find.text('还差一点').evaluate().isNotEmpty,
      isTrue,
    );
    expect(find.widgetWithText(FilledButton, '继续'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a source with nothing in it says so rather than looking broken', (
    tester,
  ) async {
    await pumpAt(
      tester,
      412,
      915,
      // Kana modes only: enabling the grammar modes would make the page build
      // the 7,700-entry lexicon before it could answer, which is not what this
      // test is about.
      home: const QuizPage(
        config: QuizConfig(
          source: IdsSource([]),
          modes: {QuizMode.kanaToRomaji},
          maxQuestions: 5,
        ),
      ),
    );
    expect(find.textContaining('暂时没有可出的题'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the modes page groups every mode under its catalog', (
    tester,
  ) async {
    // Tall enough that the list builds every row: this is about which modes
    // exist, not about how many fit on a phone. A `ListView` does not build
    // what is below the fold, and there are more modes than a phone screen.
    await pumpAt(tester, 412, 2400, home: const QuizModesPage());
    expect(find.text('测验模式'), findsOneWidget);
    expect(find.text('单词'), findsOneWidget);
    expect(find.text('假名'), findsOneWidget);
    expect(find.text('语法'), findsOneWidget);
    expect(
      find.byType(SwitchListTile),
      findsNWidgets(QuizMode.values.length),
      reason: 'a mode with no switch cannot be turned off',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('every mode starts switched on', (tester) async {
    await pumpAt(tester, 412, 2400, home: const QuizModesPage());
    for (final tile in tester.widgetList<SwitchListTile>(
      find.byType(SwitchListTile),
    )) {
      expect(tile.value, isTrue);
    }
  });

  testWidgets('the last mode cannot be switched off', (tester) async {
    // Seed the preference with a single mode rather than switching twelve off
    // through the UI: the guard is what is being tested, not the scrolling.
    File(
      p.join(temp.path, 'MyNihongo', 'storage_config.json'),
    ).writeAsStringSync('{"quizModes": "kanaToRomaji"}');

    await pumpAt(tester, 412, 915, home: const QuizModesPage());
    final theOne = find.widgetWithText(SwitchListTile, '假名 → 罗马字');
    expect(tester.widget<SwitchListTile>(theOne).value, isTrue);

    await tester.runAsync(() async {
      await tester.ensureVisible(theOne);
      await tester.pump();
      await tester.tap(theOne);
      for (var f = 0; f < 6; f++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });

    expect(
      find.text('至少要保留一种模式。'),
      findsOneWidget,
      reason: 'a quiz with no modes opens empty and looks broken',
    );
    expect(
      tester.widget<SwitchListTile>(theOne).value,
      isTrue,
      reason: 'and the switch stays on',
    );
    expect(tester.takeException(), isNull);
  });
}
