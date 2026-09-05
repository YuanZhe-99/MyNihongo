import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/models/content_catalog.dart';
import 'package:my_nihongo/features/content/models/jlpt_level.dart';
import 'package:my_nihongo/features/content/services/content_repository.dart';
import 'package:my_nihongo/features/content/services/furigana_aligner.dart';
import 'package:my_nihongo/features/drills/models/drill_file.dart';
import 'package:my_nihongo/features/drills/models/drill_section.dart';
import 'package:my_nihongo/features/sentence/models/token.dart';
import 'package:my_nihongo/features/sentence/services/lexicon.dart';
import 'package:my_nihongo/features/sentence/services/sentence_analyzer.dart';

import '../tool/draft_inputs.dart' show drillTypeSections;

/// Purpose: Judge one draft content file against everything the shipped
/// catalog and its tests require, and report **every** problem at once.
/// Inputs: The path in the `CONTENT_DRAFT` environment variable.
/// Returns: None.
/// Side effects: Reads the bundled content assets and the draft file.
/// Notes: Skipped entirely when `CONTENT_DRAFT` is not set, so it costs
/// nothing in an ordinary run and never appears in CI.
///
/// This exists because content is written in batches by agents that do not run
/// the build. The alternative — merge a batch, run the whole suite, and get one
/// failure at a time — turns a fifty-word batch into fifty round trips. So the
/// gate collects every problem in a file and prints them together, and a batch
/// is normally fixed in one pass.
///
/// **What it can check:** that the Japanese parses with the words the app
/// ships, that a reading matches the sentence it belongs to, that ids are new
/// and well formed, that all three languages are present, that a grammar point
/// can be asked about at all, and that nothing leans on a word from a harder
/// level. **What it cannot check:** whether the Japanese is natural, or the
/// translation faithful. That needs a reader, and `content-authoring.md` says
/// so rather than pretending otherwise.
///
/// ```
/// CONTENT_DRAFT=tool/content/drafts/gloss/n4-01.json \
///   flutter test test/content_gate_test.dart
/// ```
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final path = Platform.environment['CONTENT_DRAFT'];
  if (path == null || path.isEmpty) {
    test('no draft to check', () {}, skip: 'CONTENT_DRAFT is not set');
    return;
  }

  late ContentCatalog catalog;
  late SentenceAnalyzer analyzer;
  late Map<String, Object?> draft;
  final problems = <String>[];

  setUpAll(() async {
    ContentRepository.parseInIsolate = false;
    catalog = await ContentRepository.load();
    analyzer = SentenceAnalyzer(
      lexicon: Lexicon.build(catalog, functionWords: await loadFunctionWords()),
      catalog: catalog,
    );
    final file = File(path);
    if (!file.existsSync()) throw StateError('No draft at $path');
    draft = (jsonDecode(file.readAsStringSync()) as Map)
        .cast<String, Object?>();
  });

  tearDownAll(() => ContentRepository.parseInIsolate = true);

  /// Purpose: Record one problem.
  /// Inputs: `ok` and the `message` to record when it is false.
  /// Returns: None.
  /// Side effects: Appends to `problems`.
  /// Notes: Internal helper used within this file only. Nothing throws: the
  /// value of this file is the **whole** list of what is wrong.
  void need(bool ok, String message) {
    if (!ok) problems.add(message);
  }

  /// Purpose: Check one Japanese sentence the way the shipped tests do.
  /// Inputs: A `label` for the report, the sentence `ja`, its `reading`, and
  /// the `level` at or below which every word it uses must sit.
  /// Returns: None.
  /// Side effects: Appends to `problems`.
  /// Notes: Internal helper used within this file only. Three separate rules,
  /// each of which a shipped test already enforces on the catalog: the
  /// sentence tokenizes with no unknown word (`sentence_analyzer_test`), the
  /// words it uses are at or below its own level (`content_links_test`), and
  /// the reading aligns with the sentence, which is both a furigana
  /// requirement and the cheapest possible check that the reading is actually
  /// this sentence's.
  void sentence(String label, String ja, String? reading, JlptLevel level) {
    if (ja.trim().isEmpty) {
      need(false, '$label: empty sentence');
      return;
    }
    final analysis = analyzer.analyze(ja);
    final unknown = analysis.tokens
        .where((t) => t.category == TokenCategory.unknown)
        .map((t) => t.surface)
        .toList();
    need(
      unknown.isEmpty,
      '$label: "$ja" uses ${unknown.join('/')}, which is in no catalog the '
      'app ships. Rewrite it with words the level already has.',
    );
    // **There is no level check on the words a sentence parses into**, and
    // there was one until the N4 batches were written. Every finding it
    // produced turned out to be about the parse rather than about the
    // sentence: 使い方 segments into the rare noun 使い, お借りしました into
    // 借り, and これ is filed at N1 because that is the only JLPT list it
    // appears on. Three rounds of narrowing it — single characters, then one
    // level of slack, then rare words — removed every true positive it had
    // and left the false ones.
    //
    // The invariant is still enforced, by `content_links_test` on the merged
    // file, where it works on the catalog's own cross-links rather than on a
    // parse. A gate that cries wolf is worse than no gate: its whole value is
    // that an author can trust the list it prints.

    if (reading == null || reading.isEmpty) {
      need(false, '$label: no reading');
      return;
    }
    need(
      alignFurigana(ja, reading) != null,
      '$label: the reading "$reading" does not line up with "$ja". Every kana '
      'of the sentence has to appear in the reading, in order.',
    );
  }

  test('the draft is one this build understands', () {
    need(draft['kind'] is String, 'the file needs a top-level "kind"');
    need(
      JlptLevel.parse('${draft['level']}') != null,
      '"${draft['level']}" is not a JLPT level',
    );
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('every gloss names a word that needs one', () {
    if (draft['kind'] != 'gloss') return;
    final rows = draft['rows'] as List? ?? const [];
    need(rows.isNotEmpty, 'no rows');
    final seen = <String>{};
    for (final row in rows) {
      if (row is! Map) {
        need(false, 'a row that is not an object');
        continue;
      }
      final id = '${row['id']}';
      need(seen.add(id), '$id appears twice');
      if (catalog.vocabById(id) == null) {
        need(false, '$id is not in the catalog');
        continue;
      }
      final zh = row['zh'];
      if (zh is! List || zh.isEmpty) {
        need(false, '$id: "zh" has to be a non-empty list of meanings');
        continue;
      }
      for (final meaning in zh) {
        final text = '$meaning'.trim();
        need(text.isNotEmpty, '$id: an empty meaning');
        need(
          !RegExp(r'[\u3040-\u30FF]').hasMatch(text),
          '$id: "$text" contains kana. The gloss is Chinese; a Japanese word '
          'quoted inside it belongs in tool/content/opencc/preserve.txt.',
        );
        need(
          !RegExp('[A-Za-z]{3,}').hasMatch(text),
          '$id: "$text" still contains English.',
        );
        need(text.length <= 20, '$id: "$text" is too long for a list row.');
      }
    }
    expect(problems, isEmpty, reason: '\n${problems.join('\n')}');
  });

  test('every example sentence uses the word it belongs to', () {
    if (draft['kind'] != 'examples') return;
    final level = JlptLevel.parse('${draft['level']}')!;
    final rows = draft['rows'] as List? ?? const [];
    need(rows.isNotEmpty, 'no rows');
    final seen = <String>{};
    for (final row in rows) {
      if (row is! Map) {
        need(false, 'a row that is not an object');
        continue;
      }
      final id = '${row['id']}';
      need(seen.add(id), '$id appears twice');
      final entry = catalog.vocabById(id);
      if (entry == null) {
        need(false, '$id is not in the catalog');
        continue;
      }
      final examples = row['examples'];
      if (examples is! List || examples.isEmpty) {
        need(false, '$id: "examples" has to be a non-empty list');
        continue;
      }
      for (var i = 0; i < examples.length; i++) {
        final example = examples[i];
        final label = '$id#$i';
        if (example is! Map) {
          need(false, '$label: not an object');
          continue;
        }
        final ja = '${example['ja']}';
        sentence(label, ja, example['reading'] as String?, level);
        for (final language in const ['en', 'zh']) {
          need(
            '${example[language] ?? ''}'.trim().isNotEmpty,
            '$label: no "$language" translation',
          );
        }
        // The sentence has to be about the word it is filed under, in any of
        // its forms — the analyser resolves 食べます back to 食べる.
        // The sentence has to be about the word it is filed under. Three
        // ways to show that, because the first two both miss inflected forms
        // of a word that shares a surface with another entry: 降ります is 降る
        // here, and the analyser resolves it to 降りる. The stem — the
        // headword minus its conjugating kana — is what an inflected form
        // still contains, and a false accept costs nothing next to rejecting
        // a sentence the author wrote about exactly this word.
        final stem = entry.headword.length > 1
            ? entry.headword.substring(0, entry.headword.length - 1)
            : entry.headword;
        final readingStem = entry.reading.length > 1
            ? entry.reading.substring(0, entry.reading.length - 1)
            : entry.reading;
        need(
          analyzer.analyze(ja).tokens.any((t) => t.refId == id) ||
              ja.contains(entry.headword) ||
              ja.contains(entry.reading) ||
              ja.contains(stem) ||
              ja.contains(readingStem),
          '$label: "$ja" does not use ${entry.headword}.',
        );
        need(
          ja.length >= 6 && ja.length <= 42,
          '$label: "$ja" is ${ja.length} characters; aim for 6 to 42.',
        );
      }
    }
    expect(problems, isEmpty, reason: '\n${problems.join('\n')}');
  });

  test('every grammar point can be taught and asked about', () {
    if (draft['kind'] != 'grammar') return;
    final level = JlptLevel.parse('${draft['level']}')!;
    final points = draft['points'] as List? ?? const [];
    need(points.isNotEmpty, 'no points');
    final shipped = {for (final point in catalog.grammar) point.id};
    final seen = <String>{};
    for (final raw in points) {
      if (raw is! Map) {
        need(false, 'a point that is not an object');
        continue;
      }
      final id = '${raw['id']}';
      need(
        RegExp(r'^grammar:[a-z0-9-]+$').hasMatch(id),
        '"$id" is not a grammar id: lowercase, digits and hyphens after '
        '"grammar:".',
      );
      need(seen.add(id), '$id appears twice in this file');
      need(
        !shipped.contains(id),
        '$id is already shipped. A shipped id never changes meaning; pick '
        'another slug.',
      );
      need(
        '${raw['level']}' == level.label,
        '$id: level is "${raw['level']}", the file says ${level.label}',
      );
      need('${raw['pattern'] ?? ''}'.trim().isNotEmpty, '$id: no pattern');
      need('${raw['structure'] ?? ''}'.trim().isNotEmpty, '$id: no structure');

      for (final field in const ['meaning', 'explanation']) {
        final value = raw[field];
        if (value is! Map) {
          need(false, '$id: "$field" has to be an object of languages');
          continue;
        }
        for (final language in const ['en', 'zh']) {
          need(
            '${value[language] ?? ''}'.trim().isNotEmpty,
            '$id: "$field" has no "$language"',
          );
        }
        need(
          value['zh_TW'] == null,
          '$id: do not write "zh_TW" — it is generated from "zh" by '
          'tool/convert_zh_tw.dart, and a hand-written one fails its test.',
        );
      }

      final match = raw['match'];
      need(
        match is List && match.isNotEmpty,
        '$id: "match" lists the literal forms the analyser should find, and '
        'the quiz needs at least one.',
      );

      final examples = raw['examples'];
      if (examples is! List || examples.length < 2) {
        need(false, '$id: two example sentences, at least');
        continue;
      }
      for (var i = 0; i < examples.length; i++) {
        final example = examples[i];
        final label = '$id#$i';
        if (example is! Map) {
          need(false, '$label: not an object');
          continue;
        }
        final ja = '${example['ja']}';
        sentence(label, ja, example['reading'] as String?, level);
        for (final language in const ['en', 'zh']) {
          need(
            '${example[language] ?? ''}'.trim().isNotEmpty,
            '$label: no "$language" translation',
          );
        }
        if (match is List && match.isNotEmpty) {
          need(
            match.any((form) => ja.contains('$form')),
            '$label: "$ja" contains none of $match, so the analyser cannot '
            'find this point in its own example.',
          );
        }
      }
    }
    expect(problems, isEmpty, reason: '\n${problems.join('\n')}');
  });

  test('every unit is a topic the level actually covers', () {
    if (draft['kind'] != 'units') return;
    final level = JlptLevel.parse('${draft['level']}')!;
    final units = draft['units'] as List? ?? const [];
    need(units.isNotEmpty, 'no units');

    final levelPoints = {
      for (final point in catalog.grammar)
        if (point.level == level) point.id,
    };
    final used = <String, String>{};
    final unitIds = <String>{};

    for (final raw in units) {
      if (raw is! Map) {
        need(false, 'a unit that is not an object');
        continue;
      }
      final id = '${raw['id']}';
      need(
        RegExp(r'^unit:[a-z0-9-]+$').hasMatch(id),
        '"$id" is not a unit id: "unit:" then lowercase, digits and hyphens.',
      );
      need(unitIds.add(id), '$id appears twice');

      final title = raw['title'];
      for (final language in const ['en', 'zh']) {
        need(
          title is Map && '${title[language] ?? ''}'.trim().isNotEmpty,
          '$id: the title has no "$language"',
        );
      }

      final grammar = raw['grammar'] as List? ?? const [];
      need(
        grammar.length >= 4 && grammar.length <= 14,
        '$id: ${grammar.length} grammar points; a unit holds 4 to 14.',
      );
      for (final point in grammar) {
        final pointId = '$point';
        need(
          levelPoints.contains(pointId),
          '$id: $pointId is not a ${level.label} grammar point.',
        );
        final other = used[pointId];
        need(
          other == null,
          '$id: $pointId is already in $other. Every point belongs to exactly '
          'one unit, or the path teaches it twice and never at all.',
        );
        used[pointId] = id;
      }

      final vocab = raw['vocab'] as List? ?? const [];
      need(
        vocab.length >= 6 && vocab.length <= 30,
        '$id: ${vocab.length} words; a unit holds 6 to 30.',
      );
      for (final word in vocab) {
        final entry = catalog.vocabById('$word');
        if (entry == null) {
          need(false, '$id: $word is not in the catalog');
          continue;
        }
        need(
          entry.level.index <= level.index,
          '$id: ${entry.headword} is ${entry.level.label}, harder than the '
          'unit.',
        );
      }

      final own = {...grammar.map((g) => '$g'), ...vocab.map((v) => '$v')};

      for (final row in raw['sentences'] as List? ?? const []) {
        if (row is! Map) {
          need(false, '$id: a sentence that is not an object');
          continue;
        }
        final ja = '${row['ja']}';
        final label = '$id "$ja"';
        sentence(label, ja, row['reading'] as String?, level);
        for (final language in const ['en', 'zh']) {
          need(
            '${row[language] ?? ''}'.trim().isNotEmpty,
            '$label: no "$language" translation',
          );
        }
        final items = row['items'] as List? ?? const [];
        need(
          items.any((item) => own.contains('$item')),
          '$label: none of its "items" belong to this unit, so it teaches '
          'nothing here.',
        );
      }

      for (final row in raw['questions'] as List? ?? const []) {
        if (row is! Map) {
          need(false, '$id: a question that is not an object');
          continue;
        }
        final qid = '${row['id']}';
        need(
          RegExp(r'^q:[a-z0-9-]+$').hasMatch(qid),
          '$id: "$qid" is not a question id.',
        );
        need(
          own.contains('${row['item']}'),
          '$qid: "${row['item']}" is not in this unit, so a right answer '
          'would be recorded against something the unit does not teach.',
        );
        final options = row['options'] as List? ?? const [];
        need(options.length == 4, '$qid: four options, not ${options.length}');
        need(
          options.map((o) => '$o').toSet().length == options.length,
          '$qid: two identical options are two right answers.',
        );
        final answer = row['answer'];
        need(
          answer is int && answer >= 0 && answer < options.length,
          '$qid: "answer" is the index of the right option.',
        );
        for (final field in const ['prompt', 'explanation']) {
          final value = row[field];
          for (final language in const ['en', 'zh']) {
            need(
              value is Map && '${value[language] ?? ''}'.trim().isNotEmpty,
              '$qid: "$field" has no "$language"',
            );
          }
        }
      }

      final scenario = raw['scenario'];
      if (scenario is Map) {
        final lines = scenario['dialogue'] as List? ?? const [];
        need(
          lines.length >= 4,
          '$id: a scenario with ${lines.length} lines is not a conversation.',
        );
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line is! Map) {
            need(false, '$id scenario#$i: not an object');
            continue;
          }
          need(
            '${line['speaker'] ?? ''}'.trim().isNotEmpty,
            '$id scenario#$i: no speaker',
          );
          sentence(
            '$id scenario#$i',
            '${line['ja']}',
            line['reading'] as String?,
            level,
          );
          for (final language in const ['en', 'zh']) {
            need(
              '${line[language] ?? ''}'.trim().isNotEmpty,
              '$id scenario#$i: no "$language" translation',
            );
          }
        }

        // A branch stops the script and asks the learner what to say. Both
        // halves of that have to hold: the stop has to be inside the script,
        // and the question has to have exactly one expected answer.
        for (final row in scenario['branches'] as List? ?? const []) {
          if (row is! Map) {
            need(false, '$id scenario: a branch that is not an object');
            continue;
          }
          final after = row['after'];
          need(
            after is int && after >= 1 && after <= lines.length,
            '$id scenario: "after" is $after, which is not a line of a '
            '${lines.length}-line conversation.',
          );
          final choices = row['choices'] as List? ?? const [];
          need(
            choices.length >= 2,
            '$id scenario after $after: ${choices.length} choices; one choice '
            'is not a choice.',
          );
          var right = 0;
          for (var i = 0; i < choices.length; i++) {
            final choice = choices[i];
            if (choice is! Map) {
              need(false, '$id scenario after $after: choice#$i not an object');
              continue;
            }
            if (choice['correct'] == true) right++;
            sentence(
              '$id scenario after $after choice#$i',
              '${choice['ja']}',
              choice['reading'] as String?,
              level,
            );
            for (final language in const ['en', 'zh']) {
              need(
                '${choice[language] ?? ''}'.trim().isNotEmpty,
                '$id scenario after $after choice#$i: no "$language"',
              );
            }
          }
          need(
            right == 1,
            '$id scenario after $after: $right choices are marked correct; '
            'the tally at the end counts exactly one.',
          );
        }
      }
    }

    final missing = levelPoints.difference(used.keys.toSet());
    need(
      missing.isEmpty,
      '${missing.length} ${level.label} grammar points are in no unit, so the '
      'path never teaches them: ${missing.take(20).join(', ')}'
      '${missing.length > 20 ? ' ...' : ''}',
    );
    expect(problems, isEmpty, reason: '\n${problems.join('\n')}');
  });

  test('every drill question could be asked on a paper', () {
    if (draft['kind'] != 'drills') return;
    final level = JlptLevel.parse('${draft['level']}')!;
    final section = DrillSection.parse(draft['section']);
    need(section != null, '"${draft['section']}" is not a section');
    if (section == null) {
      expect(problems, isEmpty, reason: '\n${problems.join('\n')}');
      return;
    }

    // The two tables that have to agree: the app's `DrillType` and the plain
    // Dart copy the batch generator uses. They are separate because `tool/`
    // must not depend on Flutter, so this is where the copy is checked.
    for (final type in DrillType.values) {
      need(
        drillTypeSections[type.key] == type.section.name,
        'tool/draft_inputs.dart files ${type.key} under '
        '"${drillTypeSections[type.key]}", the app under '
        '"${type.section.name}"',
      );
    }

    final structure = JlptStructure.fromJson(
      jsonDecode(
        File('assets/content/drills/structure.json').readAsStringSync(),
      ),
    );
    final composition = structure.forLevel(level)?.types ?? const {};
    need(
      composition.isNotEmpty,
      'structure.json has no ${level.label}, so there is no paper to write '
      'for',
    );

    // Every id already shipped anywhere at this level. Ids are unique across
    // sections, not only within one: a question id is what "already asked"
    // is remembered by, and two questions under one id would make that mean
    // whichever the file happened to list first.
    final taken = <String>{};
    final takenPassages = <String>{};
    for (final other in DrillSection.values) {
      final file = File(
        'assets/content/drills/${level.name}-${other.name}.json',
      );
      if (!file.existsSync()) continue;
      final json = jsonDecode(file.readAsStringSync()) as Map;
      for (final question in (json['questions'] as List? ?? const [])) {
        if (question is Map) taken.add('${question['id']}');
      }
      for (final passage in (json['passages'] as List? ?? const [])) {
        if (passage is Map) takenPassages.add('${passage['id']}');
      }
    }

    final letter = switch (section) {
      DrillSection.vocab => 'v',
      DrillSection.grammar => 'g',
      DrillSection.reading => 'r',
      DrillSection.listening => 'l',
    };
    final idShape = RegExp('^q:${level.name}-$letter-\\d{3,4}\$');
    final passageShape = RegExp('^p:${level.name}-$letter-\\d{3,4}\$');

    /// Purpose: Check that a localized block has both languages.
    /// Inputs: The `label`, the block, and whether it is `required`.
    /// Returns: None.
    /// Side effects: Appends to `problems`.
    /// Notes: Internal helper used within this test only. `zh_TW` is refused
    /// rather than accepted-and-ignored: every Traditional string in the repo
    /// is generated from the Simplified beside it, so a hand-written one is a
    /// string that silently stops matching the moment the Simplified changes.
    void localized(String label, Object? block, {bool required = true}) {
      if (block == null) {
        need(!required, '$label: missing');
        return;
      }
      if (block is! Map) {
        need(false, '$label: not an object of languages');
        return;
      }
      need(block['zh_TW'] == null, '$label: zh_TW is generated, not written');
      for (final language in const ['en', 'zh']) {
        need(
          '${block[language] ?? ''}'.trim().isNotEmpty,
          '$label: no "$language"',
        );
      }
    }

    final passages = draft['passages'] as List? ?? const [];
    final passageIds = <String>{};
    final passageTypes = <String, String>{};
    for (final raw in passages) {
      if (raw is! Map) {
        need(false, 'a passage that is not an object');
        continue;
      }
      final id = '${raw['id']}';
      need(
        passageShape.hasMatch(id),
        '$id: not shaped p:${level.name}-$letter-NNN',
      );
      need(
        !takenPassages.contains(id) && passageIds.add(id),
        '$id: this passage id is already taken',
      );
      final type = '${raw['type']}';
      passageTypes[id] = type;
      need(
        DrillType.parse(type) != null,
        '$id: "$type" is not a question type',
      );
      final lines = raw['lines'] as List? ?? const [];
      need(lines.isNotEmpty, '$id: a passage with no lines');
      var translated = false;
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line is! Map) {
          need(false, '$id line $i: not an object');
          continue;
        }
        sentence(
          '$id line $i',
          '${line['ja']}',
          line['reading'] as String?,
          level,
        );
        need(line['zh_TW'] == null, '$id line $i: zh_TW is generated');
        if ('${line['en'] ?? ''}'.trim().isNotEmpty) translated = true;
      }
      // Either every line is translated or the passage is, and at least one
      // of the two: a listening script is followed line by line and a reading
      // text is read whole, so which one carries the translation depends on
      // what the passage is for.
      final whole = raw['en'] != null || raw['zh'] != null;
      need(
        translated || whole,
        '$id: no translation, on the passage or on any line',
      );
      if (whole) {
        localized('$id translation', {'en': raw['en'], 'zh': raw['zh']});
      }
      need(raw['zh_TW'] == null, '$id: zh_TW is generated, not written');
    }

    final questions = draft['questions'] as List? ?? const [];
    need(questions.isNotEmpty, 'no questions');
    final ids = <String>{};
    final referenced = <String>{};
    for (final raw in questions) {
      if (raw is! Map) {
        need(false, 'a question that is not an object');
        continue;
      }
      final id = '${raw['id']}';
      need(idShape.hasMatch(id), '$id: not shaped q:${level.name}-$letter-NNN');
      need(
        !taken.contains(id) && ids.add(id),
        '$id: this question id is already taken',
      );

      final type = DrillType.parse(raw['type']);
      if (type == null) {
        need(false, '$id: "${raw['type']}" is not a question type');
        continue;
      }
      need(
        type.section == section,
        '$id: ${type.key} is a ${type.section.name} question in the '
        '${section.name} file',
      );
      need(
        composition.containsKey(type),
        '$id: ${level.label} has no ${type.key} 大問, so this question is not '
        'on the paper',
      );

      final items = raw['items'] as List? ?? const [];
      need(items.isNotEmpty, '$id: no "items", so nothing to record it under');
      for (final item in items) {
        final itemId = '$item';
        final entry = catalog.vocabById(itemId);
        final point = catalog.grammarById(itemId);
        if (entry == null && point == null) {
          need(false, '$id: item $itemId is in no catalog the app ships');
          continue;
        }
        final itemLevel = entry?.level ?? point!.level;
        need(
          itemLevel.index >= level.index,
          '$id: item $itemId is ${itemLevel.label}, harder than ${level.label}',
        );
      }

      localized('$id prompt', raw['prompt']);
      localized('$id explanation', raw['explanation']);
      need(raw['zh_TW'] == null, '$id: zh_TW is generated, not written');

      final options = raw['options'] as List? ?? const [];
      need(options.length == 4, '$id: ${options.length} options, not 4');
      need(
        options.map((o) => '$o').toSet().length == options.length,
        '$id: two options are the same, so two answers are right',
      );
      for (final option in options) {
        need('$option'.trim().isNotEmpty, '$id: an empty option');
      }

      final kind = '${raw['kind'] ?? 'choice'}';
      if (kind == 'order') {
        final order = [
          for (final index in (raw['answerOrder'] as List? ?? const []))
            if (index is int) index,
        ];
        final sorted = [...order]..sort();
        need(
          sorted.length == options.length &&
              sorted.asMap().entries.every((e) => e.value == e.key),
          '$id: "answerOrder" is not a permutation of the four fragments',
        );
        if (sorted.length == options.length) {
          final ordered = [for (var i = 0; i < options.length; i++) i]
            ..sort((a, b) => order[a].compareTo(order[b]));
          final built =
              '${raw['frame'] is Map ? (raw['frame'] as Map)['before'] ?? '' : ''}'
              '${[for (final i in ordered) options[i]].join()}'
              '${raw['frame'] is Map ? (raw['frame'] as Map)['after'] ?? '' : ''}';
          need(
            built == '${raw['ja']}',
            '$id: the frame and the ordered fragments build "$built", not '
            '"${raw['ja']}"',
          );
        }
      } else {
        need(kind == 'choice', '$id: "$kind" is not an answer kind');
        final answer = raw['answer'];
        need(
          answer is int && answer >= 0 && answer < options.length,
          '$id: "answer" is not one of the options',
        );
      }

      final ja = raw['ja'];
      if (ja != null) {
        sentence(id, '$ja', raw['reading'] as String?, level);
        final blank = raw['blank'];
        if (blank != null) {
          need(
            '$ja'.contains('$blank'),
            '$id: "$blank" is not in "$ja", so there is nothing to mark',
          );
        }
      }

      final passage = raw['passage'];
      if (passage != null) {
        referenced.add('$passage');
        need(
          passageIds.contains('$passage') || takenPassages.contains('$passage'),
          '$id: no passage "$passage"',
        );
        need(
          passageTypes['$passage'] == null ||
              passageTypes['$passage'] == type.key,
          '$id: passage $passage is a ${passageTypes['$passage']} passage',
        );
      } else {
        need(
          !type.needsPassage,
          '$id: a ${type.key} question needs a passage to be about',
        );
      }
    }

    final orphans = passageIds.difference(referenced);
    need(
      orphans.isEmpty,
      '${orphans.length} passages are asked no questions: '
      '${orphans.join(', ')}',
    );
    expect(problems, isEmpty, reason: '\n${problems.join('\n')}');
  });
}
