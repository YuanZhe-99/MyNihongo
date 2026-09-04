import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/models/content_catalog.dart';
import 'package:my_nihongo/features/content/models/jlpt_level.dart';
import 'package:my_nihongo/features/content/services/content_repository.dart';
import 'package:my_nihongo/features/lessons/models/lesson_path.dart';
import 'package:my_nihongo/features/lessons/services/lesson_rules.dart';
import 'package:my_nihongo/features/progress/models/study_record.dart';

/// Purpose: Test the shipped unit files and the rules that open them.
/// Inputs: None.
/// Returns: None.
/// Side effects: Reads the bundled content assets.
/// Notes: Against the **shipped** file rather than a fixture, because the
/// property that makes a path a path — every grammar point of the level in
/// exactly one unit — is a property of the content and not of the code. A unit
/// file that teaches a point twice, or never, is a hole a learner falls into
/// rather than a bug a test can be written around.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ContentCatalog catalog;
  late LessonPath n5;

  setUpAll(() async {
    ContentRepository.parseInIsolate = false;
    catalog = await ContentRepository.load();
    n5 = LessonPath.fromJson(
      jsonDecode(File('assets/content/lessons/n5.json').readAsStringSync()),
    );
  });

  tearDownAll(() => ContentRepository.parseInIsolate = true);

  /// Purpose: Make a progress file from a list of passed unit ids.
  /// Inputs: `passed`.
  /// Returns: `ProgressData`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  ProgressData withPassed(List<String> passed) => ProgressData(
    records: [
      for (final id in passed)
        StudyRecord.create(
          lessonRecordId(id),
        ).copyWith(correct: 1),
    ],
  );

  group('the shipped N5 path', () {
    test('has units, in order, each with a title in both languages', () {
      expect(n5.units, isNotEmpty);
      for (final unit in n5.units) {
        expect(unit.id, startsWith('unit:'));
        expect(unit.title.resolve(const Locale('en')), isNotEmpty);
        expect(unit.title.resolve(const Locale('zh')), isNotEmpty);
      }
    });

    test('teaches every N5 grammar point exactly once', () {
      final expected = {
        for (final point in catalog.grammar)
          if (point.level == JlptLevel.n5) point.id,
      };
      final seen = <String, String>{};
      for (final unit in n5.units) {
        for (final id in unit.grammar) {
          expect(
            seen.containsKey(id),
            isFalse,
            reason: '$id is in ${unit.id} and already in ${seen[id]}',
          );
          seen[id] = unit.id;
        }
      }
      expect(
        expected.difference(seen.keys.toSet()),
        isEmpty,
        reason: 'a point in no unit is a point the path never teaches',
      );
    });

    test('names only words the catalog has, at or below N5', () {
      for (final unit in n5.units) {
        for (final id in unit.vocab) {
          final entry = catalog.vocabById(id);
          expect(entry, isNotNull, reason: '${unit.id} names $id');
          expect(entry!.level, JlptLevel.n5, reason: id);
        }
      }
    });

    test('every authored question can be answered', () {
      for (final unit in n5.units) {
        for (final question in unit.questions) {
          expect(question.options, hasLength(4), reason: question.id);
          expect(
            question.options.toSet(),
            hasLength(4),
            reason: 'two identical options are two right answers',
          );
          expect(question.answer, inInclusiveRange(0, 3));
          expect(
            unit.items,
            contains(question.item),
            reason: '${question.id} records against something this unit does '
                'not teach',
          );
        }
      }
    });

    test('every unit sentence teaches something the unit contains', () {
      for (final unit in n5.units) {
        for (final sentence in unit.sentences) {
          expect(sentence.ja, isNotEmpty);
          expect(sentence.reading, isNotNull);
          expect(
            sentence.items.any(unit.items.contains),
            isTrue,
            reason: '${unit.id}: "${sentence.ja}" teaches nothing here',
          );
        }
      }
    });
  });

  group('which units are open', () {
    test('the first is open and the rest are locked at the start', () {
      final states = unitStates(n5, const ProgressData());
      expect(states[n5.units.first.id], UnitState.open);
      for (final unit in n5.units.skip(1)) {
        expect(states[unit.id], UnitState.locked);
      }
    });

    test('passing one opens the next', () {
      final states = unitStates(n5, withPassed([n5.units.first.id]));
      expect(states[n5.units.first.id], UnitState.passed);
      expect(states[n5.units[1].id], UnitState.open);
      expect(states[n5.units[2].id], UnitState.locked);
    });

    test('passing a later unit opens the one after it', () {
      // Skipping ahead is allowed: the checkpoint of a locked unit can always
      // be attempted, and passing it is the demonstration.
      final states = unitStates(n5, withPassed([n5.units[3].id]));
      expect(states[n5.units[3].id], UnitState.passed);
      expect(states[n5.units[4].id], UnitState.open);
    });

    test('a locked unit still offers its checkpoint', () {
      expect(canAttemptCheckpoint(UnitState.locked), isTrue);
    });

    test('the next unit is the first one open', () {
      expect(nextUnit(n5, unitStates(n5, const ProgressData()))?.id,
          n5.units.first.id);
      final done = withPassed([for (final unit in n5.units) unit.id]);
      expect(nextUnit(n5, unitStates(n5, done)), isNull);
    });
  });

  group('how far through a unit the learner is', () {
    test('nothing answered is nothing done', () {
      expect(unitProgress(n5.units.first, const ProgressData()), 0);
    });

    test('an item answered right counts, and only once', () {
      final unit = n5.units.first;
      final progress = ProgressData(
        records: [
          StudyRecord.create(unit.items.first).copyWith(correct: 3),
        ],
      );
      expect(
        unitProgress(unit, progress),
        closeTo(1 / unit.items.length, 0.0001),
      );
    });

    test('an item only ever answered wrong does not count', () {
      final unit = n5.units.first;
      final progress = ProgressData(
        records: [StudyRecord.create(unit.items.first).copyWith(wrong: 2)],
      );
      expect(unitProgress(unit, progress), 0);
    });
  });

  test('a lessons file that will not parse is an empty path, not a crash', () {
    expect(LessonPath.fromJson('nonsense').units, isEmpty);
    expect(LessonPath.fromJson({'units': 'nonsense'}).units, isEmpty);
    expect(
      LessonPath.fromJson({
        'units': [
          {'title': 'no id here'},
        ],
      }).units,
      isEmpty,
      reason: 'a unit with no id has nothing to record progress against',
    );
  });
}
