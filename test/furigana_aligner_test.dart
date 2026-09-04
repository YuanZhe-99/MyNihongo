import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/services/furigana_aligner.dart';
import 'package:my_nihongo/features/sentence/models/token.dart';

/// Purpose: Test that a reading is attached to the characters it belongs to.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: The catalog ships one reading per word and none per character, so
/// every case here is recovered from two strings alone. The ones worth naming
/// are where a kanji is followed by the same kana it ends in — 母は/ははは,
/// 花は/はなは — because a left-to-right pass takes the first match and prints
/// は over 母. What a wrong alignment produces is not a worse layout, it is
/// false information, which is why the aligner returns null instead.
void main() {
  /// Purpose: Render an alignment compactly so a failure is readable.
  /// Inputs: `surface`, `reading`.
  /// Returns: `String?`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  String? align(String surface, String? reading) =>
      alignFurigana(surface, reading)?.join();

  group('a kanji run takes the kana that belong to it', () {
    test('a word that is all kanji takes the whole reading', () {
      expect(align('学生', 'がくせい'), '学生[がくせい]');
    });

    test('kana in the surface anchor the run before them', () {
      expect(align('食べる', 'たべる'), '食[た]べる');
      expect(align('入り口', 'いりぐち'), '入[い]り口[ぐち]');
      expect(align('行った', 'いった'), '行[い]った');
    });

    test('a kanji followed by the kana it ends in still resolves', () {
      expect(align('母は', 'ははは'), '母[はは]は');
      expect(align('花は', 'はなは'), '花[はな]は');
    });

    test('a repeat mark belongs to the run before it', () {
      expect(align('日々', 'ひび'), '日々[ひび]');
    });

    test('one kanji can take several kana', () {
      expect(align('一つ', 'ひとつ'), '一[ひと]つ');
      expect(align('大人', 'おとな'), '大人[おとな]');
      expect(align('今日は', 'きょうは'), '今日[きょう]は');
    });

    test('katakana in the surface anchor without being rewritten', () {
      expect(align('テレビを見る', 'てれびをみる'), 'テレビを見[み]る');
    });

    test('digits are read too', () {
      expect(align('三時', 'さんじ'), '三時[さんじ]');
      expect(align('３時', 'さんじ'), '３時[さんじ]');
    });

    test('punctuation anchors like kana', () {
      expect(align('私は学生です。', 'わたしはがくせいです。'), '私[わたし]は学生[がくせい]です。');
    });
  });

  group('an alignment that does not fit is refused', () {
    test('a word with no kanji needs no ruby at all', () {
      final segments = alignFurigana('ひらがな', 'ひらがな')!;
      expect(segments, hasLength(1));
      expect(segments.single.isRuby, isFalse);
    });

    test('a kana-only surface aligns even with no reading given', () {
      expect(alignFurigana('ひらがな', null), isNotNull);
      expect(alignFurigana('ひらがな', null)!.single.reading, isNull);
    });

    test('a kanji surface with no reading has nothing to print', () {
      expect(alignFurigana('学生', null), isNull);
      expect(alignFurigana('学生', ''), isNull);
    });

    test('a reading whose kana do not appear in the surface is refused', () {
      expect(alignFurigana('食べる', 'たべます'), isNull);
    });

    test('a reading too short to cover the kanji is refused', () {
      expect(alignFurigana('学生です', 'です'), isNull);
    });

    test('an empty surface is refused', () {
      expect(alignFurigana('', 'あ'), isNull);
    });
  });

  group('a span of the surface maps back to a span of the reading', () {
    test('a span on run boundaries maps', () {
      final segments = alignFurigana('私は学生です', 'わたしはがくせいです')!;
      // は, the second character of the surface.
      final range = readingRangeFor(segments, 1, 2);
      expect(range, isNotNull);
      expect('わたしはがくせいです'.substring(range!.start, range.end), 'は');
    });

    test('a span inside a kana run maps, because kana map one to one', () {
      final segments = alignFurigana('本を読みます', 'ほんをよみます')!;
      final range = readingRangeFor(segments, 1, 2);
      expect('ほんをよみます'.substring(range!.start, range.end), 'を');
    });

    test('a span that cuts a kanji run in half has no answer', () {
      final segments = alignFurigana('学生です', 'がくせいです')!;
      expect(readingRangeFor(segments, 0, 1), isNull);
    });
  });
  group('an inflected token is read as it stands, not as its lemma', () {
    /// Purpose: Build a token the way the analyser would.
    /// Inputs: `surface`, `lemma`, `reading` of the lemma, and `forms`.
    /// Returns: `Token`.
    /// Side effects: None.
    /// Notes: Internal helper used within this file only.
    Token token(
      String surface,
      String lemma,
      String reading, [
      List<InflectionForm> forms = const [],
    ]) => Token(
      surface: surface,
      reading: reading,
      lemma: lemma,
      category: TokenCategory.verb,
      start: 0,
      end: surface.length,
      forms: forms,
    );

    test('a masu stem keeps the kanji reading and its own kana tail', () {
      // The lexicon stores たべる against 食べ; printing that over 食べ would
      // put る on screen that the sentence does not say.
      expect(
        surfaceReadingOfToken(
          token('食べ', '食べる', 'たべる', [InflectionForm.masuStem]),
        ),
        'たべ',
      );
    });

    test('a past form keeps the reading of the stem', () {
      expect(
        surfaceReadingOfToken(token('飲んだ', '飲む', 'のむ', [InflectionForm.past])),
        'のんだ',
      );
    });

    test('a word with no kanji needs no ruby', () {
      expect(surfaceReadingOfToken(token('します', 'する', 'する')), isNull);
    });

    test('a dictionary form reads as itself', () {
      expect(surfaceReadingOfToken(token('本', '本', 'ほん')), 'ほん');
    });

    test('来る changes its kanji reading with the form', () {
      expect(surfaceReadingOfToken(token('来る', '来る', 'くる')), 'くる');
      expect(
        surfaceReadingOfToken(
          token('来', '来る', 'くる', [InflectionForm.masuStem]),
        ),
        'き',
        reason: '来ます is きます, and the ます is the next token',
      );
      expect(
        surfaceReadingOfToken(token('来', '来る', 'くる', [InflectionForm.naiStem])),
        'こ',
        reason: '来ない is こない',
      );
      expect(
        surfaceReadingOfToken(token('来て', '来る', 'くる', [InflectionForm.te])),
        'きて',
      );
    });

    test('a form the chain does not decide leaves 来 unread', () {
      expect(
        surfaceReadingOfToken(
          token('来', '来る', 'くる', [InflectionForm.adverbial]),
        ),
        isNull,
        reason: 'く where the learner would say き teaches the wrong word',
      );
    });
  });
  test('a sentence with many kanji runs aligns quickly', () {
    // Without memoizing the states already shown to fail, this is exponential
    // in the number of kanji runs and hangs the frame that draws it.
    const surface = '昨日私は友達と一緒に東京駅の近くの新しい店で美味しい物を食べました。';
    const reading =
        'きのうわたしはともだちといっしょにとうきょうえきのちかくのあたらしいみせでおいしいものをたべました。';
    final watch = Stopwatch()..start();
    expect(alignFurigana(surface, reading), isNotNull);
    watch.stop();
    expect(watch.elapsedMilliseconds, lessThan(200));
  });

  test('a long sentence that cannot align gives up quickly', () {
    // The failing case is the expensive one: every alternative is tried.
    const surface = '昨日私は友達と一緒に東京駅の近くの新しい店で美味しい物を食べました。';
    final watch = Stopwatch()..start();
    expect(alignFurigana(surface, 'ぜんぜんちがうよみかたです'), isNull);
    watch.stop();
    expect(watch.elapsedMilliseconds, lessThan(200));
  });
}
