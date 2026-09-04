# lib/features/quiz/services/question_bank.dart

Every question one unit can ask, and a weighted draw from them.

The level-wide quiz shuffles a level's items and takes twenty, which makes a mode as likely as its
items happen to be common. A unit is small enough to build the pool whole and then choose from it,
and that is the difference.

Consumers: `quiz_page.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `QuestionBank` | class | B | A unit's questions. |
| `QuestionBank.isEmpty` | getter | B | Whether the unit produced nothing. |
| [`QuestionBank.build`](#build) | method | A | Build every question a unit can ask. |
| `QuestionBank._authored` | method | B | Turn a hand-written question into a quiz question. |
| [`QuestionBank.draw`](#draw) | method | A | Draw a session's worth from the pool. |

## Documentation

### `static QuestionBank build({...})` <a id="build"></a>

- **Kind:** method
- **Purpose:** Build every question one unit can ask.
- **Inputs:** The `unit`, the `catalog`, a `generator`, the enabled `modes`, and the `locale`.
- **Returns:** `QuestionBank`.
- **Side effects:** None.
- **Algorithm:** Three sources, in order — the unit's catalog items in every enabled mode, its own
  sentences run through the grammar modes, and the questions written for it — deduplicated by item,
  mode and prompt.
- **Usage:** `quiz_page.dart`, for a `UnitSource`.
- **Notes:** Duplicates are dropped because the same sentence can reach the pool from two
  directions — as a catalog example and as a unit sentence — and would then be asked twice in one
  session. A hand-written question is the only kind carrying an explanation.

### `List<QuizQuestion> draw(int count, {...})` <a id="draw"></a>

- **Kind:** method
- **Purpose:** Draw a session's worth of questions.
- **Inputs:** How many, the learner's `progress`, and a `random` so a draw can be reproduced.
- **Returns:** `List<QuizQuestion>`.
- **Side effects:** None.
- **Algorithm:** Weighted sampling over items — no record weighs three, never right weighs two,
  everything else one, and a hand-written question doubles it — taking one question per item until
  the count is reached or the items run out.
- **Usage:** `quiz_page.dart`.
- **Notes:** **At most one question per item.** Twelve questions should be twelve different things
  rather than one word asked six ways, and that constraint is what makes the weighting meaningful
  rather than a way of asking the hardest word repeatedly. The `random` parameter exists so a
  failing session can be reproduced in a test.
