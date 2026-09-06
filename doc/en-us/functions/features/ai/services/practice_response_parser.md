# lib/features/ai/services/practice_response_parser.dart

Reads what the model wrote back, and refuses what it cannot read.

Every parser here returns null rather than a best guess. A model that ignored the format is a model
whose content cannot be trusted either, and the caller's fallback — the deterministic answer, or
nothing at all — is better than a half-parsed one.

Consumers: `why_wrong.dart`, `generated_examples.dart`.

M4.0c added `quizCheck` and the `QuizVerdict` it returns: a generated question is
asked back to the model **without** its proposed answer, so the reply is a second
derivation rather than an approval. `_unwrap` lets an example line survive the

M4.8 added the option ratings to that verdict. The judge is now asked whether
each of the four options makes a correct sentence, whatever it then means, and
the caller keeps the question only when exactly one does and it is the answer:
a judge asked only for its own answer passes a question with two right answers,
because its own answer is one of them.
packaging a model puts around it — a code fence, a list marker, or the leading
and trailing bars of a Markdown table row. That packaging is why generated
examples returned nothing at all on a Pixel 10 while the model was answering
perfectly well.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `WritingFeedback` | class | B | A rewrite and what changed. |
| `GradeVerdict` | class | B | Whether a free answer meant the same. |
| `PracticeResponseParser` | class | B | The parsers. |
| `maxNotes` | constant | B | How many notes feedback may carry (3). |
| [`writing`](#writing) | method | A | Read a rewrite and its notes. |
| [`grade`](#grade) | method | A | Read a same-or-different verdict. |
| `QuizVerdict` | class | B | The model's own answer to a generated question, whether it calls it sound, and whether each option fits. |
| `quizCheck` | static method | B | Read a verdict on a generated question: a letter, a word, and a rating for every option. |
| `_unwrap` | static method | B | Strip the packaging a model puts around a line. |
| [`examples`](#examples) | method | A | Read generated example sentences. |
| `Paraphrase` | class | B | One hard sentence said again in easier Japanese. |
| `japanese`, `reading`, `meaning` | fields | B | The easier sentence, its kana and what it means. |
| `paraphrase` | static method | B | Read one sentence said again in easier Japanese; null without a Japanese line. |
| `ScenarioReply` | class | B | One turn spoken in character at the end of a scenario. |
| `japanese`, `meaning` | fields | B | What the other speaker said, and what it means. |
| `scenarioReply` | static method | B | Read one reply in character; null when there is no Japanese in it. |
| `_japanese` | static field | B | Kana or kanji, the test of whether a reply is in Japanese at all. |
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

`paraphrase` requires only its Japanese line, and its absence is a refusal rather than a shrug:
everything else on that card is optional decoration, but a paraphrase with no sentence in it has
nothing to show. The reading and the meaning are taken when they are there, so a model that gave two
lines out of three still helps.

The four narrative tasks — rubric, contradiction, listening review and weakness — have no parser of
their own. They go through `explanation`, which is the same cleaning the sentence lab does, because
a note about what to try next is an explanation like any other.

`scenarioReply` requires kana or kanji in the Japanese line, which is not pedantry: the failure it
catches is a model answering the **instruction** rather than the learner. "Japanese: I'm sorry, I
can't continue this conversation" is a well-formed line and is not a reply, and a sentence of English
in a Japanese conversation would read as the partner's answer. The translation is optional, because a
reply the learner cannot read is still the reply and dropping the turn over a missing gloss would
cost more than the gloss is worth.
