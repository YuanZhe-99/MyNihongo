import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/models/content_catalog.dart';
import 'package:my_nihongo/features/sentence/services/lexicon.dart';

/// Purpose: Test the surface-to-entry index the app reads Japanese text with.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: `toKana` is what makes pronunciation scoring honest: a recognizer
/// that answered in kanji has to be resolved before a comparison means
/// anything, and a span the catalog does not know has to survive unchanged so
/// it still costs edits rather than vanishing.
ContentCatalog _catalog() => ContentCatalog.fromJson({
  'schemaVersion': 2,
  'entries': [
    {
      'id': 'vocab:t-tokyo',
      'level': 'N5',
      'kanji': '東京',
      'reading': 'とうきょう',
      'pos': ['proper-noun'],
      'meanings': {
        'en': ['Tokyo'],
      },
    },
    {
      'id': 'vocab:t-ni',
      'level': 'N5',
      'reading': 'に',
      'pos': ['particle'],
      'meanings': {
        'en': ['in'],
      },
    },
    {
      'id': 'vocab:t-iku',
      'level': 'N5',
      'kanji': '行く',
      'reading': 'いく',
      'pos': ['verb-godan'],
      'meanings': {
        'en': ['to go'],
      },
    },
  ],
}, const []);

void main() {
  late Lexicon lexicon;

  setUp(() => lexicon = Lexicon.build(_catalog()));

  test('entries are found by how they are written', () {
    expect(lexicon.byHeadword('東京').single.id, 'vocab:t-tokyo');
    expect(lexicon.byHeadword('京都'), isEmpty);
  });

  test('entries are found by their reading, in either script', () {
    expect(lexicon.byReading('とうきょう').single.id, 'vocab:t-tokyo');
    expect(lexicon.byReading('トウキョウ').single.id, 'vocab:t-tokyo');
  });

  test('a kana-only entry is indexed under its own form', () {
    expect(lexicon.byHeadword('に').single.id, 'vocab:t-ni');
  });

  test('toKana resolves a known headword to its reading', () {
    expect(lexicon.toKana('東京'), 'とうきょう');
  });

  test('toKana takes the longest match, not the first character', () {
    expect(lexicon.toKana('東京に行く'), 'とうきょうにいく');
  });

  test('an unknown span is copied through so it still costs edits', () {
    expect(lexicon.toKana('京都'), '京都');
  });

  test('the index reports how many entries it covers', () {
    expect(lexicon.entryCount, 3);
  });
}
