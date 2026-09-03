// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter_test/flutter_test.dart';

import '../tool/src/chinese_converter.dart';
import '../tool/src/zh_tw.dart';

/// Purpose: Test the Simplified to Traditional conversion and the JSON walker
/// that puts its output into the content files.
/// Inputs: None.
/// Returns: None.
/// Side effects: Reads the OpenCC dictionaries.
/// Notes: The conversion runs at build time, so nothing here ships — but the
/// text it produces does, and the phrase cases below are exactly the ones a
/// character-by-character table gets wrong.
void main() {
  late OpenCcConverter converter;

  setUpAll(() => converter = OpenCcConverter.load(openCcDirectory));

  test('phrases decide which Traditional character is right', () {
    // Each of these is a different Traditional character for one Simplified
    // one, chosen by the word it appears in.
    expect(converter.convert('干净'), '乾淨');
    expect(converter.convert('干部'), '幹部');
    expect(converter.convert('头发'), '頭髮');
    expect(converter.convert('发现'), '發現');
    expect(converter.convert('钟表'), '鐘錶');
    expect(converter.convert('表示'), '表示');
    expect(converter.convert('面条'), '麵條');
    expect(converter.convert('后面'), '後面');
  });

  test('Taiwan variants are used', () {
    expect(converter.convert('里面'), '裡面');
    expect(converter.convert('着'), '著');
  });

  test('ordinary text converts', () {
    expect(converter.convert('学习进度'), '學習進度');
    expect(converter.convert('什么'), '什麼');
  });

  test('everything that is not Simplified Chinese is left alone', () {
    for (final text in ['ひらがな', 'カタカナ', 'Settings', '123', '', '。、「」']) {
      expect(converter.convert(text), text, reason: text);
    }
  });

  test('Japanese words in the Chinese text survive', () {
    // The content mixes languages: a Chinese grammar note quotes the Japanese
    // word it is about. 来る is Japanese and 來る is not a word.
    expect(converter.convert('和来る'), '和来る');
    expect(converter.convert('静かな部屋'), '静かな部屋');
    expect(converter.convert('来ない'), '来ない');
    // The same character in Chinese prose still converts.
    expect(converter.convert('来了'), '來了');
    expect(converter.convert('安静'), '安靜');
  });

  test('the preserve list is not empty', () {
    expect(converter.preserved, contains('来る'));
  });

  group('withTraditional', () {
    String fake(String text) => '[$text]';

    test('writes zh_TW immediately after zh', () {
      final result =
          withTraditional({'en': 'a', 'zh': 'b', 'level': 1}, fake) as Map;
      expect(result.keys.toList(), ['en', 'zh', 'zh_TW', 'level']);
      expect(result['zh_TW'], '[b]');
    });

    test('handles both a string and a list', () {
      final result =
          withTraditional({
                'zh': ['one', 'two'],
              }, fake)
              as Map;
      expect(result['zh_TW'], ['[one]', '[two]']);
    });

    test('walks nested maps and lists', () {
      final result =
          withTraditional({
                'examples': [
                  {'ja': 'x', 'zh': 'y'},
                ],
              }, fake)
              as Map;
      expect(((result['examples'] as List).first as Map)['zh_TW'], '[y]');
    });

    test('is idempotent', () {
      final once = withTraditional({'zh': 'b'}, fake);
      final twice = withTraditional(once, fake);
      expect(twice, once);
    });

    test('drops a zh_TW whose zh is gone', () {
      final result = withTraditional({'en': 'a', 'zh_TW': 'stale'}, fake) as Map;
      expect(result.containsKey('zh_TW'), isFalse);
    });

    test('leaves an entry with no Chinese alone', () {
      final result = withTraditional({'en': 'a'}, fake) as Map;
      expect(result, {'en': 'a'});
    });
  });
}
