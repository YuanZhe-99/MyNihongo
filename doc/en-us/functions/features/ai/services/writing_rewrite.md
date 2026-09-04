# lib/features/ai/services/writing_rewrite.dart

The rewrite writing practice offers on a device whose only on-device model is the proofreader.

The two GenAI features have separate device lists and the Prompt API's is the narrower one, so a
device can have proofreading and not explanations — most non-Pixel hardware, the Galaxy Z Fold 8
included. Before `v0.3.2` the writing page asked the Prompt API for a rewrite plus notes and hid the
button when that was unavailable, so a working model sat unused. The notes need the Prompt API; the
rewrite itself is exactly what a proofreader answers.

Consumers: `writing_practice_page.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | A rewrite from the proofreader alone. |
| [`proofreadSentences`](#proofreadsentences) | top-level function | A | Proofread each analysed sentence and join what came back. |

## Documentation

### `Future<String?> proofreadSentences(SentenceEnhancer enhancer, List<SentenceAnalysis> analyses)` <a id="proofreadsentences"></a>

- **Kind:** top-level function
- **Purpose:** Offer a rewrite of a whole piece of writing using the proofreading model.
- **Inputs:** The `enhancer`, and the `analyses` in the order they were written.
- **Returns:** `Future<String?>` — the rewritten text, or null when the model suggested nothing
  different for any sentence.
- **Side effects:** One inference per sentence, in sequence.
- **Algorithm:** Ask `suggestCorrection` for each analysis in turn. A non-blank suggestion replaces
  the sentence and marks the result changed; anything else carries the learner's own normalized
  sentence through. Join, and return null when nothing changed.
- **Usage:** `_askProofreader` on the writing page, when `canProofread` holds and `canExplain` does
  not.
- **Notes:** **Sequential on purpose.** AICore serves one inference at a time per app and
  `AiAssistService` refuses a second with `busy`, so firing them off together would fail every
  sentence after the first; a test asserts the peak concurrency is one. Carrying an unchanged
  sentence through is what makes the result read as a whole piece of writing rather than as a list of
  the parts that changed. Returning null when *nothing* changed is the same rule
  `ResponseParser.correction` follows one sentence at a time: offering a learner their own correct
  writing back as a correction tells them it was wrong. A `GenAiException` is allowed through so the
  page can word the reason.
