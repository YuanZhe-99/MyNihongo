# lib/features/quiz/services/quiz_session.dart

Runs one quiz from its first question to its summary: the queue, the marking, the
re-queueing and the score.

Writing progress is a **callback**, not a dependency, so this file imports no
storage and a test can watch exactly what it would have written.

Three getters exist for the timed mock, over a `_answers` / `_all` field pair the practice quiz never
reads. `_answers` holds the **first** answer to each question by `scoreKey` — the one that scored —
and `chosen` publishes it: a saved paper is written from what was chosen rather than from the verdict
it was given, so replaying it through [`restore`](#restore) re-marks it against the content files as
they are now. `_all` is every question the session was built with, including anything `append` added,
and `allQuestions` publishes it because a results screen needs the questions themselves — the
outcomes say which ones went wrong but not what they were, and re-reading the content files to find
out would be re-answering a question the session already knows. `remainingKeys` is the other half of
a save: the questions still to come, in order, beside the ones `outcomes` says were answered.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | Run one quiz. |
| `maxRequeues` | top-level constant | B | How many times a wrong item comes back in one session. |
| `QuizOutcome` | class | B | What happened to one answer. |
| [`QuestionOutcome`](#questionoutcome) | class | A | What happened to one question over the whole session. |
| `QuizSummary` | class | B | One finished session, as the summary screen reads it. |
| `accuracy` | getter | B | First-try accuracy from 0 to 1. |
| [`QuizSession`](#session) | class | A | Run one quiz, with or without re-queueing. |
| `current`, `lastOutcome`, `isFinished`, `total`, `answeredCount`, `attempts` | getters | B | The queue's state, as the runner reads it. |
| `outcomes` | getter | B | What happened to each question, in the order they were asked. |
| `_answers`, `_all` | fields | B | The first answer to each question by score key, and every question the session was built with. |
| `chosen` | getter | B | What the learner actually chose, by score key — what a save is written from. |
| `allQuestions` | getter | B | Every question the session was built with, in the order it asked them. |
| `remainingKeys` | getter | B | The score keys still waiting to be asked, in order. |
| [`scoreKey`](#scorekey) | static method | A | Name the key a question is scored under. |
| `append` | method | B | Add a question to a session already running, and grow the total with it. |
| [`answer`](#answer) | method | A | Mark the current question and hold the result. |
| [`next`](#next) | method | A | Move to the next question, re-queueing a wrong one. |
| `skip` | method | B | Drop the current question without answering or recording it. |
| [`forfeit`](#forfeit) | method | A | End the session with whatever is left unanswered. |
| [`restore`](#restore) | method | A | Replay answers saved from an earlier sitting. |
| `summary` | getter | B | The finished session. |
| `_expectedText` | method | B | Name the right answer for the UI. |

## Documentation

### `class QuestionOutcome` <a id="questionoutcome"></a>

- **Kind:** class
- **Purpose:** Report one question's first result.
- **Inputs:** `key` — the question's score key; `itemId`; `correct`; `answered`.
- **Returns:** An immutable value.
- **Side effects:** None.
- **Algorithm:** None.
- **Usage:** `outcomes`, from which the exam record is built.
- **Notes:** One per question rather than per attempt, and per **question** rather than per item: a
  paper asks 会う four different ways and a results screen that collapsed those into one row would
  hide three of them. `answered: false` is what a timed block leaves behind when the clock runs out —
  it is not a wrong answer, nobody got it wrong, and the exam record stores it as its own value so
  the accuracy is over what was attempted.

### `class QuizSession` <a id="session"></a>

- **Kind:** class
- **Purpose:** Run one quiz over a fixed list of questions.
- **Inputs:** `questions`; `onFirstAnswer`, called once per item with whether the **first** answer was
  right; `requeue`.
- **Returns:** A `ChangeNotifier` the page listens to.
- **Side effects:** None until answered; holds no storage of its own.
- **Algorithm:** A queue with the current question at its head, a first-result map keyed by
  `scoreKey`, a re-queue count per key, and an ordered list of `QuestionOutcome`.
- **Usage:** `quiz_page.dart` builds one and hands it to `QuizRunner`.
- **Notes:** `onFirstAnswer` fires per answer rather than once at the end, so an app killed
  mid-session keeps what was already answered. `requeue` is off for a timed paper: asking a question
  again after the learner got it wrong is how practice teaches, and it is also exactly what an exam
  must not do — a mock whose length depended on how well it was going could not be scored against a
  fixed composition, and the clock would be measuring a different paper for every learner.

### `static String scoreKey(QuizQuestion question)` <a id="scorekey"></a>

- **Kind:** static method
- **Purpose:** Name the key a question is scored under.
- **Inputs:** The `question`.
- **Returns:** `String` — `questionId` where there is one, else `itemId`.
- **Side effects:** None.
- **Algorithm:** One null-coalescing expression.
- **Usage:** `answer`, `next`, `forfeit`, `restore`, and the saved-mock format.
- **Notes:** A drill question has its own id because a paper asks several different questions about
  one word, and scoring them as one item would mean the second and third never counted. Everything
  else is scored by item, which is what it has always been: two generated questions about one grammar
  point are the same question asked twice.

### `QuizOutcome answer(QuizAnswer answer, {bool? acceptedAnyway})` <a id="answer"></a>

- **Kind:** method
- **Purpose:** Mark the current question and hold the result.
- **Inputs:** What the learner did; `acceptedAnyway`, the on-device model's second opinion.
- **Returns:** `QuizOutcome`, also held as `lastOutcome`.
- **Side effects:** May call `onFirstAnswer`; appends to `outcomes`; notifies listeners.
- **Algorithm:** Mark it; if this is the first answer under its score key, record the result, add a
  `QuestionOutcome`, name the item in the wrong list if it was wrong, and call back unless the
  question was generated or the item has already been recorded; hold the outcome so the UI can show
  the verdict.
- **Usage:** `QuizRunner`, when the learner taps Check.
- **Notes:** `acceptedAnyway` only ever **raises** a verdict, never lowers it. The deterministic check
  owns "correct": if the answer matches what the catalog says, no model is asked and none can take
  that away.

  **Only the first answer to an item reaches the callback**, and now only once per item across the
  whole session — the `_recordedItems` set is what enforces that. SM-2 grades how well something was
  recalled: an item answered right on the third attempt within one minute was not recalled, and where
  a paper asks four questions about one word, the first is the one that was not primed by the three
  before it. A generated question never reaches the scheduler at all; it still counts towards the
  score the learner sees, because they answered it.

  The wrong list names an item once even when the paper asks about it four times: the list is what
  the learner is told to go and review, and the same word four times over is a worse list, not a more
  emphatic one.

### `void next()` <a id="next"></a>

- **Kind:** method
- **Purpose:** Move to the next question, re-queueing a wrong one.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** Changes the queue; notifies listeners.
- **Algorithm:** Drop the current question; if `requeue` is on, it was answered wrongly, and its score
  key has been re-queued fewer than `maxRequeues` times, put it at the back.
- **Usage:** `QuizRunner`, when the learner taps Continue.
- **Notes:** The repetition is where the learning happens, and the cap is what stops one stubborn
  item keeping the session open forever. Separate from `answer` on purpose: the question stays on
  screen after being marked, because a learner who is not shown the right answer guesses again
  rather than learning. A session created with `requeue: false` never does this at all.

### `void forfeit()` <a id="forfeit"></a>

- **Kind:** method
- **Purpose:** End the session with whatever is left unanswered.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** Empties the queue; appends `answered: false` outcomes; notifies listeners.
- **Algorithm:** For every queued question with no first result yet, record a false result and a
  `QuestionOutcome` marked unanswered; then clear the queue.
- **Usage:** A timed block, when the clock reaches zero.
- **Notes:** Unlike `skip`, the remaining questions **are** recorded — as `answered: false`, which is
  neither right nor wrong. Running out of time is a fact about the attempt, and hiding it would make
  every timed score look better than it was; calling it wrong would make the learner look worse than
  they are. Nothing reaches `onFirstAnswer`: an unanswered question says nothing about how well the
  item was recalled, so it must not move a schedule.

### `void restore(Map<String, QuizAnswer> answers)` <a id="restore"></a>

- **Kind:** method
- **Purpose:** Replay answers saved from an earlier sitting.
- **Inputs:** `answers`, keyed by `scoreKey`.
- **Returns:** None.
- **Side effects:** Marks each replayed question; may call `onFirstAnswer`; notifies listeners once at
  the end.
- **Algorithm:** Walk the head of the queue, answering and advancing while the save has an answer for
  the question in front; stop at the first one it does not.
- **Usage:** Resuming a saved mock.
- **Notes:** The answers are marked again rather than their verdicts restored, so a content update
  that corrected an answer key is applied to the resumed paper too — the alternative is carrying a
  score the shipped file no longer agrees with. Questions the save has no answer for are left in the
  queue, which is what "resume" means.
