import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/services/content_repository.dart';
import 'package:my_nihongo/features/drills/views/weakness_report_page.dart';
import 'package:my_nihongo/features/progress/models/exam_attempt.dart';
import 'package:my_nihongo/l10n/app_localizations.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Purpose: Test the weakness report page at the geometries the app supports,
/// and the two things it must say rather than imply.
/// Inputs: None.
/// Returns: None.
/// Side effects: Reads the shipped content assets; writes into a temporary
/// directory.
/// Notes: Driven in Simplified Chinese, like the other layout tests. A learner
/// who has sat nothing is **told** so — a page reached from a button, showing
/// nothing and explaining nothing, reads as broken — and a table with no
/// qualifying rows says why it is empty rather than leaving a heading over
/// blank space.
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
    temp = await Directory.systemTemp.createTemp('mynihongo_weakui_');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
    await Directory(p.join(temp.path, 'MyNihongo')).create(recursive: true);
  });

  tearDown(() async {
    if (temp.existsSync()) await temp.delete(recursive: true);
  });

  /// Purpose: Put some sat papers in the progress file before the page loads.
  /// Inputs: `tester`; `papers` — one answers map per attempt.
  /// Returns: None.
  /// Side effects: Writes the progress file directly.
  /// Notes: Internal helper used within this test file only. Written as JSON
  /// rather than through the storage API, so the test does not depend on the
  /// writer to test the reader. Through `runAsync`, because a real `dart:io`
  /// write started inside `testWidgets`' fake-async zone never completes.
  Future<void> seed(
    WidgetTester tester,
    List<Map<String, int>> papers,
  ) async {
    final records = [
      for (final (index, answers) in papers.indexed)
        ExamAttempt(
          id: 'exam:20260905T1015${index}0Z-3f2a',
          level: 'N5',
          mode: ExamMode.mock,
          scale: 'short',
          startedAt: DateTime.utc(2026, 9, 5, 10, 15).add(
            Duration(days: index),
          ),
          answers: answers,
        ).toRecord(null, DateTime.utc(2026, 9, 5)).toJson(),
    ];
    final file = File(p.join(temp.path, 'MyNihongo', 'nihongo_progress.json'));
    await tester.runAsync(
      () => file.writeAsString(jsonEncode({'records': records})),
    );
  }

  Future<void> pumpAt(WidgetTester tester, double width, double height) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.reset);
    // The page reads the progress file, the catalog and the drill assets
    // through real dart:io, which never completes inside the binding's
    // fake-async zone.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),
            home: const WeaknessReportPage(),
          ),
        ),
      );
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    await tester.pump();
  }

  testWidgets('a learner who has sat nothing is told what would fill this', (
    tester,
  ) async {
    await pumpAt(tester, 412, 915);
    expect(find.textContaining('这里就会显示'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the page says how many papers it is based on', (tester) async {
    await seed(tester, [
      const {'q:n5-v-001': 0},
      const {'q:n5-v-001': 0},
    ]);
    await pumpAt(tester, 412, 915);
    expect(find.textContaining('最近 2 次'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a section that was sat is tallied', (tester) async {
    await seed(tester, [
      const {'q:n5-v-001': 1, 'q:n5-v-002': 0},
    ]);
    await pumpAt(tester, 412, 915);
    expect(find.text('文字・词汇'), findsOneWidget);
    expect(find.text('2 题对 1 题'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a question asked once names no weakness, and says why not', (
    tester,
  ) async {
    await seed(tester, [
      const {'q:n5-v-001': 0},
    ]);
    await pumpAt(tester, 412, 915);
    expect(
      find.textContaining('还看不出明显的薄弱点'),
      findsWidgets,
      reason: 'one wrong answer is bad luck, not a gap',
    );
  });

  testWidgets('a question missed three times names its 大問 and its word', (
    tester,
  ) async {
    await seed(tester, [
      const {'q:n5-v-001': 0},
      const {'q:n5-v-001': 0},
      const {'q:n5-v-001': 0},
    ]);
    await pumpAt(tester, 412, 915);
    expect(
      find.text('漢字読み'),
      findsOneWidget,
      reason: 'the 大問 is named as the paper prints it',
    );
    expect(
      find.textContaining('还看不出明显的薄弱点'),
      findsNothing,
      reason: 'both tables now have a row',
    );
    expect(tester.takeException(), isNull);
  });

  for (final geometry in const [
    (412.0, 915.0, 'a phone in portrait'),
    (915.0, 412.0, 'a phone in landscape'),
    (933.0, 704.0, 'a Z Fold 8 unfolded'),
    (704.0, 933.0, 'a Z Fold 8 folded'),
    (659.0, 791.0, 'a Z Fold 5 unfolded'),
    (791.0, 820.0, 'a Pixel 10 Pro Fold'),
    (1024.0, 768.0, 'a tablet in landscape'),
    (768.0, 1024.0, 'a tablet in portrait'),
  ]) {
    testWidgets('${geometry.$3} renders the report without errors', (
      tester,
    ) async {
      await seed(tester, [
        const {'q:n5-v-001': 0, 'q:n5-v-002': 1},
        const {'q:n5-v-001': 0, 'q:n5-v-002': 1},
        const {'q:n5-v-001': 0, 'q:n5-v-002': 0},
      ]);
      await pumpAt(tester, geometry.$1, geometry.$2);
      expect(tester.takeException(), isNull);
    });
  }
}
