import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/models/jlpt_level.dart';
import 'package:my_nihongo/features/progress/models/learner_profile.dart';
import 'package:my_nihongo/features/progress/models/study_record.dart';

/// Purpose: Test the learner profile that rides inside the progress file.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: The load-bearing property is that the profile is an ordinary record:
/// it round-trips through `StudyRecord.toJson`, it merges by `modifiedAt` like
/// everything else, and an older build must not drop a newer one's fields. The
/// streak rule is the other one worth pinning — it is written once a day rather
/// than once an answer, which is what keeps profile conflicts rare.
void main() {
  final now = DateTime.utc(2026, 9, 3, 12);

  test('an absent profile reads as the documented defaults', () {
    const profile = LearnerProfile();
    expect(LearnerProfile.fromRecord(null).targetLevel, JlptLevel.n5);
    expect(profile.dailyNewLimit, defaultDailyNewLimit);
    expect(profile.dailyReviewLimit, defaultDailyReviewLimit);
    expect(profile.streakDays, 0);
  });

  test('a profile survives a full JSON round trip', () {
    const profile = LearnerProfile(
      targetLevel: JlptLevel.n3,
      dailyNewLimit: 20,
      dailyReviewLimit: 200,
      streakDays: 7,
      streakLastDate: '2026-09-03',
    );
    final record = profile.toRecord(null, now);
    expect(record.id, learnerProfileId);
    expect(record.kind, StudyKind.profile);

    final reparsed = StudyRecord.fromJson(
      jsonDecode(jsonEncode(record.toJson())) as Map<String, dynamic>,
    );
    final back = LearnerProfile.fromRecord(reparsed);
    expect(back.targetLevel, JlptLevel.n3);
    expect(back.dailyNewLimit, 20);
    expect(back.dailyReviewLimit, 200);
    expect(back.streakDays, 7);
    expect(back.streakLastDate, '2026-09-03');
  });

  test('a malformed payload falls back instead of throwing', () {
    final record = StudyRecord(
      id: learnerProfileId,
      createdAt: now,
      modifiedAt: now,
      extraJson: const {
        'profile': {
          'targetLevel': 'N9',
          'dailyNewLimit': 'lots',
          'streakDays': -4,
        },
      },
    );
    final profile = LearnerProfile.fromRecord(record);
    expect(profile.targetLevel, JlptLevel.n5);
    expect(profile.dailyNewLimit, defaultDailyNewLimit);
    expect(profile.streakDays, 0);
  });

  test('a payload that is not an object at all is survivable', () {
    final record = StudyRecord(
      id: learnerProfileId,
      createdAt: now,
      modifiedAt: now,
      extraJson: const {'profile': 'nonsense'},
    );
    expect(LearnerProfile.fromRecord(record).targetLevel, JlptLevel.n5);
  });

  test('a field this build does not know survives an edit by this build', () {
    final existing = StudyRecord(
      id: learnerProfileId,
      createdAt: now,
      modifiedAt: now,
      extraJson: const {
        'profile': {'targetLevel': 'N4', 'weeklyGoal': 500},
        'somethingElseEntirely': true,
      },
    );
    final edited = const LearnerProfile(
      targetLevel: JlptLevel.n2,
    ).toRecord(existing, now);
    final payload = edited.extraJson['profile'] as Map;
    expect(payload['weeklyGoal'], 500, reason: 'a newer build wrote this');
    expect(payload['targetLevel'], 'N2');
    expect(edited.extraJson['somethingElseEntirely'], true);
  });

  test('the streak advances once a day, not once an answer', () {
    const start = LearnerProfile(streakDays: 3, streakLastDate: '2026-09-02');
    final advanced = start.withStreakTouched('2026-09-03');
    expect(advanced.streakDays, 4);

    final again = advanced.withStreakTouched('2026-09-03');
    expect(
      identical(again, advanced),
      isTrue,
      reason: 'a same-day answer must not rewrite the record, or two devices '
          'studying the same day would conflict over every answer',
    );
  });

  test('a missed day restarts the streak at one', () {
    const start = LearnerProfile(streakDays: 9, streakLastDate: '2026-08-28');
    expect(start.withStreakTouched('2026-09-03').streakDays, 1);
  });

  test('the first ever answer starts the streak at one', () {
    expect(const LearnerProfile().withStreakTouched('2026-09-03').streakDays, 1);
  });

  test('the streak key is the local calendar day', () {
    expect(
      LearnerProfile.localDateKey(DateTime(2026, 9, 3, 23, 59)),
      '2026-09-03',
    );
    expect(LearnerProfile.localDateKey(DateTime(2026, 1, 7)), '2026-01-07');
  });

  test('the profile is not counted as a studied item', () {
    final data = ProgressData(
      records: [
        const LearnerProfile().toRecord(null, now),
        StudyRecord.create('vocab:test', now: now),
        StudyRecord.create('lesson:n5-1-1', now: now),
      ],
    );
    expect(data.records, hasLength(3));
    expect(data.studyRecords.map((r) => r.id), ['vocab:test']);
  });
}
