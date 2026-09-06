# lib/features/quiz/services/ai_question_generator.dart

Asks the on-device model for extra questions about a unit, and refuses most of what it might say.

Everything here is written so that a bad answer costs nothing. A generated question is
`QuizQuestion.generated`, which keeps it out of the SM-2 scheduler; it is asked for **after** the
session is already on screen, so waiting on a model never delays the first question; and every
reply is checked against the rules in `parse` before it becomes a question at all. A reply that
fails any of them is dropped in silence, because the session is complete without it.

Consumers: `quiz_page.dart`.

**Every question is read by the analyser first**, when one is available:
`passesParseFilter` puts the answer in the blank and requires a sentence that
parses and carries the point, and requires that no distractor carries it. That
costs nothing and it drops the sentence whose blank any noun could fill before a
second inference is spent on it.

**Every question is then asked twice.** The first call writes it; the second
hands it back *without* its proposed answer and asks the model to work it out, to
say whether the question stands, and to say of each option whether it makes a
correct sentence. It is kept only when the model reaches the same option, calls
it sound, and finds exactly one option that fits. A model shown an answer and
asked to approve it agrees, so the second pass deliberately does not see the
first pass's answer: two derivations that must match is a check, and a rubber
stamp is not. Asking about every option is the half that catches a question with
two right answers, which a judge asked only for its own answer always passes.
Silence drops the question, like every other refusal here.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `AiQuestionGenerator` | class | B | Ask for extra questions about a unit. |
| `AiQuestionGenerator.new` | constructor | B | Hold the unit, catalog, prompt builder, locale, service and analyser. |
| [`generate`](#generate) | method | A | Yield accepted questions as they arrive. |
| `_words` | getter | B | The unit's words, for grounding the prompt. |
| [`parse`](#parse) | static method | A | Turn one model reply into a question, or refuse it. |
| `accepts` | static method | B | Whether a judged question may be shown: same answer, called sound, exactly one option fitting and it the answer. |
| [`passesParseFilter`](#passesparsefilter) | static method | A | Check a question against the analyser before a model is asked again. |
| `_blank` | static field | B | The blank a generated question marks its slot with. |
| `_survivesReview` | method | B | Ask the model to answer its own question, judge it, and rate every option. |
| `_after` | static method | B | Take what follows a label on a line. |

## Documentation

### `Stream<QuizQuestion> generate({int? limit, Set<String> avoid})` <a id="generate"></a>

- **Kind:** method
- **Purpose:** Generate questions one at a time, as they arrive.
- **Inputs:** `limit` — how many to ask for, defaulting to the asset's `maxQuizQuestions`; `avoid` —
  prompts the session already has.
- **Returns:** A stream of accepted questions.
- **Side effects:** Runs a model on the device, once or twice per grammar point tried.
- **Algorithm:** Walk the unit's grammar points in order. For each, build a prompt, run it through
  `AiPracticeService.runInBackground` (which yields to any interactive request and retries later),
  parse the reply, drop it unless its prompt is new, put it through `passesParseFilter` when an
  analyser was supplied, then through the model judge, and yield what survives. Stop at `limit`.
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

### `static bool passesParseFilter(QuizQuestion question, {required GrammarPoint point, required SentenceAnalysis Function(String) analyze})` <a id="passesparsefilter"></a>

- **Kind:** static method
- **Purpose:** Check a generated question against the analyser before any model is asked about it
  again.
- **Inputs:** The parsed `question`, the `point` it claims to test, and `analyze` — the sentence
  analyser's own entry point.
- **Returns:** `bool` — whether it is worth a second model call.
- **Side effects:** None.
- **Algorithm:** Put each option in the blank in turn and read the result:

  | Rejected when | Because |
  |---|---|
  | The answer's sentence has an unknown token | The app could not explain that sentence afterwards either |
  | The answer's sentence does not match the point | A question filed under 〜ね with no 〜ね in it tests something else |
  | A distractor's sentence matches the point | That option is a second right answer |

  A point whose `effectiveMatchForms` is empty — every one-character particle, since a form that
  short would match nearly every sentence in the catalog — is undecidable here, so only the
  unknown-token test applies and the model judge rules on the rest. A distractor that fails to parse
  is fine: a wrong option is allowed to be nonsense, which is what makes it wrong.
- **Usage:** `generate`, when `analyze` was supplied; `quiz_page._generate` supplies it from
  `sentenceAnalyzerProvider` and passes null if that provider fails, so a session whose analyser
  will not load still gets questions, judged by the model alone as they were before this existed.
- **Notes:** Everything checked here is a fact the app already had, and it is checked first because
  it is free. The question this dropped on the device was 「わたし＿＿が学生です。」 with 私, 友達,
  先生 and 日本語 in the options: four nouns, a blank any of them fits, and a grammar point nowhere
  in the sentence.
