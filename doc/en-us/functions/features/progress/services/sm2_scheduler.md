# lib/features/progress/services/sm2_scheduler.dart

What one right-or-wrong answer does to one item's schedule. Pure: it takes a `StudyRecord` and
returns a new one, so the whole policy is tested without a device, a clock or a file.

The arithmetic and the two departures from textbook SM-2 are derived in
[`../../../../algorithms/spaced-repetition.md`](../../../../algorithms/spaced-repetition.md). This
page covers the declarations.

Consumers: `NihongoStorage.recordAnswers`, and nothing else — every answer in the app reaches the
scheduler through that one write path.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | Schedule the next review of an item from a right-or-wrong answer. |
| `minStudyEase` | top-level constant | B | The ease floor, 1.3; below it an item comes back daily forever. |
| `maxIntervalDays` | top-level constant | B | The interval ceiling, one year. |
| `easeBonusStreak` | top-level constant | B | The consecutive-correct count that earns the ease bonus. |
| `Sm2Scheduler` | class | B | Plan the next review of an item. |
| [`apply`](#apply) | method | A | Advance a record after one answer. |
| [`_nextEase`](#nextease) | method | A | Adjust the ease factor for one answer. |
| `_nextInterval` | method | B | Work out the next interval: 1, then 6, then multiply by ease. |

## Documentation

### `StudyRecord apply(StudyRecord record, {required bool correct, required DateTime now})` <a id="apply"></a>

- **Kind:** method
- **Purpose:** Advance a record after one answer.
- **Inputs:** The `record`; whether the answer was `correct`; `now`, the answer's instant.
- **Returns:** A new `StudyRecord`.
- **Side effects:** None.
- **Algorithm:** Compute the new streak (incremented, or zero), then the new ease from it, then the
  interval — for a wrong answer always one day. Write `dueAt` as `now + interval`, `lastReviewedAt`
  and `modifiedAt` as `now`, and move the lifetime counter that applies.
- **Usage:** `NihongoStorage.recordAnswers`, once per answered item.
- **Notes:** `now` is required rather than defaulted, so a batch of answers shares one instant and
  every test is deterministic. `modifiedAt` is set explicitly to that same instant rather than left
  to `copyWith`'s default, for the same reason. The lifetime `correct` and `wrong` counts are never
  rolled back: they record what happened and are not part of the schedule.

### `double _nextEase(double ease, {required bool correct, required int streak})` <a id="nextease"></a>

- **Kind:** method
- **Purpose:** Adjust the ease factor for one answer.
- **Inputs:** The current `ease`, whether the answer was `correct`, and the `streak` after it.
- **Returns:** `double`, never below `easeFloor`.
- **Side effects:** None.
- **Algorithm:** A wrong answer subtracts 0.20. A correct answer adds 0.10 once the streak has
  reached `easeBonusStreak`, and otherwise changes nothing. Clamp to the floor.
- **Usage:** `apply`.
- **Notes:** **0.20, not SM-2's 0.54, and the difference is deliberate.** The textbook penalty
  assumes a 0–5 self-assessment, so its worst value is reserved for genuinely blank answers. With
  binary grading every mistake would take it, and three mistakes would drop an item from 2.5 to the
  1.3 floor — where it returns daily forever regardless of how well the learner then does. At 0.20
  the same three mistakes reach 1.9 and the item recovers. Ease is neutral for an ordinary correct
  answer so it drifts up for items genuinely known rather than for every hit.
