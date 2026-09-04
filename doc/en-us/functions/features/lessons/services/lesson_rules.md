# lib/features/lessons/services/lesson_rules.dart

What state each unit is in, when the next one opens, and how far through a unit the learner is.
Pure functions over the progress file and the path — nothing here reads storage or builds a widget,
so the rules can be read in one sitting and tested without a device.

Consumers: `lesson_path_view.dart`, `quiz_page.dart`, `reminder_planner.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `unitSessionSize` | constant | B | Questions in a practice session (12). |
| `checkpointSize` | constant | B | Questions in a checkpoint (20). |
| `checkpointPassAccuracy` | constant | B | First-try accuracy a checkpoint needs (0.7). |
| `UnitState` | enum | B | Locked, open or passed. |
| `lessonRecordId` | function | B | Name the record a checkpoint result is written to. |
| [`unitStates`](#states) | function | A | Decide where each unit stands. |
| [`canAttemptCheckpoint`](#attempt) | function | A | Say whether a checkpoint may be attempted. |
| [`unitProgress`](#progress) | function | A | Measure how much of a unit is done. |
| `nextUnit` | function | B | The first unit that is open. |

## Documentation

### `Map<String, UnitState> unitStates(LessonPath path, ProgressData progress)` <a id="states"></a>

- **Kind:** function
- **Purpose:** Decide where each unit of a path stands.
- **Inputs:** The `path` and the learner's `progress`.
- **Returns:** A state per unit id.
- **Side effects:** None.
- **Algorithm:** The first unit is open; after that a unit opens when the one before it has been
  passed, where passed means a `lesson:` record with at least one correct.
- **Usage:** `lesson_path_view.dart`, and `nextUnit`.
- **Notes:** Passing a later unit opens the one after it, so skipping ahead leaves no gap behind
  the learner — the units they jumped stay locked for practice but their checkpoints stay open.

### `bool canAttemptCheckpoint(UnitState state)` <a id="attempt"></a>

- **Kind:** function
- **Purpose:** Say whether a unit's checkpoint may be attempted.
- **Inputs:** The unit's state.
- **Returns:** `bool` — always true.
- **Side effects:** None.
- **Algorithm:** None; it is a constant answer.
- **Usage:** `lesson_path_view.dart`, and the tests that pin the rule down.
- **Notes:** A function rather than a constant because the rule is worth naming. A checkpoint is
  how a learner skips ahead, and the only thing passing it can do is unlock what they have just
  demonstrated — so hiding it behind the units it would let them skip is circular.

### `double unitProgress(LessonUnit unit, ProgressData progress)` <a id="progress"></a>

- **Kind:** function
- **Purpose:** Measure how much of a unit the learner has answered correctly.
- **Inputs:** The `unit` and the `progress`.
- **Returns:** `double` between 0 and 1.
- **Side effects:** None.
- **Algorithm:** The fraction of the unit's items with at least one correct answer recorded.
- **Usage:** The progress bar on each unit card.
- **Notes:** Coarser than the scheduler's view of the same items, deliberately. A bar that went
  backwards because a review interval lapsed would punish the learner for the passage of time.
  Derived from the records and never stored, like the daily counts.
