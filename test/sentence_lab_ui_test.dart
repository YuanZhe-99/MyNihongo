import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/services/content_repository.dart';
import 'package:my_nihongo/features/sentence/views/sentence_lab_page.dart';
import 'package:my_nihongo/l10n/app_localizations.dart';

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
}
