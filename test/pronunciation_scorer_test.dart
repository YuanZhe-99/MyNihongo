import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/models/content_catalog.dart';
import 'package:my_nihongo/features/sentence/services/lexicon.dart';
import 'package:my_nihongo/features/speech/services/pronunciation_scorer.dart';

/// Purpose: Test the mora-level pronunciation scoring end to end.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: The diff is the output the learner sees, so it is what is asserted;
/// the score is checked as a summary of the same alignment. The lexicon cases
/// matter most: a recognizer that answered in kanji has to be resolved before
/// anything is compared, or a perfect reading would score zero.
ContentCatalog _catalog() => ContentCatalog.fromJson({
  'schemaVersion': 2,
  'entries': [
    {
      'id': 'vocab:test-tokyo',
      'level': 'N5',
      'kanji': '東京',
      'reading': 'とうきょう',
      'pos': ['proper-noun'],
      'meanings': {
        'en': ['Tokyo'],
      },
    },
    {
      'id': 'vocab:test-gakusei',
      'level': 'N5',
      'kanji': '学生',
      'reading': 'がくせい',
      'pos': ['noun'],
      'meanings': {
        'en': ['student'],
      },
    },
  ],
}, const []);

void main() {
  late PronunciationScorer scorer;

  setUp(() => scorer = PronunciationScorer(Lexicon.build(_catalog())));

  test('an identical reading scores 100 with every mora correct', () {
    final result = scorer.score(target: 'がっこう', heard: 'がっこう');
    expect(result.score, 100);
    expect(result.isPerfect, isTrue);
    expect(result.diff.every((d) => d.op == MoraOp.correct), isTrue);
  });

  test('katakana from the recognizer still matches a hiragana target', () {
    final result = scorer.score(target: 'こんにちは', heard: 'コンニチハ。');
    expect(result.score, 100);
  });

  test('one wrong mora is one substitution, not a delete and an add', () {
    final result = scorer.score(target: 'たべる', heard: 'たべた');
    expect(result.diff.map((d) => d.op), [
      MoraOp.correct,
      MoraOp.correct,
      MoraOp.substituted,
    ]);
    expect(result.score, 67);
  });

  test('a dropped mora is reported as missing', () {
    final result = scorer.score(target: 'がっこう', heard: 'がこう');
    expect(
      result.diff.where((d) => d.op == MoraOp.missing).map((d) => d.target),
      ['っ'],
    );
    expect(result.score, 75);
  });

  test('an added mora is reported as extra', () {
    final result = scorer.score(target: 'ねこ', heard: 'ねこう');
    expect(result.diff.where((d) => d.op == MoraOp.extra).map((d) => d.heard), [
      'う',
    ]);
    expect(result.score, 50);
  });

  test('a kanji answer is resolved through the catalog', () {
    final result = scorer.score(target: 'とうきょう', heard: '東京');
    expect(result.heardKana, 'とうきょう');
    expect(result.score, 100);
  });

  test('a kanji the catalog does not know still costs edits', () {
    final result = scorer.score(target: 'とうきょう', heard: '京都');
    expect(result.score, lessThan(100));
    expect(result.heardKana, '京都');
  });

  test('nothing heard scores zero with every mora missing', () {
    final result = scorer.score(target: 'がくせい', heard: '');
    expect(result.score, 0);
    expect(result.diff.length, 4);
    expect(result.diff.every((d) => d.op == MoraOp.missing), isTrue);
  });

  test('the long-vowel mark compares equal to a written-out vowel', () {
    final result = scorer.score(target: 'こおひい', heard: 'コーヒー');
    expect(result.score, 100);
  });

  test('without a lexicon the scorer still normalizes', () {
    const bare = PronunciationScorer(null);
    expect(bare.score(target: 'ねこ', heard: 'ネコ').score, 100);
  });
}
