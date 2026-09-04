# lib/features/quiz/widgets/quiz_runner.dart

Runs one session on screen: the question, the answer controls, and the feedback
between them. Splits into two panes when the window is the right shape and stacks
otherwise; the gate is `canSplitLayout`, the same one every other split uses.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `QuizRunner` | class | B | Run one session on screen. |
| `_submit` | method | B | Submit the composed answer. |
| `_continue` | method | B | Move past the feedback to the next question. |
| `build` | method | B | Build the question and its answer controls, split or stacked. |
| [`_feedback`](#feedback) | method | A | Say whether the answer was right, and what it was. |
| `_QuestionPane` | class | B | The half of the screen that asks the question. |
| `_instruction` | method | B | Say in words what the learner is being asked to do. |
| `QuizModeLabel` | extension | B | Name a quiz mode in the learner's language. |

## Documentation

### `Widget _feedback(BuildContext context, AppLocalizations l10n, QuizOutcome outcome)` <a id="feedback"></a>

- **Kind:** method
- **Purpose:** Say whether the answer was right, and what the right answer was.
- **Inputs:** The marked outcome.
- **Returns:** `Widget`.
- **Side effects:** None.
- **Algorithm:** An icon and a word in the primary or error colour, plus the expected answer when the
  learner was wrong.
- **Usage:** Between the answer controls and the Continue button.
- **Notes:** The right answer is always shown after a wrong one. An item is re-queued within the
  session, and one re-queued without being told the answer is guessed at again rather than learnt.
  The instruction above the prompt is in words for a related reason: a conjugation blank and a
  particle blank look identical, so the shape of the question cannot say what is being asked.
