import 'grammar_point.dart';
import 'vocab_entry.dart';

/// Everything the bundled content files describe, parsed once.
class ContentCatalog {
  /// Vocabulary in file order.
  final List<VocabEntry> vocab;

  /// Grammar points in file order.
  final List<GrammarPoint> grammar;

  /// Purpose: Create a content catalog instance.
  /// Inputs: `vocab`, `grammar`.
  /// Returns: A new `ContentCatalog` instance.
  /// Side effects: None.
  /// Notes: None.
  const ContentCatalog({this.vocab = const [], this.grammar = const []});

  /// Purpose: Parse the two content files.
  /// Inputs: `vocabJson` — the decoded vocabulary file; `grammarJson` — the
  /// decoded grammar file. Either may be null.
  /// Returns: `ContentCatalog`.
  /// Side effects: None.
  /// Notes: Malformed entries are skipped, not fatal; see the model parsers.
  factory ContentCatalog.fromJson(Object? vocabJson, Object? grammarJson) {
    final vocab = <VocabEntry>[];
    if (vocabJson is Map && vocabJson['entries'] is List) {
      for (final entry in vocabJson['entries'] as List) {
        final parsed = VocabEntry.fromJson(entry);
        if (parsed != null) vocab.add(parsed);
      }
    }
    final grammar = <GrammarPoint>[];
    if (grammarJson is Map && grammarJson['points'] is List) {
      for (final entry in grammarJson['points'] as List) {
        final parsed = GrammarPoint.fromJson(entry);
        if (parsed != null) grammar.add(parsed);
      }
    }
    return ContentCatalog(vocab: vocab, grammar: grammar);
  }

  /// Purpose: Look a vocabulary entry up by id.
  /// Inputs: `id`.
  /// Returns: `VocabEntry?`.
  /// Side effects: None.
  /// Notes: Linear; fine for the seed catalog, index it when JMdict lands.
  VocabEntry? vocabById(String id) {
    for (final entry in vocab) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  /// Purpose: Look a grammar point up by id.
  /// Inputs: `id`.
  /// Returns: `GrammarPoint?`.
  /// Side effects: None.
  /// Notes: Linear; see [vocabById].
  GrammarPoint? grammarById(String id) {
    for (final point in grammar) {
      if (point.id == id) return point;
    }
    return null;
  }
}
