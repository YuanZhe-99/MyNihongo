/// Purpose: Offer a rewrite of a piece of writing on a device whose only
/// on-device model is the proofreader.
/// Inputs: A [SentenceEnhancer] and the sentences the deterministic pass
/// already analysed.
/// Returns: The suggestions, joined, or null when nothing differed.
/// Side effects: Runs the proofreading model on the device, once per sentence.
/// Notes: This exists because the two on-device features have separate device
/// lists and the Prompt API's is the narrower one. Writing practice asked the
/// Prompt API for a rewrite plus notes, so on a device with proofreading only —
/// which is most non-Pixel hardware — the button was hidden and a model that
/// works sat unused. The notes are the part that needs the Prompt API; the
/// rewrite itself is exactly what a proofreader answers.
library;

import '../../sentence/models/sentence_analysis.dart';

/// Purpose: Proofread each analysed sentence and join what came back.
/// Inputs: The `enhancer` and the `analyses`, in the order they were written.
/// Returns: `Future<String?>` — the rewritten text, or null when the model
/// suggested nothing different for any sentence.
/// Side effects: One inference per sentence, in sequence.
/// Notes: **Sequential on purpose.** AICore serves one inference at a time per
/// app, and `AiAssistService` refuses a second with `busy`; firing them off
/// together would fail every sentence after the first. A sentence the model
/// left alone is carried through as the learner wrote it, so the result reads
/// as a whole piece of writing rather than as a list of the parts that changed
/// — and returning null when *nothing* changed is what stops the app telling a
/// learner their correct writing was wrong.
Future<String?> proofreadSentences(
  SentenceEnhancer enhancer,
  List<SentenceAnalysis> analyses,
) async {
  if (analyses.isEmpty) return null;
  final out = <String>[];
  var changed = false;
  for (final analysis in analyses) {
    final suggestion = await enhancer.suggestCorrection(analysis);
    if (suggestion != null && suggestion.trim().isNotEmpty) {
      changed = true;
      out.add(suggestion.trim());
    } else {
      out.add(analysis.normalized);
    }
  }
  return changed ? out.join() : null;
}
