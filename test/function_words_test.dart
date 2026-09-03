import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/sentence/models/function_word.dart';
import 'package:my_nihongo/features/sentence/models/token.dart';

/// Purpose: Validate the shipped function-word table.
/// Inputs: None.
/// Returns: None.
/// Side effects: Reads the asset from disk.
/// Notes: The table is content, and content is checked the way the catalog is:
/// ids are a compatibility contract, every entry needs both languages, and a
/// category or stem shape the code does not know would silently drop the word
/// rather than fail loudly. Read from disk rather than the bundle so the test
/// needs no binding.
void main() {
  late Map<String, dynamic> raw;
  late FunctionWordTable table;

  setUpAll(() {
    raw =
        jsonDecode(
              File('assets/content/function_words.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    table = FunctionWordTable.fromJson(raw);
  });

  test('every entry in the file parsed', () {
    expect(table.words.length, (raw['words'] as List).length);
  });

  test('ids are unique and prefixed', () {
    final ids = table.words.map((w) => w.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final id in ids) {
      expect(id, startsWith('fw:'));
    }
  });

  test('every word carries English and Chinese', () {
    for (final word in table.words) {
      expect(word.gloss['en'], isNotNull, reason: word.id);
      expect(word.gloss['en'], isNotEmpty, reason: word.id);
      expect(word.gloss['zh'], isNotNull, reason: word.id);
      expect(word.gloss['zh'], isNotEmpty, reason: word.id);
    }
  });

  test('the particles a beginner meets first are all present', () {
    final surfaces = table.words.map((w) => w.surface).toSet();
    for (final particle in ['は', 'が', 'を', 'に', 'で', 'と', 'の', 'も', 'へ']) {
      expect(surfaces, contains(particle), reason: particle);
    }
  });

  test('every stem-taking auxiliary declares what it attaches to', () {
    for (final word in table.words) {
      if (word.category != FunctionWordCategory.auxiliary) continue;
      expect(
        word.needs,
        isNot(StemShape.any),
        reason: '${word.id} would attach to anything',
      );
    }
  });

  test('a copula or auxiliary lemmatizes to its family', () {
    final byId = {for (final w in table.words) w.id: w};
    expect(byId['fw:deshita']!.lemma, byId['fw:desu']!.lemma);
    expect(byId['fw:masen']!.lemma, byId['fw:masu']!.lemma);
    expect(byId['fw:nakatta']!.lemma, byId['fw:nai']!.lemma);
  });

  test('forms name real inflection values', () {
    final names = InflectionForm.values.map((f) => f.name).toSet();
    for (final word in raw['words'] as List) {
      for (final form in ((word as Map)['forms'] as List?) ?? const []) {
        expect(names, contains(form), reason: '${word['id']}: $form');
      }
    }
  });

  test('the named sets the checks read are present and non-empty', () {
    for (final name in [
      'time-past',
      'time-future',
      'path-verbs',
      'motion-verbs',
    ]) {
      expect(table.set(name), isNotEmpty, reason: name);
    }
    expect(table.transitivityPairs, isNotEmpty);
    for (final pair in table.transitivityPairs) {
      expect(pair.$1, isNotEmpty);
      expect(pair.$2, isNotEmpty);
    }
  });

  test('a malformed entry is skipped rather than fatal', () {
    final broken = FunctionWordTable.fromJson({
      'words': [
        {'id': 'fw:ok', 'surface': 'を', 'category': 'particle-case'},
        {'id': 'fw:bad', 'surface': 'x', 'category': 'not-a-category'},
        'nonsense',
      ],
    });
    expect(broken.words.map((w) => w.id), ['fw:ok']);
  });
}
