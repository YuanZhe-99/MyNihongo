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
    double textScale = 1.0,
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
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
              child: Scaffold(body: Center(child: child)),
            ),
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

  testWidgets('every character of the word sits on one line', (tester) async {
    // The bug this pins down shipped in the first build and was found on a
    // phone, not here. Ruby used to be a `WidgetSpan` holding a two-line
    // column, and a span reports its child's baseline as its own — which for
    // a column is the **first** child's, the reading. So the kana between the
    // kanji were laid out level with the furigana and the kanji dropped to a
    // second line: one word rendered as two rows of unrelated text.
    //
    // Nothing about that throws, so every geometry test below passed it. What
    // catches it is the invariant a reader would state: the word is on one
    // line.
    await pump(tester, const FuriganaText('私は学生です', reading: 'わたしはがくせいです'));

    double bottomOf(String piece) => tester.getBottomLeft(find.text(piece)).dy;

    final base = bottomOf('私');
    for (final piece in const ['は', '学生', 'で', 'す']) {
      expect(
        bottomOf(piece),
        closeTo(base, 0.5),
        reason: '"$piece" is not on the same line as 私',
      );
    }
    // And the readings sit above them rather than beside them.
    for (final ruby in const ['わたし', 'がくせい']) {
      expect(
        tester.getBottomLeft(find.text(ruby)).dy,
        lessThan(base),
        reason: '"$ruby" should be above the word, not on its line',
      );
    }
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
  testWidgets('the reading never reaches down into the word', (tester) async {
    // The bug this pins down was reported from a Pixel 10's vocabulary list on
    // 2026-09-04: the reading was painted on top of its own kanji.
    //
    // The reservation for the ruby slot used to be `rubyScale * 1.15` — a guess
    // that the font's ascent plus descent fits in 1.15 em. The app ships no
    // font, so Japanese comes from the system CJK face, which needs about 1.4,
    // and the ruby slot had no strut to hold it to the reservation. A SizedBox
    // constrains without clipping and a paragraph paints from the top, so the
    // surplus landed on the word.
    //
    // **This test cannot reproduce that half of it.** The widget-test font has
    // 1.0 em metrics, so it never overflows a 1.15 em box in the first place;
    // the fix was checked by screenshot on the device. What this test does hold
    // is the invariant that made the fix correct — the two slots are reserved
    // exactly, so the reading's box ends at or above the word's box — and the
    // text scale, which the widget also used to ignore entirely.
    for (final scale in const [1.0, 1.3, 2.0]) {
      await pump(
        tester,
        const FuriganaText('学生', reading: 'がくせい'),
        textScale: scale,
      );

      final ruby = tester.getRect(find.text('がくせい'));
      final word = tester.getRect(find.text('学生'));
      expect(
        ruby.bottom,
        lessThanOrEqualTo(word.top + 0.01),
        reason: 'at text scale $scale the reading overlaps the word',
      );
      expect(
        ruby.height,
        greaterThan(0),
        reason: 'at text scale $scale the reading has no room at all',
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('the boxes grow with the viewer text scale', (tester) async {
    // Reserving from the nominal font size while the engine paints the scaled
    // one is the other half of the reported bug, and the half a test can hold.
    await pump(tester, const FuriganaText('学生', reading: 'がくせい'));
    final small = tester.getRect(find.text('学生'));

    await pump(
      tester,
      const FuriganaText('学生', reading: 'がくせい'),
      textScale: 2.0,
    );
    final large = tester.getRect(find.text('学生'));

    expect(
      large.height,
      greaterThan(small.height),
      reason: 'the word slot ignored the text scale',
    );
  });
}
