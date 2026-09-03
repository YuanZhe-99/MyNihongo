import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/kana/models/romaji.dart';

/// Purpose: Check the Hepburn romanizer, including the three rules the kana
/// tables do not cover.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: Phase 2's pronunciation scoring compares what the recognizer heard
/// against this output, so a change here changes what counts as a correct
/// answer. Long vowels are written out rather than macronned, matching the
/// `romaji` fields the content ships and what a learner would type.
void main() {
  test('plain syllables', () {
    expect(romajiFromKana('あ'), 'a');
    expect(romajiFromKana('かな'), 'kana');
    expect(romajiFromKana('こんにちは'), 'konnichiha');
  });

  test('yoon are matched as one unit, not two', () {
    expect(romajiFromKana('きょう'), 'kyou');
    expect(romajiFromKana('しゃしん'), 'shashin');
    expect(romajiFromKana('じゅぎょう'), 'jugyou');
  });

  test('the small tsu doubles the next consonant', () {
    expect(romajiFromKana('がっこう'), 'gakkou');
    expect(romajiFromKana('きっぷ'), 'kippu');
    expect(romajiFromKana('いっしょ'), 'issho');
  });

  test('a trailing small tsu produces nothing extra', () {
    expect(romajiFromKana('あっ'), 'a');
  });

  test('long vowels are written out', () {
    expect(romajiFromKana('とうきょう'), 'toukyou');
    expect(romajiFromKana('せんぱい'), 'senpai');
  });

  test('katakana reads the same as hiragana', () {
    expect(romajiFromKana('カタカナ'), 'katakana');
    expect(romajiFromKana('テレビ'), 'terebi');
  });

  test('the long-vowel mark repeats the previous vowel', () {
    expect(romajiFromKana('コーヒー'), 'koohii');
    expect(romajiFromKana('ケーキ'), 'keeki');
  });

  test('characters with no kana reading pass through unchanged', () {
    expect(romajiFromKana('日本'), '日本');
    expect(romajiFromKana('あ！'), 'a！');
    expect(romajiFromKana(''), '');
  });
}
