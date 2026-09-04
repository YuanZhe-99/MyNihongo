import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/progress/services/nihongo_storage.dart';
import 'package:my_nihongo/l10n/app_localizations.dart';
import 'package:my_nihongo/shared/widgets/furigana_text.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Purpose: Test that readings are drawn over kanji, and only where they can be.
/// Inputs: None.
/// Returns: None.
/// Side effects: Writes into a temporary directory.
/// Notes: Driven in Simplified Chinese like the other layout tests, and pumped
/// at the named geometries, because ruby makes a line taller and a wider run
/// wider — the two ways this widget can break a layout that used to fit.
class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.documentsPath);
  final String documentsPath;
  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('mynihongo_ruby_');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
    await Directory(p.join(temp.path, 'MyNihongo')).create(recursive: true);
  });

  tearDown(() async {
    if (temp.existsSync()) await temp.delete(recursive: true);
  });

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    double width = 412,
    double height = 915,
    Future<void> Function()? before,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      // Real file I/O, so it has to happen inside `runAsync`: a bare await in
      // a widget test runs under fake async and never completes.
      await before?.call();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),
            home: Scaffold(body: Center(child: child)),
          ),
        ),
      );
      for (var i = 0; i < 6; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    await tester.pump();
  }

  /// Purpose: Collect every string the widget actually drew.
  /// Inputs: `tester`.
  /// Returns: `List<String>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The ruby is its own
  /// `Text`, so the reading appears as a separate string when it is drawn.
  List<String> texts(WidgetTester tester) => [
    for (final widget in tester.widgetList<Text>(find.byType(Text)))
      if (widget.data != null) widget.data!,
  ];

  testWidgets('the reading is drawn over the kanji that need it', (
    tester,
  ) async {
    await pump(tester, const FuriganaText('私は学生です', reading: 'わたしはがくせいです'));
    expect(texts(tester), containsAll(['わたし', 'がくせい']));
    expect(
      texts(tester),
      isNot(contains('わたしはがくせいです')),
      reason: 'the whole reading in one piece means nothing was aligned',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a word with no kanji is drawn plainly', (tester) async {
    await pump(tester, const FuriganaText('ひらがな', reading: 'ひらがな'));
    expect(find.text('ひらがな'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a reading that does not align is not drawn at all', (
    tester,
  ) async {
    await pump(tester, const FuriganaText('食べる', reading: 'たべます'));
    expect(find.text('食べる'), findsOneWidget);
    expect(texts(tester), isNot(contains('たべます')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('forceOff draws the text plainly even when it would align', (
    tester,
  ) async {
    await pump(
      tester,
      const FuriganaText('学生', reading: 'がくせい', forceOff: true),
    );
    expect(find.text('学生'), findsOneWidget);
    expect(texts(tester), isNot(contains('がくせい')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the switch turns it off', (tester) async {
    await pump(
      tester,
      const FuriganaText('学生', reading: 'がくせい'),
      before: () => NihongoStorage.setShowFurigana(false),
    );
    expect(find.text('学生'), findsOneWidget);
    expect(texts(tester), isNot(contains('がくせい')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the bracket fallback keeps the reading when ruby is off', (
    tester,
  ) async {
    await pump(
      tester,
      const FuriganaText('学生', reading: 'がくせい', bracketFallback: true),
      before: () => NihongoStorage.setShowFurigana(false),
    );
    expect(find.text('学生 (がくせい)'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
    testWidgets('${geometry.$3} wraps a long sentence without overflowing', (
      tester,
    ) async {
      await pump(
        tester,
        const Padding(
          padding: EdgeInsets.all(16),
          child: FuriganaText(
            '昨日私は友達と一緒に東京駅の近くの新しい店で美味しい food を食べました。',
            reading: 'きのうわたしはともだちといっしょにとうきょうえきのちかくのあたらしいみせでおいしい food をたべました。',
          ),
        ),
        width: geometry.$1,
        height: geometry.$2,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
