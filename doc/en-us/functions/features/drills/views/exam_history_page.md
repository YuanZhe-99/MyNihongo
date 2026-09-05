# lib/features/drills/views/exam_history_page.dart

Every JLPT paper the learner has sat, newest first, with what they got wrong.

A full-screen route outside the tab shell, for the reason the quiz and the sentence lab are: it is
entered with a purpose from the Learn tab and left when it is finished, not a place to browse.

The page reads `examAttemptsProvider`, so an attempt written here, restored from a backup, or synced
in from another device all reach the list the same way. Only the answers were stored, so the question
text, its options and its explanation are read back from the shipped drill files at the moment a tile
is expanded.

Consumers: the `/exam-history` route, reached from `JlptPracticeCard`'s Results button.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `ExamHistoryPage` | class | B | Every JLPT paper the learner has sat, newest first. |
| [`build`](#build) | method | A | Build the list of attempts, or say there are none. |
| `_AttemptTile` | class | B | One attempt, expandable into what was got wrong. |
| [`_AttemptTile.build`](#tile) | method | A | Build one attempt's summary and its detail. |
| `_WrongQuestions` | class | B | The questions this attempt got wrong or never reached. |
| [`_WrongQuestions.build`](#wrong) | method | A | Show what went wrong, joined back from the shipped files. |

## Documentation

### `Widget build(BuildContext context, WidgetRef ref)` <a id="build"></a>

- **Kind:** method of `ExamHistoryPage`
- **Purpose:** Build the list of attempts, or say there are none.
- **Inputs:** `context`, `ref`.
- **Returns:** The widget tree for the current state.
- **Side effects:** Creates UI widgets from the current state.
- **Algorithm:** Watch `examAttemptsProvider`. With nothing in it, centre the empty-state line;
  otherwise a `ListView.builder` whose first row is the standing note and whose remaining rows are
  one `_AttemptTile` each, inside a `pageMaxContentWidth` constraint.
- **Usage:** The `/exam-history` route.
- **Notes:** Keep this method cheap because Flutter may call it often. The note at the top is not
  decoration: a screen that shows "48 of 67" beside the letters JLPT will be read as a JLPT score
  unless it says otherwise. An empty list is also what a learner sees while the progress file is
  still loading, which is deliberate — nothing on screen has to tell "not loaded" apart from
  "nothing yet".

### `Widget build(BuildContext context, WidgetRef ref)` — `_AttemptTile` <a id="tile"></a>

- **Kind:** method of `_AttemptTile`
- **Purpose:** Build one attempt's summary and its detail.
- **Inputs:** `context`, `ref`; the `attempt` field.
- **Returns:** The widget tree for the current state.
- **Side effects:** Creates UI widgets from the current state; deletes the record when the delete
  action is used.
- **Algorithm:** An `ExpansionTile` in a `Card`: the title is the level and the mode, the subtitle
  the local start time, the paper-wide score and a per-section score chip for every section
  `DrillSection.parse` recognizes. Expanded, it shows `_WrongQuestions` and a delete action that
  calls `NihongoStorage.deleteRecords` and reloads `progressDataProvider`.
- **Usage:** `ExamHistoryPage.build`, once per attempt.
- **Notes:** Keep this method cheap because Flutter may call it often. The wrong questions are loaded
  only when the tile is expanded, because showing them means reading up to four content files and
  most attempts in a long list are never opened. The delete is a **real deletion, not a tombstone**:
  the three-way merge treats a record deleted on one side and untouched on the other as deleted, so
  an attempt removed here is removed everywhere on the next sync — a record that came back would be
  worse than no delete button at all. A section key this build has no `DrillSection` for is skipped
  rather than shown unnamed.

### `Widget build(BuildContext context, WidgetRef ref)` — `_WrongQuestions` <a id="wrong"></a>

- **Kind:** method of `_WrongQuestions`
- **Purpose:** Show what went wrong, joined back from the shipped files.
- **Inputs:** `context`, `ref`; the `attempt` field.
- **Returns:** The widget tree for the current state; an empty box when the level cannot be parsed,
  the files are not loaded, or nothing was missed.
- **Side effects:** Reads the drill assets through `drillLevelProvider`.
- **Algorithm:** Parse the attempt's level, watch the level's drill files, index every question in
  them by id, then take the answers that are not 1, sorted by question id. Each one renders its
  wrong/unanswered label, the question's Japanese (with reading, unless the question type hides it)
  or its prompt, the correct option, and the explanation when there is one.
- **Usage:** `_AttemptTile.build`, as the expanded child.
- **Notes:** Keep this method cheap because Flutter may call it often. Only the answers were stored,
  so the question text, its options and its explanation are all read from the content files now. That
  is the point of storing only the input: a content update that corrected an answer key corrects the
  history with it, rather than leaving a frozen copy the app no longer agrees with. A question the
  shipped files no longer have says so in one line — content is rewritten between releases, and an
  attempt that quietly lost three of its rows would be a worse record than one that admits it.
  Nothing at all is shown while the files load, rather than a spinner: an `ExpansionTile` builds its
  children before they are ever shown, so a spinner here would run — invisibly — behind every
  collapsed row in the list, and the wait is a few milliseconds of reading four small files.
