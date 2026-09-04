/// Purpose: The learner's own settings and streak, synced with their progress.
/// Inputs: The `profile:me` record inside `nihongo_progress.json`.
/// Returns: An immutable value, with defaults for everything absent.
/// Side effects: None.
/// Notes: Stored as an ordinary [StudyRecord] whose payload lives under the
/// `profile` key of its `extraJson`. That is not a workaround: `extraJson`
/// already round-trips unknown keys through load, save and merge, so the
/// profile inherits per-record three-way merging and the ordinary conflict
/// dialog without a single new field on `StudyRecord` and without touching the
/// golden transcripts. A top-level `profile` object in the same file would
/// instead have merged local-wins with no conflict detection at all — see
/// `doc/en-us/data-formats.md`.
library;

import '../../content/models/jlpt_level.dart';
import 'study_record.dart';

/// The record id the profile always lives under. There is one learner.
const learnerProfileId = 'profile:me';

/// The default daily allowance of new items, if the learner has not chosen.
const defaultDailyNewLimit = 10;

/// The default daily allowance of reviews.
const defaultDailyReviewLimit = 100;

/// The learner's target level, daily goals and study streak.
class LearnerProfile {
  /// Purpose: Create a profile value.
  /// Inputs: All fields; every one has a default.
  /// Returns: A new `LearnerProfile` instance.
  /// Side effects: None.
  /// Notes: The defaults are what a learner who has never opened Settings
  /// gets, and what a malformed payload falls back to.
  const LearnerProfile({
    this.targetLevel = JlptLevel.n5,
    this.dailyNewLimit = defaultDailyNewLimit,
    this.dailyReviewLimit = defaultDailyReviewLimit,
    this.streakDays = 0,
    this.streakLastDate,
  });

  /// The level new items are drawn from.
  final JlptLevel targetLevel;

  /// How many new items a day the queue may introduce.
  final int dailyNewLimit;

  /// How many reviews a day the queue may offer.
  final int dailyReviewLimit;

  /// Consecutive days with at least one answer.
  final int streakDays;

  /// The local date of the last answered day, as `YYYY-MM-DD`.
  ///
  /// A date rather than an instant, and local rather than UTC, because a study
  /// streak is counted in the learner's own days. Comparing instants would
  /// break the streak for anyone who studies late at night.
  final String? streakLastDate;

  /// Purpose: Format a date the way [streakLastDate] stores it.
  /// Inputs: `date` — a local `DateTime`.
  /// Returns: `String` — `YYYY-MM-DD`.
  /// Side effects: None.
  /// Notes: Only the calendar day is kept; the time is deliberately dropped.
  static String localDateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Purpose: Read the profile out of the progress file.
  /// Inputs: `record` — the `profile:me` record, or null when there is none.
  /// Returns: `LearnerProfile`, all defaults when absent or unreadable.
  /// Side effects: None.
  /// Notes: Never throws. A profile written by a newer build with fields this
  /// one cannot read still loads, because every field is read independently
  /// and the whole payload rides along in `extraJson` regardless.
  static LearnerProfile fromRecord(StudyRecord? record) {
    final raw = record?.extraJson['profile'];
    if (raw is! Map) return const LearnerProfile();
    final streak = raw['streakDays'];
    final newLimit = raw['dailyNewLimit'];
    final reviewLimit = raw['dailyReviewLimit'];
    return LearnerProfile(
      targetLevel: JlptLevel.parse(raw['targetLevel']) ?? JlptLevel.n5,
      dailyNewLimit: newLimit is int && newLimit >= 0
          ? newLimit
          : defaultDailyNewLimit,
      dailyReviewLimit: reviewLimit is int && reviewLimit >= 0
          ? reviewLimit
          : defaultDailyReviewLimit,
      streakDays: streak is int && streak >= 0 ? streak : 0,
      streakLastDate: raw['streakLastDate'] is String
          ? raw['streakLastDate'] as String
          : null,
    );
  }

  /// Purpose: Write the profile back into its record.
  /// Inputs: `existing` — the record already in the file, if any; `now`.
  /// Returns: `StudyRecord` ready for `upsertRecords`.
  /// Side effects: None.
  /// Notes: Unknown keys inside the payload are preserved: the map is rebuilt
  /// from whatever was there, with the known fields written over it. Without
  /// that, an older build would silently drop a newer one's profile fields on
  /// the first edit — the same rule `extraJson` enforces one level up.
  StudyRecord toRecord(StudyRecord? existing, DateTime now) {
    final previous = existing?.extraJson['profile'];
    final payload = <String, dynamic>{
      if (previous is Map)
        for (final entry in previous.entries) entry.key.toString(): entry.value,
      'targetLevel': targetLevel.label,
      'dailyNewLimit': dailyNewLimit,
      'dailyReviewLimit': dailyReviewLimit,
      'streakDays': streakDays,
      if (streakLastDate != null) 'streakLastDate': streakLastDate,
    };
    final extra = <String, dynamic>{
      ...?existing?.extraJson,
      'profile': payload,
    };
    final base =
        existing ?? StudyRecord.create(learnerProfileId, now: now);
    return base.copyWith(extraJson: extra, modifiedAt: now.toUtc());
  }

  /// Purpose: Advance the study streak for a day with an answer in it.
  /// Inputs: `today` — the local date key, from [localDateKey].
  /// Returns: `LearnerProfile` — this one when the streak has already been
  /// counted today, so the caller can skip the write.
  /// Side effects: None.
  /// Notes: Yesterday continues the streak, anything older restarts it at 1.
  /// Returning `this` unchanged for a repeat answer on the same day is what
  /// keeps profile conflicts rare: the record is written once a day rather
  /// than once an answer, so two devices studying the same day disagree about
  /// one field at most.
  LearnerProfile withStreakTouched(String today) {
    if (streakLastDate == today) return this;
    final yesterday = localDateKey(
      DateTime.parse(today).subtract(const Duration(days: 1)),
    );
    return copyWith(
      streakDays: streakLastDate == yesterday ? streakDays + 1 : 1,
      streakLastDate: today,
    );
  }

  /// Purpose: Create a copy with selected fields replaced.
  /// Inputs: Any field.
  /// Returns: `LearnerProfile`.
  /// Side effects: None.
  /// Notes: `streakLastDate` has no clear flag: a streak that has started
  /// never returns to never-studied.
  LearnerProfile copyWith({
    JlptLevel? targetLevel,
    int? dailyNewLimit,
    int? dailyReviewLimit,
    int? streakDays,
    String? streakLastDate,
  }) {
    return LearnerProfile(
      targetLevel: targetLevel ?? this.targetLevel,
      dailyNewLimit: dailyNewLimit ?? this.dailyNewLimit,
      dailyReviewLimit: dailyReviewLimit ?? this.dailyReviewLimit,
      streakDays: streakDays ?? this.streakDays,
      streakLastDate: streakLastDate ?? this.streakLastDate,
    );
  }
}
