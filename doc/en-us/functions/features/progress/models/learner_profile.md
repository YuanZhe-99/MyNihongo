# lib/features/progress/models/learner_profile.dart

The learner's target level, daily goals and study streak — the one piece of user state that is
neither a device preference nor an item's progress.

It is stored as an ordinary `StudyRecord` under the id `profile:me`, with its payload in the record's
`extraJson`. [`../../../../data-formats.md`](../../../../data-formats.md) explains why that shape and
not a second data module or a top-level object.

Consumers: `learnerProfileProvider`, `NihongoStorage.recordAnswers` and `saveProfile`, the Learning
settings rows, and the conflict dialog.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | The learner's own settings and streak, synced with their progress. |
| `learnerProfileId` | top-level constant | B | The record id the profile always lives under. |
| `defaultDailyNewLimit`, `defaultDailyReviewLimit` | top-level constants | B | The allowances a learner who never opened Settings gets. |
| `LearnerProfile` | class | B | Target level, daily goals and streak. |
| `localDateKey` | static method | B | Format a local date as `YYYY-MM-DD`. |
| [`fromRecord`](#fromrecord) | static method | A | Read the profile out of the progress file. |
| [`toRecord`](#torecord) | method | A | Write the profile back into its record. |
| `withStreakTouched` | method | B | Advance the streak for a day with an answer in it. |
| `copyWith` | method | B | Create a copy with selected fields replaced. |

## Documentation

### `static LearnerProfile fromRecord(StudyRecord? record)` <a id="fromrecord"></a>

- **Kind:** static method
- **Purpose:** Read the profile out of the progress file.
- **Inputs:** The `profile:me` record, or null when there is none yet.
- **Returns:** `LearnerProfile`; all defaults when absent or unreadable.
- **Side effects:** None.
- **Algorithm:** Read `extraJson['profile']`; if it is not a map, return the defaults. Read each
  field independently, falling back per field on a wrong type or a negative number.
- **Usage:** `learnerProfileProvider`, `NihongoStorage.loadProfile`, the conflict dialog.
- **Notes:** Never throws. Reading field by field rather than all-or-nothing is what lets a profile
  written by a newer build load here: the fields this build knows are used, and the rest ride along
  in `extraJson` untouched. A learner who has never opened Settings and a learner whose payload is
  corrupt get the same answer, which is the right one in both cases.

### `StudyRecord toRecord(StudyRecord? existing, DateTime now)` <a id="torecord"></a>

- **Kind:** method
- **Purpose:** Write the profile back into its record.
- **Inputs:** The record already in the file, if any; `now`.
- **Returns:** `StudyRecord` ready for `upsertRecords`.
- **Side effects:** None.
- **Algorithm:** Rebuild the payload map from whatever was already there, overlay the known fields,
  then put it back under `profile` in a copy of the record's `extraJson`. `copyWith` sets
  `modifiedAt` to `now`, which is what makes the change visible to the sync merge.
- **Usage:** `NihongoStorage.recordAnswers` and `saveProfile`.
- **Notes:** Starting from the previous payload rather than an empty map is the same rule `extraJson`
  enforces one level up: without it, an older build would silently drop a newer build's profile
  fields the first time the learner changed a daily limit.
