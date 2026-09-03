# lib/features/ai/services/aicore_sentence_enhancer.dart

Fills the `SentenceEnhancer` seam with Android AICore.

The only place the three halves meet: `PromptBuilder` turns the deterministic analysis into a prompt,
`AiAssistService` decides whether the device may run it, and `ResponseParser` decides whether what
came back is worth showing. Keeping the pipeline's stages ignorant of all three is the point of the
seam — nothing above this file changes when a device has no model.

Consumers: `sentence_analyzer.dart`, which attaches one to `SentenceAnalyzer.enhancer`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `AiCoreSentenceEnhancer` | class | B | The seam's one implementation. |
| [`isAvailable`](#isavailable) | method | A | Whether an explanation can be generated right now. |
| [`explain`](#explain) | method | A | Explain one issue, or the whole sentence. |
| [`suggestCorrection`](#suggestcorrection) | method | A | Offer a corrected version of the sentence. |

## Documentation

### `Future<bool> isAvailable()` <a id="isavailable"></a>

- **Kind:** method
- **Purpose:** Report whether the action is worth offering.
- **Inputs:** None.
- **Returns:** `Future<bool>`.
- **Side effects:** None — reads the service's last known state.
- **Algorithm:** Returns `service.canExplain`.
- **Usage:** The seam's contract; the lab reads the service directly.
- **Notes:** Synchronous underneath on purpose. The real capability check runs inside every
  generating call, so this only decides whether to *offer* the action — and a build method must not
  await a platform call to decide whether to draw a button.

### `Future<String?> explain(SentenceAnalysis, Issue?, String?, String languageCode)` <a id="explain"></a>

- **Kind:** method
- **Purpose:** Explain one issue, or the whole sentence.
- **Inputs:** The analysis, the issue and its already-worded message when the request is about one,
  and the UI language code.
- **Returns:** `Future<String?>` — null when nothing usable came back.
- **Side effects:** Runs Gemini Nano on the device.
- **Algorithm:** Build the prompt, run it, parse the answer.
- **Usage:** `SentenceLabPage`, for both the per-issue and whole-sentence actions.
- **Notes:** A `GenAiException` is allowed through so the UI can word the reason; **null means
  something different** — the model ran and said nothing worth showing. The two read differently on
  screen, and collapsing them would send a learner looking for a fault that is not there.

### `Future<String?> suggestCorrection(SentenceAnalysis analysis)` <a id="suggestcorrection"></a>

- **Kind:** method
- **Purpose:** Offer a corrected version of the sentence.
- **Inputs:** The analysis.
- **Returns:** `Future<String?>` — null when the model suggested nothing different.
- **Side effects:** Runs the proofreading model on the device.
- **Algorithm:** Prepare the sentence, refuse it if too long, run inference, pick a suggestion.
- **Usage:** `SentenceLabPage`.
- **Notes:** The sentence sent is the **normalized** one, which is what the token offsets and the
  whole page refer to; sending the raw input would produce a suggestion that does not line up with
  the analysis above it. A sentence over the length cap throws `tooLong` rather than being trimmed,
  so the learner is told, not quietly given a correction to a fragment.
