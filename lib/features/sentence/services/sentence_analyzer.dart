import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai/services/ai_assist_service.dart';
import '../../ai/services/aicore_sentence_enhancer.dart';
import '../../ai/services/practice_prompt_builder.dart';
import '../../ai/services/prompt_builder.dart';
import '../../../shared/utils/platform_capabilities.dart';
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
    required this.lexicon,
    required ContentCatalog catalog,
    this.enhancer,
  }) : _tokenizer = Tokenizer(lexicon),
       _grammar = GrammarMatcher(catalog),
       _checks = SentenceChecks(lexicon.functionWordTable);

  /// The surface-to-entry index this analyser parses with.
  ///
  /// Exposed so the quiz can ask how a word conjugates using the same index
  /// the parser used. Two lexicons would eventually disagree, and a quiz that
  /// graded against a different one would mark correct Japanese wrong.
  final Lexicon lexicon;

  final Tokenizer _tokenizer;
  final GrammarMatcher _grammar;
  final SentenceChecks _checks;
  static const _chunker = Chunker();

  /// An optional on-device model.
  ///
  /// Null wherever one cannot run — every platform but Android, and any build
  /// whose prompt templates failed to load. Non-null does **not** mean a model
  /// will answer: the service behind it refuses every call while the learner
  /// has the feature switched off. Nothing in the pipeline above reads this;
  /// see [SentenceEnhancer].
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

/// The prompt templates the optional on-device model is driven by.
///
/// A separate provider from the catalog for the same reason the function-word
/// table is one: a few kilobytes that only one page needs.
/// The practice tasks' templates, loaded on demand.
///
/// A separate asset and a separate provider from the sentence lab's, because
/// the two are edited for different reasons and a build that never opens a
/// practice screen should not parse them.
final practicePromptTemplatesProvider = FutureProvider<PromptTemplates>(
  (ref) => loadPromptTemplates(null, practicePromptAsset),
);

/// Purpose: Get a prompt builder, waiting for the asset if it is still loading.
/// Inputs: `ref`.
/// Returns: `PracticePromptBuilder?` — null when the asset cannot be read.
/// Side effects: Starts the asset load if nothing has yet.
/// Notes: **Awaited, never read.** Reading `practicePromptTemplatesProvider`
/// for its `.value` returns null until the asset has finished loading, and
/// nothing on the way into a practice screen touches it first — so the first
/// AI action after launch silently did nothing, with no error anywhere, and
/// only a second attempt worked. Every caller goes through here.
Future<PracticePromptBuilder?> practicePromptBuilder(WidgetRef ref) async {
  try {
    return PracticePromptBuilder(
      await ref.read(practicePromptTemplatesProvider.future),
    );
  } catch (_) {
    return null;
  }
}

final promptTemplatesProvider = FutureProvider<PromptTemplates>(
  (ref) => loadPromptTemplates(),
);

/// The analyser itself, ready to use.
///
/// The enhancer is attached only where one could possibly run: a platform with
/// an on-device model, and templates that loaded. Every other build gets a null
/// enhancer and an analyser that behaves exactly as it did before M2.4, which
/// is what "optional enhancement" has to mean.
///
/// Whether the learner has actually turned the feature **on** is deliberately
/// not part of this condition. That state changes while the page is open, and
/// rebuilding the analyser — and with it the 7,700-entry lexicon — on a switch
/// flip would be a heavy way to hide two buttons. `AiAssistService` refuses
/// every call while the switch is off, so an attached enhancer is inert.
final sentenceAnalyzerProvider = FutureProvider<SentenceAnalyzer>((ref) async {
  final lexicon = await ref.watch(lexiconProvider.future);
  final catalog = await ref.watch(contentCatalogProvider.future);
  final templates = await ref.watch(promptTemplatesProvider.future);
  final enhancer = platformMayHaveOnDeviceModel && templates.schemaVersion > 0
      ? AiCoreSentenceEnhancer(
          service: ref.watch(aiAssistServiceProvider),
          prompts: PromptBuilder(templates),
          catalog: catalog,
        )
      : null;
  return SentenceAnalyzer(
    lexicon: lexicon,
    catalog: catalog,
    enhancer: enhancer,
  );
});
