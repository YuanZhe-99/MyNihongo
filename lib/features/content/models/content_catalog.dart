/// Purpose: Hold everything the bundled content files describe, parsed once.
/// Inputs: The decoded vocabulary, grammar and kana-note files.
/// Returns: A catalog with constant-time lookups.
/// Side effects: None.
/// Notes: The catalog grew from 24 words to roughly 8,300 in `PLAN.md` M1.2,
/// so the lookups are maps built once at construction rather than the linear
/// scans the seed could afford. Grammar arrives as one file per level, so the
/// factory takes an iterable.
library;

import '../../kana/models/kana_note.dart';
import 'grammar_point.dart';
import 'vocab_entry.dart';

/// Everything the bundled content files describe, parsed once.
class ContentCatalog {
  /// Vocabulary in file order: by level, then reading.
  final List<VocabEntry> vocab;

  /// Grammar points in file order, level files concatenated easiest first.
  final List<GrammarPoint> grammar;

  /// Teaching notes for the kana that have one, keyed by `kana:` id.
  final Map<String, KanaNote> kanaNotes;

  final Map<String, VocabEntry> _vocabById;
  final Map<String, GrammarPoint> _grammarById;

  /// Purpose: Create a content catalog instance.
  /// Inputs: `vocab`, `grammar`, `kanaNotes`.
  /// Returns: A new `ContentCatalog` instance.
  /// Side effects: Builds the id lookups, including one entry per alias.
  /// Notes: An alias maps to the same entry object as the primary id, so a
  /// caller cannot tell which id it arrived by — which is the point.
  ContentCatalog({
    this.vocab = const [],
    this.grammar = const [],
    this.kanaNotes = const {},
  }) : _vocabById = {
         for (final entry in vocab) ...{
           entry.id: entry,
           for (final alias in entry.aliases) alias: entry,
         },
       },
       _grammarById = {for (final point in grammar) point.id: point};

  /// Purpose: Parse the content files.
  /// Inputs: `vocabJson` — the decoded vocabulary file; `grammarJsons` — the
  /// decoded per-level grammar files, easiest first; `kanaNotesJson` — the
  /// decoded kana notes file. Any may be null.
  /// Returns: `ContentCatalog`.
  /// Side effects: None.
  /// Notes: Malformed entries are skipped, not fatal; see the model parsers.
  /// Bundled content is a build input, so a bad entry is caught by
  /// `content_catalog_test.dart` before it ships, and a partial catalog is
  /// better than a blank app if one ever slips through.
  factory ContentCatalog.fromJson(
    Object? vocabJson,
    Iterable<Object?> grammarJsons, [
    Object? kanaNotesJson,
  ]) {
    final vocab = <VocabEntry>[];
    if (vocabJson is Map && vocabJson['entries'] is List) {
      for (final entry in vocabJson['entries'] as List) {
        final parsed = VocabEntry.fromJson(entry);
        if (parsed != null) vocab.add(parsed);
      }
    }
    final grammar = <GrammarPoint>[];
    for (final grammarJson in grammarJsons) {
      if (grammarJson is Map && grammarJson['points'] is List) {
        for (final entry in grammarJson['points'] as List) {
          final parsed = GrammarPoint.fromJson(entry);
          if (parsed != null) grammar.add(parsed);
        }
      }
    }
    return ContentCatalog(
      vocab: vocab,
      grammar: grammar,
      kanaNotes: KanaNote.mapFromJson(kanaNotesJson),
    );
  }

  /// Purpose: Look a vocabulary entry up by id.
  /// Inputs: `id` — a primary id or any alias.
  /// Returns: `VocabEntry?`.
  /// Side effects: None.
  /// Notes: Constant time.
  VocabEntry? vocabById(String id) => _vocabById[id];

  /// Purpose: Look a grammar point up by id.
  /// Inputs: `id`.
  /// Returns: `GrammarPoint?`.
  /// Side effects: None.
  /// Notes: Constant time. Grammar has no aliases yet; when one is retired it
  /// gains them the same way vocabulary did.
  GrammarPoint? grammarById(String id) => _grammarById[id];

  /// Purpose: Resolve any id to the one the catalog ships it under.
  /// Inputs: `id`.
  /// Returns: `String` — the primary id, or `id` itself when nothing matches.
  /// Side effects: None.
  /// Notes: Progress records keep whichever id they were written with, so this
  /// is for grouping and display, never for rewriting stored data.
  String canonicalId(String id) =>
      _vocabById[id]?.id ?? _grammarById[id]?.id ?? id;

  /// Purpose: List every vocabulary id the catalog answers to.
  /// Inputs: None.
  /// Returns: `Iterable<String>` — primaries and aliases.
  /// Side effects: None.
  /// Notes: Used by the uniqueness test, which has to see aliases too.
  Iterable<String> get allVocabIds => _vocabById.keys;
}
