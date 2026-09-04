/// Purpose: Schedule the next review of an item from a right-or-wrong answer.
/// Inputs: A `StudyRecord` and whether the learner got it right.
/// Returns: The same record with its counters, interval, ease and due date
/// advanced.
/// Side effects: None — a pure function over an immutable model.
/// Notes: SM-2, adapted for binary grading. The original takes a 0–5
/// self-assessment; a quiz has two answers, so the quality is derived rather
/// than asked for, and the penalty for a wrong answer is softened. Both
/// departures are recorded in `doc/en-us/algorithms/spaced-repetition.md`.
library;

import '../models/study_record.dart';

/// How far ease may fall. Below this an item comes back daily forever, which
/// is the classic SM-2 failure mode rather than useful scheduling.
const minStudyEase = 1.3;

/// How far ahead a review may be pushed. A year is past the point where an
/// interval is a prediction about anything.
const maxIntervalDays = 365;

/// The consecutive-correct count from which an answer earns the ease bonus.
const easeBonusStreak = 3;

/// Plans the next review of an item.
///
/// Deliberately a class with no state rather than free functions: the two
/// constants a test may want to vary are constructor parameters, and every
/// call site holds one instance.
class Sm2Scheduler {
  /// Purpose: Create a scheduler.
  /// Inputs: `easeFloor` and `maxInterval`, for tests and future tuning.
  /// Returns: A new `Sm2Scheduler` instance.
  /// Side effects: None.
  /// Notes: The defaults are the shipped behaviour; nothing in the app passes
  /// anything else.
  const Sm2Scheduler({
    this.easeFloor = minStudyEase,
    this.maxInterval = maxIntervalDays,
  });

  /// The lowest ease an item can reach.
  final double easeFloor;

  /// The longest interval that can be scheduled, in days.
  final int maxInterval;

  /// Purpose: Advance a record after one answer.
  /// Inputs: `record`; `correct`; `now` — the answer's UTC instant.
  /// Returns: A new `StudyRecord`.
  /// Side effects: None.
  /// Notes: `now` is required rather than defaulted so the caller decides the
  /// instant once for a whole batch, and so every test is deterministic. The
  /// returned record's `modifiedAt` is `now` too, which is what makes the
  /// change visible to the sync merge.
  StudyRecord apply(
    StudyRecord record, {
    required bool correct,
    required DateTime now,
  }) {
    final stamp = now.toUtc();
    final streak = correct ? record.streak + 1 : 0;
    final ease = _nextEase(record.ease, correct: correct, streak: streak);
    final interval = correct
        ? _nextInterval(record.streak, record.intervalDays, ease)
        : 1;
    return record.copyWith(
      correct: correct ? record.correct + 1 : record.correct,
      wrong: correct ? record.wrong : record.wrong + 1,
      streak: streak,
      intervalDays: interval,
      ease: ease,
      dueAt: stamp.add(Duration(days: interval)),
      lastReviewedAt: stamp,
      modifiedAt: stamp,
    );
  }

  /// Purpose: Adjust the ease factor for one answer.
  /// Inputs: The current `ease`, whether the answer was `correct`, and the
  /// `streak` after it.
  /// Returns: `double`, never below [easeFloor].
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. A wrong answer costs
  /// **0.20**, not SM-2's 0.54 for its lowest quality. With binary grading
  /// every mistake would otherwise be graded as the worst possible answer, and
  /// three of them would pin a word to the floor — where it returns daily and
  /// never leaves, however well the learner then does. A correct answer is
  /// neutral, and only a run of them earns the +0.10 bonus, so ease drifts up
  /// for items that are genuinely known rather than for every hit.
  double _nextEase(double ease, {required bool correct, required int streak}) {
    final next = correct
        ? (streak >= easeBonusStreak ? ease + 0.10 : ease)
        : ease - 0.20;
    return next < easeFloor ? easeFloor : next;
  }

  /// Purpose: Work out the next interval for a correct answer.
  /// Inputs: `streakBefore` — consecutive correct answers before this one;
  /// `intervalBefore`; the `ease` already adjusted for this answer.
  /// Returns: `int` days, at least 1 and at most [maxInterval].
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The first two steps
  /// are fixed at 1 and 6 days, as in SM-2: an item answered right once has
  /// shown almost nothing, and the ease factor has no evidence to work from
  /// until there is a repetition history. From the third correct answer the
  /// interval multiplies by ease.
  int _nextInterval(int streakBefore, int intervalBefore, double ease) {
    final next = switch (streakBefore) {
      0 => 1,
      1 => 6,
      _ => (intervalBefore * ease).round(),
    };
    return next.clamp(1, maxInterval);
  }
}
