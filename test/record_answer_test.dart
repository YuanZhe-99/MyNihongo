import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/app/data_modules.dart';
import 'package:my_nihongo/features/content/models/jlpt_level.dart';
import 'package:my_nihongo/features/progress/models/learner_profile.dart';
import 'package:my_nihongo/features/progress/services/nihongo_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Purpose: Test the write path an answer takes to disk.
/// Inputs: None.
/// Returns: None.
/// Side effects: Writes into a temporary directory.
/// Notes: The properties that matter are on the file, not in memory: a batch is
/// **one** save rather than one per answer, the first answer to an item creates
/// its record, the profile streak is written once a day rather than once an
/// answer, and unknown fields written by a newer build survive an edit by this
/// one. The last is the reason this goes through real files at all — a mock
/// would not catch a serializer that drops a key.
class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.documentsPath);
  final String documentsPath;
  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late File dataFile;
  final now = DateTime.utc(2026, 9, 3, 12);

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('mynihongo_answers_');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
    final appDir = Directory(p.join(temp.path, 'MyNihongo'));
    await appDir.create(recursive: true);
    dataFile = File(p.join(appDir.path, progressDataFileName));
  });

  tearDown(() async {
    if (temp.existsSync()) await temp.delete(recursive: true);
  });

  Map<String, dynamic> onDisk() =>
      jsonDecode(dataFile.readAsStringSync()) as Map<String, dynamic>;

  test('the first answer creates the record it is about', () async {
    await NihongoStorage.recordAnswer('vocab:jm1198180', true, now: now);

    final data = await NihongoStorage.load();
    final record = data.recordById('vocab:jm1198180')!;
    expect(record.correct, 1);
    expect(record.streak, 1);
    expect(record.intervalDays, 1);
    expect(record.dueAt, now.add(const Duration(days: 1)));
    expect(record.createdAt, now, reason: 'created by its first answer');
  });

  test('a wrong first answer is still recorded', () async {
    await NihongoStorage.recordAnswer('kana:あ', false, now: now);
    final record = (await NihongoStorage.load()).recordById('kana:あ')!;
    expect(record.wrong, 1);
    expect(record.correct, 0);
    expect(record.streak, 0);
  });

  test('a batch of answers is a single file write', () async {
    await NihongoStorage.recordAnswers({
      'kana:あ': true,
      'kana:い': false,
      'vocab:jm1198180': true,
    }, now: now);

    final data = await NihongoStorage.load();
    // Three items plus the profile the streak was written into.
    expect(data.studyRecords, hasLength(3));
    expect(data.recordById(learnerProfileId), isNotNull);
    expect(data.recordById('kana:い')!.wrong, 1);
  });

  test('the profile streak is written once a day, not once an answer', () async {
    await NihongoStorage.recordAnswer('kana:あ', true, now: now);
    final first = (await NihongoStorage.load()).recordById(learnerProfileId)!;
    expect(LearnerProfile.fromRecord(first).streakDays, 1);

    await NihongoStorage.recordAnswer('kana:い', true, now: now);
    final second = (await NihongoStorage.load()).recordById(learnerProfileId)!;
    expect(
      second.modifiedAt,
      first.modifiedAt,
      reason:
          'a second answer the same day must not rewrite the profile, or '
          'two devices studying the same day would conflict over every answer',
    );
  });

  test('studying on consecutive days advances the streak', () async {
    await NihongoStorage.recordAnswer('kana:あ', true, now: now);
    await NihongoStorage.recordAnswer(
      'kana:い',
      true,
      now: now.add(const Duration(days: 1)),
    );
    final profile = await NihongoStorage.loadProfile();
    expect(profile.streakDays, 2);
  });

  test('the file stays in the two-space format sync depends on', () async {
    await NihongoStorage.recordAnswer('kana:あ', true, now: now);
    final text = dataFile.readAsStringSync();
    expect(text.startsWith('{\n  "records": [\n    {\n'), isTrue);
  });

  test(
    'a newer build\'s fields survive an answer written by this one',
    () async {
      dataFile.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'records': [
            {
              'id': 'kana:あ',
              'correct': 3,
              'wrong': 1,
              'streak': 3,
              'intervalDays': 6,
              'ease': 2.5,
              'createdAt': '2026-08-01T00:00:00.000Z',
              'modifiedAt': '2026-08-01T00:00:00.000Z',
              'confidenceFromANewerBuild': 0.8,
            },
          ],
          'aTopLevelFieldFromANewerBuild': true,
        }),
      );

      await NihongoStorage.recordAnswer('kana:あ', true, now: now);

      final json = onDisk();
      final record = (json['records'] as List).first as Map<String, dynamic>;
      expect(record['confidenceFromANewerBuild'], 0.8);
      expect(json['aTopLevelFieldFromANewerBuild'], true);
      expect(record['correct'], 4, reason: 'and the answer was still recorded');
    },
  );

  test('saving the profile leaves the study records alone', () async {
    await NihongoStorage.recordAnswer('kana:あ', true, now: now);
    await NihongoStorage.saveProfile(
      const LearnerProfile(targetLevel: JlptLevel.n3, dailyNewLimit: 20),
      now: now,
    );

    final data = await NihongoStorage.load();
    expect(data.recordById('kana:あ')!.correct, 1);
    final profile = LearnerProfile.fromRecord(
      data.recordById(learnerProfileId),
    );
    expect(profile.targetLevel, JlptLevel.n3);
    expect(profile.dailyNewLimit, 20);
    expect(
      profile.streakDays,
      1,
      reason:
          'a streak is earned by answering, so a settings write must carry '
          'it through rather than reset it',
    );
  });

  test('an empty batch writes nothing at all', () async {
    await NihongoStorage.recordAnswers(const {}, now: now);
    expect(dataFile.existsSync(), isFalse);
  });

  test('twenty answers recorded at once are all kept', () async {
    // Quizzes record one answer per tap, without awaiting. Unqueued, each of
    // these loaded the same file and the last save dropped the others.
    await Future.wait([
      for (var i = 0; i < 20; i++)
        NihongoStorage.recordAnswer('vocab:q$i', i.isEven, now: now),
    ]);

    final data = await NihongoStorage.load();
    for (var i = 0; i < 20; i++) {
      final record = data.recordById('vocab:q$i');
      expect(record, isNotNull, reason: 'vocab:q$i was lost');
      expect(record!.correct + record.wrong, 1);
    }
  });

  test('saving the profile while answers are recorded keeps both', () async {
    // saveProfile ends in an upsert; run inside the queue it must not wait on
    // the queue it is holding.
    await Future.wait([
      NihongoStorage.recordAnswers({'kana:あ': true, 'kana:い': false}, now: now),
      NihongoStorage.saveProfile(
        const LearnerProfile(targetLevel: JlptLevel.n4, dailyNewLimit: 12),
        now: now,
      ),
      NihongoStorage.recordAnswer('kana:う', true, now: now),
      NihongoStorage.recordLessonResult('lesson:n5-u1', true, now: now),
    ]).timeout(const Duration(seconds: 20));

    final data = await NihongoStorage.load();
    expect(data.recordById('kana:あ'), isNotNull);
    expect(data.recordById('kana:い'), isNotNull);
    expect(data.recordById('kana:う'), isNotNull);
    expect(data.recordById('lesson:n5-u1')!.correct, 1);
    final profile = LearnerProfile.fromRecord(
      data.recordById(learnerProfileId),
    );
    expect(profile.targetLevel, JlptLevel.n4);
    expect(profile.dailyNewLimit, 12);
  });

  test('a failing write does not block the ones after it', () async {
    dataFile.writeAsStringSync('{ this is not json');
    final first = NihongoStorage.recordAnswer('kana:あ', true, now: now);
    final second = NihongoStorage.recordAnswer('kana:い', true, now: now);
    await expectLater(first, throwsA(anything));
    await expectLater(second, throwsA(anything));

    dataFile.deleteSync();
    await NihongoStorage.recordAnswer(
      'kana:う',
      true,
      now: now,
    ).timeout(const Duration(seconds: 20));
    expect((await NihongoStorage.load()).recordById('kana:う')!.correct, 1);
  });

  test('the streak counts across a daylight-saving change', () async {
    // The night the clocks go forward (2026-03-08 in the US) is 23 hours long;
    // yesterday must be found by calendar, not by subtracting 24 hours.
    const start = LearnerProfile(streakDays: 4, streakLastDate: '2026-03-08');
    final next = start.withStreakTouched('2026-03-09');
    expect(next.streakDays, 5);
    // And the night they go back (2026-11-01) is 25 hours long.
    const fall = LearnerProfile(streakDays: 2, streakLastDate: '2026-11-01');
    expect(fall.withStreakTouched('2026-11-02').streakDays, 3);
    // A gap of one whole day still restarts it.
    expect(start.withStreakTouched('2026-03-10').streakDays, 1);
  });
}
