import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/models/grammar_point.dart';
import 'package:my_nihongo/features/content/models/jlpt_level.dart';
import 'package:my_nihongo/features/content/models/localized_strings.dart';
import 'package:my_nihongo/features/ai/services/practice_response_parser.dart';
import 'package:my_nihongo/features/quiz/models/quiz_question.dart';
import 'package:my_nihongo/features/quiz/services/ai_question_generator.dart';

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

    test('agreement on both counts keeps the question', () {
      expect(accepts('A\nSOUND'), isTrue);
    });

    test('a different answer drops it, however confident the verdict', () {
      expect(accepts('B\nSOUND'), isFalse);
    });

    test('a matching answer does not rescue an unsound question', () {
      expect(accepts('A\nUNSOUND'), isFalse);
    });

    test('a verdict that cannot be read is a no', () {
      for (final raw in const [
        '',
        'Looks fine to me.',
        'A',
        'A\nmaybe',
        'E\nSOUND',
      ]) {
        expect(accepts(raw), isFalse, reason: 'accepted "$raw"');
      }
    });

    test('the letter and the word survive ordinary decoration', () {
      // Refusing over a full stop would throw away a sound question, which is
      // the one cost this check is not allowed to have.
      expect(accepts('A.\nSOUND.'), isTrue);
    });
  });
}
