/// Purpose: Regenerate `assets/content/vocab.json` from JMdict and the JLPT
/// lists.
/// Inputs: Command-line flags; the JMdict body under `tool/data/`, the lists
/// under `tool/content/jlpt/`, the seed and the Chinese overlay.
/// Returns: Process exit code 0 on success, 1 on a fatal input problem.
/// Side effects: Reads several files and rewrites the vocabulary asset.
/// Notes: Offline and deterministic: running it twice with unchanged inputs
/// leaves an empty `git diff`. The JMdict body is 117 MB unpacked and is **not**
/// committed; `tool/data/` is git-ignored and the tool prints the download URL
/// when the file is missing. Run it with:
///
/// ```bash
/// dart run tool/import_vocab.dart
/// dart run tool/import_vocab.dart --overlay-only   # re-apply Chinese glosses
/// ```
library;

import 'dart:convert';
import 'dart:io';

import 'src/chinese_converter.dart';
import 'src/vocab_import_core.dart';
import 'src/zh_tw.dart';

/// Where to get the JMdict body, printed when it is missing.
const _jmdictRelease =
    'https://github.com/scriptin/jmdict-simplified/releases/latest';

/// Purpose: Run the import.
/// Inputs: `args` — `--data`, `--out`, `--overlay`, `--seed`, `--overlay-only`.
/// Returns: None; sets the exit code.
/// Side effects: File I/O and console output.
/// Notes: `--overlay-only` rewrites the existing catalog's Chinese glosses from
/// the overlay without touching JMdict, so authoring Chinese level by level
/// never needs the 117 MB download.
Future<void> main(List<String> args) async {
  final options = _parseArgs(args);

  final overlayFile = File(options.overlay);
  final overlay = overlayFile.existsSync()
      ? _readOverlay(overlayFile.readAsStringSync())
      : <String, Map<String, Object?>>{};
  if (!overlayFile.existsSync()) {
    stderr.writeln('No overlay at ${options.overlay}; English glosses only.');
  }

  if (options.overlayOnly) {
    _applyOverlayOnly(options.out, overlay);
    return;
  }

  final dataFile = _findJmdict(options.data);
  if (dataFile == null) {
    stderr
      ..writeln('No JMdict body found under ${options.data}.')
      ..writeln('Download jmdict-eng-<version>.json.zip from')
      ..writeln('  $_jmdictRelease')
      ..writeln('and unpack the .json into ${options.data}.');
    exitCode = 1;
    return;
  }

  stdout.writeln('Reading ${dataFile.path} ...');
  final jmdict =
      jsonDecode(dataFile.readAsStringSync()) as Map<String, dynamic>;
  final index = indexJmdict(jmdict);
  stdout.writeln('  ${index.length} JMdict entries indexed.');

  final listsByLevel = <String, List<JlptRow>>{};
  for (final level in importLevels) {
    final file = File('tool/content/jlpt/${level.toLowerCase()}.csv');
    if (!file.existsSync()) {
      stderr.writeln('Missing JLPT list ${file.path}.');
      exitCode = 1;
      return;
    }
    listsByLevel[level] = parseJlptCsv(file.readAsStringSync());
    stdout.writeln('  $level: ${listsByLevel[level]!.length} rows.');
  }

  final seedRaw = jsonDecode(File(options.seed).readAsStringSync());
  final seedEntries = <Map<String, Object?>>[
    if (seedRaw is Map && seedRaw['entries'] is List)
      for (final entry in seedRaw['entries'] as List)
        if (entry is Map) entry.cast<String, Object?>(),
  ];

  final result = buildEntries(
    jmdictIndex: index,
    listsByLevel: listsByLevel,
    seedEntries: seedEntries,
    overlay: overlay,
  );

  for (final line in result.log) {
    stderr.writeln('  $line');
  }

  if (result.missingSeqs.isNotEmpty) {
    stderr
      ..writeln(
        '${result.missingSeqs.length} sequence numbers are not in '
        'this JMdict release:',
      )
      ..writeln(
        '  ${result.missingSeqs.take(40).join(', ')}'
        '${result.missingSeqs.length > 40 ? ' ...' : ''}',
      )
      ..writeln(
        'Update the lists or the JMdict release; refusing to write a '
        'catalog with holes in it.',
      );
    exitCode = 1;
    return;
  }

  _write(
    options.out,
    entries: result.entries,
    jmdictVersion: '${jmdict['version']}',
    jmdictDate: '${jmdict['dictDate']}',
  );
  stdout.writeln('Wrote ${result.entries.length} entries to ${options.out}.');
}

/// Command-line options, with the defaults the repository layout implies.
typedef _Options = ({
  String data,
  String out,
  String overlay,
  String seed,
  bool overlayOnly,
});

/// Purpose: Read the command line.
/// Inputs: `args`.
/// Returns: `_Options`.
/// Side effects: None.
/// Notes: Internal helper. Flags take `--name value`; an unknown flag is
/// ignored rather than fatal, because the tool is run by hand.
_Options _parseArgs(List<String> args) {
  var data = 'tool/data';
  var out = 'assets/content/vocab.json';
  var overlay = 'assets/content/vocab_zh.json';
  var seed = 'tool/content/vocab_seed.json';
  var overlayOnly = false;
  for (var i = 0; i < args.length; i++) {
    final next = i + 1 < args.length ? args[i + 1] : null;
    switch (args[i]) {
      case '--data' when next != null:
        data = next;
      case '--out' when next != null:
        out = next;
      case '--overlay' when next != null:
        overlay = next;
      case '--seed' when next != null:
        seed = next;
      case '--overlay-only':
        overlayOnly = true;
    }
  }
  return (
    data: data,
    out: out,
    overlay: overlay,
    seed: seed,
    overlayOnly: overlayOnly,
  );
}

/// Purpose: Find the unpacked JMdict JSON.
/// Inputs: `dir`.
/// Returns: `File?` — the first `jmdict-eng-*.json`, or null.
/// Side effects: Lists a directory.
/// Notes: Internal helper. The file name carries the release version, so it is
/// matched by prefix rather than named exactly.
File? _findJmdict(String dir) {
  final directory = Directory(dir);
  if (!directory.existsSync()) return null;
  final matches = directory
      .listSync()
      .whereType<File>()
      .where(
        (f) =>
            f.uri.pathSegments.last.startsWith('jmdict-eng') &&
            f.path.endsWith('.json'),
      )
      .toList();
  if (matches.isEmpty) return null;
  matches.sort((a, b) => a.path.compareTo(b.path));
  return matches.first;
}

/// Purpose: Parse the Chinese overlay file.
/// Inputs: `raw`.
/// Returns: `Map<String, Map<String, Object?>>` keyed by catalog id.
/// Side effects: None.
/// Notes: Internal helper. The overlay's `reviewed` flag stays here and never
/// reaches the catalog; it tracks authoring, not runtime behavior.
Map<String, Map<String, Object?>> _readOverlay(String raw) {
  final json = jsonDecode(raw);
  if (json is! Map || json['entries'] is! Map) return {};
  return {
    for (final entry in (json['entries'] as Map).entries)
      if (entry.value is Map)
        entry.key.toString(): (entry.value as Map).cast<String, Object?>(),
  };
}

/// Purpose: Re-apply the overlay to an existing catalog.
/// Inputs: `out` — the catalog path; `overlay`.
/// Returns: None.
/// Side effects: Rewrites the catalog in place.
/// Notes: Internal helper. Only the `zh` key of `meanings` is touched, so a
/// hand-written seed gloss is left exactly as the full import wrote it. An
/// overlay row naming an id the catalog no longer has is reported, not
/// dropped silently.
void _applyOverlayOnly(String out, Map<String, Map<String, Object?>> overlay) {
  final file = File(out);
  if (!file.existsSync()) {
    stderr.writeln('No catalog at $out; run a full import first.');
    exitCode = 1;
    return;
  }
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final entries = <Map<String, Object?>>[
    for (final entry in json['entries'] as List)
      (entry as Map).cast<String, Object?>(),
  ];
  final known = {for (final entry in entries) '${entry['id']}'};
  var applied = 0;
  for (final entry in entries) {
    final row = overlay['${entry['id']}'];
    if (row == null) continue;
    final zh = row['zh'];
    if (zh is! List || zh.isEmpty) continue;
    final meanings = (entry['meanings'] as Map).cast<String, Object?>();
    meanings['zh'] = zh;
    entry['meanings'] = meanings;
    applied++;
  }
  for (final id in overlay.keys) {
    if (!known.contains(id)) {
      stderr.writeln('  overlay id $id is not in the catalog any more');
    }
  }
  _write(
    out,
    entries: entries,
    jmdictVersion: '${(json['inputs'] as Map?)?['jmdictVersion']}',
    jmdictDate: '${(json['inputs'] as Map?)?['jmdictDate']}',
  );
  stdout.writeln('Applied $applied Chinese glosses to $out.');
}

/// Purpose: Write the catalog file.
/// Inputs: `path`, `entries`, `jmdictVersion`, `jmdictDate`.
/// Returns: None.
/// Side effects: Writes the file; reads the conversion dictionaries.
/// Notes: Internal helper. Traditional Chinese is generated here rather than
/// by a later pass, so a fresh catalog already carries it and
/// `tool/convert_zh_tw.dart` has nothing to do — the two tools cannot disagree
/// about what the Traditional text should be, because they run the same code.
void _write(
  String path, {
  required List<Map<String, Object?>> entries,
  required String jmdictVersion,
  required String jmdictDate,
}) {
  final converter = OpenCcConverter.load(openCcDirectory);
  final translated = <Map<String, Object?>>[
    for (final entry in entries)
      (withTraditional(entry, converter.convert) as Map).cast<String, Object?>(),
  ];
  File(path).writeAsStringSync(
    encodeCatalog(
      translated,
      jmdictVersion: jmdictVersion,
      jmdictDate: jmdictDate,
    ),
  );
}
