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
| `forWriting` | method | B | Ask for a rewrite of what the learner wrote. |
| `forGrading` | method | B | Ask whether a free answer means the same as the model one. |
| `forWhyWrong` | method | B | Ask why the chosen option is wrong. |
| `forExamples` | method | B | Ask for example sentences using one word. |
| [`forQuizCheck`](#forquizcheck) | method | A | Ask the model to answer a generated question and judge it. |
| `forQuiz` | method | B | Ask for one extra multiple-choice question about a unit. |
| `_build` | method | B | Assemble one prompt from a task, its labels and a body. |

## Documentation

### `String? forQuizCheck({required String question, required List<String> options, required Locale locale})` <a id="forquizcheck"></a>

- **Kind:** method
- **Purpose:** Ask the model to answer a generated question and to judge whether it stands.
- **Inputs:** The `question` as it would be shown, its four `options`, and the `locale`.
- **Returns:** `String?` — null when the question is empty, when there are not exactly four options,
  or when any option is blank.
- **Side effects:** None.
- **Algorithm:** Writes the question, then the four options labelled A to D, and asks for a letter on
  the first line and `SOUND` or `UNSOUND` on the second.
- **Usage:** `AiQuestionGenerator._survivesReview`, once per candidate question.
- **Notes:** **The proposed answer is deliberately not in the prompt.** A model shown an answer and
  asked whether it is right agrees; a model asked to work the question out produces something that
  can disagree, and only the second is a check. The caller compares the two letters itself and keeps
  the question only when they match and the verdict is `SOUND`.
