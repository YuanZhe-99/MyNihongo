import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/models/content_catalog.dart';
import 'package:my_nihongo/features/content/models/jlpt_level.dart';
import 'package:my_nihongo/features/content/services/content_repository.dart';
import 'package:my_nihongo/features/drills/models/drill_file.dart';
import 'package:my_nihongo/features/drills/models/drill_section.dart';

/// Purpose: Test the drill files that actually ship, rather than a fixture.
/// Inputs: `assets/content/drills/`.
/// Returns: None.
/// Side effects: Reads the shipped assets.
/// Notes: The gate checks a draft before it is merged; this checks what came
/// out the other side. They overlap on purpose. A merge is a script, a script
/// can be run with the wrong flags, and the failure that would produce — an N5
/// grammar question sitting in the vocabulary file — is invisible in a diff
/// and fatal on a results screen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ContentCatalog catalog;
  late JlptStructure structure;
  final files = <(JlptLevel, DrillSection), DrillFile>{};

  setUpAll(() async {
    ContentRepository.parseInIsolate = false;
    catalog = await ContentRepository.load();
    ContentRepository.parseInIsolate = true;
    structure = JlptStructure.fromJson(
      jsonDecode(
        File('assets/content/drills/structure.json').readAsStringSync(),
      ),
    );
    for (final level in JlptLevel.values) {
      for (final section in DrillSection.values) {
        final file = File(
          'assets/content/drills/${level.name}-${section.name}.json',
        );
        if (!file.existsSync()) continue;
        files[(level, section)] = DrillFile.fromJson(
          jsonDecode(file.readAsStringSync()),
          level: level,
          section: section,
        );
      }
    }
  });

  test('the structure file describes every level', () {
    expect(structure.source, isNotEmpty, reason: 'whose numbers are these?');
    for (final level in JlptLevel.values) {
      final entry = structure.forLevel(level);
      expect(entry, isNotNull, reason: '${level.label} has no paper');
      expect(entry!.blocks, isNotEmpty);
      expect(entry.scoring, isNotEmpty);
      expect(entry.overallPass, greaterThan(0));
      expect(entry.overallPass, lessThan(entry.overallMax));
    }
  });

  test('a full paper is the length the feature doc says it is', () {
    // Pinned because `features/jlpt-practice.md` prints these five numbers,
    // and a table in a document is the one place a silent edit to the
    // structure file would not show up.
    expect(
      {
        for (final level in JlptLevel.values)
          level.label: structure.forLevel(level)!.fullCount,
      },
      {'N5': 67, 'N4': 85, 'N3': 102, 'N2': 107, 'N1': 108},
    );
  });

  test('every block examines sections the level has 大問 for', () {
    for (final level in JlptLevel.values) {
      final entry = structure.forLevel(level)!;
      final examined = {for (final block in entry.blocks) ...block.sections};
      final asked = {for (final type in entry.types.keys) type.section};
      expect(
        asked.difference(examined),
        isEmpty,
        reason: '${level.label} asks a section no block gives time to',
      );
      expect(
        examined.difference(asked),
        isEmpty,
        reason: '${level.label} times a section it asks nothing about',
      );
    }
  });

  test('every section is scored in exactly one group', () {
    for (final level in JlptLevel.values) {
      final entry = structure.forLevel(level)!;
      for (final section in DrillSection.values) {
        final groups = [
          for (final group in entry.scoring)
            if (group.sections.contains(section)) group.id,
        ];
        expect(
          groups.length,
          1,
          reason: '${level.label} scores ${section.name} in $groups',
        );
      }
    }
  });

  test('every shipped file loads and none is empty', () {
    expect(files, isNotEmpty, reason: 'no drill content ships at all');
    for (final entry in files.entries) {
      expect(
        entry.value.questions,
        isNotEmpty,
        reason:
            '${entry.key.$1.label} ${entry.key.$2.name} loaded no questions, '
            'which means the file disagrees with its own name',
      );
    }
  });

  test('a question id names exactly one question, across every file', () {
    // "Already asked" is remembered by question id. Two questions under one
    // id would make that mean whichever the file happened to list first.
    final seen = <String, String>{};
    for (final entry in files.entries) {
      final where = '${entry.key.$1.label} ${entry.key.$2.name}';
      for (final question in entry.value.questions) {
        expect(
          seen[question.id],
          isNull,
          reason: '${question.id} is in $where and in ${seen[question.id]}',
        );
        seen[question.id] = where;
      }
    }
  });

  test('a passage id names exactly one passage', () {
    final seen = <String>{};
    for (final file in files.values) {
      for (final passage in file.passages) {
        expect(seen.add(passage.id), isTrue, reason: '${passage.id} twice');
      }
    }
  });

  test('every question is filed under the section it is scored in', () {
    for (final entry in files.entries) {
      for (final question in entry.value.questions) {
        expect(
          question.type.section,
          entry.key.$2,
          reason:
              '${question.id} is a ${question.type.key} question in the '
              '${entry.key.$2.name} file',
        );
      }
    }
  });

  test('every question is a 大問 its level actually has', () {
    for (final entry in files.entries) {
      final composition = structure.forLevel(entry.key.$1)!.types;
      for (final question in entry.value.questions) {
        expect(
          composition.containsKey(question.type),
          isTrue,
          reason:
              '${question.id} is a ${question.type.key}, which is not on '
              'the ${entry.key.$1.label} paper',
        );
      }
    }
  });

  test('every question records against something the app ships', () {
    for (final entry in files.entries) {
      for (final question in entry.value.questions) {
        expect(question.items, isNotEmpty, reason: '${question.id} has none');
        for (final id in question.items) {
          final word = catalog.vocabById(id);
          final point = catalog.grammarById(id);
          expect(
            word != null || point != null,
            isTrue,
            reason: '${question.id}: $id is in no catalog',
          );
          final level = word?.level ?? point!.level;
          expect(
            level.index,
            greaterThanOrEqualTo(entry.key.$1.index),
            reason:
                '${question.id}: $id is ${level.label}, harder than the '
                'paper it is on',
          );
        }
      }
    }
  });

  test('every passage is asked about and every reference resolves', () {
    for (final entry in files.entries) {
      final referenced = <String>{};
      for (final question in entry.value.questions) {
        final id = question.passageId;
        if (id == null) {
          expect(
            question.type.needsPassage,
            isFalse,
            reason: '${question.id} is a ${question.type.key} with no passage',
          );
          continue;
        }
        referenced.add(id);
        final passage = entry.value.passageById(id);
        expect(passage, isNotNull, reason: '${question.id} points at $id');
        expect(
          passage!.type,
          question.type,
          reason:
              '${question.id} is a ${question.type.key} on a '
              '${passage.type.key} passage',
        );
      }
      for (final passage in entry.value.passages) {
        expect(
          referenced.contains(passage.id),
          isTrue,
          reason: '${passage.id} is asked no questions, so it is dead weight',
        );
      }
    }
  });

  test('every option is distinct, and there are four of them', () {
    for (final file in files.values) {
      for (final question in file.questions) {
        expect(
          question.options,
          hasLength(4),
          reason: '${question.id} has ${question.options.length}',
        );
        expect(
          question.options.toSet(),
          hasLength(4),
          reason: '${question.id} has two right answers',
        );
      }
    }
  });

  test('a marked or gapped question has something to mark', () {
    for (final file in files.values) {
      for (final question in file.questions) {
        if (question.blank == null) continue;
        expect(
          question.ja,
          isNotNull,
          reason: '${question.id} marks a span of nothing',
        );
        expect(
          question.ja!.contains(question.blank!),
          isTrue,
          reason: '${question.id}: "${question.blank}" is not in its sentence',
        );
        expect(
          question.renderJa(),
          isNot(question.ja),
          reason:
              '${question.id} renders identically with and without its '
              'blank, so the learner cannot see what is being asked',
        );
      }
    }
  });

  test('an ordering question rebuilds its own sentence', () {
    for (final file in files.values) {
      for (final question in file.questions) {
        if (question.answerOrder.isEmpty) continue;
        final ordered = [for (var i = 0; i < question.options.length; i++) i]
          ..sort(
            (a, b) =>
                question.answerOrder[a].compareTo(question.answerOrder[b]),
          );
        final built =
            '${question.frameBefore ?? ''}'
            '${[for (final i in ordered) question.options[i]].join()}'
            '${question.frameAfter ?? ''}';
        expect(
          built,
          question.ja,
          reason: '${question.id} builds a different sentence',
        );
      }
    }
  });

  test('a level that ships a section ships the whole 大問 it promises', () {
    // The composition is what makes a paper a paper. A section that shipped
    // four of its five 大問 would quietly stop examining the fifth, and the
    // results screen would show a full-looking paper.
    for (final entry in files.entries) {
      final composition = structure.forLevel(entry.key.$1)!.types;
      final counts = <DrillType, int>{};
      for (final question in entry.value.questions) {
        counts[question.type] = (counts[question.type] ?? 0) + 1;
      }
      for (final wanted in composition.entries) {
        if (wanted.key.section != entry.key.$2) continue;
        expect(
          counts[wanted.key] ?? 0,
          greaterThanOrEqualTo(wanted.value),
          reason:
              '${entry.key.$1.label} ships ${counts[wanted.key] ?? 0} '
              '${wanted.key.key} questions; a full paper asks ${wanted.value}',
        );
      }
    }
  });
}
