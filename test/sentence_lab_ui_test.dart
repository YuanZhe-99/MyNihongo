import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/services/content_repository.dart';
import 'package:my_nihongo/features/progress/models/history_entry.dart';
import 'package:my_nihongo/features/progress/services/nihongo_storage.dart';
import 'package:my_nihongo/features/sentence/views/sentence_lab_page.dart';
import 'package:my_nihongo/l10n/app_localizations.dart';
import 'package:my_nihongo/shared/widgets/history_list.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Gives the history somewhere real to be written, so the round trip is
/// exercised rather than silently swallowed.
class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.documentsPath);
  final String documentsPath;
  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

/// Purpose: Render the sentence lab at the named geometries and walk one
/// analysis from an empty field to a result.
/// Inputs: None.
/// Returns: None.
/// Side effects: Reads the bundled content assets.
/// Notes: Driven in Simplified Chinese for the same font reason as the other
/// layout tests. The page is one column at every size — the sections are a
/// chain, each referring to the one above it — so what is checked here is that
/// it renders without overflow from a phone to a desktop, and that the four
/// result sections appear once a sentence has been analysed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => ContentRepository.parseInIsolate = false);
  tearDownAll(() => ContentRepository.parseInIsolate = true);

  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('mynihongo_lab_ui_');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
    await Directory(p.join(temp.path, 'MyNihongo')).create(recursive: true);
  });

  tearDown(() async {
    if (temp.existsSync()) await temp.delete(recursive: true);
  });

  Future<void> pumpAt(
    WidgetTester tester,
    double width,
    double height, {
    String? sentence,
  }) async {
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
            home: SentenceLabPage(initialSentence: sentence),
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

  testWidgets('an empty lab explains what to do', (tester) async {
    await pumpAt(tester, 412, 915);
    expect(find.text('句子实验室'), findsOneWidget);
    expect(find.textContaining('在上面输入一个句子'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a sentence opened from an example is analysed on arrival', (
    tester,
  ) async {
    await pumpAt(tester, 412, 915, sentence: 'これは本です。');
    expect(find.text('词'), findsOneWidget);
    expect(find.text('结构'), findsOneWidget);
    expect(find.text('用到的语法'), findsOneWidget);
    expect(find.text('可能的问题'), findsOneWidget);
    // Every word of the sentence became a chip.
    expect(find.text('これ'), findsWidgets);
    expect(find.text('本'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a clean sentence says nothing looked unusual', (tester) async {
    await pumpAt(tester, 412, 915, sentence: '私は学生です。');
    expect(find.text('没有看到异常之处。'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the structure names one main predicate', (tester) async {
    await pumpAt(tester, 412, 915, sentence: '私は本を読みます。');
    expect(find.textContaining('主谓语', findRichText: true), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('typing a sentence and analysing it shows the result', (
    tester,
  ) async {
    await pumpAt(tester, 412, 915);
    await tester.enterText(find.byType(TextField), 'これは本です。');
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.text('分析'));
      for (var i = 0; i < 6; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();
    expect(find.text('词'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the lab renders on an unfolded Z Fold 8', (tester) async {
    await pumpAt(tester, 933, 704, sentence: 'これは本です。');
    expect(find.text('句子实验室'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the lab renders on a folded Z Fold 8', (tester) async {
    await pumpAt(tester, 704, 933, sentence: 'これは本です。');
    expect(find.text('句子实验室'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the lab renders on a desktop window', (tester) async {
    await pumpAt(tester, 1600, 900, sentence: 'これは本です。');
    expect(find.text('句子实验室'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('history', () {
    testWidgets('an analysed sentence is remembered', (tester) async {
      await pumpAt(tester, 412, 915, sentence: 'これは本です。');

      // Real file I/O has to run outside the fake-async zone.
      var entries = <HistoryEntry>[];
      await tester.runAsync(() async {
        final stored = await NihongoStorage.load();
        entries = historyEntries(stored.records, kind: HistoryKind.lab);
      });
      expect(entries.single.text, 'これは本です。');
    });

    testWidgets('analysing the same sentence twice keeps one entry', (
      tester,
    ) async {
      await pumpAt(tester, 412, 915, sentence: 'これは本です。');
      await tester.runAsync(() async {
        await tester.tap(find.text('分析'));
        for (var i = 0; i < 6; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
        }
      });
      await tester.pumpAndSettle();

      var entries = <HistoryEntry>[];
      await tester.runAsync(() async {
        final stored = await NihongoStorage.load();
        entries = historyEntries(stored.records, kind: HistoryKind.lab);
      });
      expect(entries.length, 1);
    });

    testWidgets('the history is a pane of its own on a wide window', (
      tester,
    ) async {
      await pumpAt(tester, 1600, 900, sentence: 'これは本です。');
      expect(find.byType(HistoryList), findsOneWidget);
      expect(find.byIcon(Icons.history), findsNothing);
      // The input is left of the analysis; the chain itself stays one column.
      final field = tester.getTopLeft(find.byType(TextField));
      final words = tester.getTopLeft(find.text('词'));
      final structure = tester.getTopLeft(find.text('结构'));
      expect(field.dx, lessThan(words.dx));
      expect(words.dx, structure.dx);
      expect(words.dy, lessThan(structure.dy));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the history is behind a button on a narrow window', (
      tester,
    ) async {
      await pumpAt(tester, 412, 915, sentence: 'これは本です。');
      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.byType(HistoryList), findsNothing);

      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();
      expect(find.byType(HistoryList), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a folded Z Fold 8 keeps the button, unfolded gets the pane', (
      tester,
    ) async {
      // The aspect gate: 704x933 is portrait and does not split, 933x704 does.
      await pumpAt(tester, 704, 933, sentence: 'これは本です。');
      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.byType(HistoryList), findsNothing);

      await pumpAt(tester, 933, 704, sentence: 'これは本です。');
      expect(find.byType(HistoryList), findsOneWidget);
      expect(find.byIcon(Icons.history), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('deleting an entry empties the history', (tester) async {
      await pumpAt(tester, 1600, 900, sentence: 'これは本です。');
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.byIcon(Icons.delete_outline));
        for (var i = 0; i < 6; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
        }
      });
      await tester.pumpAndSettle();

      expect(find.textContaining('这里还没有内容'), findsOneWidget);
      var entries = <HistoryEntry>[];
      await tester.runAsync(() async {
        final stored = await NihongoStorage.load();
        entries = historyEntries(stored.records, kind: HistoryKind.lab);
      });
      expect(entries, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping a remembered sentence analyses it again', (
      tester,
    ) async {
      await pumpAt(tester, 1600, 900, sentence: 'これは本です。');
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      await tester.runAsync(() async {
        await tester.tap(find.text('これは本です。').last);
        for (var i = 0; i < 8; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
        }
      });
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'これは本です。'), findsOneWidget);
      expect(find.text('词'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
