import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/drills/models/drill_file.dart';
import 'package:my_nihongo/features/drills/models/drill_section.dart';
import 'package:my_nihongo/features/drills/services/exam_session.dart';
import 'package:my_nihongo/features/quiz/models/quiz_question.dart';
import 'package:my_nihongo/features/quiz/services/answer_checker.dart';
import 'package:my_nihongo/features/quiz/services/quiz_session.dart';

/// Purpose: Test the clock, the block order, and what a saved paper keeps.
/// Inputs: None.
/// Returns: None.
/// Side effects: None — the clock is injected.
/// Notes: The rule the whole file turns on is that **time is counted only
/// while the block is on screen**. A learner who takes a phone call has not
/// spent that time on the paper, and one who leaves it overnight has not lost
/// the paper. Every other property here — resume, the deadline, the save —
/// falls out of that one.
void main() {
  QuizQuestion question(String id, {int answer = 0}) => QuizQuestion(
    itemId: 'vocab:one',
    questionId: id,
    mode: QuizMode.drill,
    kind: AnswerKind.choice,
    prompt: id,
    options: const ['a', 'b', 'c', 'd'],
    answerIndex: answer,
  );

  /// A clock the test moves by hand.
  late DateTime now;
  DateTime clock() => now;

  setUp(() => now = DateTime.utc(2026, 9, 5, 10));

  ExamSession examOf({
    int blocks = 2,
    int questionsPerBlock = 2,
    Duration limit = const Duration(minutes: 10),
  }) => ExamSession(
    level: 'N5',
    scale: ExamScale.short,
    clock: clock,
    blocks: [
      for (var b = 0; b < blocks; b++)
        ExamBlock(
          index: b,
          sections: [b == 0 ? DrillSection.vocab : DrillSection.grammar],
          limit: limit,
          session: QuizSession(
            questions: [
              for (var q = 0; q < questionsPerBlock; q++) question('q:b$b-$q'),
            ],
            requeue: false,
          ),
        ),
    ],
  );

  group('the clock', () {
    test('does not run until the block is started', () {
      final exam = examOf();
      expect(exam.betweenBlocks, isTrue);
      now = now.add(const Duration(minutes: 5));
      expect(
        exam.remaining,
        const Duration(minutes: 10),
        reason:
            'a paper that began counting while the start card was on '
            'screen would be a worse exam than the real one',
      );
    });

    test('runs once the block is started', () {
      final exam = examOf()..resumeClock();
      now = now.add(const Duration(minutes: 3));
      expect(exam.remaining, const Duration(minutes: 7));
      expect(exam.betweenBlocks, isFalse);
      exam.dispose();
    });

    test(
      'stops when the block leaves the screen and picks up where it was',
      () {
        final exam = examOf()..resumeClock();
        now = now.add(const Duration(minutes: 3));
        exam.pauseClock();
        now = now.add(const Duration(hours: 8));
        expect(
          exam.remaining,
          const Duration(minutes: 7),
          reason: 'the clock measures attention, not wall-clock hours',
        );
        exam.resumeClock();
        now = now.add(const Duration(minutes: 2));
        expect(exam.remaining, const Duration(minutes: 5));
        exam.dispose();
      },
    );

    test('resuming twice does not make the paper shorter', () {
      // A lifecycle callback can fire more than once.
      final exam = examOf()..resumeClock();
      now = now.add(const Duration(minutes: 2));
      exam.resumeClock();
      now = now.add(const Duration(minutes: 2));
      expect(exam.remaining, const Duration(minutes: 6));
      exam.dispose();
    });

    test('never counts below zero', () {
      final exam = examOf()..resumeClock();
      now = now.add(const Duration(hours: 3));
      expect(exam.remaining, Duration.zero);
      exam.dispose();
    });
  });

  group('the deadline', () {
    test('hands the block in and moves to the next', () {
      final exam = examOf()..resumeClock();
      now = now.add(const Duration(minutes: 11));
      expect(exam.checkDeadline(), isTrue);
      expect(exam.blocks[0].submitted, isTrue);
      expect(exam.currentIndex, 1);
      expect(
        exam.betweenBlocks,
        isTrue,
        reason:
            'the next block is not on '
            'the clock until the learner has looked at it',
      );
      exam.dispose();
    });

    test('records what was left as unanswered, not as wrong', () {
      final exam = examOf()..resumeClock();
      exam.current!.session.answer(const ChoiceAnswer(0));
      exam.current!.session.next();
      now = now.add(const Duration(minutes: 11));
      exam.checkDeadline();

      final outcomes = exam.blocks[0].session.outcomes;
      expect(outcomes, hasLength(2));
      expect(outcomes[0].answered, isTrue);
      expect(outcomes[1].answered, isFalse);
      expect(outcomes[1].correct, isFalse);
      exam.dispose();
    });

    test('is not tripped early', () {
      final exam = examOf()..resumeClock();
      now = now.add(const Duration(minutes: 9, seconds: 59));
      expect(exam.checkDeadline(), isFalse);
      exam.dispose();
    });

    test('a paper whose last block expires is finished', () {
      final exam = examOf(blocks: 1)..resumeClock();
      now = now.add(const Duration(minutes: 11));
      exam.checkDeadline();
      expect(exam.isFinished, isTrue);
      exam.dispose();
    });
  });

  test('a block whose questions run out is handed in early', () {
    // The real paper allows this too, and the recorded time is then the time
    // actually spent rather than the limit.
    final exam = examOf(questionsPerBlock: 1)..resumeClock();
    now = now.add(const Duration(minutes: 2));
    exam.current!.session.answer(const ChoiceAnswer(0));
    exam.current!.session.next();
    exam.finishBlockEarly();
    expect(exam.blocks[0].submitted, isTrue);
    expect(exam.blocks[0].usedBefore, const Duration(minutes: 2));
    expect(exam.currentIndex, 1);
    exam.dispose();
  });

  test('pausing for a dialog does not send the block to its start card', () {
    // The clock stops every time the page shows a dialog or the app is
    // backgrounded. A block that fell back to its start card each time would
    // look to the learner as though the paper had been thrown away — which is
    // exactly what the device showed before `started` was separated from "the
    // clock is running".
    final exam = examOf()..resumeClock();
    expect(exam.betweenBlocks, isFalse);
    exam.pauseClock();
    expect(exam.betweenBlocks, isFalse);
    expect(exam.blocks[0].started, isTrue);
    exam.dispose();
  });

  test('a started block is still started after a save and a reload', () {
    final exam = examOf()..resumeClock();
    final saved = SavedExam.fromJson(exam.toJson())!;
    expect(saved.blocks[0].started, isTrue);
    expect(
      saved.blocks[1].started,
      isFalse,
      reason: 'a block nobody has opened still needs its start card',
    );
    exam.dispose();
  });

  group('the save', () {
    test('writes the questions by id and the answers as chosen', () {
      final exam = examOf()..resumeClock();
      exam.current!.session.answer(const ChoiceAnswer(2));
      exam.current!.session.next();
      now = now.add(const Duration(minutes: 4));

      final json = exam.toJson();
      expect(json['v'], examSaveVersion);
      expect(json['level'], 'N5');
      expect(json['blockIndex'], 0);
      final blocks = json['blocks'] as List;
      expect(blocks, hasLength(2));
      final first = blocks[0] as Map;
      expect(first['questionIds'], ['q:b0-0', 'q:b0-1']);
      expect(first['answers'], {
        'q:b0-0': {'index': 2},
      });
      expect(
        first['usedSecs'],
        240,
        reason: 'a save taken mid-block records the time actually spent',
      );
      exam.dispose();
    });

    test('a typed answer is not written, because no 大問 asks for one', () {
      final session = QuizSession(
        questions: [
          QuizQuestion(
            itemId: 'vocab:one',
            questionId: 'q:typed',
            mode: QuizMode.drill,
            kind: AnswerKind.typed,
            prompt: 'x',
            acceptedAnswers: const {'a'},
          ),
        ],
        requeue: false,
      )..answer(const TypedAnswer('a'));
      expect(ExamSession.encodeAnswer(session.chosen['q:typed']!), isNull);
    });

    test('an ordering answer round-trips', () {
      const answer = OrderAnswer([2, 0, 1, 3]);
      final encoded = ExamSession.encodeAnswer(answer)!;
      final decoded = ExamSession.decodeAnswer(encoded);
      expect(decoded, isA<OrderAnswer>());
      expect((decoded! as OrderAnswer).order, [2, 0, 1, 3]);
    });

    test('an answer that cannot be read is dropped, not guessed', () {
      expect(ExamSession.decodeAnswer(null), isNull);
      expect(ExamSession.decodeAnswer('two'), isNull);
      expect(ExamSession.decodeAnswer({'index': 'two'}), isNull);
      expect(
        ExamSession.decodeAnswer({
          'order': [0, 'x'],
        }),
        isNull,
      );
    });
  });

  group('reading a save back', () {
    Map<String, dynamic> saveOf({int version = examSaveVersion}) {
      final exam = examOf()..resumeClock();
      exam.current!.session.answer(const ChoiceAnswer(1));
      exam.current!.session.next();
      now = now.add(const Duration(minutes: 4));
      final json = exam.toJson();
      exam.dispose();
      return {...json, 'v': version};
    }

    test('everything the paper needs comes back', () {
      final saved = SavedExam.fromJson(saveOf())!;
      expect(saved.level, 'N5');
      expect(saved.scale, 'short');
      expect(saved.blockIndex, 0);
      expect(saved.blocks, hasLength(2));
      expect(saved.blocks[0].questionIds, ['q:b0-0', 'q:b0-1']);
      expect(saved.blocks[0].answers['q:b0-0'], isA<ChoiceAnswer>());
      expect(saved.remaining, const Duration(minutes: 6));
    });

    test('a save from a newer build is refused rather than half-read', () {
      // An exam resumed from a file only partly understood would be scored
      // against questions it could not reconstruct.
      expect(SavedExam.fromJson(saveOf(version: examSaveVersion + 1)), isNull);
    });

    test('anything unreadable is no saved paper at all', () {
      expect(SavedExam.fromJson(null), isNull);
      expect(SavedExam.fromJson('{}'), isNull);
      expect(SavedExam.fromJson({'v': examSaveVersion}), isNull);
      expect(
        SavedExam.fromJson({
          'v': examSaveVersion,
          'level': 'N5',
          'startedAt': '2026-09-05T10:00:00.000Z',
          'blocks': <Object>[],
        }),
        isNull,
      );
    });

    test('a block index past the end falls back to the first block', () {
      final saved = SavedExam.fromJson({...saveOf(), 'blockIndex': 9})!;
      expect(saved.blockIndex, 0);
    });
  });

  test('replaying a save restores the score, not the verdict', () {
    // The answers are re-marked against the files as they are now, so a
    // content update that corrected an answer key corrects the resumed paper.
    final session = QuizSession(
      questions: [question('q:1'), question('q:2', answer: 1)],
      requeue: false,
    );
    session.restore(const {'q:1': ChoiceAnswer(0), 'q:2': ChoiceAnswer(0)});
    expect(session.outcomes.map((o) => o.correct), [true, false]);
    expect(session.isFinished, isTrue);
  });
}
