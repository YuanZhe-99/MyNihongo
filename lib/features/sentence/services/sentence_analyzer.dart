import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/models/content_catalog.dart';
import '../../content/services/content_repository.dart';
import '../models/function_word.dart';
import '../models/sentence_analysis.dart';
import 'chunker.dart';
import 'grammar_matcher.dart';
import 'lexicon.dart';
import 'sentence_checks.dart';
import 'tokenizer.dart';

/// Runs the whole sentence pipeline.
///
/// Tokenize → chunk → match grammar → check. Every stage is deterministic,
/// offline and separately tested; this only holds them together and is where
/// an optional on-device model would attach, without any stage depending on
/// one. See `doc/en-us/algorithms/sentence-analysis.md`.
class SentenceAnalyzer {
  SentenceAnalyzer({
    required Lexicon lexicon,
    required ContentCatalog catalog,
    this.enhancer,
  }) : _tokenizer = Tokenizer(lexicon),
       _grammar = GrammarMatcher(catalog),
       _checks = SentenceChecks(lexicon.functionWordTable);

  final Tokenizer _tokenizer;
  final GrammarMatcher _grammar;
  final SentenceChecks _checks;
  static const _chunker = Chunker();

  /// An optional on-device model. Null in every build today; see
  /// [SentenceEnhancer] for why the seam exists before the implementation.
  final SentenceEnhancer? enhancer;

  /// Purpose: Analyse one sentence.
  /// Inputs: `text` as the learner typed it.
  /// Returns: `SentenceAnalysis`.
  /// Side effects: None.
  /// Notes: Synchronous, and fast enough to run on every keystroke after the
  /// lexicon is built — a sentence is tens of characters and the lattice is
  /// linear in that with a bounded number of edges per position. The lexicon
  /// build is the expensive part, and it happens once per app run.
  SentenceAnalysis analyze(String text) {
    final normalized = Tokenizer.normalize(text);
    final tokens = _tokenizer.tokenize(normalized);
    final chunks = _chunker.chunk(tokens);
    return SentenceAnalysis(
      input: text,
      normalized: normalized,
      tokens: tokens,
      chunks: chunks,
      grammar: _grammar.match(tokens),
      issues: _checks.run(tokens, chunks),
    );
  }
}

/// The function-word table, loaded once per app run.
///
/// Separate from the catalog provider because it is a few kilobytes and only
/// the sentence lab needs it; loading it with the 2 MB catalog would make every
/// page pay for a page that may never be opened.
final functionWordsProvider = FutureProvider<FunctionWordTable>(
  (ref) => loadFunctionWords(),
);

/// The surface-to-entry index, built once from the catalog and the table.
///
/// Depends on both, so it rebuilds if either is reloaded and never holds a
/// stale half. Building it is tens of milliseconds over 7,700 entries, which is
/// why it is a provider and not something the page does in `initState`.
final lexiconProvider = FutureProvider<Lexicon>((ref) async {
  final catalog = await ref.watch(contentCatalogProvider.future);
  final words = await ref.watch(functionWordsProvider.future);
  return Lexicon.build(catalog, functionWords: words);
});

/// The analyser itself, ready to use.
final sentenceAnalyzerProvider = FutureProvider<SentenceAnalyzer>((ref) async {
  final lexicon = await ref.watch(lexiconProvider.future);
  final catalog = await ref.watch(contentCatalogProvider.future);
  return SentenceAnalyzer(lexicon: lexicon, catalog: catalog);
});
