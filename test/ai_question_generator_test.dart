import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/models/grammar_point.dart';
import 'package:my_nihongo/features/content/models/jlpt_level.dart';
import 'package:my_nihongo/features/content/models/localized_strings.dart';
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
}
