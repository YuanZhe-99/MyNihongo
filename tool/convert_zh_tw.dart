/// Purpose: Regenerate the Traditional Chinese text in the bundled content.
/// Inputs: `args` — `--opencc <dir>` and `--assets <dir>` for testing.
/// Returns: None; sets the exit code.
/// Side effects: Rewrites the content files under `assets/content/`.
/// Notes: Run this after editing any Simplified Chinese text. Every `zh_TW`
/// string in the content is generated from the `zh` beside it and never
/// hand-edited — `test/content_zh_tw_test.dart` compares the two and fails when
/// they have drifted. The tool is idempotent: a second run leaves an empty
/// `git diff`, which is what makes "did anyone forget to run it" answerable.
library;

import 'dart:convert';
import 'dart:io';

import 'src/chinese_converter.dart';
import 'src/vocab_import_core.dart';
import 'src/zh_tw.dart';

Future<void> main(List<String> args) async {
  var openCc = openCcDirectory;
  var assets = 'assets/content';
  for (var i = 0; i + 1 < args.length; i++) {
    if (args[i] == '--opencc') openCc = args[i + 1];
    if (args[i] == '--assets') assets = args[i + 1];
  }

  final converter = OpenCcConverter.load(openCc);
  var written = 0;

  final catalog = File('$assets/vocab.json');
  if (!catalog.existsSync()) {
    stderr.writeln('No catalog at ${catalog.path}.');
    exitCode = 1;
    return;
  }
  written += _rewriteCatalog(catalog, converter) ? 1 : 0;

  final others = <File>[
    File('$assets/kana_notes.json'),
    File('$assets/function_words.json'),
    // Every directory of catalog content, so a new level's grammar or units
    // are converted the first time the tool runs after they land rather than
    // the first time somebody notices. **Not `prompts/`**: those templates are
    // instructions a model follows, hand-written in each language the way the
    // ARB files are, and this tool would delete a Traditional block it cannot
    // regenerate from a Simplified sibling.
    for (final name in const ['drills', 'grammar', 'lessons'])
      if (Directory('$assets/$name').existsSync())
        ...Directory('$assets/$name').listSync().whereType<File>().where(
          (file) => file.path.endsWith('.json'),
        ),
  ]..sort((a, b) => a.path.compareTo(b.path));
  for (final file in others) {
    if (!file.existsSync()) {
      stderr.writeln('Missing ${file.path}.');
      exitCode = 1;
      return;
    }
    written += _rewritePretty(file, converter) ? 1 : 0;
  }

  stdout.writeln(
    written == 0
        ? 'Traditional Chinese is already up to date.'
        : 'Updated $written content file${written == 1 ? '' : 's'}.',
  );
}

/// Purpose: Rewrite the vocabulary catalog in its own committed shape.
/// Inputs: `file`, `converter`.
/// Returns: `bool` — whether the file changed.
/// Side effects: Writes the file when it changed.
/// Notes: Internal helper. The catalog keeps its one-entry-per-line encoding
/// through [encodeCatalog], the same function the importer writes it with, so
/// running this tool never reformats 7,744 entries into a different shape.
bool _rewriteCatalog(File file, OpenCcConverter converter) {
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final entries = <Map<String, Object?>>[
    for (final entry in json['entries'] as List)
      (withTraditional(entry, converter.convert) as Map)
          .cast<String, Object?>(),
  ];
  final inputs = json['inputs'] as Map?;
  return _writeIfChanged(
    file,
    encodeCatalog(
      entries,
      jmdictVersion: '${inputs?['jmdictVersion']}',
      jmdictDate: '${inputs?['jmdictDate']}',
    ),
  );
}

/// Purpose: Rewrite a hand-authored content file.
/// Inputs: `file`, `converter`.
/// Returns: `bool` — whether the file changed.
/// Side effects: Writes the file when it changed.
/// Notes: Internal helper. Two-space pretty printing, the same encoder every
/// other JSON file in the series is written with, so the first run reformats
/// the file once and every run after that is a no-op.
bool _rewritePretty(File file, OpenCcConverter converter) {
  final json = jsonDecode(file.readAsStringSync());
  final encoded = const JsonEncoder.withIndent(
    '  ',
  ).convert(withTraditional(json, converter.convert));
  return _writeIfChanged(file, '$encoded\n');
}

/// Purpose: Write a file only when its content differs.
/// Inputs: `file`, `content`.
/// Returns: `bool` — whether it was written.
/// Side effects: Writes the file.
/// Notes: Internal helper. Skipping an identical write keeps the file's
/// timestamp, so a build system that watches the assets is not woken by a tool
/// that decided nothing.
bool _writeIfChanged(File file, String content) {
  if (file.existsSync() && file.readAsStringSync() == content) return false;
  file.writeAsStringSync(content);
  stdout.writeln('  ${file.path.replaceAll(r'\', '/')}');
  return true;
}
