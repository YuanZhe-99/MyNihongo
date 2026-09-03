# lib/shared/widgets/study_conflict_dialog.dart

The dialog shown once per conflicting record when a sync finds the same item studied on two
devices. See [../../../sync.md](../../../sync.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | `library` | B | Let the user pick a winner when sync finds one record edited on two devices. |
| `StudyConflictDialog` | constructor | B | Create a study conflict dialog instance. |
| `StudyConflictDialog._formatTime` | static method | B | Format a UTC timestamp in the device's zone. |
| `StudyConflictDialog._version` | method | B | Render one version's facts as a labelled block. |
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
  all-or-nothing: the caller treats null as "abort the whole sync", never as "keep local". Each
  block shows the modification time in local time, the correct and wrong counts, the streak, the
  derived stage, and when the item was last reviewed.
