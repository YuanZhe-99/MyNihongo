import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/progress/models/study_record.dart';
import 'package:my_nihongo/features/progress/services/sm2_scheduler.dart';

/// Purpose: Test the spaced-repetition scheduler.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: Pure, so every case is exact rather than approximate. The two
/// departures from textbook SM-2 are asserted directly, because they are
/// judgement calls that a later change could silently undo: the interval
/// sequence starts 1, 6 before ease is trusted at all, and a wrong answer
/// costs 0.20 of ease rather than 0.54 — with binary grading the textbook
/// penalty pins an item to the floor after three mistakes and it never
/// recovers, however well the learner then does.
void main() {
  const scheduler = Sm2Scheduler();
  final now = DateTime.utc(2026, 9, 3, 12);

  StudyRecord fresh() => StudyRecord.create('vocab:test', now: now);

  StudyRecord answer(
    StudyRecord record,
    bool correct, {
    DateTime? at,
  }) => scheduler.apply(record, correct: correct, now: at ?? now);

  test('the first correct answer schedules one day out', () {
    final result = answer(fresh(), true);
    expect(result.correct, 1);
    expect(result.streak, 1);
    expect(result.intervalDays, 1);
    expect(result.ease, defaultStudyEase);
    expect(result.dueAt, now.add(const Duration(days: 1)));
    expect(result.lastReviewedAt, now);
  });

  test('the second correct answer jumps to six days', () {
    final result = answer(answer(fresh(), true), true);
    expect(result.streak, 2);
    expect(result.intervalDays, 6);
  });

  test('from the third answer the interval multiplies by ease', () {
    var record = answer(answer(fresh(), true), true);
    record = answer(record, true);
    // Third correct answer earns the streak bonus: ease 2.6, 6 × 2.6 = 15.6.
    expect(record.ease, closeTo(2.6, 1e-9));
    expect(record.intervalDays, 16);
    expect(record.streak, 3);
  });

  test('a correct answer below the bonus streak leaves ease alone', () {
    final result = answer(fresh(), true);
    expect(result.ease, defaultStudyEase);
    expect(answer(result, true).ease, defaultStudyEase);
  });

  test('a wrong answer resets the interval and the streak but not the count', () {
    var record = answer(answer(answer(fresh(), true), true), true);
    expect(record.intervalDays, greaterThan(6));
    record = answer(record, false);
    expect(record.streak, 0);
    expect(record.intervalDays, 1);
    expect(record.wrong, 1);
    expect(record.correct, 3, reason: 'lifetime counts are never rolled back');
    expect(record.dueAt, now.add(const Duration(days: 1)));
  });

  test('a wrong answer costs 0.20 of ease, not the textbook 0.54', () {
    final result = answer(fresh(), false);
    expect(result.ease, closeTo(2.3, 1e-9));
  });

  test('ease never falls below the floor however many mistakes are made', () {
    var record = fresh();
    for (var i = 0; i < 20; i++) {
      record = answer(record, false);
    }
    expect(record.ease, minStudyEase);
    expect(record.intervalDays, 1);
  });

  test('an item at the floor still recovers with correct answers', () {
    var record = fresh();
    for (var i = 0; i < 20; i++) {
      record = answer(record, false);
    }
    for (var i = 0; i < 5; i++) {
      record = answer(record, true);
    }
    // The point of the softened penalty: the item leaves daily review again.
    expect(record.ease, greaterThan(minStudyEase));
    expect(record.intervalDays, greaterThan(6));
  });

  test('an interval is never scheduled beyond a year', () {
    var record = fresh();
    for (var i = 0; i < 30; i++) {
      record = answer(record, true, at: now.add(Duration(days: i)));
    }
    expect(record.intervalDays, maxIntervalDays);
    expect(record.dueAt, isNotNull);
  });

  test('the stage follows the interval it schedules', () {
    var record = fresh();
    expect(record.stage, StudyStage.fresh);
    record = answer(record, true);
    expect(record.stage, StudyStage.learning);
    for (var i = 0; i < 4; i++) {
      record = answer(record, true);
    }
    expect(record.intervalDays, greaterThanOrEqualTo(masteredIntervalDays));
    expect(record.stage, StudyStage.mastered);
  });

  test('every timestamp it writes is UTC', () {
    final result = scheduler.apply(
      fresh(),
      correct: true,
      now: DateTime(2026, 9, 3, 12),
    );
    expect(result.dueAt!.isUtc, isTrue);
    expect(result.lastReviewedAt!.isUtc, isTrue);
    expect(result.modifiedAt.isUtc, isTrue);
  });

  test('unknown fields on the record survive being scheduled', () {
    final record = StudyRecord(
      id: 'vocab:test',
      createdAt: now,
      modifiedAt: now,
      extraJson: const {'fromANewerBuild': 42},
    );
    expect(answer(record, true).extraJson['fromANewerBuild'], 42);
  });
}
