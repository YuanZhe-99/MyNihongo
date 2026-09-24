/// Purpose: Write the input batches a content-authoring agent works from.
/// Inputs: Command-line flags; the shipped catalog under `assets/content/`.
/// Returns: None; sets the exit code.
/// Side effects: Writes files under `tool/content/drafts/`.
/// Notes: An authoring agent is handed one small JSON file and writes one
/// small JSON file back. It never reads the 1.5 MB catalog, never runs a
/// build, and never has to be told which words are already done — the batch
/// **is** the list of what is missing, so two agents working at once cannot
/// collide and a re-run after a merge simply produces fewer batches.
///
/// ```
/// dart run tool/draft_inputs.dart gloss --level N4 --batch 300
/// dart run tool/draft_inputs.dart examples --level N5 --batch 150
/// dart run tool/draft_inputs.dart grammar-inventory --level N4
/// dart run tool/draft_inputs.dart units --level N5
/// dart run tool/draft_inputs.dart drills --level N5 --section reading
/// dart run tool/draft_inputs.dart gloss-ja --level N5 --batch 100
/// dart run tool/draft_inputs.dart ja --kind grammar --level N5 --batch 25
/// ```
library;

import 'dart:convert';
import 'dart:io';

/// Where the batches are written; git-ignored, and emptied before a commit.
const draftRoot = 'tool/content/drafts';

/// Purpose: Run the generator.
/// Inputs: `args` — the kind, then `--level`, `--batch`, `--assets`, `--out`.
/// Returns: None; sets the exit code.
/// Side effects: File I/O and console output.
/// Notes: None.
void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln(
      'Usage: draft_inputs.dart <gloss|examples|'
      'grammar-inventory|units|drills|gloss-ja|ja> --level N5 '
      '[--section reading] [--kind grammar] [--target 1] [--batch 300]',
    );
    exitCode = 1;
    return;
  }
  final kind = args.first;
  var level = 'N5';
  var batch = 300;
  var assets = 'assets/content';
  var out = draftRoot;
  var section = '';
  var target = 1;
  var jaTarget = '';
  for (var i = 1; i < args.length; i++) {
    final next = i + 1 < args.length ? args[i + 1] : null;
    switch (args[i]) {
      case '--level' when next != null:
        level = next.toUpperCase();
      case '--batch' when next != null:
        batch = int.tryParse(next) ?? batch;
      case '--assets' when next != null:
        assets = next;
      case '--out' when next != null:
        out = next;
      case '--section' when next != null:
        section = next.toLowerCase();
      case '--target' when next != null:
        target = int.tryParse(next) ?? target;
      case '--kind' when next != null:
        jaTarget = next.toLowerCase();
    }
  }

  final catalog =
      jsonDecode(File('$assets/vocab.json').readAsStringSync()) as Map;
  final entries = <Map<String, Object?>>[
    for (final entry in catalog['entries'] as List)
      (entry as Map).cast<String, Object?>(),
  ];

  switch (kind) {
    case 'gloss':
      _write(out, kind, level, batch, _glossRows(entries, level));
    case 'examples':
      _write(out, kind, level, batch, _exampleRows(entries, level, assets));
    case 'grammar-inventory':
      _inventory(out, level, assets);
    case 'units':
      _units(out, level, assets, entries);
    case 'drills':
      _drills(out, level, section, assets, entries, target, batch);
    case 'gloss-ja':
      _write(out, kind, level, batch, _glossJaRows(entries, level));
    case 'ja':
      _ja(out, jaTarget, level, assets, batch);
    default:
      stderr.writeln('Unknown kind "$kind".');
      exitCode = 1;
  }
}

/// Purpose: List the words at a level that have no Chinese gloss yet.
/// Inputs: `entries`, `level`.
/// Returns: `List<Map<String, Object?>>` — one row per word to translate.
/// Side effects: None.
/// Notes: Internal helper used within this file only. The English meanings are
/// what the agent translates from; the reading and part of speech are what
/// disambiguate a word whose English gloss is a single ambiguous noun.
List<Map<String, Object?>> _glossRows(
  List<Map<String, Object?>> entries,
  String level,
) => [
  for (final entry in entries)
    if ('${entry['level']}' == level &&
        ((entry['meanings'] as Map?)?['zh'] == null))
      {
        'id': entry['id'],
        if (entry['kanji'] != null) 'kanji': entry['kanji'],
        'reading': entry['reading'],
        'pos': entry['pos'],
        'en': (entry['meanings'] as Map)['en'],
      },
];

/// Purpose: List the words at a level that have no example sentence yet.
/// Inputs: `entries`, `level`, `assets`.
/// Returns: `List<Map<String, Object?>>` — one row per word to write for.
/// Side effects: Reads the catalog for the vocabulary the sentence may use.
/// Notes: Internal helper used within this file only. Each row carries the
/// Chinese gloss where there is one, because a sentence written from an
/// English gloss alone drifts when the two languages disagree about which
/// sense the word has.
List<Map<String, Object?>> _exampleRows(
  List<Map<String, Object?>> entries,
  String level,
  String assets,
) => [
  for (final entry in entries)
    if ('${entry['level']}' == level &&
        (entry['examples'] == null || (entry['examples'] as List).isEmpty))
      {
        'id': entry['id'],
        if (entry['kanji'] != null) 'kanji': entry['kanji'],
        'reading': entry['reading'],
        'pos': entry['pos'],
        'en': (entry['meanings'] as Map)['en'],
        if ((entry['meanings'] as Map)['zh'] != null)
          'zh': (entry['meanings'] as Map)['zh'],
      },
];

/// Purpose: Write one kind of batch, split into files of `batch` rows.
/// Inputs: `out`, `kind`, `level`, `batch`, `rows`.
/// Returns: None.
/// Side effects: Writes the batch files and prints what it wrote.
/// Notes: Internal helper used within this file only. Numbered from 01 so the
/// files sort the way they are worked through, and so a half-finished level
/// picks up where it left off after the finished batches are merged.
void _write(
  String out,
  String kind,
  String level,
  int batch,
  List<Map<String, Object?>> rows,
) {
  if (rows.isEmpty) {
    stdout.writeln('Nothing left to do for $kind at $level.');
    return;
  }
  final dir = Directory('$out/$kind')..createSync(recursive: true);
  final encoder = const JsonEncoder.withIndent('  ');
  final files = <String>[];
  for (var i = 0; i < rows.length; i += batch) {
    final slice = rows.sublist(i, (i + batch).clamp(0, rows.length));
    final n = (i ~/ batch) + 1;
    final name =
        '${dir.path}/${level.toLowerCase()}-${n.toString().padLeft(2, '0')}'
        '.input.json';
    File(name).writeAsStringSync(
      '${encoder.convert({'kind': kind, 'level': level, 'count': slice.length, 'rows': slice})}\n',
    );
    files.add(name);
  }
  stdout
    ..writeln(
      '${rows.length} rows for $kind at $level '
      'in ${files.length} batches:',
    )
    ..writeln('  ${files.join('\n  ')}');
}

/// Purpose: Write the input for planning one level's grammar points.
/// Inputs: `out`, `level`, `assets`.
/// Returns: None.
/// Side effects: Writes one file and prints its path.
/// Notes: Internal helper used within this file only. The whole point of the
/// inventory step is that **ids are a compatibility contract**: they are
/// settled once, for the level, before anybody writes an explanation, so two
/// batches cannot invent the same slug for different points or two slugs for
/// the same one. Every id already shipped is listed so a new one cannot
/// collide, and the patterns are listed so a new point is not a duplicate of
/// an easier level's under another name.
void _inventory(String out, String level, String assets) {
  final taken = <String>[];
  final patterns = <String, String>{};
  final dir = Directory('$assets/grammar');
  if (dir.existsSync()) {
    for (final file in dir.listSync().whereType<File>()) {
      if (!file.path.endsWith('.json')) continue;
      final json = jsonDecode(file.readAsStringSync()) as Map;
      for (final point in (json['points'] as List? ?? const [])) {
        if (point is! Map) continue;
        taken.add('${point['id']}');
        patterns['${point['id']}'] = '${point['pattern']}';
      }
    }
  }
  taken.sort();
  Directory('$out/grammar').createSync(recursive: true);
  final path = '$out/grammar/${level.toLowerCase()}.inventory.input.json';
  File(path).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert({'kind': 'grammar-inventory', 'level': level, 'takenIds': taken, 'shippedPatterns': patterns})}\n',
  );
  stdout.writeln('${taken.length} ids already taken; wrote $path');
}

/// Purpose: Write the input for dividing one level into units.
/// Inputs: `out`, `level`, `assets`, `entries`.
/// Returns: None.
/// Side effects: Writes one file and prints its path.
/// Notes: Internal helper used within this file only. A unit is a topic, and
/// the constraint that makes the path complete rather than decorative is that
/// **every grammar point of the level appears in exactly one unit** — so the
/// whole level's points go in one file rather than being split across batches
/// that could not see each other's choices. Only the common words are offered:
/// a topic built out of rare words is a topic nobody can use yet.
void _units(
  String out,
  String level,
  String assets,
  List<Map<String, Object?>> entries,
) {
  final file = File('$assets/grammar/${level.toLowerCase()}.json');
  if (!file.existsSync()) {
    stderr.writeln('No grammar file for $level yet; write it first.');
    exitCode = 1;
    return;
  }
  final json = jsonDecode(file.readAsStringSync()) as Map;
  final points = [
    for (final point in json['points'] as List)
      if (point is Map)
        {
          'id': point['id'],
          'pattern': point['pattern'],
          'meaning': (point['meaning'] as Map?)?['en'],
        },
  ];
  final words = [
    for (final entry in entries)
      if ('${entry['level']}' == level && entry['common'] != false)
        {
          'id': entry['id'],
          'word': entry['kanji'] ?? entry['reading'],
          'reading': entry['reading'],
          'en': ((entry['meanings'] as Map)['en'] as List).first,
        },
  ];
  Directory('$out/units').createSync(recursive: true);
  final path = '$out/units/${level.toLowerCase()}.input.json';
  File(path).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert({'kind': 'units', 'level': level, 'grammar': points, 'vocabulary': words})}\n',
  );
  stdout.writeln(
    '${points.length} points and ${words.length} common words; wrote $path',
  );
}

/// Which section each 大問 belongs to, mirroring `DrillType` in the app.
///
/// Duplicated here rather than imported because `tool/` is plain Dart with no
/// Flutter dependency, and `drill_section.dart` is reached only through files
/// that need Flutter. `content_gate_test.dart` asserts the two agree, so a
/// type added on one side and not the other fails a test rather than shipping.
const drillTypeSections = {
  'kanji-reading': 'vocab',
  'orthography': 'vocab',
  'word-formation': 'vocab',
  'context': 'vocab',
  'paraphrase': 'vocab',
  'usage': 'vocab',
  'form-selection': 'grammar',
  'sentence-composition': 'grammar',
  'text-grammar': 'grammar',
  'short': 'reading',
  'mid': 'reading',
  'long': 'reading',
  'integrated': 'reading',
  'thematic': 'reading',
  'info': 'reading',
  'task': 'listening',
  'point': 'listening',
  'outline': 'listening',
  'expression': 'listening',
  'quick-response': 'listening',
  'integrated-listening': 'listening',
};

/// How many questions one passage of each type carries, and how long it is.
///
/// A guide for the author rather than a rule the gate enforces: the JLPT's own
/// 中文 passages carry three questions and its 短文 carry one, and a batch that
/// wrote one question per passage would be asking the learner to read six
/// texts for six marks.
const drillPassageShapes = {
  'short': {'questions': 1, 'shape': '2-4 sentences'},
  'mid': {'questions': 3, 'shape': '5-8 sentences'},
  'long': {'questions': 4, 'shape': '10-14 sentences'},
  'integrated': {'questions': 1, 'shape': 'two texts of 3-5 sentences'},
  'thematic': {'questions': 1, 'shape': '8-12 sentences of argument'},
  'info': {'questions': 1, 'shape': 'a notice or timetable, 4-8 short lines'},
  'text-grammar': {'questions': 4, 'shape': '6-10 sentences with 4 gaps'},
  'task': {'questions': 1, 'shape': 'a 4-8 line exchange, then the question'},
  'point': {'questions': 1, 'shape': 'a 4-8 line exchange, then the question'},
  'outline': {'questions': 1, 'shape': 'a 5-9 line monologue'},
  'expression': {'questions': 1, 'shape': 'one line describing the situation'},
  'quick-response': {'questions': 1, 'shape': 'one spoken line'},
  'integrated-listening': {
    'questions': 2,
    'shape': 'an 8-12 line exchange between three speakers',
  },
};

/// Purpose: Write the batches for one level's section of drill questions.
/// Inputs: `out`, `level`, `section`, `assets`, `entries`, `target` — how many
/// times the official count to reach — and `batch` — questions per file.
/// Returns: None; sets the exit code.
/// Side effects: Writes one resources file and one file per batch.
/// Notes: Internal helper used within this file only. "Missing" is computed
/// per 大問 against `structure.json` times `target`, so a re-run after a merge
/// asks for exactly what is still short and a finished section produces
/// nothing — the same property the other four kinds have.
///
/// The vocabulary and grammar of the level go in a **separate resources file**
/// that every batch names, rather than being copied into each batch. A level's
/// common vocabulary is a few thousand rows; repeating it per batch would turn
/// a thirty-question ask into a megabyte of input and would still be the same
/// list.
void _drills(
  String out,
  String level,
  String section,
  String assets,
  List<Map<String, Object?>> entries,
  int target,
  int batch,
) {
  if (section.isEmpty) {
    stderr.writeln(
      '--section is required for drills '
      '(vocab|grammar|reading|listening).',
    );
    exitCode = 1;
    return;
  }
  final structureFile = File('$assets/drills/structure.json');
  if (!structureFile.existsSync()) {
    stderr.writeln('No $assets/drills/structure.json.');
    exitCode = 1;
    return;
  }
  final structure = jsonDecode(structureFile.readAsStringSync()) as Map;
  final levels = structure['levels'] as Map?;
  final wanted = (levels?[level] as Map?)?['types'] as Map?;
  if (wanted == null) {
    stderr.writeln('structure.json has no $level.');
    exitCode = 1;
    return;
  }

  // What is already shipped, per type, and every id already taken across the
  // whole level — ids have to be unique across sections, not only within one.
  final shipped = <String, int>{};
  final takenIds = <String>[];
  final takenPassages = <String>[];
  for (final other in const ['vocab', 'grammar', 'reading', 'listening']) {
    final file = File('$assets/drills/${level.toLowerCase()}-$other.json');
    if (!file.existsSync()) continue;
    final json = jsonDecode(file.readAsStringSync()) as Map;
    for (final question in (json['questions'] as List? ?? const [])) {
      if (question is! Map) continue;
      takenIds.add('${question['id']}');
      if (other == section) {
        final type = '${question['type']}';
        shipped[type] = (shipped[type] ?? 0) + 1;
      }
    }
    for (final passage in (json['passages'] as List? ?? const [])) {
      if (passage is Map) takenPassages.add('${passage['id']}');
    }
  }

  final needed = <Map<String, Object?>>[];
  for (final entry in wanted.entries) {
    final type = '${entry.key}';
    if (drillTypeSections[type] != section) continue;
    final full = entry.value is int ? entry.value as int : 0;
    final short = full * target - (shipped[type] ?? 0);
    if (short <= 0) continue;
    needed.add({
      'type': type,
      'count': short,
      'officialCount': full,
      if (drillPassageShapes[type] != null) 'passage': drillPassageShapes[type],
    });
  }
  if (needed.isEmpty) {
    stdout.writeln('Nothing left to write for $level $section at x$target.');
    return;
  }

  final dir = Directory('$out/drills')..createSync(recursive: true);
  const encoder = JsonEncoder.withIndent('  ');
  final slug = '${level.toLowerCase()}-$section';

  final grammarFile = File('$assets/grammar/${level.toLowerCase()}.json');
  final points = <Map<String, Object?>>[];
  if (grammarFile.existsSync()) {
    final json = jsonDecode(grammarFile.readAsStringSync()) as Map;
    for (final point in (json['points'] as List? ?? const [])) {
      if (point is! Map) continue;
      points.add({
        'id': point['id'],
        'pattern': point['pattern'],
        'meaning': (point['meaning'] as Map?)?['en'],
      });
    }
  }
  final words = [
    for (final entry in entries)
      if ('${entry['level']}' == level && entry['common'] != false)
        {
          'id': entry['id'],
          'word': entry['kanji'] ?? entry['reading'],
          'reading': entry['reading'],
          'en': ((entry['meanings'] as Map)['en'] as List).first,
        },
  ];
  takenIds.sort();
  takenPassages.sort();
  final resources = '${dir.path}/$slug.resources.json';
  File(resources).writeAsStringSync(
    '${encoder.convert({'kind': 'drills-resources', 'level': level, 'section': section, 'grammar': points, 'vocabulary': words, 'takenQuestionIds': takenIds, 'takenPassageIds': takenPassages})}\n',
  );

  final files = <String>[];
  var fileIndex = 1;
  var current = <Map<String, Object?>>[];
  var running = 0;
  void flush() {
    if (current.isEmpty) return;
    final name =
        '${dir.path}/$slug-${fileIndex.toString().padLeft(2, '0')}.input.json';
    File(name).writeAsStringSync(
      '${encoder.convert({'kind': 'drills', 'level': level, 'section': section, 'resources': resources, 'count': running, 'needed': current})}\n',
    );
    files.add(name);
    fileIndex++;
    current = [];
    running = 0;
  }

  for (final need in needed) {
    // A 大問 is never split across two batches: its questions share a style
    // and, for reading and listening, share passages, and two agents writing
    // half each would produce two halves that do not match.
    if (running > 0 && running + (need['count'] as int) > batch) flush();
    current.add(need);
    running += need['count'] as int;
  }
  flush();

  final total = needed.fold<int>(0, (a, b) => a + (b['count'] as int));
  stdout
    ..writeln(
      '$total questions needed for $level $section at x$target, '
      'in ${files.length} batches:',
    )
    ..writeln('  resources: $resources')
    ..writeln('  ${files.join('\n  ')}');
}

/// Purpose: List the words at a level that have no Japanese definition yet.
/// Inputs: `entries`, `level`.
/// Returns: `List<Map<String, Object?>>` — one row per word to define.
/// Side effects: None.
/// Notes: Internal helper used within this file only. The twin of
/// `_glossRows`, and "missing" means the same thing: the catalog entry has no
/// `meanings.ja`, which `import_vocab.dart` writes from `vocab_ja.json` in both
/// of its modes. The English and Chinese glosses are there to pin down which
/// sense is meant, not to be translated: a definition is written about the
/// word, in Japanese, from scratch.
List<Map<String, Object?>> _glossJaRows(
  List<Map<String, Object?>> entries,
  String level,
) => [
  for (final entry in entries)
    if ('${entry['level']}' == level &&
        ((entry['meanings'] as Map?)?['ja'] == null))
      {
        'id': entry['id'],
        if (entry['kanji'] != null) 'kanji': entry['kanji'],
        'reading': entry['reading'],
        'pos': entry['pos'],
        'en': (entry['meanings'] as Map)['en'],
        if ((entry['meanings'] as Map)['zh'] != null)
          'zh': (entry['meanings'] as Map)['zh'],
      },
];

/// Purpose: Keep only the English and Chinese of a localized field.
/// Inputs: `field` — a `{en, zh, zh_TW, ...}` map or null.
/// Returns: `Map<String, Object?>?` — `{en, zh}`, or null when absent.
/// Side effects: None.
/// Notes: Internal helper used within this file only. What the agent works
/// from; the Traditional copy is the same text again and would only cost
/// tokens.
Map<String, Object?>? _enZh(Object? field) {
  if (field is! Map) return null;
  return {
    if (field['en'] != null) 'en': field['en'],
    if (field['zh'] != null) 'zh': field['zh'],
  };
}

/// Purpose: Say whether a localized field still needs its Japanese text.
/// Inputs: `field`.
/// Returns: `bool` — true when the field exists and has no `ja`.
/// Side effects: None.
/// Notes: Internal helper used within this file only.
bool _needsJa(Object? field) => field is Map && field['ja'] == null;

/// Purpose: Write the input batches for one `ja` target.
/// Inputs: `out`, the `target` (`grammar`, `function-words`, `units`,
/// `drills`), `level`, `assets`, `batch`.
/// Returns: None.
/// Side effects: Writes files under `<out>/ja/<target>/` and prints them.
/// Notes: Internal helper used within this file only. The `ja` stream adds a
/// Japanese version of text the catalog already has in English and Chinese,
/// so every row carries that text and nothing else. "Missing" is the same
/// rule everywhere: a field that has no `ja` yet. The envelope names the
/// target, because the gate and the merge both need to know which file the
/// rows belong to.
void _ja(String out, String target, String level, String assets, int batch) {
  final rows = <Map<String, Object?>>[];
  switch (target) {
    case 'grammar':
      final file = File('$assets/grammar/${level.toLowerCase()}.json');
      if (!file.existsSync()) break;
      final json = jsonDecode(file.readAsStringSync()) as Map;
      for (final point in json['points'] as List) {
        if (point is! Map) continue;
        if (!_needsJa(point['meaning']) && !_needsJa(point['explanation'])) {
          continue;
        }
        rows.add({
          'id': point['id'],
          'pattern': point['pattern'],
          if (point['structure'] != null) 'structure': point['structure'],
          'meaning': _enZh(point['meaning']),
          'explanation': _enZh(point['explanation']),
          'examples': [
            for (final example in (point['examples'] as List? ?? const []))
              if (example is Map) example['ja'],
          ].take(2).toList(),
        });
      }
    case 'function-words':
      final json =
          jsonDecode(File('$assets/function_words.json').readAsStringSync())
              as Map;
      for (final word in json['words'] as List) {
        if (word is! Map || !_needsJa(word['gloss'])) continue;
        rows.add({
          'id': word['id'],
          'surface': word['surface'],
          'category': word['category'],
          'gloss': _enZh(word['gloss']),
        });
      }
    case 'units':
      final file = File('$assets/lessons/${level.toLowerCase()}.json');
      if (!file.existsSync()) break;
      final json = jsonDecode(file.readAsStringSync()) as Map;
      for (final unit in json['units'] as List) {
        if (unit is! Map) continue;
        final scenario = unit['scenario'];
        final questions = [
          for (final q in (unit['questions'] as List? ?? const []))
            if (q is Map &&
                (_needsJa(q['prompt']) || _needsJa(q['explanation'])))
              {
                'id': q['id'],
                'prompt': _enZh(q['prompt']),
                'explanation': _enZh(q['explanation']),
                'options': q['options'],
                'answer': q['answer'],
              },
        ];
        final needsUnit =
            _needsJa(unit['title']) ||
            _needsJa(unit['writingPrompt']) ||
            (scenario is Map && _needsJa(scenario['title'])) ||
            questions.isNotEmpty;
        if (!needsUnit) continue;
        rows.add({
          'id': unit['id'],
          'title': _enZh(unit['title']),
          if (unit['writingPrompt'] != null)
            'writingPrompt': _enZh(unit['writingPrompt']),
          if (scenario is Map && scenario['title'] != null)
            'scenarioTitle': _enZh(scenario['title']),
          'questions': questions,
        });
      }
    case 'drills':
      final dir = Directory('$assets/drills');
      final prefix = '${level.toLowerCase()}-';
      final files =
          dir
              .listSync()
              .whereType<File>()
              .where((f) => f.uri.pathSegments.last.startsWith(prefix))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));
      for (final file in files) {
        final json = jsonDecode(file.readAsStringSync()) as Map;
        final passages = {
          for (final p in (json['passages'] as List? ?? const []))
            if (p is Map)
              '${p['id']}': [
                for (final line in (p['lines'] as List? ?? const []))
                  if (line is Map) '${line['ja']}',
              ].join(),
        };
        for (final q in json['questions'] as List) {
          if (q is! Map) continue;
          if (!_needsJa(q['prompt']) && !_needsJa(q['explanation'])) continue;
          rows.add({
            'id': q['id'],
            'section': json['section'],
            'type': q['type'],
            if (q['stem'] != null) 'stem': q['stem'],
            'prompt': _enZh(q['prompt']),
            'explanation': _enZh(q['explanation']),
            'options': q['options'],
            'answer': q['answer'],
            if (q['passage'] != null)
              'passage': passages['${q['passage']}'] ?? '',
          });
        }
      }
    default:
      stderr.writeln(
        'Unknown ja target "$target"; use grammar, function-words, units or '
        'drills.',
      );
      exitCode = 1;
      return;
  }
  if (rows.isEmpty) {
    stdout.writeln('Nothing left to do for ja $target at $level.');
    return;
  }
  final dir = Directory('$out/ja/$target')..createSync(recursive: true);
  final encoder = const JsonEncoder.withIndent('  ');
  final files = <String>[];
  for (var i = 0; i < rows.length; i += batch) {
    final slice = rows.sublist(i, (i + batch).clamp(0, rows.length));
    final n = (i ~/ batch) + 1;
    final name =
        '${dir.path}/${level.toLowerCase()}-${n.toString().padLeft(2, '0')}'
        '.input.json';
    File(name).writeAsStringSync(
      '${encoder.convert({'kind': 'ja', 'target': target, 'level': level, 'count': slice.length, 'rows': slice})}\n',
    );
    files.add(name);
  }
  stdout
    ..writeln(
      '${rows.length} rows for ja $target at $level '
      'in ${files.length} batches:',
    )
    ..writeln('  ${files.join('\n  ')}');
}
