import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/ai/services/response_parser.dart';

/// Purpose: Test what survives between the model and the screen.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: A small model asked for four plain sentences will sometimes answer
/// with a heading, a bulleted list, a code fence, the prompt back, or nothing.
/// These are the cases that decide whether the learner reads an explanation or
/// a mess — and the two rejections are the load-bearing ones, because showing
/// an echo as an explanation, or the learner's own correct sentence as a
/// correction, teaches something false.
void main() {
  group('explanation', () {
    test('a plain paragraph is passed through', () {
      expect(
        ResponseParser.explanation('  Because 昨日 is a past time word.  '),
        'Because 昨日 is a past time word.',
      );
    });

    test('empty and whitespace are nothing to show', () {
      expect(ResponseParser.explanation(''), isNull);
      expect(ResponseParser.explanation('   \n  \n'), isNull);
    });

    test('a code fence around the whole answer is removed', () {
      expect(
        ResponseParser.explanation('```\nThe verb is in the past.\n```'),
        'The verb is in the past.',
      );
    });

    test('headings, bullets and numbering are stripped', () {
      const raw = '## Explanation\n- The verb is past.\n2. 昨日 is past too.';
      expect(
        ResponseParser.explanation(raw),
        'Explanation\nThe verb is past.\n昨日 is past too.',
      );
    });

    test('inline emphasis is removed rather than shown as asterisks', () {
      expect(
        ResponseParser.explanation('The **verb** is in the *past*.'),
        'The verb is in the past.',
      );
    });

    test('blank runs collapse to single breaks', () {
      expect(ResponseParser.explanation('One.\n\n\nTwo.'), 'One.\nTwo.');
    });

    test('an answer that only echoes the prompt is rejected', () {
      const prompt = 'Sentence: 私は学生です。\nRules:\n- Answer in English.';
      expect(
        ResponseParser.explanation('私は学生です。', prompt: prompt),
        isNull,
        reason: 'a model that echoes has not answered',
      );
    });

    test('an answer that opens by quoting is kept', () {
      const prompt = 'Sentence: 私は学生です。';
      expect(
        ResponseParser.explanation(
          '私は学生です。\nIt says "I am a student".',
          prompt: prompt,
        ),
        isNotNull,
      );
    });

    test('an over-long answer is cut at a sentence end', () {
      final long = '${'This is a sentence. ' * 60}And a tail with no end';
      final parsed = ResponseParser.explanation(long)!;

      expect(
        parsed.length,
        lessThanOrEqualTo(ResponseParser.maxExplanationChars),
      );
      expect(parsed.endsWith('.'), isTrue, reason: 'cut on a boundary');
      expect(parsed, isNot(contains('And a tail')));
    });

    test('an over-long answer with no boundary is ellipsised', () {
      final parsed = ResponseParser.explanation('あ' * 900)!;

      expect(parsed.endsWith('…'), isTrue);
      expect(
        parsed.length,
        lessThanOrEqualTo(ResponseParser.maxExplanationChars + 1),
      );
    });
  });

  group('correction', () {
    test('the first different suggestion is offered', () {
      expect(
        ResponseParser.correction(['これは本です。', 'これは本だ。'], 'これは本'),
        'これは本です。',
      );
    });

    test('a suggestion identical to the input is not a correction', () {
      expect(
        ResponseParser.correction(['これは本です。'], 'これは本です。'),
        isNull,
        reason: 'offering it would say a correct sentence was wrong',
      );
    });

    test('a suggestion differing only in spacing is not a correction', () {
      expect(ResponseParser.correction(['これは 本です。'], 'これは本です。'), isNull);
    });

    test('an unchanged first suggestion does not hide a changed second', () {
      expect(
        ResponseParser.correction(['これは本です。', 'これは本でした。'], 'これは本です。'),
        'これは本でした。',
      );
    });

    test('no suggestions at all is null', () {
      expect(ResponseParser.correction(const [], 'これは本です。'), isNull);
      expect(ResponseParser.correction(const ['  '], 'これは本です。'), isNull);
    });
  });
}
