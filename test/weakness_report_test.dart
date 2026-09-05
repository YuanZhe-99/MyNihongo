import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/models/localized_strings.dart';
import 'package:my_nihongo/features/drills/models/drill_file.dart';
import 'package:my_nihongo/features/drills/models/drill_section.dart';
import 'package:my_nihongo/features/drills/services/weakness_report.dart';
import 'package:my_nihongo/features/progress/models/exam_attempt.dart';
import 'package:my_nihongo/features/quiz/models/quiz_question.dart';

/// Purpose: Test the weakness report — what it counts, what it refuses to
/// count, and how far back it looks.
/// Inputs: None.
/// Returns: None.
/// Side effects: None; every test here is pure.
/// Notes: Two rules carry the weight and both are about honesty rather than
/// arithmetic. **An unanswered question is not a wrong one** — the clock took
/// it away, and reading a time-out as a gap in the learner's Japanese would
/// send them to study the wrong thing. And **the window is the last few
/// attempts**, so a weakness the learner has actually fixed disappears instead
/// of following them around.

/// Purpose: Build one drill question for a fixture.
/// Inputs: `id`, its `type`, and the catalog `items` it is attributed to.
/// Returns: `DrillQuestion`.
/// Side effects: None.
/// Notes: Internal helper used within this test file only.
DrillQuestion question(
  String id,
  DrillType type, {
  List<String> items = const ['vocab:a'],
}) => DrillQuestion(
  id: id,
  type: type,
  items: items,
  kind: AnswerKind.choice,
  prompt: const LocalizedStrings({
    'en': ['q'],
    'zh': ['q'],
  }),
  options: const ['a', 'b', 'c', 'd'],
  answer: 0,
);

/// Purpose: Build one attempt for a fixture.
/// Inputs: The `answers` map, the `level`, and `startedAt`.
/// Returns: `ExamAttempt`.
/// Side effects: None.
/// Notes: Internal helper used within this test file only.
ExamAttempt attempt(
  Map<String, int> answers, {
  String level = 'N5',
  DateTime? startedAt,
}) => ExamAttempt(
  id: 'exam:${answers.hashCode}',
  level: level,
  mode: ExamMode.mock,
  scale: 'short',
  startedAt: startedAt ?? DateTime.utc(2026, 9, 5),
  answers: answers,
);

void main() {
  final questions = {
    'q:v1': question('q:v1', DrillType.kanjiReading),
    'q:v2': question('q:v2', DrillType.kanjiReading, items: ['vocab:b']),
    'q:g1': question('q:g1', DrillType.formSelection, items: ['grammar:x']),
    'q:l1': question('q:l1', DrillType.task, items: ['vocab:a']),
  };

  test('an empty history is an empty report', () {
    expect(
      WeaknessReport.build(attempts: const [], questions: questions).isEmpty,
      isTrue,
    );
  });

  test('answers are tallied by section, by 大問 and by item', () {
    final report = WeaknessReport.build(
      attempts: [
        attempt({'q:v1': 1, 'q:v2': 0, 'q:g1': 0, 'q:l1': 1}),
      ],
      questions: questions,
    );

    expect(report.attempts, 1);
    expect(report.bySection[DrillSection.vocab]?.asked, 2);
    expect(report.bySection[DrillSection.vocab]?.right, 1);
    expect(report.bySection[DrillSection.grammar]?.right, 0);
    expect(report.bySection[DrillSection.listening]?.right, 1);
    expect(report.byType[DrillType.kanjiReading]?.asked, 2);
    // Two questions attributed to the same word are two data points about it.
    expect(report.byItem['vocab:a']?.asked, 2);
    expect(report.byItem['vocab:b']?.asked, 1);
  });

  test('an unanswered question counts as nothing at all', () {
    final report = WeaknessReport.build(
      attempts: [
        attempt({'q:v1': examUnanswered, 'q:v2': 1}),
      ],
      questions: questions,
    );

    expect(
      report.bySection[DrillSection.vocab]?.asked,
      1,
      reason: 'the clock took the question away; the learner did not fail it',
    );
    expect(report.byItem.containsKey('vocab:a'), isFalse);
  });

  test('a question the shipped files no longer have is skipped', () {
    final report = WeaknessReport.build(
      attempts: [
        attempt({'q:gone': 0, 'q:v1': 1}),
      ],
      questions: questions,
    );

    expect(report.bySection[DrillSection.vocab]?.asked, 1);
  });

  test('only the target level is counted', () {
    final report = WeaknessReport.build(
      attempts: [
        attempt({'q:v1': 0}, level: 'N4'),
        attempt({'q:v2': 1}),
      ],
      questions: questions,
      level: 'N5',
    );

    expect(report.attempts, 1);
    expect(report.bySection[DrillSection.vocab]?.right, 1);
  });

  test('only the most recent attempts are in the window', () {
    final report = WeaknessReport.build(
      attempts: [
        for (var i = 0; i < 8; i++) attempt({'q:v1': i < 2 ? 1 : 0}),
      ],
      questions: questions,
      recent: 2,
    );

    expect(report.attempts, 2);
    expect(
      report.bySection[DrillSection.vocab]?.right,
      2,
      reason: 'the six older papers are outside the window',
    );
  });

  test('a weakness needs to have been asked enough, and got wrong', () {
    final report = WeaknessReport.build(
      attempts: [
        attempt({'q:v1': 0}),
        attempt({'q:v1': 0}),
      ],
      questions: questions,
    );

    expect(
      report.weakestItems,
      isEmpty,
      reason: 'asked twice, below weaknessMinAsked',
    );

    final more = WeaknessReport.build(
      attempts: [
        attempt({'q:v1': 0}),
        attempt({'q:v1': 0}),
        attempt({'q:v1': 0, 'q:v2': 1}),
        attempt({'q:v2': 1}),
        attempt({'q:v2': 1}),
      ],
      questions: questions,
    );

    expect(more.weakestItems.map((e) => e.key), ['vocab:a']);
    expect(
      more.weakestItems.single.value.accuracy,
      0,
      reason: 'vocab:b was asked three times and never missed',
    );
  });

  test('the weakest come first, and ties break on the id', () {
    final report = WeaknessReport.build(
      attempts: [
        attempt({'q:v1': 0, 'q:v2': 0, 'q:g1': 0}),
        attempt({'q:v1': 0, 'q:v2': 1, 'q:g1': 1}),
        attempt({'q:v1': 0, 'q:v2': 1, 'q:g1': 1}),
      ],
      questions: questions,
    );

    expect(report.weakestItems.first.key, 'vocab:a');
    // vocab:b and grammar:x are both two in three, so only the id can order
    // them — and it must, or two builds could disagree about the list.
    expect(report.weakestItems.map((e) => e.key), [
      'vocab:a',
      'grammar:x',
      'vocab:b',
    ]);
  });

  test('prioritized ids are what the review queue is given', () {
    final report = WeaknessReport.build(
      attempts: [
        attempt({'q:v1': 0}),
        attempt({'q:v1': 0}),
        attempt({'q:v1': 0}),
      ],
      questions: questions,
    );

    expect(report.prioritizedIds(null), {'vocab:a'});
  });
}
