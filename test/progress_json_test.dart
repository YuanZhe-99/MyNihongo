import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/progress/models/study_record.dart';
import 'package:my_nihongo/shared/services/sync_merge.dart';

/// Purpose: Pin the progress model's forward compatibility and merge rules.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: Unknown fields written by a newer build must survive a round trip
/// through this one, and conflicts must never be resolved silently.
void main() {
  const createdAt = '2026-01-01T00:00:00.000Z';
  const modifiedAt = '2026-01-02T00:00:00.000Z';

  Map<String, dynamic> record(
    String id, {
    String modified = modifiedAt,
    int correct = 0,
    Map<String, dynamic> extra = const {},
  }) => {
    'id': id,
    'correct': correct,
    'createdAt': createdAt,
    'modifiedAt': modified,
    ...extra,
  };

  test('preserves unknown record and top-level JSON fields', () {
    final data = ProgressData.fromJson({
      'schemaVersion': 2,
      'profile': {'targetLevel': 'N4'},
      'records': [
        record(
          'vocab:watashi',
          correct: 3,
          extra: {
            'futureField': {'score': 98},
            'intervalDays': 'not-a-number',
            'dueAt': 'someday',
          },
        ),
      ],
    });

    final json = data.toJson();
    expect(json['schemaVersion'], 2);
    expect(json['profile'], {'targetLevel': 'N4'});

    final recordJson =
        (json['records'] as List<dynamic>).single as Map<String, dynamic>;
    expect(recordJson['futureField'], {'score': 98});
    // A nullable field this build could not parse is kept verbatim; a
    // counter that could not be parsed takes its default and writes it back,
    // because a typed value and a raw one cannot share a key.
    expect(recordJson['dueAt'], 'someday');
    expect(data.records.single.dueAt, isNull);
    expect(recordJson['intervalDays'], 0);
    expect(data.records.single.intervalDays, 0);

    final edited = data.records.single.copyWith(correct: 4);
    final editedJson = edited.toJson();
    expect(editedJson['correct'], 4);
    expect(editedJson['futureField'], {'score': 98});
    expect(editedJson['dueAt'], 'someday');
  });

  test('kind is derived from the id prefix, unknown prefixes load', () {
    expect(studyKindOf('kana:あ'), StudyKind.kana);
    expect(studyKindOf('vocab:watashi'), StudyKind.vocab);
    expect(studyKindOf('grammar:desu'), StudyKind.grammar);
    expect(studyKindOf('kanji:日'), StudyKind.other);
    expect(studyKindOf('no-prefix'), StudyKind.other);
  });

  test('a history record loads, merges and is not a studied item', () {
    final data = ProgressData.fromJson({
      'records': [
        {
          'id': 'lab:abc123',
          'correct': 0,
          'wrong': 0,
          'createdAt': '2026-09-04T10:00:00.000Z',
          'modifiedAt': '2026-09-04T10:00:00.000Z',
          'history': {'text': 'これは本です。'},
        },
        {
          'id': 'vocab:watashi',
          'createdAt': '2026-09-04T10:00:00.000Z',
          'modifiedAt': '2026-09-04T10:00:00.000Z',
        },
      ],
    });

    final record = data.recordById('lab:abc123')!;
    expect(record.kind, StudyKind.history);
    expect(
      data.studyRecords.map((r) => r.id),
      ['vocab:watashi'],
      reason: 'a remembered sentence is not something anybody studied',
    );
    // The payload survives a round trip through this build's serializer.
    expect(
      (record.toJson()['history'] as Map)['text'],
      'これは本です。',
    );
  });

  test('stage is derived from review state', () {
    final fresh = StudyRecord.create('kana:あ');
    expect(fresh.stage, StudyStage.fresh);
    expect(fresh.accuracy, 0);

    final learning = fresh.copyWith(
      correct: 2,
      wrong: 1,
      intervalDays: 3,
      lastReviewedAt: DateTime.utc(2026, 1, 3),
    );
    expect(learning.stage, StudyStage.learning);
    expect(learning.accuracy, closeTo(2 / 3, 1e-9));

    final mastered = learning.copyWith(intervalDays: masteredIntervalDays);
    expect(mastered.stage, StudyStage.mastered);
  });

  test('timestamps are normalized to UTC and nullable fields are omitted', () {
    final parsed = StudyRecord.fromJson({
      'id': 'kana:あ',
      'createdAt': '2026-01-01T09:00:00.000+09:00',
      'modifiedAt': '2026-01-01T09:00:00.000+09:00',
    });
    expect(parsed.modifiedAt.isUtc, isTrue);
    expect(parsed.modifiedAt, DateTime.utc(2026, 1, 1));
    final json = parsed.toJson();
    expect(json.containsKey('dueAt'), isFalse);
    expect(json.containsKey('lastReviewedAt'), isFalse);
  });

  test('a record without modifiedAt gets the epoch and loses merges', () {
    final orphan = StudyRecord.fromJson({'id': 'kana:あ'});
    expect(
      orphan.modifiedAt,
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
    expect(orphan.createdAt, orphan.modifiedAt);
  });

  test('copyWith bumps modifiedAt unless told otherwise', () {
    final original = StudyRecord.fromJson(record('kana:あ'));
    final bumped = original.copyWith(correct: 1);
    expect(bumped.modifiedAt.isAfter(original.modifiedAt), isTrue);
    final held = original.copyWith(correct: 1, modifiedAt: original.modifiedAt);
    expect(held.modifiedAt, original.modifiedAt);
  });

  group('mergeProgressData', () {
    test('merges disjoint edits without conflicts', () {
      final base = jsonEncode({
        'records': [record('kana:あ'), record('kana:い')],
      });
      final local = jsonEncode({
        'records': [
          record('kana:あ', correct: 5, modified: '2026-01-03T00:00:00.000Z'),
          record('kana:い'),
        ],
      });
      final remote = jsonEncode({
        'records': [
          record('kana:あ'),
          record('kana:い', correct: 7, modified: '2026-01-04T00:00:00.000Z'),
          record('kana:う', modified: '2026-01-04T00:00:00.000Z'),
        ],
      });

      final result = mergeProgressData(local, remote, base);
      expect(result.hasConflicts, isFalse);
      final byId = {for (final r in result.merged) r.id: r};
      expect(byId['kana:あ']!.correct, 5);
      expect(byId['kana:い']!.correct, 7);
      expect(byId.containsKey('kana:う'), isTrue);
    });

    test(
      'both sides changing one record is a conflict, never auto-resolved',
      () {
        final base = jsonEncode({
          'records': [record('vocab:watashi')],
        });
        final local = jsonEncode({
          'records': [
            record(
              'vocab:watashi',
              correct: 5,
              modified: '2026-01-03T00:00:00.000Z',
            ),
          ],
        });
        final remote = jsonEncode({
          'records': [
            record(
              'vocab:watashi',
              correct: 9,
              modified: '2026-01-04T00:00:00.000Z',
            ),
          ],
        });

        final result = mergeProgressData(local, remote, base);
        expect(result.hasConflicts, isTrue);
        expect(result.conflicts.single.id, 'vocab:watashi');
        expect(result.conflicts.single.displayName, 'vocab:watashi');

        // Choosing the remote copy carries it into the resolved file; an
        // unresolved conflict falls back to the local copy.
        final chosen = result.buildResolved({
          'vocab:watashi': result.conflicts.single.remoteRecord,
        });
        expect(chosen.recordById('vocab:watashi')!.correct, 9);
        final fallback = result.buildResolved(const {});
        expect(fallback.recordById('vocab:watashi')!.correct, 5);
      },
    );

    test('unknown fields from both sides survive the merge', () {
      final base = jsonEncode({
        'records': [record('kana:あ')],
      });
      final local = jsonEncode({
        'localOnlyTop': true,
        'records': [
          record(
            'kana:あ',
            correct: 1,
            modified: '2026-01-03T00:00:00.000Z',
            extra: {'localOnly': 1},
          ),
        ],
      });
      final remote = jsonEncode({
        'remoteOnlyTop': true,
        'records': [
          record('kana:あ', extra: {'remoteOnly': 2}),
        ],
      });

      final result = mergeProgressData(local, remote, base);
      expect(result.hasConflicts, isFalse);
      final merged = result.merged.single.toJson();
      expect(merged['localOnly'], 1);
      expect(merged['remoteOnly'], 2);
      expect(result.extraJson['localOnlyTop'], true);
      expect(result.extraJson['remoteOnlyTop'], true);
    });
  });
}
