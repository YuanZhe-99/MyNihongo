# lib/features/ai/services/practice_prompt_builder.dart

Builds the prompts for the practice features: writing feedback, grading a free answer, why an answer
was wrong, extra example sentences, an extra quiz question, and the second opinion on one.

Every prompt is grounded in something the app already computed or already shows — the learner's own
text, the catalog's own explanation, the question exactly as it was worded on screen. That is what
keeps a generated answer consistent with the rest of the app, and it is why the model is never asked
an open question about Japanese.

The templates come from `assets/content/prompts/practice.json`, so the wording, the caps and the
rules are content rather than code. Every method returns null when its template is missing or the
grounding is unusable, so a build whose asset failed to load offers no AI actions rather than sending
the model an empty instruction.

Consumers: `generated_examples.dart`, `why_wrong.dart`, `quiz_runner.dart`,
`writing_practice_page.dart`, `ai_question_generator.dart`.

`forExamples` asked for the labels `sentence` and `expected` until `v0.4.3`. Both exist, so nothing
fell back and nothing failed — the prompt simply announced a single word as "Sentence:" and its gloss
as "The model answer:", and then asked for sentences. Nothing tested the asset for completeness
either; `ai_practice_test` now checks that every task is written in all three languages and that
every label a builder indexes is defined.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `practicePromptAsset` | constant | B | Where the practice templates live. |
| `PracticePromptBuilder` | class | B | Builds the practice prompts. |
| `PracticePromptBuilder.new` | constructor | B | Build prompts from a set of templates. |
| `templates` | field | B | The parsed templates. |
| `maxOutputTokens` | getter | B | How long an answer to any of these prompts may be. |
| `maxQuizQuestions` | getter | B | How many generated questions one session may be offered. |
| `forWriting` | method | B | Ask for a rewrite of what the learner wrote. |
| `forGrading` | method | B | Ask whether a free answer means the same as the model one. |
| `forWhyWrong` | method | B | Ask why the chosen option is wrong. |
| `forExamples` | method | B | Ask for example sentences using one word. |
| [`forQuizCheck`](#forquizcheck) | method | A | Ask the model to answer a generated question, judge it, and rate every option. |
| `forQuiz` | method | B | Ask for one extra multiple-choice question about a unit, grounded in everything the app knows about the point. |
| `forRubric` | method | B | Ask for a note on what to try next, given what the checklist found. |
| `forParaphrase` | method | B | Ask for one hard sentence said again in easier Japanese. |
| `forContradiction` | method | B | Ask which part of a passage rules the learner's choice out. |
| `forListeningReview` | method | B | Ask which spoken line carried the answer, and what is easy to mishear in it. |
| `forWeakness` | method | B | Ask what to do about what the learner keeps getting wrong. |
| `forScenarioReply` | method | B | Ask the model to answer in character once a scenario’s script has run out. |
| `_build` | method | B | Assemble one prompt from a task, its labels and a body. |

## Documentation

### `String? forQuizCheck({required GrammarPoint point, required String question, required List<String> options, required Locale locale})` <a id="forquizcheck"></a>

- **Kind:** method
- **Purpose:** Ask the model to answer a generated question, judge whether it stands, and rate every
  option.
- **Inputs:** The grammar `point` the question claims to test, the `question` as it would be shown,
  its four `options`, and the `locale`.
- **Returns:** `String?` — null when the question is empty, when there are not exactly four options,
  or when any option is blank.
- **Side effects:** None.
- **Algorithm:** Writes the point and its meaning, then the question, then the four options labelled
  A to D, and asks for a letter on the first line, `SOUND` or `UNSOUND` on the second, and a `FITS`
  or `NO` for each of A to D after that.
- **Usage:** `AiQuestionGenerator._survivesReview`, once per candidate question.
- **Notes:** **The proposed answer is deliberately not in the prompt.** A model shown an answer and
  asked whether it is right agrees; a model asked to work the question out produces something that
  can disagree, and only the second is a check. The caller compares the two letters itself and keeps
  the question only when they match, the verdict is `SOUND`, and exactly one option fits.

  The point is named because the judge is asked two different things: which option expresses *this*
  point, and which options make a correct sentence at all. 「今日は暑い＿＿。」 offering both ね and
  です is a bad question that a judge asked only for its own answer passes, because its own answer is
  right.
The five tasks added for the JLPT features share one rule with everything above them: **the prompt
carries what the app already computed, and the task's rules forbid the model from computing it
again.** `forRubric` hands over the deterministic checklist's findings and forbids re-scoring;
`forWeakness` hands over the counts the weakness report produced and forbids estimating whether the
learner would pass, because the readiness band is derived under stated rules and a guessed one beside
it would be a second, unexplainable answer to the same question. `forContradiction` forbids bringing
in anything outside the passage, since a reading question is a question about one text and an answer
justified from general knowledge would teach the wrong skill even when it happened to be true. And
`forListeningReview` is only ever built after the question has been answered, because the transcript
is the answer to a listening question.

`forScenarioReply` is the one prompt that grows with use, so it is the one that truncates. The script
is cut from its oldest end, whole lines at a time, and only the last `maxScenarioTurnsInPrompt` free
turns are sent: a conversation has no natural length, and what a reply needs is the situation and
what was just said. Cutting a line in half would leave the model reading a fragment as if it were
speech. Its rules forbid correcting the learner — correcting is the proofreader's job, and it has
already run on the learner's own line before this is asked.
