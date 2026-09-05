# lib/features/learn/widgets/study_calendar.dart

The days a learner answered something, as a twelve-week grid on the Learn tab.

Derived from the records and never stored, like the daily counts and the unit progress bars: a day
counts as studied when a record was created or last reviewed on it. That is coarser than counting
answers — a day's second answer to the same word leaves no separate trace — and it is the honest
limit of what the progress file remembers.

Consumers: `learn_page.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `calendarWeeks` | top-level constant | B | How many weeks the calendar shows — twelve, long enough that a habit is visible and a gap is obvious, short enough to fit a phone at a legible square size. |
| `StudyCalendar` | class | B | The days a learner answered something, as a grid. |
| [`build`](#build) | method | A | Build the grid. |
| `_cell` | method | B | Draw one day; a future day is drawn faintly rather than left blank, so the grid keeps its shape to the end of the week. |
| [`studiedDays`](#studieddays) | top-level function | A | Find the local days on which anything was answered. |

## Documentation

### `Widget build(BuildContext context, WidgetRef ref)` <a id="build"></a>

- **Kind:** method
- **Purpose:** Build the grid.
- **Inputs:** `context`, `ref`.
- **Returns:** `Widget`; an empty box while the progress file is loading.
- **Side effects:** None beyond building widgets.
- **Algorithm:** Read the studied days, find the Monday `calendarWeeks - 1` weeks back, then lay out
  one column per week of seven `_cell`s, sizing the cell from the available width clamped to 6–18
  logical pixels. A summary line reports how many days are filled.
- **Usage:** `learn_page.dart`.
- **Notes:** One column per week, oldest on the left, with today in the last column — so the shape a
  learner recognises is the right-hand edge. A day with nothing on it is drawn, not skipped: the gaps
  are the information.

### `Set<String> studiedDays(ProgressData progress)` <a id="studieddays"></a>

- **Kind:** top-level function
- **Purpose:** Find the local days on which anything was answered.
- **Inputs:** The learner's `progress`.
- **Returns:** `Set<String>` of `YYYY-MM-DD` keys.
- **Side effects:** None.
- **Algorithm:** For every record that is not a profile or history record, take the local date of
  `createdAt` and, when set, of `lastReviewedAt`.
- **Usage:** `build`, and the summary count beneath the grid.
- **Notes:** A record's `lastReviewedAt` is when it was last answered and its `createdAt` is when it
  was first answered, because **a record is created by its first answer**. Both count, so the day
  somebody started a word shows up even after they have reviewed it since. The profile record is
  skipped: it is written once a day by the streak and would mark days nothing was studied on. The
  sentence history is skipped for the same reason — looking a sentence up is not answering anything,
  and a calendar that filled in on the strength of it would overstate what the learner did. An
  **exam attempt does** count: its `createdAt` is the moment it was recorded, which is the moment the
  learner finished sitting a paper — the clearest case there is of a day something was studied.
