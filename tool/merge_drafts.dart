/// Purpose: Fold checked draft batches into the shipped content files.
/// Inputs: Command-line flags and the draft paths.
/// Returns: None; sets the exit code.
/// Side effects: Rewrites files under `assets/content/`.
/// Notes: The last step of the authoring loop, and deliberately the dumbest:
/// every judgement about a draft was made by `test/content_gate_test.dart`
/// before this runs. All this does is merge, sort and write, so that a batch
/// which passed the gate lands byte-identically however many times it is run.
///
/// ```
/// dart run tool/merge_drafts.dart gloss    tool/content/drafts/gloss/n4-*.json
/// dart run tool/merge_drafts.dart examples tool/content/drafts/examples/n5-*.json
/// dart run tool/merge_drafts.dart grammar --level N4 tool/content/drafts/grammar/n4-*.json
/// dart run tool/merge_drafts.dart units   --level N5 tool/content/drafts/units/n5.json
/// ```
///
/// Then, for the two vocabulary overlays:
/// `dart run tool/import_vocab.dart --overlay-only && dart run tool/convert_zh_tw.dart`.
library;

import 'dart:convert';
import 'dart:io';

/// The encoder every content file is written with, per `AGENTS.md`.
const _encoder = JsonEncoder.withIndent('  ');

/// What a model-authored file declares about where it came from.
const _source = 'model-authored (Claude), unreviewed';

/// Purpose: Run the merge.
/// Inputs: `args` — the kind, `--level`, `--assets`, then the draft paths.
/// Returns: None; sets the exit code.
/// Side effects: File I/O and console output.
/// Notes: None.
void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln(
      'Usage: merge_drafts.dart <gloss|examples|grammar|units|drills> '
      '[--level N4] [--section reading] <draft.json ...>',
    );
    exitCode = 1;
    return;
  }
  final kind = args.first;
  var level = '';
  var section = '';
  var assets = 'assets/content';
  final drafts = <String>[];
  for (var i = 1; i < args.length; i++) {
    final next = i + 1 < args.length ? args[i + 1] : null;
    switch (args[i]) {
      case '--level' when next != null:
        level = next.toUpperCase();
        i++;
      case '--section' when next != null:
        section = next.toLowerCase();
        i++;
      case '--assets' when next != null:
        assets = next;
        i++;
      default:
        drafts.add(args[i]);
    }
  }
  if (drafts.isEmpty) {
    stderr.writeln('No draft files given.');
    exitCode = 1;
    return;
  }

  switch (kind) {
    case 'gloss':
      _mergeGloss(assets, drafts);
    case 'examples':
      _mergeExamples(assets, drafts);
    case 'grammar':
      _mergeGrammar(assets, level, drafts);
    case 'units':
      _mergeUnits(assets, level, drafts);
    case 'drills':
      _mergeDrills(assets, level, section, drafts);
    default:
      stderr.writeln('Unknown kind "$kind".');
      exitCode = 1;
  }
}

/// Purpose: Read the rows of every draft file given.
/// Inputs: `paths`, and the `key` the rows live under.
/// Returns: `List<Map<String, Object?>>` in the order the files were given.
/// Side effects: Reads the files; exits non-zero when one is missing.
/// Notes: Internal helper used within this file only.
List<Map<String, Object?>> _rows(List<String> paths, String key) {
  final out = <Map<String, Object?>>[];
  for (final path in paths) {
    final file = File(path);
    if (!file.existsSync()) {
      stderr.writeln('No draft at $path');
      exitCode = 1;
      continue;
    }
    final json = jsonDecode(file.readAsStringSync());
    if (json is! Map || json[key] is! List) {
      stderr.writeln('$path has no "$key" list');
      exitCode = 1;
      continue;
    }
    for (final row in json[key] as List) {
      if (row is Map) out.add(row.cast<String, Object?>());
    }
  }
  return out;
}

/// Purpose: Fold gloss batches into the Chinese overlay.
/// Inputs: `assets`, `drafts`.
/// Returns: None.
/// Side effects: Rewrites `vocab_zh.json`.
/// Notes: Internal helper used within this file only. **An existing row is
/// never overwritten**: the overlay is where a human correction lands, and a
/// later batch must not undo one. `reviewed` stays false — it tracks whether a
/// speaker has read the row, and nothing here has read anything.
void _mergeGloss(String assets, List<String> drafts) {
  final path = '$assets/vocab_zh.json';
  final json =
      jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
  final entries = (json['entries'] as Map).cast<String, Object?>();
  var added = 0;
  var kept = 0;
  for (final row in _rows(drafts, 'rows')) {
    final id = '${row['id']}';
    final zh = row['zh'];
    if (zh is! List || zh.isEmpty) continue;
    if (entries.containsKey(id)) {
      kept++;
      continue;
    }
    entries[id] = {
      'zh': [for (final meaning in zh) '$meaning'],
      'reviewed': false,
    };
    added++;
  }
  json['entries'] = Map.fromEntries(
    entries.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
  File(path).writeAsStringSync('${_encoder.convert(json)}\n');
  stdout.writeln(
    'Added $added glosses to $path'
    '${kept > 0 ? '; left $kept existing rows alone' : ''}.',
  );
}

/// Purpose: Fold example batches into the example overlay.
/// Inputs: `assets`, `drafts`.
/// Returns: None.
/// Side effects: Writes `vocab_examples.json`, creating it if needed.
/// Notes: Internal helper used within this file only. Sentences are appended
/// and de-duplicated by their Japanese, so re-running a merged batch changes
/// nothing. The generated `zh_TW` is not written here: `convert_zh_tw.dart`
/// owns it, and a hand-written one fails `content_zh_tw_test`.
void _mergeExamples(String assets, List<String> drafts) {
  final path = '$assets/vocab_examples.json';
  final file = File(path);
  final json = file.existsSync()
      ? jsonDecode(file.readAsStringSync()) as Map<String, Object?>
      : <String, Object?>{
          'schemaVersion': 1,
          'source': _source,
          'license': 'GPL-3.0 with the app.',
          'note':
              'Example sentences layered onto the generated catalog by '
              'tool/import_vocab.dart. Keyed by the catalog id. Written by a '
              'model against tool/content/drafts and checked by '
              'test/content_gate_test.dart; no native speaker has read them.',
          'entries': <String, Object?>{},
        };
  final entries = (json['entries'] as Map).cast<String, Object?>();
  var added = 0;
  for (final row in _rows(drafts, 'rows')) {
    final id = '${row['id']}';
    final examples = row['examples'];
    if (examples is! List || examples.isEmpty) continue;
    final existing = <Map<String, Object?>>[
      if (entries[id] is Map && (entries[id] as Map)['examples'] is List)
        for (final e in ((entries[id] as Map)['examples'] as List))
          if (e is Map) e.cast<String, Object?>(),
    ];
    final seen = {for (final e in existing) '${e['ja']}'};
    for (final example in examples) {
      if (example is! Map) continue;
      final row = example.cast<String, Object?>()..remove('zh_TW');
      if (!seen.add('${row['ja']}')) continue;
      existing.add(row);
      added++;
    }
    entries[id] = {'examples': existing};
  }
  json['entries'] = Map.fromEntries(
    entries.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
  file.writeAsStringSync('${_encoder.convert(json)}\n');
  stdout.writeln('Added $added example sentences to $path.');
}

/// Purpose: Assemble one level's grammar file from its batches.
/// Inputs: `assets`, `level`, `drafts`.
/// Returns: None.
/// Side effects: Writes `assets/content/grammar/<level>.json`.
/// Notes: Internal helper used within this file only. Points are written in
/// the order the batches were given, which is the order the inventory settled,
/// so the file reads as a progression rather than as whatever order the
/// batches came back in. A duplicate id is fatal here even though the gate
/// already checks it, because the gate sees one batch at a time.
void _mergeGrammar(String assets, String level, List<String> drafts) {
  if (level.isEmpty) {
    stderr.writeln('--level is required for grammar.');
    exitCode = 1;
    return;
  }
  final points = _rows(drafts, 'points');
  final seen = <String>{};
  for (final point in points) {
    if (!seen.add('${point['id']}')) {
      stderr.writeln('${point['id']} appears in more than one batch.');
      exitCode = 1;
      return;
    }
    point.remove('zh_TW');
  }
  final path = '$assets/grammar/${level.toLowerCase()}.json';
  File(path).writeAsStringSync(
    '${_encoder.convert({'schemaVersion': 2, 'source': _source, 'license': 'GPL-3.0 with the app.', 'level': level, 'points': points})}\n',
  );
  stdout
    ..writeln('Wrote ${points.length} points to $path.')
    ..writeln(
      'Add it to ContentRepository.grammarAssets if it is new, then '
      'run tool/convert_zh_tw.dart.',
    );
}

/// Purpose: Write one level's unit file.
/// Inputs: `assets`, `level`, `drafts`.
/// Returns: None.
/// Side effects: Writes `assets/content/lessons/<level>.json`.
/// Notes: Internal helper used within this file only. A level is one draft,
/// not several: the constraint that every grammar point of the level belongs
/// to exactly one unit cannot be checked by batches that cannot see each
/// other, so it is planned whole.
void _mergeUnits(String assets, String level, List<String> drafts) {
  if (level.isEmpty) {
    stderr.writeln('--level is required for units.');
    exitCode = 1;
    return;
  }
  if (drafts.length != 1) {
    stderr.writeln('A level is one units draft, not ${drafts.length}.');
    exitCode = 1;
    return;
  }
  final units = _rows(drafts, 'units');
  Directory('$assets/lessons').createSync(recursive: true);
  final path = '$assets/lessons/${level.toLowerCase()}.json';
  File(path).writeAsStringSync(
    '${_encoder.convert({'schemaVersion': 1, 'source': _source, 'license': 'GPL-3.0 with the app.', 'level': level, 'units': units})}\n',
  );
  stdout.writeln('Wrote ${units.length} units to $path.');
}

/// Purpose: Fold drill batches into one level's section file.
/// Inputs: `assets`, `level`, `section`, `drafts`.
/// Returns: None; sets the exit code.
/// Side effects: Rewrites `assets/content/drills/<level>-<section>.json`.
/// Notes: Internal helper used within this file only. Unlike the gloss merge,
/// this one **appends** to what is shipped rather than skipping what is
/// already there: a section is filled up over several releases, and each batch
/// is new questions rather than a better version of old ones.
///
/// An id that already exists is **fatal**, not skipped. Two questions under
/// one id would make "already asked" mean one of them, and which one would
/// depend on the order the file happened to be written in. The gate checks
/// this too; this is the second line of defence, because a merge run against
/// the wrong section is exactly how a collision would arrive.
///
/// `zh_TW` is stripped, as everywhere else: every Traditional string in this
/// repo is generated by `convert_zh_tw.dart` from the Simplified beside it, so
/// a hand-written one is a string that will silently stop matching.
void _mergeDrills(
  String assets,
  String level,
  String section,
  List<String> drafts,
) {
  if (level.isEmpty || section.isEmpty) {
    stderr.writeln('--level and --section are required for drills.');
    exitCode = 1;
    return;
  }
  final dir = Directory('$assets/drills')..createSync(recursive: true);
  final path = '${dir.path}/${level.toLowerCase()}-$section.json';
  final file = File(path);

  final questions = <Map<String, Object?>>[];
  final passages = <Map<String, Object?>>[];
  final ids = <String>{};
  final passageIds = <String>{};
  if (file.existsSync()) {
    final json = jsonDecode(file.readAsStringSync()) as Map;
    for (final question in (json['questions'] as List? ?? const [])) {
      if (question is! Map) continue;
      questions.add(question.cast<String, Object?>());
      ids.add('${question['id']}');
    }
    for (final passage in (json['passages'] as List? ?? const [])) {
      if (passage is! Map) continue;
      passages.add(passage.cast<String, Object?>());
      passageIds.add('${passage['id']}');
    }
  }

  var added = 0;
  for (final passage in _rows(drafts, 'passages')) {
    final id = '${passage['id']}';
    if (!passageIds.add(id)) {
      stderr.writeln('Duplicate passage id $id.');
      exitCode = 1;
      return;
    }
    passages.add(_stripTwMap(passage));
  }
  for (final question in _rows(drafts, 'questions')) {
    final id = '${question['id']}';
    if (!ids.add(id)) {
      stderr.writeln('Duplicate question id $id.');
      exitCode = 1;
      return;
    }
    questions.add(_stripTwMap(question));
    added++;
  }

  // Sorted by id, which sorts by type-letter and then by number, so a file
  // diff after a merge shows the new questions in one block rather than
  // scattered through the file.
  questions.sort((a, b) => '${a['id']}'.compareTo('${b['id']}'));
  passages.sort((a, b) => '${a['id']}'.compareTo('${b['id']}'));

  file.writeAsStringSync(
    '${_encoder.convert({'schemaVersion': 1, 'source': _source, 'license': 'GPL-3.0 with the app.', 'level': level, 'section': section, 'passages': passages, 'questions': questions})}\n',
  );
  stdout.writeln(
    'Added $added questions and ${passages.length} passages total; '
    'wrote $path with ${questions.length} questions.',
  );
}

/// Purpose: Strip Traditional Chinese from one row, keeping its map type.
/// Inputs: `row`.
/// Returns: `Map<String, Object?>`.
/// Side effects: None.
/// Notes: Internal helper used within this file only.
Map<String, Object?> _stripTwMap(Map<String, Object?> row) =>
    (_stripTw(row) as Map).cast<String, Object?>();

/// Purpose: Remove every hand-written Traditional Chinese string.
/// Inputs: `row`.
/// Returns: A copy with no `zh_TW` key at any depth.
/// Side effects: None.
/// Notes: Internal helper used within this file only. Recursive because a
/// drill row nests three deep — a passage holds lines, a line holds
/// translations — and a `zh_TW` at any of those depths is one
/// `convert_zh_tw.dart` will not know it did not write.
Object? _stripTw(Object? value) {
  if (value is Map) {
    return <String, Object?>{
      for (final entry in value.entries)
        if ('${entry.key}' != 'zh_TW') '${entry.key}': _stripTw(entry.value),
    };
  }
  if (value is List) return [for (final member in value) _stripTw(member)];
  return value;
}
