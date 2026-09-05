import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/progress/models/exam_attempt.dart';
import 'package:my_nihongo/features/progress/models/study_record.dart';
import 'package:my_nihongo/features/progress/services/nihongo_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Purpose: Test the exam record — its id, its round trip, its caps and what
/// it deliberately does not store.
/// Inputs: None.
/// Returns: None.
/// Side effects: Writes into a temporary directory.
/// Notes: Two rules carry the weight. **Only the input is stored** — which
/// questions were asked and what the first answer to each was — so a content
/// update that corrects an answer key corrects the history with it rather than
/// leaving a frozen score the files no longer agree with. And **pruning is per
/// mode**, so a learner who practises daily and mocks monthly does not lose
/// every mock to the practice runs.
class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.documentsPath);
  final String documentsPath;
  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('mynihongo_exam_');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
    await Directory(p.join(temp.path, 'MyNihongo')).create(recursive: true);
  });

  tearDown(() async {
    if (temp.existsSync()) await temp.delete(recursive: true);
  });

  ExamAttempt attempt({
    String id = 'exam:20260905T101500Z-3f2a',
    ExamMode mode = ExamMode.practice,
    DateTime? startedAt,
    Map<String, int> answers = const {'q:n5-v-001': 1, 'q:n5-v-002': 0},
  }) => ExamAttempt(
    id: id,
    level: 'N5',
    mode: mode,
    scale: 'short',
    startedAt: startedAt ?? DateTime.utc(2026, 9, 5, 10, 15),
    finishedAt: DateTime.utc(2026, 9, 5, 10, 42),
    sections: const {
      'vocab': ExamSectionResult(asked: 2, right: 1, seconds: 300),
    },
    answers: answers,
  );

  group('the id', () {
    test('sorts the way the attempts happened', () {
      final first = ExamAttempt.buildId(
        DateTime.utc(2026, 9, 5, 10, 15),
        'aaaa',
      );
      final second = ExamAttempt.buildId(
        DateTime.utc(2026, 9, 5, 11, 15),
        'aaaa',
      );
      expect(first, 'exam:20260905T101500Z-aaaa');
      expect(first.compareTo(second), lessThan(0));
    });

    test('two attempts in the same second are two attempts', () {
      // Unlike the sentence history, which is content-addressed so that
      // re-analysing one sentence updates one record. Two sittings of one
      // paper are genuinely two things and must not collapse.
      final at = DateTime.utc(2026, 9, 5, 10, 15);
      expect(
        ExamAttempt.buildId(at, 'aaaa'),
        isNot(ExamAttempt.buildId(at, 'bbbb')),
      );
    });

    test('a local time is written as UTC', () {
      final id = ExamAttempt.buildId(DateTime.utc(2026, 1, 2, 3, 4, 5), 'cafe');
      expect(id, 'exam:20260102T030405Z-cafe');
    });
  });

  group('the round trip', () {
    test('everything written comes back', () {
      final written = attempt().toRecord(null, DateTime.utc(2026, 9, 5));
      final read = ExamAttempt.fromRecord(written)!;
      expect(read.level, 'N5');
      expect(read.mode, ExamMode.practice);
      expect(read.scale, 'short');
      expect(read.startedAt, DateTime.utc(2026, 9, 5, 10, 15));
      expect(read.finishedAt, DateTime.utc(2026, 9, 5, 10, 42));
      expect(read.sections['vocab']?.asked, 2);
      expect(read.sections['vocab']?.right, 1);
      expect(read.sections['vocab']?.seconds, 300);
      expect(read.answers, {'q:n5-v-001': 1, 'q:n5-v-002': 0});
      expect(read.asked, 2);
      expect(read.right, 1);
      expect(read.accuracy, 0.5);
    });

    test('the counters carry the totals for an older build to read', () {
      // A build that has never heard of an exam record still shows its
      // conflict dialog, and "correct 0 · wrong 0" there would be false.
      final written = attempt().toRecord(null, DateTime.utc(2026, 9, 5));
      expect(written.correct, 1);
      expect(written.wrong, 1);
    });

    test('a payload key this build does not know survives an edit', () {
      final existing =
          StudyRecord.create(
            'exam:20260905T101500Z-3f2a',
            now: DateTime.utc(2026, 9, 4),
          ).copyWith(
            extraJson: {
              'exam': {'level': 'N5', 'futureField': 42},
              'somethingElse': true,
            },
          );
      final written = attempt().toRecord(existing, DateTime.utc(2026, 9, 5));
      final payload = written.extraJson['exam'] as Map;
      expect(payload['futureField'], 42);
      expect(written.extraJson['somethingElse'], true);
    });

    test('a record that is not an exam is not read as one', () {
      expect(
        ExamAttempt.fromRecord(
          StudyRecord.create('vocab:one', now: DateTime.utc(2026, 9, 5)),
        ),
        isNull,
      );
      expect(ExamAttempt.fromRecord(null), isNull);
    });

    test('an exam record with no payload is refused, not shown blank', () {
      expect(
        ExamAttempt.fromRecord(
          StudyRecord.create(
            'exam:20260905T101500Z-3f2a',
            now: DateTime.utc(2026, 9, 5),
          ),
        ),
        isNull,
      );
    });

    test('a section the build has no name for still round-trips', () {
      // The keys are plain strings so `progress/` does not import `drills/`.
      // A section added in a later release must not make an older build lose
      // the rest of the attempt.
      final written = ExamAttempt(
        id: 'exam:20260905T101500Z-3f2a',
        level: 'N5',
        mode: ExamMode.mock,
        scale: 'full',
        startedAt: DateTime.utc(2026, 9, 5),
        sections: const {'composition': ExamSectionResult(asked: 3, right: 2)},
      ).toRecord(null, DateTime.utc(2026, 9, 5));
      final read = ExamAttempt.fromRecord(written)!;
      expect(read.sections['composition']?.asked, 3);
    });
  });

  test('an unanswered question is neither right nor wrong', () {
    final read = ExamAttempt.fromRecord(
      attempt(
        answers: {'q:n5-v-001': 1, 'q:n5-v-002': examUnanswered},
      ).toRecord(null, DateTime.utc(2026, 9, 5)),
    )!;
    expect(read.answers['q:n5-v-002'], -1);
  });

  group('the list', () {
    StudyRecord recordOf(String id, ExamMode mode, DateTime at) => ExamAttempt(
      id: id,
      level: mode == ExamMode.mock ? 'N4' : 'N5',
      mode: mode,
      scale: 'short',
      startedAt: at,
      sections: const {'vocab': ExamSectionResult(asked: 1, right: 1)},
      answers: const {'q:n5-v-001': 1},
    ).toRecord(null, at);

    test('is newest first', () {
      final records = [
        recordOf('exam:a', ExamMode.practice, DateTime.utc(2026, 9, 1)),
        recordOf('exam:c', ExamMode.practice, DateTime.utc(2026, 9, 3)),
        recordOf('exam:b', ExamMode.practice, DateTime.utc(2026, 9, 2)),
      ];
      expect(examAttempts(records).map((a) => a.id), [
        'exam:c',
        'exam:b',
        'exam:a',
      ]);
    });

    test('can be narrowed by level and by mode', () {
      final records = [
        recordOf('exam:a', ExamMode.practice, DateTime.utc(2026, 9, 1)),
        recordOf('exam:b', ExamMode.mock, DateTime.utc(2026, 9, 2)),
      ];
      expect(examAttempts(records, mode: ExamMode.mock).map((a) => a.id), [
        'exam:b',
      ]);
      expect(examAttempts(records, level: 'N5').map((a) => a.id), ['exam:a']);
    });

    test('ignores every record that is not an attempt', () {
      final records = [
        StudyRecord.create('vocab:one', now: DateTime.utc(2026, 9, 1)),
        recordOf('exam:a', ExamMode.practice, DateTime.utc(2026, 9, 1)),
      ];
      expect(examAttempts(records), hasLength(1));
    });
  });

  group('through the real file', () {
    test('an attempt is written and read back', () async {
      await NihongoStorage.recordExam(attempt());
      final data = await NihongoStorage.load();
      final attempts = examAttempts(data.records);
      expect(attempts, hasLength(1));
      expect(attempts.single.answers, {'q:n5-v-001': 1, 'q:n5-v-002': 0});
    });

    test('the caps are per mode, so a mock is not lost to practice', () async {
      for (var i = 0; i < examMaxPracticeEntries + 5; i++) {
        await NihongoStorage.recordExam(
          attempt(
            id: 'exam:practice-$i',
            startedAt: DateTime.utc(2026, 1, 1).add(Duration(days: i)),
          ),
        );
      }
      await NihongoStorage.recordExam(
        attempt(
          id: 'exam:mock-1',
          mode: ExamMode.mock,
          startedAt: DateTime.utc(2025, 1, 1),
        ),
      );

      final data = await NihongoStorage.load();
      expect(
        examAttempts(data.records, mode: ExamMode.practice),
        hasLength(examMaxPracticeEntries),
      );
      expect(
        examAttempts(data.records, mode: ExamMode.mock).map((a) => a.id),
        ['exam:mock-1'],
        reason: 'the oldest attempt in the file, and the one worth keeping',
      );
    });

    test('the oldest practice attempts are the ones dropped', () async {
      for (var i = 0; i < examMaxPracticeEntries + 3; i++) {
        await NihongoStorage.recordExam(
          attempt(
            id: 'exam:practice-${i.toString().padLeft(3, '0')}',
            startedAt: DateTime.utc(2026, 1, 1).add(Duration(days: i)),
          ),
        );
      }
      final data = await NihongoStorage.load();
      final ids = examAttempts(data.records).map((a) => a.id).toSet();
      expect(ids.contains('exam:practice-000'), isFalse);
      expect(ids.contains('exam:practice-002'), isFalse);
      expect(ids.contains('exam:practice-003'), isTrue);
    });

    test('a study record is never pruned by an exam write', () async {
      await NihongoStorage.recordAnswer('vocab:one', true);
      for (var i = 0; i < examMaxPracticeEntries + 3; i++) {
        await NihongoStorage.recordExam(
          attempt(
            id: 'exam:practice-$i',
            startedAt: DateTime.utc(2026, 1, 1).add(Duration(days: i)),
          ),
        );
      }
      final data = await NihongoStorage.load();
      expect(data.recordById('vocab:one'), isNotNull);
    });

    test('re-recording the same id updates rather than duplicates', () async {
      await NihongoStorage.recordExam(attempt());
      await NihongoStorage.recordExam(
        attempt(answers: const {'q:n5-v-001': 1, 'q:n5-v-002': 1}),
      );
      final data = await NihongoStorage.load();
      final attempts = examAttempts(data.records);
      expect(attempts, hasLength(1));
      expect(attempts.single.answers['q:n5-v-002'], 1);
    });

    test('deleting an attempt really removes it', () async {
      // A real deletion, not a tombstone: the merge treats a record deleted on
      // one side and untouched on the other as deleted, so an attempt removed
      // here is removed everywhere on the next sync.
      await NihongoStorage.recordExam(attempt());
      await NihongoStorage.deleteRecords(['exam:20260905T101500Z-3f2a']);
      final data = await NihongoStorage.load();
      expect(examAttempts(data.records), isEmpty);
    });

    test('the file it writes is the ordinary progress file', () async {
      await NihongoStorage.recordExam(attempt());
      final file = await NihongoStorage.getDataFile();
      final json = jsonDecode(await file.readAsString()) as Map;
      final records = json['records'] as List;
      expect(records, hasLength(1));
      expect((records.single as Map)['id'], 'exam:20260905T101500Z-3f2a');
    });
  });
}
