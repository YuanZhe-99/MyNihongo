# lib/shared/widgets/study_conflict_dialog.dart

The dialog shown once per conflicting record when a sync finds the same item studied on two
devices. See [../../../sync.md](../../../sync.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | `library` | B | Let the user pick a winner when sync finds one record edited on two devices. |
| `StudyConflictDialog` | constructor | B | Create a study conflict dialog instance. |
| `StudyConflictDialog._formatTime` | static method | B | Format a UTC timestamp in the device's zone. |
| `StudyConflictDialog._version` | method | B | Render one version's facts as a labelled block, dispatching by kind. |
| `StudyConflictDialog._historyVersion` | method | B | Show one side of a remembered-sentence conflict. |
| `StudyConflictDialog._examVersion` | method | B | Show one side of an exam-attempt conflict. |
| `StudyConflictDialog._profileVersion` | method | B | Show one side of a learner-profile conflict. |
| `StudyConflictDialog.build` | method | B | Build the current widget subtree. |
| `showStudyConflictDialog` | top-level function | A | Present one conflict and wait for the user's choice. |

### `showStudyConflictDialog`

- **Purpose:** Present one conflict and wait for the user's choice.
- **Inputs:** `context`, `conflict` — the pair the merge reported, `label` — from
  [`resolveStudyItemLabel`](../../features/content/services/study_item_labels.md).
- **Returns:** `Future<StudyRecord?>` — the kept record, or null when the user dismissed the dialog
  with system back.
- **Side effects:** Opens a modal route.
- **Algorithm:** `showDialog` with `barrierDismissible: false`, popping the local record from the
  text button and the remote record from the filled button.
- **Usage:** Called in a loop over `pending.allConflicts` by the WebDAV page.
- **Notes:** There is no cancel action, and the barrier is inert, because resolution is
  all-or-nothing: the caller treats null as "abort the whole sync", never as "keep local".

**Four kinds of block, because not every record has counters.** `_version` dispatches on
`record.kind`:

- An ordinary item shows the modification time in local time, the correct and wrong counts, the
  streak, the derived stage, and when it was last reviewed.
- The **learner profile** (`profile:me`) shows the target level, the daily limits and the streak
  instead. "Correct 0 · wrong 0, stage fresh" is not a description of a target level, and a conflict
  the learner cannot read is a conflict they cannot resolve.
- A **remembered sentence** (`lab:` or `writing:`, from `v0.3.2`) shows the timestamp and the text in
  full. The text *is* the record, so truncating it would hide the only thing that tells the two
  versions apart.
- An **exam attempt** (`exam:`) shows the level and the mode, the score, and when the paper was sat.
  An attempt *does* have the counter fields — they are written so an older build's dialog says
  something true — but they are not what distinguishes two versions of one. What does is the paper:
  which level, practice or timed, when it was sat and what it scored. The counters are deliberately
  **not** repeated here, because "correct 48 · wrong 19" alongside "48 / 67" is the same fact twice
  in two shapes.

Every block reads its payload through the model's own `fromRecord`, so a record written by a newer
build with fields this one cannot show still renders the ones it can.
