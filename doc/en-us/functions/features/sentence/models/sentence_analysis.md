# lib/features/sentence/models/sentence_analysis.dart

Everything the analyser produces: the chunks, the grammar matches, the issues, the analysis object
that holds them, and the seam an on-device model would attach to.

Consumers: `sentence_analyzer.dart`, `chunker.dart`, `sentence_checks.dart`, and the four widgets
under `features/sentence/widgets/`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `Bunsetsu` | class | B | A content word plus whatever attached to it, and what it attaches to. |
| `GrammarMatch` | class | B | A taught grammar point found in the sentence, with its token span. |
| `GrammarMatch.span` | getter | B | How many tokens the match covers, for resolving overlaps. |
| `IssueKind` | enum | B | The five kinds of problem the checks can raise. |
| `Issue` | class | B | One possible issue, located in the sentence, with an optional suggestion. |
| `SentenceAnalysis` | class | B | The whole result of analysing one sentence. |
| `SentenceAnalysis.hasUnknown` | getter | B | Whether anything at all could not be read. |
| [`toFixtureString`](#tofixturestring) | method | A | Render the analysis as one line, for fixture comparison. |
| [`SentenceEnhancer`](#enhancer) | abstract class | A | The seam an on-device model would plug into. |
| `SentenceEnhancer.isAvailable` | method | B | Report whether an on-device model is present and enabled. |
| `SentenceEnhancer.explain` | method | B | Explain one issue, or the sentence, in more words, in the UI language. |
| `SentenceEnhancer.suggestCorrection` | method | B | Offer a corrected version of the whole sentence. |

## Documentation

### `String toFixtureString()` <a id="tofixturestring"></a>

- **Kind:** method
- **Purpose:** Put a whole analysis on one line, so a change to it shows up in a diff.
- **Inputs:** None.
- **Returns:** Four fields separated by ` | `: tokens, chunk dependencies, grammar ids, issue kinds.
- **Side effects:** None.
- **Algorithm:** Each field is joined from the corresponding list; an empty grammar or issue list is
  a single dash.
- **Usage:** `test/sentence_analyzer_test.dart`.
- **Notes:** Deliberately readable rather than compact. A fixture is authored by recording it and
  reading the diff, so a wrong parse has to be visible at a glance — a hash or a JSON blob would
  make a regression as easy to approve as to notice.

### `abstract class SentenceEnhancer` <a id="enhancer"></a>

- **Kind:** abstract class
- **Purpose:** Declare what an optional on-device model would be allowed to do.
- **Inputs:** —
- **Returns:** —
- **Side effects:** An implementation would run a model on the device.
- **Algorithm:** —
- **Usage:** `SentenceAnalyzer.enhancer`, which is null in every build today.
- **Notes:** `PLAN.md` M2.3 keeps AICore / Gemini Nano as an enhancement that never becomes the
  source of truth. Nothing implements this. It exists so the shape is settled before the pressure to
  add one exists, and so the analyser has somewhere to put it that is **not** the middle of the
  pipeline: every stage above it stays deterministic and testable whether a model is present or not.
