import '../../content/models/content_catalog.dart';
import '../../sentence/models/sentence_analysis.dart';
import 'ai_assist_service.dart';
import 'genai_backend.dart';
import 'prompt_builder.dart';
import 'response_parser.dart';

/// Fills the [SentenceEnhancer] seam with Android AICore.
///
/// It is the only place the three halves meet: [PromptBuilder] turns the
/// deterministic analysis into a prompt, [AiAssistService] decides whether the
/// device may run it, and [ResponseParser] decides whether what came back is
/// worth showing. Keeping the pipeline's stages ignorant of all three is the
/// point of the seam — nothing above this file changes when a device has no
/// model.
class AiCoreSentenceEnhancer implements SentenceEnhancer {
  const AiCoreSentenceEnhancer({
    required this.service,
    required this.prompts,
    required this.catalog,
  });

  /// The service that owns the enabled switch and the model statuses.
  final AiAssistService service;

  /// The prompt templates, already loaded.
  final PromptBuilder prompts;

  /// The catalog, for the grammar explanations a prompt is grounded in.
  final ContentCatalog? catalog;

  /// Purpose: Report whether an explanation can be generated right now.
  /// Inputs: None.
  /// Returns: `Future<bool>`.
  /// Side effects: None — reads the service's last known state.
  /// Notes: Synchronous underneath on purpose. The real capability check runs
  /// inside every generating call, so this only decides whether to *offer* the
  /// action, and a build must not await a platform call.
  @override
  Future<bool> isAvailable() async => service.canExplain;

  /// Purpose: Explain one issue, or the whole sentence.
  /// Inputs: The `analysis`, the `issue` and its `issueMessage` when the
  /// request is about one, and the UI `languageCode`.
  /// Returns: `Future<String?>` — null when nothing usable came back.
  /// Side effects: Runs Gemini Nano on the device.
  /// Notes: A [GenAiException] is allowed through so the UI can word the
  /// reason; null means the model answered with nothing worth showing, which
  /// is a different thing and reads differently on screen.
  @override
  Future<String?> explain(
    SentenceAnalysis analysis,
    Issue? issue,
    String? issueMessage,
    String languageCode,
  ) async {
    final prompt = issue != null && issueMessage != null
        ? prompts.forIssue(analysis, issue, issueMessage, catalog, languageCode)
        : prompts.forSentence(analysis, catalog, languageCode);
    if (prompt == null) return null;
    final raw = await service.explain(prompt);
    return ResponseParser.explanation(raw, prompt: prompt);
  }

  /// Purpose: Offer a corrected version of the sentence.
  /// Inputs: The `analysis`.
  /// Returns: `Future<String?>` — null when the model suggested nothing new.
  /// Side effects: Runs the proofreading model on the device.
  /// Notes: The sentence sent is the **normalized** one, which is what the
  /// token offsets and the whole page refer to; sending the raw input would
  /// make a suggestion that does not line up with the analysis above it.
  @override
  Future<String?> suggestCorrection(SentenceAnalysis analysis) async {
    final text = prompts.forProofreading(analysis.normalized);
    if (text == null) throw const GenAiException(GenAiFailure.tooLong);
    final suggestions = await service.proofread(text);
    return ResponseParser.correction(suggestions, text);
  }
}
