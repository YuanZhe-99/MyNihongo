# lib/features/quiz/services/quiz_session.dart

Runs one quiz from its first question to its summary: the queue, the marking, the
re-queueing and the score.

Writing progress is a **callback**, not a dependency, so this file imports no
storage and a test can watch exactly what it would have written.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | Run one quiz. |
| `maxRequeues` | top-level constant | B | How many times a wrong item comes back in one session. |
| `QuizOutcome` | class | B | What happened to one answer. |
| `QuizSummary` | class | B | One finished session, as the summary screen reads it. |
| `accuracy` | getter | B | First-try accuracy from 0 to 1. |
| `QuizSession` | class | B | Run one quiz. |
| [`answer`](#answer) | method | A | Mark the current question and hold the result. |
| [`next`](#next) | method | A | Move to the next question, re-queueing a wrong one. |
| `summary` | getter | B | The finished session. |
| `_expectedText` | method | B | Name the right answer for the UI. |

## Documentation

### `QuizOutcome answer(QuizAnswer answer)` <a id="answer"></a>

- **Kind:** method
- **Purpose:** Mark the current question and hold the result.
- **Inputs:** What the learner did.
- **Returns:** `QuizOutcome`, also held as `lastOutcome`.
- **Side effects:** May call `onFirstAnswer`; notifies listeners.
- **Algorithm:** Mark it; if this is the item's first answer, record it and call back; hold the
  outcome so the UI can show the verdict.
- **Usage:** `QuizRunner`, when the learner taps Check.
- **Notes:** **Only the first answer to an item reaches the callback.** SM-2 grades how well
  something was recalled, and an item answered right on the third attempt within one minute was not
  recalled — recording the retry would tell the scheduler the learner knows a word they had just
  got wrong. The callback fires per answer rather than once at the end, so an app killed mid-session
  keeps what was already answered.

### `void next()` <a id="next"></a>

- **Kind:** method
- **Purpose:** Move to the next question, re-queueing a wrong one.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** Changes the queue; notifies listeners.
- **Algorithm:** Drop the current question; if it was answered wrongly and has been re-queued fewer
  than `maxRequeues` times, put it at the back.
- **Usage:** `QuizRunner`, when the learner taps Continue.
- **Notes:** The repetition is where the learning happens, and the cap is what stops one stubborn
  item keeping the session open forever. Separate from `answer` on purpose: the question stays on
  screen after being marked, because a learner who is not shown the right answer guesses again
  rather than learning.
