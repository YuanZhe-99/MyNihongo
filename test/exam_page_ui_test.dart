import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/models/jlpt_level.dart';
import 'package:my_nihongo/features/content/services/content_repository.dart';
import 'package:my_nihongo/features/drills/views/exam_page.dart';
import 'package:my_nihongo/features/quiz/widgets/quiz_runner.dart';
import 'package:my_nihongo/l10n/app_localizations.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Purpose: Test the mock exam at the geometries the app supports, and the
/// three things it must do that a practice session must not.
/// Inputs: None.
/// Returns: None.
/// Side effects: Reads the shipped content assets; writes into a temporary
/// directory.
/// Notes: Driven in Simplified Chinese, like the other layout tests. The three
/// differences from practice are the start card, the clock, and the absence of
/// feedback between questions — a paper is marked at the end, and being told
/// after each question is the thing a real exam most conspicuously does not
/// do.
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
    temp = await Directory.systemTemp.createTemp('mynihongo_exam_ui_');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
    await Directory(p.join(temp.path, 'MyNihongo')).create(recursive: true);
  });

  tearDown(() async {
    if (temp.existsSync()) await temp.delete(recursive: true);
  });

  /// Purpose: Pump until something is true, rather than a fixed number of
  /// times.
  /// Inputs: The `tester` and the `until` condition.
  /// Returns: None.
  /// Side effects: Pumps frames inside `runAsync`.
  /// Notes: Internal helper used within this test file only. A fixed count is
  /// what this file had first, and it passed alone and failed in a full run:
  /// this page reads the structure file and four drill files through real
  /// `dart:io`, and on a machine running eight suites at once that takes
  /// longer than six hundred milliseconds. A condition is both faster in the
  /// common case and honest about what is being waited for.
  Future<void> pumpUntil(WidgetTester tester, bool Function() until) async {
    await tester.runAsync(() async {
      for (var i = 0; i < 200 && !until(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    await tester.pump();
  }

  Future<void> pumpAt(WidgetTester tester, double width, double height) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),
            home: const ExamPage(config: ExamConfig(JlptLevel.n5)),
          ),
        ),
      );
    });
    await pumpUntil(tester, () => find.text('开始本部分').evaluate().isNotEmpty);
  }

  /// Purpose: Start the block that is on the start card.
  /// Inputs: The `tester`.
  /// Returns: None.
  /// Side effects: Starts the clock.
  /// Notes: Internal helper used within this test file only.
  Future<void> startBlock(WidgetTester tester) async {
    await tester.runAsync(
      () => tester.tap(find.widgetWithText(FilledButton, '开始本部分')),
    );
    await pumpUntil(
      tester,
      () => find.byType(QuizRunner).evaluate().isNotEmpty,
    );
  }

  testWidgets('a paper opens on a start card, not on the clock', (
    tester,
  ) async {
    // Starting a clock the learner has not looked at is not a test of
    // Japanese.
    await pumpAt(tester, 412, 915);
    expect(find.text('开始本部分'), findsOneWidget);
    expect(find.byType(QuizRunner), findsNothing);
    expect(find.textContaining('第 1 部分'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the start card says what the block is and how long it runs', (
    tester,
  ) async {
    await pumpAt(tester, 412, 915);
    expect(find.text('文字・词汇'), findsOneWidget);
    expect(find.textContaining('分钟'), findsOneWidget);
    expect(find.textContaining('题'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('starting a block shows the questions and a running clock', (
    tester,
  ) async {
    await pumpAt(tester, 412, 915);
    await startBlock(tester);
    expect(find.byType(QuizRunner), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNWidgets(4));
    // mm:ss, and the first block of an N5 short paper is seven minutes.
    expect(find.textContaining(RegExp(r'^0[67]:\d\d$')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a paper is marked at the end, not after each question', (
    tester,
  ) async {
    await pumpAt(tester, 412, 915);
    await startBlock(tester);
    await tester.tap(find.byType(OutlinedButton).first);
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(FilledButton, '检查'));
      for (var i = 0; i < 6; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    await tester.pump();

    expect(find.text('正确'), findsNothing);
    expect(find.text('还差一点'), findsNothing);
    expect(
      find.widgetWithText(FilledButton, '继续'),
      findsNothing,
      reason:
          'a timed block advances by itself; a Continue button would be '
          'spending the learner clock on a button',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving a running paper offers to save it', (tester) async {
    await pumpAt(tester, 412, 915);
    await startBlock(tester);
    await tester.runAsync(() async {
      final state = tester.state(find.byType(ExamPage));
      Navigator.of(state.context).maybePop();
    });
    await pumpUntil(tester, () => find.text('离开考试？').evaluate().isNotEmpty);
    expect(find.text('离开考试？'), findsOneWidget);
    expect(
      find.textContaining('剩余时间'),
      findsOneWidget,
      reason: 'unlike the quiz, the rest of the paper is not discarded',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving writes the paper to disk', (tester) async {
    await pumpAt(tester, 412, 915);
    await startBlock(tester);
    await tester.runAsync(() async {
      final state = tester.state(find.byType(ExamPage));
      Navigator.of(state.context).maybePop();
    });
    await pumpUntil(tester, () => find.text('离开考试？').evaluate().isNotEmpty);
    final saved = File(p.join(temp.path, 'MyNihongo', 'exam_in_progress.json'));
    // Polled rather than asserted straight away: the page starts the write and
    // does not await it, so a bare check races the file system and passes or
    // fails depending on how loaded the machine is.
    await tester.runAsync(() async {
      for (var i = 0; i < 200 && !saved.existsSync(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });
    expect(saved.existsSync(), isTrue);
    expect(saved.readAsStringSync(), contains('questionIds'));
  });

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
    testWidgets('${geometry.$3} renders a timed block without errors', (
      tester,
    ) async {
      await pumpAt(tester, geometry.$1, geometry.$2);
      await startBlock(tester);
      expect(find.byType(QuizRunner), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
