# lib/features/ai/services/response_parser.dart

Decides whether what the model returned is worth showing, and cleans it up if it is.

A small model asked for four plain sentences will sometimes answer with a heading, a bulleted list, a
code fence, the prompt back, or nothing. Everything here is pure and unit-tested, which is the point
of keeping it out of the widget and out of the platform channel.

Consumers: `aicore_sentence_enhancer.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `ResponseParser` | class | B | The cleanup rules. |
| `maxExplanationChars` | constant | B | How long a shown explanation may be. |
| [`explanation`](#explanation) | static method | A | Turn a raw completion into a paragraph, or null. |
| [`correction`](#correction) | static method | A | Pick the one correction worth offering. |
| `_stripFences` | static method | B | Remove a code fence wrapping the whole answer. |
| `_stripLineMarkup` | static method | B | Strip bullets, numbering, headings and emphasis. |
| `_isEcho` | static method | B | Decide whether the answer is the prompt repeated. |
| `_capAtSentence` | static method | B | Cut long text at the last sentence end that fits. |
| `_normalize` | static method | B | Normalize text for comparison. |

## Documentation

### `static String? explanation(String raw, {String? prompt})` <a id="explanation"></a>

- **Kind:** static method
- **Purpose:** Turn a raw completion into something worth putting on the page.
- **Inputs:** `raw`, and the `prompt` it answered.
- **Returns:** `String?` — null when there is nothing usable.
- **Side effects:** None.
- **Algorithm:** Trim, unwrap a fence, strip per-line markup, collapse blank runs, reject an echo,
  cap at a sentence boundary.
- **Usage:** `AiCoreSentenceEnhancer.explain`.
- **Notes:** The echo rejection is the load-bearing part. A model that answers with the learner's own
  sentence has not answered, and showing that back **labelled as an explanation** teaches nothing and
  costs trust. Markup is stripped rather than rendered because the card draws plain text, so a stray
  asterisk would be shown as an asterisk. Emphasis is removed with `replaceAllMapped`, not
  `replaceAll` — Dart's string replacement does not expand `$1`, and the first version of this
  printed the literal `$1` until a test caught it.

### `static String? correction(List<String> suggestions, String original)` <a id="correction"></a>

- **Kind:** static method
- **Purpose:** Decide whether the proofreader actually suggested anything.
- **Inputs:** The model's `suggestions` and the `original` sentence.
- **Returns:** `String?` — null when none of them says anything new.
- **Side effects:** None.
- **Algorithm:** Return the first suggestion that differs from the input once whitespace is removed.
- **Usage:** `AiCoreSentenceEnhancer.suggestCorrection`.
- **Notes:** A proofreader handed a **correct** sentence answers with that sentence. Offering it as a
  correction would tell the learner their correct sentence was wrong, so it is dropped and the UI
  says nothing needed changing. Whitespace is removed rather than collapsed before comparing, because
  Japanese is written without it and a model may add or remove spaces freely — a suggestion differing
  only in spacing is not a correction either. Confirmed on the device: this is exactly what the
  Proofreading API returned for a well-formed sentence.
