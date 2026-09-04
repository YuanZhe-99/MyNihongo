import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/services/content_repository.dart';
import 'package:my_nihongo/features/progress/models/history_entry.dart';
import 'package:my_nihongo/features/progress/services/nihongo_storage.dart';
import 'package:my_nihongo/features/writing/views/writing_practice_page.dart';
import 'package:my_nihongo/l10n/app_localizations.dart';
import 'package:my_nihongo/shared/widgets/history_list.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Purpose: Render writing practice at the named geometries, check that its
/// feedback is the sentence lab's four sections rather than a thinner second
/// answer, and walk the history round trip.
/// Inputs: None.
/// Returns: None.
/// Side effects: Reads the bundled content assets; writes into a temporary
/// directory.
/// Notes: Driven in Simplified Chinese for the same font reason as the other
/// layout tests. The page splits into two panes wherever `canSplitLayout`
/// passes: the prompt, the field and the history on the left, the feedback on
/// the right. The page had no test at all before v0.3.2.
class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.documentsPath);
  final String documentsPath;
  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => ContentRepository.parseInIsolate = false);
  tearDownAll(() => ContentRepository.parseInIsolate = true);

  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('mynihongo_writing_ui_');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
    await Directory(p.join(temp.path, 'MyNihongo')).create(recursive: true);
  });

  tearDown(() async {
    if (temp.existsSync()) await temp.delete(recursive: true);
  });

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
            home: const WritingPracticePage(
              prompt: WritingPrompt(prompt: '写两句自我介绍。'),
            ),
          ),
        ),
      );
      // The catalog is read from the bundle, so the first frames need real
      // async time rather than `pumpAndSettle`'s fake clock.
      for (var i = 0; i < 8; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();
  }

  Future<void> check(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.text('检查我的句子'));
      for (var i = 0; i < 8; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();
  }

  testWidgets('the prompt and the field are shown before anything is written', (
    tester,
  ) async {
    await pumpAt(tester, 412, 915);
    expect(find.text('写作练习'), findsOneWidget);
    expect(find.text('写两句自我介绍。'), findsOneWidget);
    expect(find.text('检查我的句子'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('checking shows the same four sections the lab shows', (
    tester,
  ) async {
    await pumpAt(tester, 412, 2400);
    await check(tester, 'これは本です。');

    // Before v0.3.2 this page showed unlabelled chips and an issue list; the
    // structure and the grammar sections were not there at all.
    expect(find.text('词'), findsOneWidget);
    expect(find.text('结构'), findsOneWidget);
    expect(find.text('用到的语法'), findsOneWidget);
    expect(find.text('可能的问题'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('two sentences are analysed separately and numbered', (
    tester,
  ) async {
    await pumpAt(tester, 412, 3200);
    await check(tester, 'これは本です。私は学生です。');

    expect(find.text('词'), findsNWidgets(2));
    expect(find.text('第 1 句'), findsOneWidget);
    expect(find.text('第 2 句'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('one sentence is not numbered', (tester) async {
    await pumpAt(tester, 412, 2400);
    await check(tester, 'これは本です。');
    expect(find.text('第 1 句'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('what was written is remembered', (tester) async {
    await pumpAt(tester, 412, 2400);
    await check(tester, 'これは本です。');

    // Real file I/O has to run outside the fake-async zone.
    var entries = <HistoryEntry>[];
    await tester.runAsync(() async {
      final stored = await NihongoStorage.load();
      entries = historyEntries(stored.records, kind: HistoryKind.writing);
    });
    expect(entries.single.text, 'これは本です。');
    expect(
      entries.single.unitId,
      isNull,
      reason: 'this prompt came from no unit',
    );
  });

  testWidgets('tapping a remembered entry puts it back in the field', (
    tester,
  ) async {
    await pumpAt(tester, 1600, 900);
    await check(tester, 'これは本です。');

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(find.widgetWithText(TextField, 'これは本です。'), findsNothing);

    await tester.runAsync(() async {
      await tester.tap(find.text('これは本です。').last);
      for (var i = 0; i < 8; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'これは本です。'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the history is a pane of its own on a wide window', (
    tester,
  ) async {
    await pumpAt(tester, 1600, 900);
    await check(tester, 'これは本です。');
    await tester.pumpAndSettle();

    expect(find.byType(HistoryList), findsOneWidget);
    expect(
      find.byIcon(Icons.history),
      findsNothing,
      reason: 'the app-bar button is the narrow-window alternative',
    );
    // The input is left of the analysis.
    final field = tester.getTopLeft(find.byType(TextField));
    final words = tester.getTopLeft(find.text('词'));
    expect(field.dx, lessThan(words.dx));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the history is behind a button on a narrow window', (
    tester,
  ) async {
    await pumpAt(tester, 412, 915);
    expect(find.byIcon(Icons.history), findsOneWidget);
    expect(find.byType(HistoryList), findsNothing);

    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();
    expect(find.byType(HistoryList), findsOneWidget);
    expect(find.text('历史记录'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty history says so rather than showing nothing', (
    tester,
  ) async {
    await pumpAt(tester, 1600, 900);
    expect(find.textContaining('这里还没有内容'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no AI controls appear while the switch is off', (tester) async {
    await pumpAt(tester, 412, 915);
    expect(find.text('改写得更自然'), findsNothing);
    expect(find.text('给出改写建议'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final geometry in const [
    [412.0, 915.0], // phone portrait
    [915.0, 412.0], // phone landscape
    [933.0, 704.0], // Z Fold 8 unfolded, landscape
    [704.0, 933.0], // Z Fold 8 unfolded, portrait
    [659.0, 791.0], // Z Fold 5
    [791.0, 820.0], // Pixel 10 Pro Fold
    [1024.0, 768.0], // tablet landscape
    [768.0, 1024.0], // tablet portrait
  ]) {
    testWidgets(
      'renders at ${geometry[0].toInt()}x${geometry[1].toInt()}',
      (tester) async {
        await pumpAt(tester, geometry[0], geometry[1]);
        expect(find.text('写作练习'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
