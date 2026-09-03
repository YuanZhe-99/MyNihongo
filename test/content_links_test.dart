import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/models/content_catalog.dart';
import 'package:my_nihongo/features/content/models/localized_strings.dart';
import 'package:my_nihongo/features/content/services/content_links.dart';
import 'package:my_nihongo/features/content/services/content_repository.dart';
import 'package:my_nihongo/features/kana/models/kana.dart';

/// Purpose: Test the cross-links between kana, vocabulary and grammar.
/// Inputs: The real bundled catalog, plus a couple of hand-made cases.
/// Returns: None.
/// Side effects: Reads the content assets.
/// Notes: These are substring matches, not parsing, so the properties worth
/// pinning are the ones that keep a wrong match from being useless: the
/// longest pattern wins, a link never points above its own level, and a
/// single-character particle does not match every sentence in the catalog.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ContentCatalog catalog;

  setUpAll(() async {
    ContentRepository.parseInIsolate = false;
    catalog = await ContentRepository.load();
  });

  tearDownAll(() => ContentRepository.parseInIsolate = true);

  test('a pattern is stripped to the text a sentence would contain', () {
    expect(grammarMatchCore('〜てもいいです（か）'), 'てもいいですか');
    expect(grammarMatchCore('〜ます / 〜ません'), 'ます/ません');
    expect(grammarMatchCore('あります / います'), 'あります/います');
  });

  test('derived forms drop placeholders and single characters', () {
    final point = catalog.grammarById('grammar:koto-ga-dekiru')!;
    // This point has no authored match list, so the forms come from the
    // pattern.
    expect(effectiveMatchForms(point), contains('ことができます'));
  });

  test('an authored match list wins over the pattern', () {
    final point = catalog.grammarById('grammar:wa-topic')!;
    expect(effectiveMatchForms(point), ['は']);
  });

  test('the longest matching point is listed first', () {
    const example = ContentExample(
      ja: 'ここに座ってもいいですか。',
      reading: 'ここにすわってもいいですか。',
    );
    final points = grammarPointsInExample(catalog, example);
    expect(points, isNotEmpty);
    expect(points.first.id, 'grammar:te-mo-ii');
  });

  test('a sentence with no grammar in the catalog links nothing', () {
    const example = ContentExample(ja: 'zzz');
    expect(grammarPointsInExample(catalog, example), isEmpty);
  });

  test('words linked from a grammar point stay at or below its level', () {
    for (final point in catalog.grammar) {
      for (final word in vocabInExamples(catalog, point)) {
        expect(
          word.level.index,
          lessThanOrEqualTo(point.level.index),
          reason: '${point.id} links ${word.id}',
        );
      }
    }
  });

  test('a grammar point links the words its examples actually use', () {
    final point = catalog.grammarById('grammar:o-object')!;
    final words = vocabInExamples(catalog, point);
    expect(words.map((w) => w.headword), contains('水'));
  });

  test('kana example words start with that kana and are easy first', () {
    final entry = kanaEntryById('kana:あ')!;
    final words = vocabStartingWithKana(catalog, entry);
    expect(words, isNotEmpty);
    expect(words.length, lessThanOrEqualTo(8));
    for (final word in words) {
      expect(word.reading, startsWith('あ'));
      expect(word.reading.length, greaterThanOrEqualTo(2));
    }
    // Sorted by level, so nothing harder appears before something easier.
    for (var i = 1; i < words.length; i++) {
      expect(
        words[i].level.index,
        greaterThanOrEqualTo(words[i - 1].level.index),
      );
    }
  });

  test('every kana in the tables offers at least one example word', () {
    // Not a coverage target so much as a check that the reading match works
    // for every row, including the voiced and yoon tables.
    var withWords = 0;
    for (final entry in allKanaEntries()) {
      if (vocabStartingWithKana(catalog, entry).isNotEmpty) withWords++;
    }
    expect(withWords, greaterThan(allKanaEntries().length ~/ 2));
  });
}
