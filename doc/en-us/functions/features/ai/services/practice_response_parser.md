# lib/features/ai/services/practice_response_parser.dart

Reads what the model wrote back, and refuses what it cannot read.

Every parser here returns null rather than a best guess. A model that ignored the format is a model
whose content cannot be trusted either, and the caller's fallback — the deterministic answer, or
nothing at all — is better than a half-parsed one.

Consumers: `why_wrong.dart`, `generated_examples.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `WritingFeedback` | class | B | A rewrite and what changed. |
| `GradeVerdict` | class | B | Whether a free answer meant the same. |
| `PracticeResponseParser` | class | B | The parsers. |
| `maxNotes` | constant | B | How many notes feedback may carry (3). |
| [`writing`](#writing) | method | A | Read a rewrite and its notes. |
| [`grade`](#grade) | method | A | Read a same-or-different verdict. |
| [`examples`](#examples) | method | A | Read generated example sentences. |
| `explanation` | method | B | Read a plain explanation, as the lab does. |
| `_after` | method | B | Take what follows a label. |

## Documentation

### `static WritingFeedback? writing(String raw)` <a id="writing"></a>

- **Kind:** method
- **Purpose:** Read a rewrite and its notes.
- **Inputs:** The model's reply.
- **Returns:** `WritingFeedback?` — null without a rewrite line.
- **Side effects:** None.
- **Algorithm:** The first `Rewrite:` line, then up to three `Note:` lines, matched
  case-insensitively and with either kind of colon.
- **Usage:** Writing practice.
- **Notes:** The rewrite is the only required part, because it is the only part a learner can act
  on directly. A model that produced ten notes has stopped following the instruction, and the first
  three are the ones it thought of first.

### `static GradeVerdict? grade(String raw)` <a id="grade"></a>

- **Kind:** method
- **Purpose:** Read a same-or-different verdict.
- **Inputs:** The model's reply.
- **Returns:** `GradeVerdict?` — null when the first line is neither word.
- **Side effects:** None.
- **Algorithm:** Strips everything but letters from the first line and requires SAME or DIFFERENT.
- **Usage:** Free-answer grading.
- **Notes:** A reply that hedges into a paragraph is refused, and the learner marks it themselves —
  which is what happens on a device with no model anyway. **The verdict is a suggestion:** what
  reaches the scheduler is the button the learner pressed.

### `static List<ContentExample> examples(String raw, {...})` <a id="examples"></a>

- **Kind:** method
- **Purpose:** Read generated example sentences.
- **Inputs:** The reply, the language its translations are in, and a limit.
- **Returns:** The examples that parsed; empty when none did.
- **Side effects:** None.
- **Algorithm:** Three fields per line separated by a vertical bar, half-width or full-width.
- **Usage:** The generated-examples block in a word's sheet.
- **Notes:** A line with any other number of fields is dropped rather than guessed at. A generated
  example is drawn beside the catalog's own, so a mangled one would look exactly as authoritative
  as a real one.
