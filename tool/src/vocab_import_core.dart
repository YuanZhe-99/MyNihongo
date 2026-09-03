/// Purpose: Build `assets/content/vocab.json` from JMdict and the JLPT lists.
/// Inputs: The decoded JMdict body, the per-level JLPT CSVs, the hand-written
/// seed, and the Chinese gloss overlay.
/// Returns: The generated catalog as a list of entry maps, plus a log.
/// Side effects: None — every file read and write lives in `import_vocab.dart`,
/// so this half is directly unit-testable.
/// Notes: The output must be byte-stable: re-running with unchanged inputs has
/// to produce an empty `git diff`, or nobody will re-run it. That rules out
/// timestamps, map iteration order, and anything derived from the file system.
library;

import 'dart:convert';

// ignore: avoid_relative_lib_imports
import '../../lib/features/content/models/parts_of_speech.dart';

/// One row of a JLPT list CSV.
class JlptRow {
  /// JMdict sequence number the row points at.
  final int seq;

  /// The reading the list gives.
  final String kana;

  /// The written form the list gives; empty for kana-only words.
  final String kanji;

  /// Purpose: Create a JLPT row instance.
  /// Inputs: `seq`, `kana`, `kanji`.
  /// Returns: A new `JlptRow` instance.
  /// Side effects: None.
  /// Notes: None.
  const JlptRow({required this.seq, required this.kana, required this.kanji});
}

/// What one import run produced.
class ImportResult {
  /// The catalog entries, in output order.
  final List<Map<String, Object?>> entries;

  /// Lines worth showing the operator: dropped duplicates, unmapped tags.
  final List<String> log;

  /// Sequence numbers a list named but JMdict does not carry.
  final List<int> missingSeqs;

  /// Purpose: Create an import result instance.
  /// Inputs: `entries`, `log`, `missingSeqs`.
  /// Returns: A new `ImportResult` instance.
  /// Side effects: None.
  /// Notes: None.
  const ImportResult({
    required this.entries,
    this.log = const [],
    this.missingSeqs = const [],
  });
}

/// JMdict part-of-speech tags mapped onto the app's closed set.
///
/// Tags not listed here are dropped, with a count reported per run so a JMdict
/// update that introduces one is noticed rather than silently swallowed.
const jmdictPosMap = <String, String>{
  'n': 'noun',
  'n-adv': 'noun',
  'n-t': 'noun',
  'n-suf': 'noun',
  'n-pref': 'noun',
  'pn': 'pronoun',
  'n-pr': 'proper-noun',
  'v1': 'verb-ichidan',
  'v1-s': 'verb-ichidan',
  'v5u': 'verb-godan',
  'v5u-s': 'verb-godan',
  'v5k': 'verb-godan',
  'v5k-s': 'verb-godan',
  'v5g': 'verb-godan',
  'v5s': 'verb-godan',
  'v5t': 'verb-godan',
  'v5n': 'verb-godan',
  'v5b': 'verb-godan',
  'v5m': 'verb-godan',
  'v5r': 'verb-godan',
  'v5r-i': 'verb-godan',
  'v5aru': 'verb-godan',
  'vk': 'verb-irregular',
  'vs-i': 'verb-irregular',
  'vs-s': 'verb-irregular',
  'vz': 'verb-irregular',
  'vn': 'verb-irregular',
  'vr': 'verb-irregular',
  'vs': 'suru-verb',
  'vt': 'transitive',
  'vi': 'intransitive',
  'adj-i': 'i-adjective',
  'adj-ix': 'i-adjective',
  'adj-na': 'na-adjective',
  'adj-no': 'no-adjective',
  'adj-pn': 'adnominal',
  // Pre-noun-only and taru adjectives both behave adnominally for a learner;
  // the app's set does not split them out.
  'adj-f': 'adnominal',
  'adj-t': 'adnominal',
  'adv': 'adverb',
  'adv-to': 'adverb',
  'exp': 'expression',
  'prt': 'particle',
  'conj': 'conjunction',
  'int': 'interjection',
  'ctr': 'counter',
  'pref': 'prefix',
  'suf': 'suffix',
  'num': 'numeric',
  'aux': 'auxiliary',
  'aux-v': 'auxiliary',
  'aux-adj': 'auxiliary',
  'cop': 'auxiliary',
};

/// Sense tags whose glosses are not worth teaching a learner.
///
/// An archaic or obscene reading is still the same word, so the entry stays;
/// only that sense's glosses are skipped.
const skippedSenseMisc = <String>{'arch', 'obs', 'obsc', 'rare', 'vulg', 'X'};

/// Levels in import order: easiest first, so a word shared between lists is
/// taught at the earliest level it appears in.
const importLevels = ['N5', 'N4', 'N3', 'N2', 'N1'];

/// JLPT-list sequence numbers that point at the wrong JMdict entry.
///
/// The lists are keyed by sequence number, and a handful of rows name a
/// homograph instead of the word the list means. Each of these was checked by
/// hand against the reading the list gives:
///
/// | List row | Points at | Should be |
/// |---|---|---|
/// | コップ | 2846389 "cop, police officer" | 1050390 "drinking glass" |
/// | ボタン | 1182880 牡丹 "tree peony" | 1123880 釦 "button" |
/// | だんだん | 2546180 "thank you" (dialect) | 1597350 段々 "gradually" |
///
/// Keeping the correction here rather than editing the committed CSVs means
/// the lists stay byte-identical to their upstream source and the reason for
/// each change stays readable.
const jlptSeqCorrections = <int, int>{
  2846389: 1050390,
  1182880: 1123880,
  2546180: 1597350,
};

/// Purpose: Parse one JLPT list CSV.
/// Inputs: `csv` — the file contents, header row included.
/// Returns: `List<JlptRow>` in file order.
/// Side effects: None.
/// Notes: The files are `jmdict_seq,kana,kanji,waller_definition` with
/// quoted definitions that may contain commas, so the split stops after three
/// fields. A row whose sequence number does not parse is skipped: the lists
/// are a build input, and one bad row should not stop a rebuild.
List<JlptRow> parseJlptCsv(String csv) {
  final rows = <JlptRow>[];
  final lines = csv.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trimRight();
    if (line.isEmpty) continue;
    if (i == 0 && line.startsWith('jmdict_seq')) continue;
    final parts = line.split(',');
    if (parts.length < 3) continue;
    final raw = int.tryParse(parts[0].trim());
    if (raw == null) continue;
    final seq = jlptSeqCorrections[raw] ?? raw;
    rows.add(JlptRow(seq: seq, kana: parts[1].trim(), kanji: parts[2].trim()));
  }
  return rows;
}

/// Purpose: Index a decoded JMdict body by sequence number.
/// Inputs: `jmdict` — the decoded top-level object.
/// Returns: `Map<int, Map<String, Object?>>`.
/// Side effects: None.
/// Notes: JMdict writes the id as a string; it is parsed here once so every
/// later lookup is an int.
Map<int, Map<String, Object?>> indexJmdict(Object? jmdict) {
  final index = <int, Map<String, Object?>>{};
  if (jmdict is! Map || jmdict['words'] is! List) return index;
  for (final word in jmdict['words'] as List) {
    if (word is! Map) continue;
    final id = int.tryParse('${word['id']}');
    if (id == null) continue;
    index[id] = word.cast<String, Object?>();
  }
  return index;
}

/// Purpose: Read the forms of a JMdict word.
/// Inputs: `word`, `key` — `kanji` or `kana`.
/// Returns: A list of `(text, common)` pairs in JMdict order.
/// Side effects: None.
/// Notes: JMdict orders forms by how usual they are, so the first entry is the
/// default choice when the JLPT list does not name one.
List<({String text, bool common})> formsOf(
  Map<String, Object?> word,
  String key,
) {
  final raw = word[key];
  if (raw is! List) return const [];
  return [
    for (final form in raw)
      if (form is Map && form['text'] is String)
        (text: form['text'] as String, common: form['common'] == true),
  ];
}

/// Purpose: Decide how a word should be written and read.
/// Inputs: `word` — the JMdict entry; `row` — the list row naming it.
/// Returns: The chosen headword, reading, whether the form is common, and a
/// warning when the list's own forms are not in JMdict.
/// Side effects: None.
/// Notes: The list's forms win when JMdict carries them, because the lists are
/// what learners are tested on. A word with no kanji, or whose first sense is
/// tagged `uk` (usually written in kana), is headed by its reading — writing
/// 有る for ある would teach the wrong thing.
({String headword, String reading, bool common, String? warning}) chooseForms(
  Map<String, Object?> word,
  JlptRow row,
) {
  final kanjiForms = formsOf(word, 'kanji');
  final kanaForms = formsOf(word, 'kana');
  if (kanaForms.isEmpty) {
    return (
      headword: row.kana,
      reading: row.kana,
      common: false,
      warning: 'seq ${row.seq}: JMdict entry has no kana form',
    );
  }

  String? warning;
  var reading = kanaForms.first.text;
  var readingCommon = kanaForms.first.common;
  final listedKana = kanaForms.where((f) => f.text == row.kana);
  if (listedKana.isNotEmpty) {
    reading = listedKana.first.text;
    readingCommon = listedKana.first.common;
  } else if (row.kana.isNotEmpty) {
    warning = 'seq ${row.seq}: list reading ${row.kana} not in JMdict';
  }

  final usuallyKana = _isUsuallyKana(word);
  if (kanjiForms.isEmpty || usuallyKana || row.kanji.isEmpty) {
    return (
      headword: reading,
      reading: reading,
      common: readingCommon,
      warning: warning,
    );
  }

  // The lists name a written form, but not always the usual one: the N5 list
  // gives 明い for あかるい, which JMdict marks as a search-only form of the
  // common 明るい. Follow the list only when its form is one JMdict considers
  // common, or when no form is.
  final commonKanji = kanjiForms.where((f) => f.common);
  final listedKanji = kanjiForms.where(
    (f) => f.text == row.kanji && (f.common || commonKanji.isEmpty),
  );
  if (listedKanji.isEmpty && commonKanji.isNotEmpty) {
    return (
      headword: commonKanji.first.text,
      reading: reading,
      common: true,
      warning: kanjiForms.any((f) => f.text == row.kanji)
          ? 'seq ${row.seq}: list form ${row.kanji} is not a common form, '
                'using ${commonKanji.first.text}'
          : warning ?? 'seq ${row.seq}: list form ${row.kanji} not in JMdict',
    );
  }
  if (listedKanji.isEmpty) {
    return (
      headword: kanjiForms.first.text,
      reading: reading,
      common: kanjiForms.first.common,
      warning:
          warning ?? 'seq ${row.seq}: list form ${row.kanji} not in JMdict',
    );
  }
  return (
    headword: listedKanji.first.text,
    reading: reading,
    common: listedKanji.first.common,
    warning: warning,
  );
}

/// Purpose: Report whether JMdict says the word is usually written in kana.
/// Inputs: `word`.
/// Returns: `bool`.
/// Side effects: None.
/// Notes: Internal helper. `uk` sits on a sense, not the word, and the first
/// sense is the one the headword should follow.
bool _isUsuallyKana(Map<String, Object?> word) {
  final senses = word['sense'];
  if (senses is! List || senses.isEmpty) return false;
  final first = senses.first;
  if (first is! Map) return false;
  final misc = first['misc'];
  return misc is List && misc.contains('uk');
}

/// Purpose: Collect the English glosses worth showing for a word.
/// Inputs: `word`, `headword`, `reading`.
/// Returns: Up to three gloss strings.
/// Side effects: None.
/// Notes: One string per sense, each joining that sense's first three glosses
/// with `; `. Senses restricted to a different written form or reading are
/// skipped, so a word imported under one form does not display another form's
/// meaning. Archaic and offensive senses are skipped for the same reason a
/// textbook leaves them out.
List<String> glossesOf(
  Map<String, Object?> word,
  String headword,
  String reading,
) {
  final filtered = _glosses(word, headword, reading, filter: true);
  // A handful of entries are made up entirely of archaic or form-restricted
  // senses, so filtering leaves nothing. Shipping a word with no meaning at
  // all is worse than showing its one rare sense, so fall back to the
  // unfiltered read.
  return filtered.isNotEmpty
      ? filtered
      : _glosses(word, headword, reading, filter: false);
}

/// Purpose: Read a word's glosses, optionally filtering unhelpful senses.
/// Inputs: `word`, `headword`, `reading`, `filter`.
/// Returns: Up to three gloss strings.
/// Side effects: None.
/// Notes: Internal helper; see [glossesOf] for the rules.
List<String> _glosses(
  Map<String, Object?> word,
  String headword,
  String reading, {
  required bool filter,
}) {
  final senses = word['sense'];
  if (senses is! List) return const [];
  final out = <String>[];
  for (final sense in senses) {
    if (out.length >= 3) break;
    if (sense is! Map) continue;
    if (filter) {
      final misc = sense['misc'];
      if (misc is List && misc.any(skippedSenseMisc.contains)) continue;
      if (!_appliesTo(sense['appliesToKanji'], headword)) continue;
      if (!_appliesTo(sense['appliesToKana'], reading)) continue;
    }
    final glosses = sense['gloss'];
    if (glosses is! List) continue;
    final texts = <String>[];
    for (final gloss in glosses) {
      if (texts.length >= 3) break;
      if (gloss is Map && gloss['lang'] == 'eng' && gloss['text'] is String) {
        texts.add(gloss['text'] as String);
      }
    }
    if (texts.isNotEmpty) out.add(texts.join('; '));
  }
  return out;
}

/// Purpose: Test a sense's form restriction.
/// Inputs: `restriction` — JMdict's `appliesToKanji`/`appliesToKana`; `form`.
/// Returns: `bool` — true when the sense applies to this form.
/// Side effects: None.
/// Notes: Internal helper. JMdict writes `["*"]` for "every form", and an
/// explicit list otherwise.
bool _appliesTo(Object? restriction, String form) {
  if (restriction is! List || restriction.isEmpty) return true;
  if (restriction.contains('*')) return true;
  return restriction.contains(form);
}

/// Purpose: Map a word's JMdict part-of-speech tags onto the app's set.
/// Inputs: `word`, `unmappedTags` — a counter the caller owns.
/// Returns: The mapped tags, in the order [vocabPartsOfSpeech] declares them.
/// Side effects: Increments `unmappedTags` for tags with no mapping.
/// Notes: Ordering by the declared set rather than by encounter is what makes
/// the output stable: JMdict's own order varies between senses.
List<String> posOf(Map<String, Object?> word, Map<String, int> unmappedTags) {
  final senses = word['sense'];
  if (senses is! List) return const [];
  final found = <String>{};
  for (final sense in senses) {
    if (sense is! Map) continue;
    final misc = sense['misc'];
    if (misc is List && misc.any(skippedSenseMisc.contains)) continue;
    final pos = sense['partOfSpeech'];
    if (pos is! List) continue;
    for (final tag in pos) {
      if (tag is! String) continue;
      final mapped = jmdictPosMap[tag];
      if (mapped == null) {
        unmappedTags[tag] = (unmappedTags[tag] ?? 0) + 1;
        continue;
      }
      found.add(mapped);
    }
  }
  return [
    for (final tag in vocabPartsOfSpeech)
      if (found.contains(tag)) tag,
  ];
}

/// Purpose: Build the catalog entries from every input.
/// Inputs: `jmdictIndex` from [indexJmdict]; `listsByLevel` — the parsed rows
/// per level label; `seedEntries` — the hand-written entries, each carrying
/// `jmdictSeq`; `overlay` — Chinese glosses keyed by generated id.
/// Returns: `ImportResult`.
/// Side effects: None.
/// Notes: The rules, in the order they bite:
/// 1. Levels are walked easiest first, so a word on two lists is taught at the
///    easier one and its id is fixed there.
/// 2. A sequence number already taken is skipped; a second row that produces
///    the same written form and reading within one level is dropped with a log
///    line, because the lists do contain such pairs.
/// 3. A sequence number JMdict does not carry is collected in `missingSeqs`
///    for the caller to fail on — a silently missing word would be invisible.
/// 4. A seed entry is emitted whether or not the lists name it, keeps its own
///    level and examples, and contributes its old id as an alias. Its
///    hand-written glosses win over JMdict's, because they were written for
///    a learner rather than for a dictionary.
/// 5. Entries are sorted by level, then reading, then sequence number, so the
///    file order never depends on a hash.
ImportResult buildEntries({
  required Map<int, Map<String, Object?>> jmdictIndex,
  required Map<String, List<JlptRow>> listsByLevel,
  required List<Map<String, Object?>> seedEntries,
  required Map<String, Map<String, Object?>> overlay,
}) {
  final log = <String>[];
  final missingSeqs = <int>[];
  final unmappedTags = <String, int>{};
  final takenSeqs = <int>{};
  final entries = <Map<String, Object?>>[];

  final seedBySeq = <int, Map<String, Object?>>{
    for (final entry in seedEntries)
      if (entry['jmdictSeq'] is int) entry['jmdictSeq'] as int: entry,
  };
  final seedUsed = <int>{};

  for (final level in importLevels) {
    final rows = listsByLevel[level] ?? const <JlptRow>[];
    final seenForms = <String>{};
    for (final row in rows) {
      if (!takenSeqs.add(row.seq)) continue;
      final word = jmdictIndex[row.seq];
      if (word == null) {
        missingSeqs.add(row.seq);
        continue;
      }
      final chosen = chooseForms(word, row);
      if (chosen.warning != null) log.add(chosen.warning!);
      final formKey = '${chosen.headword}|${chosen.reading}';
      if (!seenForms.add(formKey)) {
        log.add(
          'seq ${row.seq}: duplicate of ${chosen.headword} '
          '(${chosen.reading}) within $level, dropped',
        );
        continue;
      }
      final seed = seedBySeq[row.seq];
      if (seed != null) seedUsed.add(row.seq);
      entries.add(
        _entry(
          seq: row.seq,
          level: level,
          headword: chosen.headword,
          reading: chosen.reading,
          common: chosen.common,
          pos: posOf(word, unmappedTags),
          english: glossesOf(word, chosen.headword, chosen.reading),
          seed: seed,
          overlay: overlay,
        ),
      );
    }
  }

  // Seed words the lists do not carry still ship: they were written with
  // examples and reviewed glosses, and their ids are already in users'
  // progress files.
  for (final entry in seedEntries) {
    final seq = entry['jmdictSeq'];
    if (seq is! int || seedUsed.contains(seq)) continue;
    if (!takenSeqs.add(seq)) continue;
    final word = jmdictIndex[seq];
    if (word == null) {
      missingSeqs.add(seq);
      continue;
    }
    final reading = '${entry['reading']}';
    final kanji = entry['kanji'];
    entries.add(
      _entry(
        seq: seq,
        level: '${entry['level']}',
        headword: kanji is String && kanji.isNotEmpty ? kanji : reading,
        reading: reading,
        common: true,
        pos: posOf(word, unmappedTags),
        english: glossesOf(word, '${entry['kanji'] ?? reading}', reading),
        seed: entry,
        overlay: overlay,
      ),
    );
  }

  entries.sort((a, b) {
    final levelOrder = importLevels
        .indexOf('${a['level']}')
        .compareTo(importLevels.indexOf('${b['level']}'));
    if (levelOrder != 0) return levelOrder;
    final reading = '${a['reading']}'.compareTo('${b['reading']}');
    if (reading != 0) return reading;
    return '${a['id']}'.compareTo('${b['id']}');
  });

  for (final tag in unmappedTags.keys.toList()..sort()) {
    log.add('unmapped JMdict pos tag "$tag": ${unmappedTags[tag]} occurrences');
  }
  for (final id in overlay.keys) {
    if (!entries.any((e) => e['id'] == id)) {
      log.add('overlay id $id is not in the catalog any more');
    }
  }

  return ImportResult(entries: entries, log: log, missingSeqs: missingSeqs);
}

/// Purpose: Assemble one catalog entry with its keys in a fixed order.
/// Inputs: Everything the entry needs, plus the optional seed and overlay.
/// Returns: `Map<String, Object?>`.
/// Side effects: None.
/// Notes: Internal helper. Key order is fixed by insertion order here, which
/// is what keeps the encoded file stable. Chinese is optional: an entry with
/// neither a seed gloss nor an overlay row ships English only and the UI falls
/// back to it.
Map<String, Object?> _entry({
  required int seq,
  required String level,
  required String headword,
  required String reading,
  required bool common,
  required List<String> pos,
  required List<String> english,
  required Map<String, Object?>? seed,
  required Map<String, Map<String, Object?>> overlay,
}) {
  final id = 'vocab:jm$seq';
  final seedMeanings = seed?['meanings'];
  final seedEnglish = seedMeanings is Map ? seedMeanings['en'] : null;
  final seedChinese = seedMeanings is Map ? seedMeanings['zh'] : null;
  final overlayChinese = overlay[id]?['zh'];

  final meanings = <String, Object?>{
    'en': seedEnglish is List && seedEnglish.isNotEmpty ? seedEnglish : english,
  };
  if (seedChinese is List && seedChinese.isNotEmpty) {
    meanings['zh'] = seedChinese;
  } else if (overlayChinese is List && overlayChinese.isNotEmpty) {
    meanings['zh'] = overlayChinese;
  }

  final examples = seed?['examples'];
  final seedId = seed?['id'];

  return <String, Object?>{
    'id': id,
    'level': level,
    if (headword != reading) 'kanji': headword,
    'reading': reading,
    if (seed?['romaji'] is String) 'romaji': seed!['romaji'],
    'pos': pos,
    'meanings': meanings,
    if (common) 'common': true,
    if (seedId is String && seedId != id) 'aliases': [seedId],
    if (examples is List && examples.isNotEmpty) 'examples': examples,
  };
}

/// Purpose: Encode the catalog file exactly as it ships.
/// Inputs: `entries`, `jmdictVersion`, `jmdictDate`.
/// Returns: `String` — the whole file.
/// Side effects: None.
/// Notes: The header is pretty-printed for review, and the entries are one
/// compact object per line: a 1.5 MB file pretty-printed would be four times
/// the size and give a useless diff, while one entry per line shows exactly
/// which words changed. No timestamp is written — a rebuild with unchanged
/// inputs has to produce an identical file. It lives here rather than beside
/// the file writing so `tool/convert_zh_tw.dart` can rewrite the catalog in
/// the same shape without importing the importer.
String encodeCatalog(
  List<Map<String, Object?>> entries, {
  required String jmdictVersion,
  required String jmdictDate,
}) {
  final buffer = StringBuffer()
    ..writeln('{')
    ..writeln('  "schemaVersion": 2,')
    ..writeln('  "source": "jmdict+jlpt",')
    ..writeln('  "sources": [')
    ..writeln('    {')
    ..writeln('      "name": "JMdict",')
    ..writeln('      "url": "https://www.edrdg.org/jmdict/j_jmdict.html",')
    ..writeln('      "license": "CC BY-SA 4.0 (EDRDG)",')
    ..writeln('      "via": "https://github.com/scriptin/jmdict-simplified"')
    ..writeln('    },')
    ..writeln('    {')
    ..writeln('      "name": "JLPT vocabulary lists",')
    ..writeln('      "url": "https://github.com/stephenmk/yomitan-jlpt-vocab",')
    ..writeln(
      '      "license": "CC BY-SA 4.0; underlying lists CC BY (Waller)"',
    )
    ..writeln('    }')
    ..writeln('  ],')
    ..writeln('  "inputs": {')
    ..writeln('    "jmdictVersion": ${jsonEncode(jmdictVersion)},')
    ..writeln('    "jmdictDate": ${jsonEncode(jmdictDate)}')
    ..writeln('  },')
    ..writeln('  "entries": [');
  for (var i = 0; i < entries.length; i++) {
    buffer
      ..write('    ')
      ..write(jsonEncode(entries[i]))
      ..writeln(i == entries.length - 1 ? '' : ',');
  }
  buffer
    ..writeln('  ]')
    ..writeln('}');
  return buffer.toString();
}
