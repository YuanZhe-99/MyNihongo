import 'package:flutter_test/flutter_test.dart';
import 'package:my_nihongo/features/content/models/content_catalog.dart';
import 'package:my_nihongo/features/content/models/localized_strings.dart';
import 'package:my_nihongo/features/content/services/content_repository.dart';

/// Purpose: Test that `LocalizedStrings.matches` searches every language and
/// that its cached lowercase text gives the same answers as the plain loop.
/// Inputs: None.
/// Returns: None.
/// Side effects: Reads the content assets.
/// Notes: The cache exists because the vocabulary search lowercased every
/// string of every entry on every keystroke. The equivalence test runs both
/// implementations over the whole bundled catalog, so a cache that dropped a
/// language, or kept stale text, is caught by the data and not by a guess.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The straightforward version the cache replaced.
  bool reference(LocalizedStrings strings, String query) {
    for (final list in strings.values.values) {
      for (final text in list) {
        if (text.toLowerCase().contains(query)) return true;
      }
    }
    return false;
  }

  test('a query finds text in any language, whatever its case', () {
    const strings = LocalizedStrings({
      'en': ['Water', 'a drink'],
      'zh': ['水'],
    });
    expect(strings.matches('water'), isTrue);
    expect(strings.matches('drink'), isTrue);
    expect(strings.matches('水'), isTrue);
    expect(strings.matches('fire'), isFalse);
    // Searching twice, from the cache, gives the same answers.
    expect(strings.matches('water'), isTrue);
    expect(strings.matches('fire'), isFalse);
  });

  test('a query does not match across two separate strings', () {
    const strings = LocalizedStrings({
      'en': ['abc', 'def'],
    });
    expect(strings.matches('cd'), isFalse);
    expect(strings.matches('abc'), isTrue);
  });

  test('nothing matches an empty set of strings', () {
    expect(LocalizedStrings.empty.matches('a'), isFalse);
    expect(const LocalizedStrings({'en': <String>[]}).matches('a'), isFalse);
  });

  test(
    'the cached search agrees with the plain loop over the catalog',
    () async {
      final ContentCatalog catalog = await ContentRepository.load();
      const queries = ['a', 'water', 'eat', 'the', '水', '食', 'ひと', 'xyzzy', ''];
      var compared = 0;
      for (final entry in catalog.vocab) {
        for (final query in queries) {
          if (query.isEmpty) continue;
          expect(
            entry.meanings.matches(query),
            reference(entry.meanings, query),
            reason: '${entry.id} for "$query"',
          );
          compared++;
        }
      }
      expect(compared, greaterThan(1000));
    },
  );
}
