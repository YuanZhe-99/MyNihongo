import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/models/grammar_point.dart';
import 'package:my_nihongo/features/content/models/jlpt_level.dart';
import 'package:my_nihongo/features/content/models/localized_strings.dart';
import 'package:my_nihongo/features/content/services/content_links.dart';
import 'package:my_nihongo/features/ai/services/practice_response_parser.dart';
import 'package:my_nihongo/features/quiz/models/quiz_question.dart';
import 'package:my_nihongo/features/quiz/services/ai_question_generator.dart';
import 'package:my_nihongo/features/sentence/models/sentence_analysis.dart';
import 'package:my_nihongo/features/sentence/models/token.dart';

/// Purpose: Test what the app will and will not accept as a generated question.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: Every rejection here has a specific failure behind it. A question
/// with no blank asks nothing; two identical options are two right answers; an
/// answer letter with no option behind it is a reply that contradicts itself.
/// None of those can be repaired by guessing, and a guessed question looks
/// exactly as authoritative on screen as an authored one.
void main() {
  final point = GrammarPoint(
    id: 'grammar:tara',
    level: JlptLevel.n4,
    pattern: '〜たら',
    structure: 'V-たら',
    meaning: const LocalizedStrings({
      'en': ['if, when'],
    }),
    explanation: const LocalizedStrings({
      'en': ['A conditional.'],
    }),
    examples: const [ContentExample(ja: '雨が降ったら行きません。')],
  );

  QuizQuestion? parse(String raw) =>
      AiQuestionGenerator.parse(raw, point: point);

  test('a well-formed reply becomes a generated question', () {
    final question = parse('''
Q: 雨が＿＿、行きません。
A: 降ったら
B: 降ります
C: 降って
D: 降る
Answer: A
Why: たら marks the condition.
''');

    expect(question, isNotNull);
    expect(question!.generated, isTrue);
    expect(question.itemId, 'grammar:tara');
    expect(question.kind, AnswerKind.choice);
    expect(question.options, hasLength(4));
    expect(question.answerIndex, 0);
    expect(question.explanation, 'たら marks the condition.');
  });

  test('a full-width colon is read the same way', () {
    final question = parse('''
Q：雨が＿＿、行きません。
A：降ったら
B：降ります
C：降って
D：降る
Answer：B
''');
    expect(question?.answerIndex, 1);
    expect(question?.explanation, isNull);
  });

  test('a sentence with no blank asks nothing', () {
    expect(
      parse('Q: 雨が降ったら行きません。\nA: あ\nB: い\nC: う\nD: え\nAnswer: A'),
      isNull,
    );
  });

  test('two identical options are two right answers', () {
    expect(
      parse('Q: 雨が＿＿。\nA: あ\nB: あ\nC: う\nD: え\nAnswer: A'),
      isNull,
    );
  });

  test('three options is not a four-choice question', () {
    expect(parse('Q: 雨が＿＿。\nA: あ\nB: い\nC: う\nAnswer: A'), isNull);
  });

  test('an answer letter with no option behind it is refused', () {
    expect(
      parse('Q: 雨が＿＿。\nA: あ\nB: い\nC: う\nD: え\nAnswer: E'),
      isNull,
    );
    expect(parse('Q: 雨が＿＿。\nA: あ\nB: い\nC: う\nD: え'), isNull);
  });

  test('prose instead of the asked-for shape is refused', () {
    expect(
      parse('Here is a question about たら for your learner. It is useful!'),
      isNull,
    );
    expect(parse(''), isNull);
  });

  test('a blank option is refused rather than shown empty', () {
    expect(
      parse('Q: 雨が＿＿。\nA: \nB: い\nC: う\nD: え\nAnswer: B'),
      isNull,
    );
  });
  group('the second opinion', () {
    // A generated question used to be shown on the strength of one model call
    // that both wrote the question and declared its answer. Now the model is
    // handed the question back without that answer and asked to work it out,
    // and the question is kept only if the two derivations agree.
    final question = parse(
      'Q: 雨が降＿＿行きません。\n'
      'A: ったら\nB: ったり\nC: っては\nD: ってから\n'
      'Answer: A\nWhy: A conditional.',
    )!;

    bool accepts(String raw) => AiQuestionGenerator.accepts(
      verdict: PracticeResponseParser.quizCheck(raw),
      question: question,
    );

    const onlyA = 'A: FITS\nB: NO\nC: NO\nD: NO';

    test('agreement on every count keeps the question', () {
      expect(accepts('A\nSOUND\n$onlyA'), isTrue);
    });

    test('a different answer drops it, however confident the verdict', () {
      expect(accepts('B\nSOUND\n$onlyA'), isFalse);
    });

    test('a matching answer does not rescue an unsound question', () {
      expect(accepts('A\nUNSOUND\n$onlyA'), isFalse);
    });

    test('a second option that also fits drops the question', () {
      // 「今日は暑い＿＿。」 with both ね and です in the options, from the
      // device. The judge's own answer was right and the question was still
      // unusable, which is exactly what asking only for that answer cannot
      // see.
      expect(
        accepts('A\nSOUND\nA: FITS\nB: FITS\nC: NO\nD: NO'),
        isFalse,
      );
    });

    test('the one option that fits has to be the answer', () {
      expect(
        accepts('A\nSOUND\nA: NO\nB: FITS\nC: NO\nD: NO'),
        isFalse,
      );
    });

    test('no option fitting drops it too', () {
      expect(accepts('A\nSOUND\nA: NO\nB: NO\nC: NO\nD: NO'), isFalse);
    });

    test('a verdict that cannot be read is a no', () {
      for (final raw in const [
        '',
        'Looks fine to me.',
        'A',
        'A\nmaybe',
        'A\nSOUND',
        'E\nSOUND\nA: FITS\nB: NO\nC: NO\nD: NO',
        // A rating short of four is a reply that did not do what was asked,
        // and the missing one cannot be guessed without inventing the fact it
        // exists to establish.
        'A\nSOUND\nA: FITS\nB: NO\nC: NO',
        'A\nSOUND\nA: FITS\nA: NO\nC: NO\nD: NO',
        'A\nSOUND\nA: maybe\nB: NO\nC: NO\nD: NO',
      ]) {
        expect(accepts(raw), isFalse, reason: 'accepted "$raw"');
      }
    });

    test('the ratings are read in whatever order they arrive', () {
      expect(accepts('A\nSOUND\nD: NO\nB: NO\nA: FITS\nC: NO'), isTrue);
    });

    test('the letter and the word survive ordinary decoration', () {
      // Refusing over a full stop would throw away a sound question, which is
      // the one cost this check is not allowed to have.
      expect(accepts('A.\nSOUND.\nA：FITS\nB: no\nC: NO\nD: NO'), isTrue);
    });
  });

  group('the parse filter', () {
    // The analyser reads the sentence before a second model call is spent on
    // it. Everything it checks is something the app already knows, and the
    // sentence it rejects is the one from the device: a blank any noun could
    // fill, under a grammar point that is nowhere in it.
    final question = AiQuestionGenerator.parse(
      'Q: 雨が降＿＿行きません。\n'
      'A: ったら\nB: ったり\nC: っては\nD: ってから\n'
      'Answer: A\nWhy: A conditional.',
      point: point,
    )!;

    SentenceAnalysis analysisOf(
      String input, {
      bool unknown = false,
      bool matches = false,
    }) => SentenceAnalysis(
      input: input,
      normalized: input,
      tokens: [
        Token(
          surface: input,
          lemma: input,
          reading: input,
          category: unknown ? TokenCategory.unknown : TokenCategory.noun,
          start: 0,
          end: input.length,
        ),
      ],
      chunks: const [],
      grammar: matches
          ? [GrammarMatch(pointId: point.id, first: 0, last: 0)]
          : const [],
      issues: const [],
    );

    bool passes(SentenceAnalysis Function(String) analyze) =>
        AiQuestionGenerator.passesParseFilter(
          question,
          point: point,
          analyze: analyze,
        );

    test('the answer sentence must parse and carry the point', () {
      expect(
        passes(
          (s) => analysisOf(s, matches: s.contains('降ったら')),
        ),
        isTrue,
      );
    });

    test('a sentence the analyser cannot read is dropped', () {
      // Not because the model is wrong, but because the app could not explain
      // that sentence afterwards either.
      expect(
        passes(
          (s) => analysisOf(
            s,
            unknown: s.contains('降ったら'),
            matches: s.contains('降ったら'),
          ),
        ),
        isFalse,
      );
    });

    test('an answer that does not use the point is dropped', () {
      expect(passes(analysisOf), isFalse);
    });

    test('a distractor that also carries the point is a second answer', () {
      expect(
        passes(
          (s) => analysisOf(
            s,
            matches: s.contains('降ったら') || s.contains('降ったり'),
          ),
        ),
        isFalse,
      );
    });

    test('a point with no matchable form leaves the judging to the model', () {
      // A one-character particle carries no derived match form, because a form
      // that short matches nearly every sentence in the catalog. 〜ね is the
      // point the device complaint was about, so this is not a hypothetical:
      // nothing here can decide such a question, and it goes forward on the
      // unknown-token test alone for the model to rule on.
      final particle = GrammarPoint(
        id: 'grammar:ne',
        level: JlptLevel.n5,
        pattern: '〜ね',
        meaning: const LocalizedStrings({
          'en': ['seeking agreement'],
        }),
        explanation: const LocalizedStrings({
          'en': ['A sentence-final particle.'],
        }),
        examples: const [],
      );
      expect(effectiveMatchForms(particle), isEmpty);
      expect(
        AiQuestionGenerator.passesParseFilter(
          question,
          point: particle,
          analyze: analysisOf,
        ),
        isTrue,
      );
    });
  });
}
