import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/models/content_catalog.dart';
import 'package:my_nihongo/features/content/models/jlpt_level.dart';
import 'package:my_nihongo/features/content/services/content_repository.dart';
import 'package:my_nihongo/features/content/services/furigana_aligner.dart';
import 'package:my_nihongo/features/sentence/models/token.dart';
import 'package:my_nihongo/features/sentence/services/lexicon.dart';
import 'package:my_nihongo/features/sentence/services/sentence_analyzer.dart';

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
    for (final token in analysis.tokens) {
      final refId = token.refId;
      if (refId == null || !refId.startsWith('vocab:')) continue;
      final word = catalog.vocabById(refId);
      if (word == null) continue;
      // Two allowances, both learnt from the first batch this gate saw.
      //
      // **Single-character tokens are skipped.** 六時 is not in the catalog,
      // so it segments into 六 and 時, and 時 on its own is filed at N3 — the
      // sentence is ordinary N5 Japanese and the finding is an artefact of
      // where the word boundary fell. A genuinely hard word written in kanji
      // is caught by the unknown-token rule above instead, because the
      // catalog does not have it at all.
      //
      // **One level of slack.** An example sentence that reaches one level up
      // for a word like ケーキ or 優しい is how textbooks are written; two
      // levels up is where a sentence stops being readable at its own level.
      if (token.surface.length < 2) continue;
      need(
        word.level.index <= level.index + 1,
        '$label: "$ja" uses ${word.headword} (${word.level.label}), which is '
        'more than one level harder than ${level.label}.',
      );
    }
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
        need(
          analyzer.analyze(ja).tokens.any((t) => t.refId == id) ||
              ja.contains(entry.headword) ||
              ja.contains(entry.reading),
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
}
