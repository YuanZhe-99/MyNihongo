import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/app/data_modules.dart';
import 'package:my_nihongo/features/progress/models/history_entry.dart';
import 'package:my_nihongo/features/progress/models/study_record.dart';
import 'package:my_nihongo/features/progress/services/nihongo_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Purpose: Test the sentence history: its content-addressed id, its round trip
/// through a progress record, and the write path to disk including the cap.
/// Inputs: None.
/// Returns: None.
/// Side effects: Writes into a temporary directory.
/// Notes: The id is the load-bearing part. It has to be stable for the same
/// text so re-analysing updates one row rather than adding another, and it has
/// to differ per unit so the same sentence written for two exercises stays two
/// pieces of work. The cap goes through real files for the same reason
/// `record_answer_test` does: a serializer that drops a key is only visible on
/// the file.
class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.documentsPath);
  final String documentsPath;
  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.utc(2026, 9, 4, 12);

  group('the id is derived from the content', () {
    test('the same sentence gives the same id', () {
      expect(
        HistoryEntry.buildId(HistoryKind.lab, 'これは本です。'),
        HistoryEntry.buildId(HistoryKind.lab, 'これは本です。'),
      );
    });

    test('surrounding and internal whitespace does not make a new id', () {
      expect(
        HistoryEntry.buildId(HistoryKind.lab, '  これは  本です。 '),
        HistoryEntry.buildId(HistoryKind.lab, 'これは 本です。'),
      );
    });

    test('a different sentence gives a different id', () {
      expect(
        HistoryEntry.buildId(HistoryKind.lab, 'これは本です。'),
        isNot(HistoryEntry.buildId(HistoryKind.lab, 'それは本です。')),
      );
    });

    test('the same text under two kinds is two entries', () {
      expect(
        HistoryEntry.buildId(HistoryKind.lab, '私は学生です。'),
        isNot(HistoryEntry.buildId(HistoryKind.writing, '私は学生です。')),
      );
    });

    test('the same text for two units is two pieces of work', () {
      expect(
        HistoryEntry.buildId(HistoryKind.writing, '私は学生です。', unitId: 'n5-1'),
        isNot(
          HistoryEntry.buildId(
            HistoryKind.writing,
            '私は学生です。',
            unitId: 'n5-2',
          ),
        ),
      );
    });

    test('the id carries its kind as the record prefix', () {
      expect(
        HistoryEntry.buildId(HistoryKind.lab, 'これは本です。'),
        startsWith('lab:'),
      );
      expect(
        HistoryEntry.buildId(HistoryKind.writing, 'これは本です。'),
        startsWith('writing:'),
      );
      expect(
        studyKindOf(HistoryEntry.buildId(HistoryKind.lab, 'x')),
        StudyKind.history,
      );
    });
  });

  group('a record round trip', () {
    test('an entry survives being written and read back', () {
      final entry = HistoryEntry.forInput(
        HistoryKind.writing,
        '私は学生です。',
        unitId: 'n5-1',
        now: now,
      )!;
      final back = HistoryEntry.fromRecord(entry.toRecord(null, now))!;
      expect(back.id, entry.id);
      expect(back.kind, HistoryKind.writing);
      expect(back.text, '私は学生です。');
      expect(back.unitId, 'n5-1');
      expect(back.at, now);
    });

    test('blank input is refused rather than remembered', () {
      expect(HistoryEntry.forInput(HistoryKind.lab, '   '), isNull);
      expect(HistoryEntry.forInput(HistoryKind.lab, ''), isNull);
    });

    test('a payload key this build does not know survives an edit', () {
      final existing = StudyRecord(
        id: 'lab:abc',
        createdAt: now,
        modifiedAt: now,
        extraJson: const {
          'history': {'text': 'old', 'futureField': 42},
          'somethingElse': true,
        },
      );
      final entry = HistoryEntry(
        id: 'lab:abc',
        kind: HistoryKind.lab,
        text: 'new',
        at: now,
      );
      final written = entry.toRecord(existing, now);
      final payload = written.extraJson['history'] as Map;
      expect(payload['text'], 'new');
      expect(payload['futureField'], 42);
      expect(written.extraJson['somethingElse'], true);
    });

    test('a record that is not history, or has no payload, reads as null', () {
      expect(HistoryEntry.fromRecord(null), isNull);
      expect(
        HistoryEntry.fromRecord(StudyRecord.create('vocab:x', now: now)),
        isNull,
      );
      expect(
        HistoryEntry.fromRecord(StudyRecord.create('lab:x', now: now)),
        isNull,
      );
      expect(
        HistoryEntry.fromRecord(
          StudyRecord(
            id: 'lab:x',
            createdAt: now,
            modifiedAt: now,
            extraJson: const {
              'history': {'text': '   '},
            },
          ),
        ),
        isNull,
      );
    });
  });

  group('collecting a history', () {
    StudyRecord entryRecord(String text, DateTime at, {String? unitId}) =>
        HistoryEntry.forInput(
          unitId == null ? HistoryKind.lab : HistoryKind.writing,
          text,
          unitId: unitId,
          now: at,
        )!.toRecord(null, at);

    test('newest first, and only the kind asked for', () {
      final records = [
        entryRecord('one', now),
        entryRecord('two', now.add(const Duration(minutes: 1))),
        entryRecord('written', now, unitId: 'n5-1'),
        StudyRecord.create('vocab:x', now: now),
      ];
      final lab = historyEntries(records, kind: HistoryKind.lab);
      expect(lab.map((e) => e.text), ['two', 'one']);
      final writing = historyEntries(records, kind: HistoryKind.writing);
      expect(writing.map((e) => e.text), ['written']);
    });

    test('a unit id narrows the writing history to that exercise', () {
      final records = [
        entryRecord('for one', now, unitId: 'n5-1'),
        entryRecord('for two', now, unitId: 'n5-2'),
      ];
      expect(
        historyEntries(
          records,
          kind: HistoryKind.writing,
          unitId: 'n5-1',
        ).map((e) => e.text),
        ['for one'],
      );
      expect(
        historyEntries(records, kind: HistoryKind.writing).length,
        2,
      );
    });
  });

  group('through real files', () {
    late Directory temp;
    late File dataFile;

    setUp(() async {
      temp = await Directory.systemTemp.createTemp('mynihongo_history_');
      PathProviderPlatform.instance = _FakePathProvider(temp.path);
      final appDir = Directory(p.join(temp.path, 'MyNihongo'));
      await appDir.create(recursive: true);
      dataFile = File(p.join(appDir.path, progressDataFileName));
    });

    tearDown(() async {
      if (temp.existsSync()) await temp.delete(recursive: true);
    });

    Future<List<dynamic>> records() async =>
        (jsonDecode(await dataFile.readAsString())
                as Map<String, dynamic>)['records']
            as List<dynamic>;

    test('analysing the same sentence twice keeps one record', () async {
      await NihongoStorage.recordHistory(
        HistoryEntry.forInput(HistoryKind.lab, 'これは本です。', now: now)!,
        now: now,
      );
      await NihongoStorage.recordHistory(
        HistoryEntry.forInput(HistoryKind.lab, 'これは本です。', now: now)!,
        now: now.add(const Duration(hours: 1)),
      );
      expect((await records()).length, 1);
      final data = await NihongoStorage.load();
      final entries = historyEntries(data.records, kind: HistoryKind.lab);
      expect(entries.single.at, now.add(const Duration(hours: 1)));
    });

    test('the history is capped, oldest dropped first', () async {
      for (var i = 0; i < historyMaxEntries + 5; i++) {
        await NihongoStorage.recordHistory(
          HistoryEntry.forInput(HistoryKind.lab, 'sentence $i')!,
          now: now.add(Duration(minutes: i)),
        );
      }
      final data = await NihongoStorage.load();
      final entries = historyEntries(data.records, kind: HistoryKind.lab);
      expect(entries.length, historyMaxEntries);
      expect(entries.first.text, 'sentence ${historyMaxEntries + 4}');
      expect(entries.map((e) => e.text), isNot(contains('sentence 0')));
    });

    test('one kind being busy does not empty the other', () async {
      await NihongoStorage.recordHistory(
        HistoryEntry.forInput(HistoryKind.writing, 'kept', now: now)!,
        now: now,
      );
      for (var i = 0; i < historyMaxEntries + 5; i++) {
        await NihongoStorage.recordHistory(
          HistoryEntry.forInput(HistoryKind.lab, 'sentence $i')!,
          now: now.add(Duration(minutes: i)),
        );
      }
      final data = await NihongoStorage.load();
      expect(
        historyEntries(data.records, kind: HistoryKind.writing).single.text,
        'kept',
      );
    });

    test('a study record is never pruned by the history cap', () async {
      await NihongoStorage.recordAnswer('vocab:watashi', true, now: now);
      for (var i = 0; i < historyMaxEntries + 5; i++) {
        await NihongoStorage.recordHistory(
          HistoryEntry.forInput(HistoryKind.lab, 'sentence $i')!,
          now: now.add(Duration(minutes: i)),
        );
      }
      final data = await NihongoStorage.load();
      expect(data.recordById('vocab:watashi'), isNotNull);
    });

    test('deleting a record removes it from the file', () async {
      final entry = HistoryEntry.forInput(
        HistoryKind.lab,
        'これは本です。',
        now: now,
      )!;
      await NihongoStorage.recordHistory(entry, now: now);
      expect((await records()).length, 1);
      await NihongoStorage.deleteRecords([entry.id]);
      expect((await records()), isEmpty);
    });

    test('deleting nothing does not rewrite the file', () async {
      await NihongoStorage.recordHistory(
        HistoryEntry.forInput(HistoryKind.lab, 'x', now: now)!,
        now: now,
      );
      final before = await dataFile.lastModified();
      await NihongoStorage.deleteRecords(const []);
      await NihongoStorage.deleteRecords(['lab:nothing-like-this']);
      expect(await dataFile.lastModified(), before);
    });
  });
}
