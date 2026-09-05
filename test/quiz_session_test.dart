import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/quiz/models/quiz_question.dart';
import 'package:my_nihongo/features/quiz/services/answer_checker.dart';
import 'package:my_nihongo/features/quiz/services/quiz_session.dart';

/// Purpose: Test how a session marks, re-queues and scores.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: Two rules carry the weight. **Only the first answer to an item is
/// recorded**, because SM-2 grades recall and an item answered right on the
/// third try within one minute was not recalled. And a wrong item **comes back
/// within the session** but only twice, or one stubborn item would keep a
/// session open forever.
void main() {
  QuizQuestion choice(String id, {int answer = 0}) => QuizQuestion(
    itemId: id,
    mode: QuizMode.vocabJaToMeaning,
    kind: AnswerKind.choice,
    prompt: id,
    options: const ['a', 'b', 'c', 'd'],
    answerIndex: answer,
  );

  test('a right answer is reported and recorded once', () {
    final recorded = <String, bool>{};
    final session = QuizSession(
      questions: [choice('vocab:1')],
      onFirstAnswer: (id, correct) => recorded[id] = correct,
    );

    final outcome = session.answer(const ChoiceAnswer(0));
    expect(outcome.correct, isTrue);
    expect(recorded, {'vocab:1': true});
    expect(session.lastOutcome?.correct, isTrue);
  });

  test('a wrong answer carries the right one for the learner to see', () {
    final session = QuizSession(questions: [choice('vocab:1', answer: 2)]);
    final outcome = session.answer(const ChoiceAnswer(0));
    expect(outcome.correct, isFalse);
    expect(outcome.expected, 'c');
  });

  test('the question stays until the learner moves on', () {
    final session = QuizSession(questions: [choice('vocab:1')]);
    session.answer(const ChoiceAnswer(0));
    expect(session.current, isNotNull, reason: 'the feedback is still showing');
    session.next();
    expect(session.isFinished, isTrue);
  });

  test('a wrong item comes back later in the session', () {
    final session = QuizSession(
      questions: [choice('vocab:1', answer: 1), choice('vocab:2')],
    );
    session.answer(const ChoiceAnswer(0));
    session.next();
    expect(session.current?.itemId, 'vocab:2');
    session.answer(const ChoiceAnswer(0));
    session.next();
    expect(
      session.current?.itemId,
      'vocab:1',
      reason: 'the item answered wrongly is asked again',
    );
  });

  test('only the first answer to an item is recorded', () {
    final recorded = <(String, bool)>[];
    final session = QuizSession(
      questions: [choice('vocab:1', answer: 1)],
      onFirstAnswer: (id, correct) => recorded.add((id, correct)),
    );

    session.answer(const ChoiceAnswer(0));
    session.next();
    session.answer(const ChoiceAnswer(1));
    session.next();

    expect(
      recorded,
      [('vocab:1', false)],
      reason: 'getting it right on the retry does not mean it was recalled',
    );
  });

  test('a stubborn item stops coming back after two retries', () {
    final session = QuizSession(questions: [choice('vocab:1', answer: 1)]);
    for (var i = 0; i < 6; i++) {
      if (session.isFinished) break;
      session.answer(const ChoiceAnswer(0));
      session.next();
    }
    expect(
      session.isFinished,
      isTrue,
      reason: 'a session with one unanswerable item still ends',
    );
    expect(session.attempts, maxRequeues + 1);
  });

  test('the score is over first answers, not over attempts', () {
    final session = QuizSession(
      questions: [
        choice('vocab:1'),
        choice('vocab:2', answer: 1),
        choice('vocab:3'),
      ],
    );
    session.answer(const ChoiceAnswer(0));
    session.next();
    session.answer(const ChoiceAnswer(0));
    session.next();
    session.answer(const ChoiceAnswer(0));
    session.next();

    final summary = session.summary;
    expect(summary.total, 3);
    expect(summary.firstTryCorrect, 2);
    expect(summary.wrongIds, ['vocab:2']);
    expect(summary.accuracy, closeTo(2 / 3, 1e-9));
  });

  test('a typed answer accepts either script of the reading', () {
    const question = QuizQuestion(
      itemId: 'vocab:1',
      mode: QuizMode.vocabTypeReading,
      kind: AnswerKind.typed,
      prompt: '会う',
      acceptedAnswers: {'あう', 'au'},
    );
    final session = QuizSession(questions: [question]);
    expect(session.answer(const TypedAnswer(' あう ')).correct, isTrue);

    final second = QuizSession(questions: [question]);
    expect(second.answer(const TypedAnswer('AU')).correct, isTrue);

    final third = QuizSession(questions: [question]);
    expect(third.answer(const TypedAnswer('あお')).correct, isFalse);
  });

  test('katakana and long vowels normalize to the same reading', () {
    const question = QuizQuestion(
      itemId: 'vocab:1',
      mode: QuizMode.vocabTypeReading,
      kind: AnswerKind.typed,
      prompt: 'コーヒー',
      acceptedAnswers: {'こおひい'},
    );
    final session = QuizSession(questions: [question]);
    expect(session.answer(const TypedAnswer('コーヒー')).correct, isTrue);
  });

  test('an empty typed answer is wrong rather than accepted', () {
    const question = QuizQuestion(
      itemId: 'vocab:1',
      mode: QuizMode.vocabTypeReading,
      kind: AnswerKind.typed,
      prompt: '会う',
      acceptedAnswers: {'あう'},
    );
    final session = QuizSession(questions: [question]);
    expect(session.answer(const TypedAnswer('   ')).correct, isFalse);
  });

  test('an ordering is right only in the intended order', () {
    // Options are shuffled, so answerOrder says where each one belongs.
    const question = QuizQuestion(
      itemId: 'grammar:1',
      mode: QuizMode.grammarOrder,
      kind: AnswerKind.order,
      prompt: 'This is a book.',
      options: ['です', 'これは', '本'],
      answerOrder: [2, 0, 1],
    );
    final right = QuizSession(questions: [question]);
    expect(right.answer(const OrderAnswer([1, 2, 0])).correct, isTrue);

    final wrong = QuizSession(questions: [question]);
    final outcome = wrong.answer(const OrderAnswer([0, 1, 2]));
    expect(outcome.correct, isFalse);
    expect(outcome.expected, 'これは本です');
  });

  test('a partial ordering is not a correct one', () {
    const question = QuizQuestion(
      itemId: 'grammar:1',
      mode: QuizMode.grammarOrder,
      kind: AnswerKind.order,
      prompt: 'This is a book.',
      options: ['です', 'これは', '本'],
      answerOrder: [2, 0, 1],
    );
    final session = QuizSession(questions: [question]);
    expect(session.answer(const OrderAnswer([1])).correct, isFalse);
  });

  test('a session with nothing in it finishes immediately', () {
    final session = QuizSession(questions: const []);
    expect(session.isFinished, isTrue);
    expect(session.summary.total, 0);
    expect(session.summary.accuracy, 0);
  });
  test('skipping a question removes it and shortens the session', () {
    final session = QuizSession(questions: [choice('a'), choice('b')]);
    expect(session.total, 2);

    session.skip();

    expect(session.current?.itemId, 'b');
    expect(
      session.total,
      1,
      reason: 'the progress line counts what will actually be asked',
    );
    expect(session.answeredCount, 0);
    expect(session.summary.wrongIds, isEmpty);
  });

  test('a skipped question never comes back', () {
    final session = QuizSession(questions: [choice('a'), choice('b')]);
    session.skip();
    session.answer(const ChoiceAnswer(0));
    session.next();
    expect(session.isFinished, isTrue);
  });

  test('skipping records nothing for the scheduler', () {
    final recorded = <String>[];
    final session = QuizSession(
      questions: [choice('a'), choice('b')],
      onFirstAnswer: (id, _) => recorded.add(id),
    );
    session.skip();
    expect(recorded, isEmpty, reason: 'a declined question is not a wrong one');
  });

  test('skipping the last question finishes the session', () {
    final session = QuizSession(questions: [choice('a')]);
    session.skip();
    expect(session.isFinished, isTrue);
    expect(session.total, 0);
  });

  group('a paper rather than a practice run', () {
    // A drill question carries its own id because a paper asks several
    // different questions about one word. Everything in this group follows
    // from that one difference.
    QuizQuestion drill(String id, String item, {int answer = 0}) =>
        QuizQuestion(
          itemId: item,
          questionId: id,
          mode: QuizMode.drill,
          kind: AnswerKind.choice,
          prompt: id,
          options: const ['a', 'b', 'c', 'd'],
          answerIndex: answer,
        );

    test('two questions about one word are two questions', () {
      final session = QuizSession(
        questions: [
          drill('q:1', 'vocab:1'),
          drill('q:2', 'vocab:1', answer: 1),
        ],
      );
      session.answer(const ChoiceAnswer(0));
      session.next();
      expect(
        session.current?.questionId,
        'q:2',
        reason: 'the second question about the word is still to be asked',
      );
      session.answer(const ChoiceAnswer(0));
      session.next();
      expect(session.summary.total, 2);
      expect(session.summary.firstTryCorrect, 1);
    });

    test('but the scheduler hears about the word once', () {
      // SM-2 grades one recall. The second question about a word was primed
      // by the first, so it says nothing about how well the word was known.
      final calls = <(String, bool)>[];
      final session = QuizSession(
        questions: [
          drill('q:1', 'vocab:1'),
          drill('q:2', 'vocab:1', answer: 1),
        ],
        onFirstAnswer: (id, correct) => calls.add((id, correct)),
      );
      session.answer(const ChoiceAnswer(0));
      session.next();
      session.answer(const ChoiceAnswer(0));
      session.next();
      expect(calls, [('vocab:1', true)]);
    });

    test('a word got wrong twice is named once in the review list', () {
      final session = QuizSession(
        questions: [
          drill('q:1', 'vocab:1', answer: 1),
          drill('q:2', 'vocab:1', answer: 1),
        ],
        requeue: false,
      );
      session.answer(const ChoiceAnswer(0));
      session.next();
      session.answer(const ChoiceAnswer(0));
      session.next();
      expect(
        session.summary.wrongIds,
        ['vocab:1'],
        reason: 'the same word four times is a worse list, not a louder one',
      );
    });

    test('a paper does not ask a question again because it was wrong', () {
      // A mock whose length depended on how well it was going could not be
      // scored against a fixed composition, and the clock would be measuring
      // a different paper for every learner.
      final session = QuizSession(
        questions: [drill('q:1', 'vocab:1', answer: 1)],
        requeue: false,
      );
      session.answer(const ChoiceAnswer(0));
      session.next();
      expect(session.isFinished, isTrue);
      expect(session.total, 1);
    });

    test('the outcomes are one per question, in the order asked', () {
      final session = QuizSession(
        questions: [
          drill('q:1', 'vocab:1'),
          drill('q:2', 'vocab:2', answer: 1),
        ],
        requeue: false,
      );
      session.answer(const ChoiceAnswer(0));
      session.next();
      session.answer(const ChoiceAnswer(0));
      session.next();
      expect(session.outcomes.map((o) => o.key), ['q:1', 'q:2']);
      expect(session.outcomes.map((o) => o.itemId), ['vocab:1', 'vocab:2']);
      expect(session.outcomes.map((o) => o.correct), [true, false]);
      expect(session.outcomes.every((o) => o.answered), isTrue);
    });

    test('a re-queued question is one outcome, not three', () {
      final session = QuizSession(questions: [choice('vocab:1', answer: 1)]);
      for (var i = 0; i < 3; i++) {
        if (session.isFinished) break;
        session.answer(const ChoiceAnswer(0));
        session.next();
      }
      expect(session.outcomes, hasLength(1));
      expect(session.outcomes.single.correct, isFalse);
    });
  });

  group('running out of time', () {
    test('what was left is recorded unanswered, not wrong', () {
      // Calling it wrong would make the learner look worse than they are;
      // hiding it would make every timed score look better than it was.
      final calls = <String>[];
      final session = QuizSession(
        questions: [choice('vocab:1'), choice('vocab:2'), choice('vocab:3')],
        onFirstAnswer: (id, _) => calls.add(id),
        requeue: false,
      );
      session.answer(const ChoiceAnswer(0));
      session.next();
      session.forfeit();

      expect(session.isFinished, isTrue);
      expect(session.outcomes, hasLength(3));
      expect(session.outcomes[0].answered, isTrue);
      expect(session.outcomes[1].answered, isFalse);
      expect(session.outcomes[2].answered, isFalse);
      expect(session.outcomes[1].correct, isFalse);
      expect(calls, [
        'vocab:1',
      ], reason: 'an unanswered question says nothing about recall');
    });

    test('forfeiting an already finished session changes nothing', () {
      final session = QuizSession(questions: [choice('vocab:1')]);
      session.answer(const ChoiceAnswer(0));
      session.next();
      session.forfeit();
      expect(session.outcomes, hasLength(1));
      expect(session.outcomes.single.answered, isTrue);
    });
  });

  group('resuming a saved paper', () {
    test('saved answers are replayed and the rest is where it was left', () {
      final session = QuizSession(
        questions: [
          choice('vocab:1'),
          choice('vocab:2', answer: 1),
          choice('vocab:3'),
        ],
        requeue: false,
      );
      session.restore(const {
        'vocab:1': ChoiceAnswer(0),
        'vocab:2': ChoiceAnswer(0),
      });
      expect(session.current?.itemId, 'vocab:3');
      expect(session.answeredCount, 2);
      expect(session.summary.firstTryCorrect, 1);
      expect(session.summary.wrongIds, ['vocab:2']);
    });

    test('a save with nothing in it leaves the paper untouched', () {
      final session = QuizSession(questions: [choice('vocab:1')]);
      session.restore(const {});
      expect(session.current?.itemId, 'vocab:1');
      expect(session.answeredCount, 0);
    });

    test('replaying stops at the first question the save does not cover', () {
      // Which is what "resume" means: the questions after the gap are still
      // to be answered, not silently skipped.
      final session = QuizSession(
        questions: [choice('vocab:1'), choice('vocab:2'), choice('vocab:3')],
        requeue: false,
      );
      session.restore(const {
        'vocab:1': ChoiceAnswer(0),
        'vocab:3': ChoiceAnswer(0),
      });
      expect(session.current?.itemId, 'vocab:2');
      expect(session.answeredCount, 1);
    });
  });
}
