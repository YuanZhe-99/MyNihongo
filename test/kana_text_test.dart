import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/kana/models/kana_text.dart';

/// Purpose: Test the kana normalization the pronunciation scoring compares on.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: The cases that matter are the ones where the two sides of the
/// comparison legitimately differ: a recognizer answers in katakana, writes
/// long vowels with `ー`, adds punctuation of its own, and may use full-width
/// ASCII. Everything here has to survive that without changing what was said.
void main() {
  group('toHiragana', () {
    test('katakana becomes hiragana', () {
      expect(toHiragana('コンニチハ'), 'こんにちは');
      expect(toHiragana('テレビ'), 'てれび');
    });

    test('the long-vowel mark becomes the previous vowel', () {
      expect(toHiragana('コーヒー'), 'こおひい');
      expect(toHiragana('ラーメン'), 'らあめん');
    });

    test('punctuation and spaces are dropped', () {
      expect(toHiragana('こんにちは。'), 'こんにちは');
      expect(toHiragana('はい、そうです！'), 'はいそうです');
      expect(toHiragana('わたし は がくせい'), 'わたしはがくせい');
    });

    test('full-width ASCII becomes ASCII', () {
      expect(toHiragana('ＡＢＣ'), 'ABC');
    });

    test('kanji are left alone for the caller to resolve', () {
      expect(toHiragana('東京'), '東京');
    });

    test('a leading long-vowel mark has nothing to repeat', () {
      expect(toHiragana('ーあ'), 'あ');
    });
  });

  group('splitMorae', () {
    test('a small kana joins the mora before it', () {
      expect(splitMorae('きょう'), ['きょ', 'う']);
      expect(splitMorae('しゃしん'), ['しゃ', 'し', 'ん']);
    });

    test('っ and ん are morae of their own', () {
      expect(splitMorae('がっこう'), ['が', 'っ', 'こ', 'う']);
      expect(splitMorae('ほん'), ['ほ', 'ん']);
    });

    test('an empty string has no morae', () {
      expect(splitMorae(''), isEmpty);
    });

    test('an unresolved character still costs a mora', () {
      expect(splitMorae('東きょう'), ['東', 'きょ', 'う']);
    });
  });
}
