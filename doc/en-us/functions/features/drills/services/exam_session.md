# lib/features/drills/services/exam_session.dart

Runs one timed JLPT paper — its blocks, its clock, and the save that lets a learner put it down and
come back.

The clock is **injected** for the reason `QuizSession`'s callback is: a test that had to wait real
minutes to watch a block expire would be a test nobody runs. Persistence is the page's job, so this
file imports no storage and a test can read exactly what would have been written.

Time is counted only while a block is actually on screen. `usedBefore` and `resumedAt` are the two
halves of that number, which is why leaving the page cannot cost the learner time and cannot give
them any either — the clock measures attention, not wall-clock hours.

The saved paper is split in two. `ExamSession.toJson` writes it; `SavedExam` reads it back **without
touching the content files**, so the Learn card can say "N5 mock, block 2, 18 minutes left" without
parsing four drill files to do it. The exam page is the only thing that turns a `SavedExam` back into
a running `ExamSession`.

Consumers: `exam_page.dart` (runs and saves), `exam_results_view.dart` (reads the finished blocks),
`exam_provider.dart` (`savedExamProvider` reads the save).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | Run one timed JLPT paper: its blocks, its clock and its save. |
| `examSaveVersion` | top-level constant | B | The version written into a saved paper; a newer save is discarded rather than half-read. |
| [`ExamBlock`](#examblock) | class | A | One timed block of a paper: the sections it examines, and its clock. |
| `index`, `sections`, `limit`, `session`, `usedBefore`, `resumedAt`, `started`, `submitted` | fields | B | One block's place in the paper, its questions, and the two halves of its clock. |
| `used` | method | B | Say how much of the block's time has been used, counting the running sitting. |
| `remaining` | method | B | Say how much time is left, clamped at zero. |
| `expired` | method | B | Whether the clock has run out. |
| [`ExamSession`](#examsession) | class | A | Run one timed paper. |
| `blocks`, `currentIndex`, `current`, `isFinished`, `remaining` | getters | B | The paper's state, as the exam page reads it. |
| `betweenBlocks` | getter | B | Whether the paper is between blocks — one handed in, the next not started. |
| [`resumeClock`](#resumeclock) | method | A | Start or resume the clock on the current block. |
| [`pauseClock`](#pauseclock) | method | A | Stop the clock without handing the block in. |
| [`submitBlock`](#submitblock) | method | A | Hand in the current block and move to the next. |
| [`checkDeadline`](#checkdeadline) | method | A | Hand the block in if its clock has run out. |
| `finishBlockEarly` | method | B | Move the paper on when the current block runs out of questions. |
| `_tick` | method | B | Report one tick of the clock. |
| [`toJson`](#tojson) | method | A | Write the paper down so it can be picked up later. |
| `encodeAnswer` | static method | B | Write one answer down; null for a shape a paper cannot ask. |
| `decodeAnswer` | static method | B | Read one answer back; null for anything unreadable, never throws. |
| `dispose` | method | B | Cancel the timer with the notifier. |
| `SavedExam` | class | B | A paper written down, before its questions have been found again. |
| `level`, `scale`, `startedAt`, `blockIndex`, `blocks`, `remaining` | fields and getter | B | What the Learn card needs to describe a saved paper. |
| [`SavedExam.fromJson`](#savedexamfromjson) | static method | A | Read a saved paper, refusing one this build cannot resume. |
| `SavedExamBlock` | class | B | One block of a saved paper. |
| `sections`, `limit`, `used`, `submitted`, `started`, `questionIds`, `answers`, `remaining` | fields and getter | B | One saved block's clock, its questions and what was chosen. |
| `SavedExamBlock.fromJson` | static method | B | Read one saved block; null without sections or questions. |
| `_int` | top-level function | B | Read a JSON value as an integer. |

## Documentation

### `class ExamBlock` <a id="examblock"></a>

- **Kind:** class
- **Purpose:** Hold one block, its questions and how much of its time is gone.
- **Inputs:** `index` in the paper; the `sections` it examines; the `limit`; the `session` that runs
  its questions; `usedBefore` — time already spent in earlier sittings; `submitted`; `started`.
- **Returns:** A mutable holder the session drives.
- **Side effects:** None of its own.
- **Algorithm:** `used(now)` is `usedBefore` plus, when `resumedAt` is set, the time since it was set;
  `remaining` is the limit less that, clamped at zero; `expired` is `remaining == Duration.zero`.
- **Usage:** Built by `exam_page.dart` — one per block of the paper — and read by the results view.
- **Notes:** `usedBefore` and `resumedAt` are two halves of the same number. Time is only counted
  while the block is actually on screen, so the clock is "what earlier sittings used" plus "how long
  this sitting has been running" — which is why leaving the page cannot cost the learner time and
  cannot give them any either.

  `started` is **distinct from "the clock is running"**, and the distinction matters: the clock stops
  every time the page shows a dialog or the app is backgrounded, and a block that fell back to its
  start card each time would look to the learner as though the paper had been thrown away.

  `remaining` is clamped so a block whose deadline passed while the app was being killed shows
  `00:00` rather than a negative countdown.

### `class ExamSession extends ChangeNotifier` <a id="examsession"></a>

- **Kind:** class
- **Purpose:** Run one timed paper.
- **Inputs:** The `level` label; the `scale`; the `blocks`; `startedAt`; and a `clock` for tests.
- **Returns:** A `ChangeNotifier` the exam page listens to.
- **Side effects:** Runs a one-second timer while a block is on screen; holds no storage of its own.
- **Algorithm:** A list of blocks with an index into it. The current block's clock runs while
  `resumedAt` is set; a one-second timer notifies listeners and checks the deadline. Handing a block
  in forfeits whatever is left in its `QuizSession` and advances the index.
- **Usage:** `exam_page.dart` builds one, listens to it, and saves on every notification.
- **Notes:** The timer is **not** started in the constructor. A paper exists as soon as it is drawn,
  but its clock must not run until the learner has seen the start card and said they are ready — an
  exam that began counting while the questions were still being read would be a worse exam than the
  real one.

  Persistence is deliberately somebody else's job: this file imports no storage, so a test can read
  exactly what would have been written. The clock is injected for the same reason the quiz session's
  callback is — a test that had to wait real minutes to watch a block expire would be a test nobody
  runs.

### `void resumeClock()` <a id="resumeclock"></a>

- **Kind:** method
- **Purpose:** Start or resume the clock on the current block.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** Starts a one-second timer; sets `started`; notifies listeners.
- **Algorithm:** Return when there is no current block, it is submitted, or its clock is already
  running; otherwise stamp `resumedAt`, mark the block started, and (re)start the periodic timer.
- **Usage:** The Start button on the start card, and the exam page whenever it comes back to the
  foreground.
- **Notes:** **Idempotent.** Resuming a block whose clock is already running changes nothing, so a
  lifecycle callback that fires twice cannot make the paper shorter.

### `void pauseClock()` <a id="pauseclock"></a>

- **Kind:** method
- **Purpose:** Stop the clock without handing the block in.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** Cancels the timer; folds the running sitting into `usedBefore`; notifies.
- **Algorithm:** Cancel the timer; if a block is running, set `usedBefore = used(now)` and clear
  `resumedAt`.
- **Usage:** What leaving the page and backgrounding the app both do; also the first step of
  `submitBlock`.
- **Notes:** The time spent so far is folded into `usedBefore`, so the paper can be picked up later
  with the same time left — the clock measures attention, not wall-clock hours. The timer is always
  cancelled, even when no block is running, so a paused paper costs nothing.

### `void submitBlock()` <a id="submitblock"></a>

- **Kind:** method
- **Purpose:** Hand in the current block and move to the next.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** Stops the clock; forfeits anything unanswered; advances the block index; notifies.
- **Algorithm:** Return if there is no current block or it is already in. Pause the clock,
  `session.forfeit()`, mark it submitted, and advance the index unless this was the last block.
- **Usage:** The deadline check, finishing a block early, and the timer tick behind both.
- **Notes:** Everything still unanswered is recorded as **unanswered**, not as wrong. Running out of
  time is a fact about the attempt: calling it wrong would make every timed score worse than the
  learner did, and dropping it would make every timed score better. The index stops at the last block
  rather than running past the end, so `current` stays valid while the results are being read.

### `bool checkDeadline()` <a id="checkdeadline"></a>

- **Kind:** method
- **Purpose:** Hand the block in if its clock has run out.
- **Inputs:** None.
- **Returns:** `bool` — whether it did.
- **Side effects:** As `submitBlock`, when the deadline has passed.
- **Algorithm:** Return false when there is no current block, it is already in, or it has not expired;
  otherwise `submitBlock()` and return true.
- **Usage:** Every tick of the clock, and the exam page's lifecycle callback on the way back to the
  foreground.
- **Notes:** Checked on the way back in and not only on tick, because a phone that slept through the
  deadline has to find out on waking rather than resume a block that ended twenty minutes ago. The
  return value is what lets the page choose between resuming the clock and showing the next start
  card.

### `Map<String, dynamic> toJson()` <a id="tojson"></a>

- **Kind:** method
- **Purpose:** Write the paper down so it can be picked up later.
- **Inputs:** None.
- **Returns:** `Map<String, dynamic>` — the save's whole shape, versioned by `examSaveVersion`.
- **Side effects:** None.
- **Algorithm:** Take `now` once. Write the version, level, scale, start time and current block index;
  then per block its section names, its limit, `used(now)` in seconds, its two flags, its question
  ids — the answered ones from `outcomes` followed by `session.remainingKeys` — and its answers from
  `session.chosen`, each through `encodeAnswer`.
- **Usage:** `exam_page.dart`, on every change to the session.
- **Notes:** The questions are saved **by id**, not by content: they are in the shipped files, and a
  save that carried its own copy would resume a paper the app no longer agrees with. The answers are
  saved as what the learner **chose**, so resuming re-marks them against the files as they are now.

  The running sitting is folded into `usedSecs` first, so a save taken mid-block records the time
  actually spent rather than the time spent up to the last pause.

  Answers that `encodeAnswer` cannot represent are dropped by the null-aware entry rather than
  written as null, which is why a typed answer costs nothing here.

### `static SavedExam? fromJson(Object? json)` <a id="savedexamfromjson"></a>

- **Kind:** static method
- **Purpose:** Read a saved paper.
- **Inputs:** `json`.
- **Returns:** `SavedExam?` — null for anything this build cannot resume.
- **Side effects:** None.
- **Algorithm:** Refuse a non-map, or a version that is not `examSaveVersion`. Require a level and a
  parseable start time; read the blocks through `SavedExamBlock.fromJson`, dropping the ones that
  fail, and refuse an empty list. Clamp `blockIndex` into range.
- **Usage:** `savedExamProvider` for the Learn card, and `exam_page.dart` when resuming.
- **Notes:** A save whose version this build does not know is **refused rather than half-read**. An
  exam resumed from a file only partly understood would be scored against questions it could not
  reconstruct, which is worse than telling the learner the saved paper is gone. Everything below that
  is forgiving instead: an unreadable answer is dropped and its question resumes unanswered rather
  than costing the whole block, and an out-of-range block index falls back to the first block.
