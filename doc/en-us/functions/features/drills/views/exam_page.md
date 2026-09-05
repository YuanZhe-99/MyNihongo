# lib/features/drills/views/exam_page.dart

One sitting of a timed JLPT paper: draw it or pick up the saved one, run each block on its clock,
record the attempt, and clear the save.

A full-screen route outside the tab shell, like the quiz: it is entered with a purpose and left when
it is finished, and a navigation bar under a running clock would be an invitation to leave.

The page owns everything the [`ExamSession`](../services/exam_session.md) deliberately does not:
reading the drill files, drawing the paper, writing the save, and turning a finished paper into an
`exam:` record. It is a `WidgetsBindingObserver` because the clock has to stop when the app leaves
the foreground and the deadline has to be re-checked on the way back.

Consumers: the `/exam` route, reached from `JlptPracticeCard` with an `ExamConfig`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `ExamConfig` | class | B | What a mock is being started for: a fresh paper, or the saved one. |
| `ExamConfig.resume` | constructor | B | Ask for the paper already saved on this device; its level and scale come from the save. |
| `level`, `scale`, `resume` | fields | B | The level to sit, how much of the paper, and whether to pick up the save. |
| `ExamPage` | class | B | One sitting of a timed JLPT paper. |
| `createState` | method | B | Create the page's state. |
| `_ExamPageState` | class | B | Holds the session, the passages and the section map for one sitting. |
| `initState`, `dispose` | methods | B | Register and remove the lifecycle observer; build the paper after the first frame; dispose the session. |
| [`didChangeAppLifecycleState`](#lifecycle) | method | A | Stop the clock when the app leaves the foreground, and pick it up again when it comes back. |
| [`_build`](#build-paper) | method | A | Draw the paper, or pick up the saved one. |
| [`_sessionFor`](#sessionfor) | method | A | Build one block's session. |
| [`_onExamChanged`](#onexamchanged) | method | A | Follow the exam's clock and save after every change. |
| [`_save`](#save) | method | A | Write the paper down, or clear it once it is finished. |
| `_saving` | field | B | The save in flight, so the next one queues behind it rather than racing. |
| `_saveNow` | method | B | Do one save. |
| [`_record`](#record) | method | A | Record the finished paper and clear the save. |
| `_passageFor` | method | B | Show whatever the question on screen is about — a listening script played once, or a passage with no translation. |
| [`_confirmLeave`](#confirmleave) | method | A | Confirm before leaving a paper that is still running. |
| [`build`](#build) | method | A | Build the start card, the timed block, or the results. |
| `_startCard` | method | B | Offer to start the next block, naming its sections, its minutes and its question count. |
| [`_block`](#block) | method | A | Run the block that is on the clock. |

## Documentation

### `void didChangeAppLifecycleState(AppLifecycleState state)` <a id="lifecycle"></a>

- **Kind:** method
- **Purpose:** Stop the clock when the app leaves the foreground, and pick it up again when it comes
  back.
- **Inputs:** The new `state`.
- **Returns:** None.
- **Side effects:** Pauses or resumes the clock; saves; may submit the block.
- **Algorithm:** Do nothing without a session or once the paper is recorded. On `resumed`,
  `checkDeadline()` first and only resume the clock when it did not fire; on anything else, pause the
  clock and save.
- **Usage:** The Flutter framework, through `WidgetsBindingObserver`.
- **Notes:** The clock measures attention, not wall-clock time. A learner who takes a phone call has
  not spent that time on the paper, and one who leaves it overnight has not lost the paper. The
  deadline is re-checked on the way back in, because a phone that slept past it has to find out on
  waking rather than resume a block that ended hours ago.

### `Future<void> _build()` <a id="build-paper"></a>

- **Kind:** method
- **Purpose:** Draw the paper, or pick up the saved one.
- **Inputs:** None; reads the config, the JLPT structure and the level's drill files.
- **Returns:** None.
- **Side effects:** Reads assets and the save file; builds an `ExamSession` and attaches the listener.
- **Algorithm:** Await the structure and, when resuming, the save; take the level and scale from the
  save where it has them. Await the level's drill files, index every question by id and every id to
  its section. Then either rebuild the saved blocks — looking each question id up and dropping the
  ones that are gone, then `restore`-ing each block's answers — or draw fresh ones: for each block of
  the spec, keep the sections that can be sat, `DrillSampler.drawByPassage` each one against the
  composition and the already-asked ids, and skip a block that ends up with no questions. Collect the
  passages the chosen questions refer to, then set the session.
- **Usage:** A post-frame callback from `initState`.
- **Notes:** Internal helper used within this file only.

  **Listening is dropped where there is no Japanese voice**, and the block is left out of the paper
  entirely rather than shown and skipped: a block nobody can hear is not a section anybody scored
  zero on.

  Question ids the shipped files no longer have are dropped on resume. Content is rewritten between
  releases, and a paper that refused to resume because three of its questions had been renumbered
  would be a worse answer than one that is three questions shorter and says how many it asked.

  A resume with no readable save, or a level with no spec, leaves `_exam` null and the page says
  there is no content rather than showing an empty paper.

### `QuizSession _sessionFor(List<DrillQuestion> questions, Locale locale)` <a id="sessionfor"></a>

- **Kind:** method
- **Purpose:** Build one block's session.
- **Inputs:** The `questions` and the `locale`.
- **Returns:** `QuizSession`.
- **Side effects:** None; the session it returns records answers through `progressDataProvider`.
- **Algorithm:** Convert each drill question for the locale and construct a `QuizSession` with
  `requeue: false` and an `onFirstAnswer` that calls `recordAnswer`.
- **Usage:** `_build`, once per block.
- **Notes:** Internal helper used within this file only. **No re-queueing:** asking a question again
  after the learner got it wrong is how practice teaches and exactly what an exam must not do — a
  mock whose length depended on how well it was going could not be scored against a fixed
  composition. Every answer still moves its item's review interval: sitting a mock is studying, and
  the schedule should not pretend it did not happen.

### `void _onExamChanged()` <a id="onexamchanged"></a>

- **Kind:** method
- **Purpose:** Follow the exam's clock and save after every change.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** Rebuilds; writes the save file.
- **Algorithm:** `setState` and an unawaited `_save()`, guarded on `mounted`.
- **Usage:** Attached to the session as its listener in `_build`.
- **Notes:** Internal helper used within this file only. Saving on every notification is once a second
  while a block runs, which is a small atomic write to a file nothing else reads — and the alternative
  is a paper lost to a phone that ran out of battery.

### `Future<void> _save({bool refreshCard = false})` <a id="save"></a>

- **Kind:** method
- **Purpose:** Write the paper down, or clear it once it is finished.
- **Inputs:** `refreshCard` — whether the Learn card is about to be looked at.
- **Returns:** None.
- **Side effects:** Writes or deletes the save file; refreshes `savedExamProvider` when asked to.
- **Algorithm:** Chain `_saveNow` onto the save already in flight and return the chained future. In
  `_saveNow`: with no session, return; a finished paper clears the save, anything else writes
  `exam.toJson()`; refresh `savedExamProvider` only when asked to.
- **Usage:** `_onExamChanged`, the lifecycle callback, and `_confirmLeave` — the last of which is the
  only one that asks for the card to be refreshed.
- **Notes:** Internal helper used within this file only. The refresh is the fix for a real bug: the
  Learn card reads the save through a `FutureProvider`, which resolved before this paper existed.
  Without it the learner leaves a half-sat exam and the card that should offer to continue it shows
  nothing — which is what the device did before that line.

  **Saves are chained, never concurrent.** The clock notifies once a second and leaving the page saves
  as well, so two writes to the same file could start in the same millisecond — and Windows refuses a
  rename onto a file another rename is touching, so one of them failed and the paper it was writing
  was lost. Each save writes the whole paper, so running them in order costs nothing and the last one
  is the current state either way.

  **And the card is refreshed only on the way out.** Refreshing it on every tick starts a read of the
  save file that the next tick's write then renames over, and Windows refuses a rename onto a file
  another handle has open — so a save failed roughly once a minute, on a page whose whole job is not
  losing the paper. The card sits behind this page, so the only moments it can be seen are the ones
  that leave.

### `Future<void> _record()` <a id="record"></a>

- **Kind:** method
- **Purpose:** Record the finished paper and clear the save.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** Writes an `exam:` record through `progressDataProvider`; deletes the save file;
  refreshes `savedExamProvider`.
- **Algorithm:** Guard on `_finished` and set it first. Walk every block: keep the block's time and
  limit under its first section's name, and for every outcome add to that section's asked/right tally
  and store the answer as 1, 0 or `examUnanswered`. Return without writing when nothing was answered.
  Salt the id with a hash of the answered keys, then `recordExam` an `ExamAttempt` carrying a
  per-section `ExamSectionResult`, and clear the save.
- **Usage:** The Done button on the results view.
- **Notes:** Internal helper used within this file only. Written **once, at the end**, because half a
  paper is not an attempt — and unlike a practice section, a mock that was abandoned is not recorded
  at all. Unanswered is stored as its own value rather than as wrong, so the accuracy is over what
  was attempted. Times are read from `usedBefore`, which is exact by then because submitting a block
  pauses its clock first.

### `Future<bool> _confirmLeave()` <a id="confirmleave"></a>

- **Kind:** method
- **Purpose:** Confirm before leaving a paper that is still running.
- **Inputs:** None.
- **Returns:** `Future<bool>` — whether to pop.
- **Side effects:** Pauses the clock and saves; may show a dialog.
- **Algorithm:** Allow the pop outright when there is no session, the paper is recorded, or every
  block is in. Otherwise pause, save, and ask; resume the clock when the learner stays.
- **Usage:** `build`'s `PopScope`.
- **Notes:** Internal helper used within this file only. Unlike the quiz, the answer is not "the rest
  is discarded": the paper is saved and the Learn card offers to continue it. So this is an
  information dialog rather than a warning, and it says where the paper went. The clock is paused
  *before* the dialog, so the seconds spent reading it are not taken off the block.

### `Widget build(BuildContext context)` <a id="build"></a>

- **Kind:** method
- **Purpose:** Build the start card, the timed block, or the results.
- **Inputs:** `context`.
- **Returns:** The widget tree for the current state.
- **Side effects:** Creates UI widgets from the current state.
- **Algorithm:** A `PopScope` with `canPop: false` that pops only once `_confirmLeave` agrees, around
  a scaffold whose body switches on `(_building, exam)`: a spinner while building, the no-content line
  for a null session, `ExamResultsView` once every block is in, the start card between blocks, and
  otherwise the running block — all inside a `pageMaxContentWidth` constraint.
- **Usage:** The `/exam` route.
- **Notes:** Keep this method cheap because Flutter may call it often. Done on the results view calls
  `_record` before popping, which is what makes the attempt exist; the navigator is captured before
  the await rather than reached for across it.

### `Widget _block(AppLocalizations l10n, ExamSession exam)` <a id="block"></a>

- **Kind:** method
- **Purpose:** Run the block that is on the clock.
- **Inputs:** `l10n`, the `exam`.
- **Returns:** `Widget`.
- **Side effects:** None; the runner it returns drives the block's session.
- **Algorithm:** A `QuizRunner` keyed to the block index, over the block's session, with
  `showFeedback: false`, `_passageFor` as its leading builder, a header carrying the section names and
  a tabular-figures `mm:ss` countdown, and `finishBlockEarly` as its `onFinished`.
- **Usage:** `build`, while a block is running.
- **Notes:** Internal helper used within this file only. **No feedback between questions:** a paper is
  marked at the end, and being told after each one is the thing a real exam most conspicuously does
  not do. The last minute is the one worth colouring — before that a countdown in red is just noise,
  and after it there is nothing to warn about. Tabular figures stop the countdown from jittering as
  the digits change.
