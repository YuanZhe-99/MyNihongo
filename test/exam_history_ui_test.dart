import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/services/content_repository.dart';
import 'package:my_nihongo/features/drills/views/exam_history_page.dart';
import 'package:my_nihongo/features/progress/models/exam_attempt.dart';
import 'package:my_nihongo/l10n/app_localizations.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Purpose: Test the results history at the geometries the app supports, and
/// the one claim it must never make.
/// Inputs: None.
/// Returns: None.
/// Side effects: Reads the shipped content assets; writes into a temporary
/// directory.
/// Notes: Driven in Simplified Chinese, like the other layout tests. The claim
/// is the note at the top: a screen showing "48 of 67" beside the letters JLPT
/// will be read as a JLPT score unless it says in words that it is not one.
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
    temp = await Directory.systemTemp.createTemp('mynihongo_examui_');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
    await Directory(p.join(temp.path, 'MyNihongo')).create(recursive: true);
  });

  tearDown(() async {
    if (temp.existsSync()) await temp.delete(recursive: true);
  });

  /// Purpose: Put one attempt in the progress file before the page loads.
  /// Inputs: `answers` — what the paper recorded.
  /// Returns: None.
  /// Side effects: Writes the progress file directly.
  /// Notes: Written as JSON rather than through the storage API so the test
  /// does not depend on the writer to test the reader.
  Future<void> seed(
    WidgetTester tester, {
    Map<String, int> answers = const {'q:n5-v-001': 1, 'q:n5-v-002': 0},
  }) async {
    final record = ExamAttempt(
      id: 'exam:20260905T101500Z-3f2a',
      level: 'N5',
      mode: ExamMode.practice,
      scale: 'short',
      startedAt: DateTime.utc(2026, 9, 5, 10, 15),
      finishedAt: DateTime.utc(2026, 9, 5, 10, 42),
      sections: {'vocab': ExamSectionResult(asked: answers.length, right: 1)},
      answers: answers,
    ).toRecord(null, DateTime.utc(2026, 9, 5));
    final file = File(p.join(temp.path, 'MyNihongo', 'nihongo_progress.json'));
    // Through `runAsync`: `testWidgets` runs its body in a fake-async zone,
    // and a real `dart:io` write started inside one never completes — the
    // test hangs until the runner gives up rather than failing.
    await tester.runAsync(
      () => file.writeAsString(
        jsonEncode({
          'records': [record.toJson()],
        }),
      ),
    );
  }

  /// Purpose: Open the first attempt and let its content files load.
  /// Inputs: The `tester`.
  /// Returns: None.
  /// Side effects: Pumps frames.
  /// Notes: Bounded pumps inside `runAsync`, because opening a row reads four
  /// content files through real `dart:io`, which never completes inside the
  /// binding's fake-async zone.
  Future<void> expand(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.tap(find.byType(ExpansionTile));
      for (var i = 0; i < 12; i++) {
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
    // The page reads the progress file and the drill assets through real
    // dart:io, which never completes inside the binding's fake-async zone.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),
            home: const ExamHistoryPage(),
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

  testWidgets('a learner who has sat nothing is told so, not shown a blank', (
    tester,
  ) async {
    await pumpAt(tester, 412, 915);
    expect(find.textContaining('这里还是空的'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an attempt shows its level, its score and its sections', (
    tester,
  ) async {
    await seed(tester);
    await pumpAt(tester, 412, 915);
    expect(find.textContaining('N5'), findsWidgets);
    expect(find.text('2 题答对 1 题'), findsOneWidget);
    expect(find.textContaining('文字・词汇：1/2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('it says in words that this is not a JLPT score', (tester) async {
    await seed(tester);
    await pumpAt(tester, 412, 915);
    expect(
      find.textContaining('不是 JLPT 成绩'),
      findsOneWidget,
      reason: 'the numbers beside the letters JLPT read as a JLPT score',
    );
  });

  testWidgets('expanding an attempt shows what was got wrong', (tester) async {
    await seed(tester);
    await pumpAt(tester, 412, 915);
    await expand(tester);
    expect(find.text('答错'), findsOneWidget);
    expect(
      find.text('答对'),
      findsNothing,
      reason: 'the point of the list is what to go back to',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a question the files no longer have says so', (tester) async {
    // Content is rewritten between releases. An attempt that quietly lost
    // three of its rows would be a worse record than one that admits it.
    await seed(tester, answers: const {'q:n5-v-999': 0});
    await pumpAt(tester, 412, 915);
    await expand(tester);
    expect(find.textContaining('已不在应用中'), findsOneWidget);
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
    testWidgets('${geometry.$3} renders the history without errors', (
      tester,
    ) async {
      await seed(tester);
      await pumpAt(tester, geometry.$1, geometry.$2);
      expect(find.text('JLPT 成绩记录'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
