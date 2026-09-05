# lib/features/quiz/services/ai_question_generator.dart

Asks the on-device model for extra questions about a unit, and refuses most of what it might say.

Everything here is written so that a bad answer costs nothing. A generated question is
`QuizQuestion.generated`, which keeps it out of the SM-2 scheduler; it is asked for **after** the
session is already on screen, so waiting on a model never delays the first question; and every
reply is checked against the rules in `parse` before it becomes a question at all. A reply that
fails any of them is dropped in silence, because the session is complete without it.

Consumers: `quiz_page.dart`.

**Every question is asked twice.** The first call writes it; the second hands it
back *without* its proposed answer and asks the model to work it out and to say
whether the question stands. It is kept only when the model reaches the same
option and calls it sound. A model shown an answer and asked to approve it
agrees, so the second pass deliberately does not see the first pass's answer:
two derivations that must match is a check, and a rubber stamp is not. Silence
drops the question, like every other refusal here.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `maxGeneratedQuestions` | constant | B | How many generated questions one session may receive (3). |
| `AiQuestionGenerator` | class | B | Ask for extra questions about a unit. |
| `AiQuestionGenerator.new` | constructor | B | Hold the unit, catalog, prompt builder, locale and service. |
| [`generate`](#generate) | method | A | Yield accepted questions as they arrive. |
| `_words` | getter | B | The unit's words, for grounding the prompt. |
| [`parse`](#parse) | static method | A | Turn one model reply into a question, or refuse it. |
| `accepts` | static method | B | Whether a judged question may be shown: same answer, called sound. |
| `_survivesReview` | method | B | Ask the model to answer its own question, and judge it. |
| `_after` | static method | B | Take what follows a label on a line. |

## Documentation

### `Stream<QuizQuestion> generate({int limit, Set<String> avoid})` <a id="generate"></a>

- **Kind:** method
- **Purpose:** Generate questions one at a time, as they arrive.
- **Inputs:** `limit` — how many to ask for; `avoid` — prompts the session already has.
- **Returns:** A stream of accepted questions.
- **Side effects:** Runs a model on the device, once per grammar point tried.
- **Algorithm:** Walk the unit's grammar points in order. For each, build a prompt, run it through
  `AiPracticeService.runInBackground` (which yields to any interactive request and retries later),
  parse the reply, and yield it if it parses and its prompt is new. Stop at `limit`.
- **Usage:** `quiz_page._generate`, started with `unawaited` right after the session is built.
- **Notes:** A stream rather than a list because each question is useful the moment it exists: the
  session appends it, and the learner may reach it while the next one is still being written. The
  `avoid` set is seeded from the questions already drawn, so a generated question never repeats one
  the bank produced deterministically.

### `static QuizQuestion? parse(String raw, {required GrammarPoint point})` <a id="parse"></a>

- **Kind:** static method
- **Purpose:** Turn one model reply into a question, or refuse it.
- **Inputs:** The `raw` reply and the `point` it was asked about.
- **Returns:** `QuizQuestion?` — null whenever anything is off.
- **Side effects:** None.
- **Algorithm:** Scan the lines for `Q:`, `A:`–`D:`, `Answer:` and `Why:`, either colon. Then five
  rejections, each guarding a specific failure:

  | Rejected when | Because |
  |---|---|
  | No `Q:` line, or it is empty | The model answered in prose |
  | The sentence has no `＿` or `_` | Nothing is being asked |
  | Fewer or more than four options | Not a four-choice question |
  | Any option is empty | An option would render blank |
  | Two options are identical | Two right answers |
  | `Answer:` names no option | The reply contradicts itself |

- **Usage:** `generate`; tested directly in `ai_question_generator_test.dart`.
- **Notes:** None of those can be repaired by guessing, and **a guessed question is worse than no
  question**, because on screen it looks exactly as authoritative as an authored one. The label the
  runner shows above a generated question is the other half of that: see
  [`ai-assist.md`](../../../../features/ai-assist.md).
