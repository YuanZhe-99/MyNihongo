import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/models/content_catalog.dart';
import 'package:my_nihongo/features/content/models/jlpt_level.dart';
import 'package:my_nihongo/features/kana/models/kana.dart';
import 'package:my_nihongo/features/progress/models/learner_profile.dart';
import 'package:my_nihongo/features/progress/models/study_record.dart';
import 'package:my_nihongo/features/progress/services/review_queue.dart';

/// Purpose: Test what the app decides is worth studying right now.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: Two rules carry the weight here. **Due is a local calendar day, not
/// an instant** — the stored `dueAt` is UTC so it compares identically on every
/// device, but a learner expects anything due today to be available all day.
/// And **today's counts are derived from the records**, never stored, so
/// nothing has to be reset at midnight and work synced in from another device
/// counts against the same daily goal.
void main() {
  final now = DateTime(2026, 9, 3, 12);

  ContentCatalog catalog() => ContentCatalog.fromJson({
    'schemaVersion': 2,
    'entries': [
      {
        'id': 'vocab:common1',
        'level': 'N5',
        'reading': 'ひとつ',
        'common': true,
        'meanings': {
          'en': ['one'],
        },
      },
      {
        'id': 'vocab:rare1',
        'level': 'N5',
        'reading': 'まれ',
        'meanings': {
          'en': ['rare'],
        },
      },
      {
        'id': 'vocab:n4word',
        'level': 'N4',
        'reading': 'よん',
        'common': true,
        'meanings': {
          'en': ['four'],
        },
      },
    ],
  }, const []);

  StudyRecord due(String id, {required int daysAgo}) => StudyRecord(
    id: id,
    createdAt: now.toUtc().subtract(const Duration(days: 40)),
    modifiedAt: now.toUtc(),
    lastReviewedAt: now.toUtc().subtract(Duration(days: daysAgo + 1)),
    dueAt: now.toUtc().subtract(Duration(days: daysAgo)),
    intervalDays: 1,
  );

  ReviewQueue build({
    List<StudyRecord> records = const [],
    LearnerProfile profile = const LearnerProfile(),
  }) => ReviewQueue.build(
    progress: ProgressData(records: records),
    catalog: catalog(),
    profile: profile,
    now: now,
  );

  test('an item never reviewed is not a review', () {
    final queue = build(records: [StudyRecord.create('vocab:common1')]);
    expect(queue.due, isEmpty);
  });

  test('an item due later today is already due', () {
    final record = StudyRecord(
      id: 'vocab:common1',
      createdAt: now.toUtc(),
      modifiedAt: now.toUtc(),
      lastReviewedAt: now.toUtc(),
      // 23:00 local on the same day: due all day, not only in the evening.
      dueAt: DateTime(2026, 9, 3, 23).toUtc(),
      intervalDays: 1,
    );
    expect(ReviewQueue.isDue(record, now), isTrue);
  });

  test('an item due tomorrow is not due yet', () {
    final record = StudyRecord(
      id: 'vocab:common1',
      createdAt: now.toUtc(),
      modifiedAt: now.toUtc(),
      lastReviewedAt: now.toUtc(),
      dueAt: DateTime(2026, 9, 4).toUtc(),
      intervalDays: 1,
    );
    expect(ReviewQueue.isDue(record, now), isFalse);
  });

  test('the most overdue item comes first', () {
    final queue = build(
      records: [
        due('vocab:common1', daysAgo: 1),
        due('vocab:rare1', daysAgo: 9),
        due('vocab:n4word', daysAgo: 4),
      ],
    );
    expect(queue.due.map((r) => r.id), [
      'vocab:rare1',
      'vocab:n4word',
      'vocab:common1',
    ]);
  });

  test('new items are kana first, then common words, then grammar', () {
    final queue = build(profile: const LearnerProfile(dailyNewLimit: 3));
    expect(queue.newIds, hasLength(3));
    expect(
      queue.newIds.every((id) => id.startsWith('kana:')),
      isTrue,
      reason: 'the alphabet comes before the words written in it',
    );
  });

  test('new words come from the target level, commonest first', () {
    // Every kana already studied, so the queue has to reach the vocabulary.
    // Studied a month ago, or they would use up today's new-item allowance
    // themselves — which is the behaviour the next test but one pins down.
    final studied = _studiedLongAgo(now);
    final queue = build(
      records: studied,
      profile: const LearnerProfile(dailyNewLimit: 2),
    );
    expect(queue.newIds, ['vocab:common1', 'vocab:rare1']);
  });

  test('a different target level draws different words', () {
    final studied = _studiedLongAgo(now);
    final queue = build(
      records: studied,
      profile: const LearnerProfile(
        targetLevel: JlptLevel.n4,
        dailyNewLimit: 5,
      ),
    );
    expect(queue.newIds, ['vocab:n4word']);
  });

  test('reviews already answered today count against the daily limit', () {
    final answeredToday = StudyRecord(
      id: 'vocab:common1',
      createdAt: now.toUtc().subtract(const Duration(days: 30)),
      modifiedAt: now.toUtc(),
      lastReviewedAt: now.toUtc(),
      dueAt: now.toUtc().add(const Duration(days: 3)),
      intervalDays: 3,
    );
    final queue = build(
      records: [answeredToday, due('vocab:rare1', daysAgo: 2)],
      profile: const LearnerProfile(dailyReviewLimit: 1),
    );
    expect(queue.reviewsDoneToday, 1);
    expect(queue.reviewAllowance, 0);
    expect(queue.due, isEmpty);
    expect(queue.overdueTotal, 1, reason: 'the backlog is still reported');
    expect(queue.reviewLimitReached, isTrue);
  });

  test('an item started today counts against the new-item allowance', () {
    final queue = build(
      records: [StudyRecord.create('vocab:common1', now: now.toUtc())],
      profile: const LearnerProfile(dailyNewLimit: 3),
    );
    expect(queue.newDoneToday, 1);
    expect(queue.newAllowance, 2);
    expect(queue.newIds, hasLength(2));
  });

  test('the backlog is reported in full even when the day is capped', () {
    final queue = build(
      records: [
        due('vocab:common1', daysAgo: 5),
        due('vocab:rare1', daysAgo: 4),
        due('vocab:n4word', daysAgo: 3),
      ],
      profile: const LearnerProfile(dailyReviewLimit: 2),
    );
    expect(queue.due, hasLength(2));
    expect(queue.overdueTotal, 3);
  });

  test('the profile and lesson records are never scheduled', () {
    final queue = build(
      records: [
        const LearnerProfile().toRecord(null, now.toUtc()),
        StudyRecord(
          id: 'lesson:n5-1-1',
          createdAt: now.toUtc(),
          modifiedAt: now.toUtc(),
          lastReviewedAt: now.toUtc(),
          dueAt: now.toUtc().subtract(const Duration(days: 5)),
        ),
      ],
    );
    expect(queue.due, isEmpty);
    expect(queue.reviewsDoneToday, 0);
  });

  test('an empty queue and a capped queue are different states', () {
    expect(build().reviewLimitReached, isFalse);
    expect(
      build(
        records: [due('vocab:common1', daysAgo: 1)],
        profile: const LearnerProfile(dailyReviewLimit: 0),
      ).reviewLimitReached,
      isTrue,
    );
  });
}

/// Purpose: Mark every kana studied a month ago.
/// Inputs: `now`.
/// Returns: `List<StudyRecord>`.
/// Side effects: None.
/// Notes: Internal helper used within this file only. The date matters: a
/// record created today counts against today's new-item allowance, so kana
/// created "now" would leave no room for the vocabulary these tests are about.
List<StudyRecord> _studiedLongAgo(DateTime now) {
  final then = now.toUtc().subtract(const Duration(days: 30));
  return [
    for (final entry in allKanaEntries())
      StudyRecord(
        id: entry.progressId,
        createdAt: then,
        modifiedAt: then,
        lastReviewedAt: then,
        dueAt: now.toUtc().add(const Duration(days: 10)),
        intervalDays: 40,
      ),
  ];
}
