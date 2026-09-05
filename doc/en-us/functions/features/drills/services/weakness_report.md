# lib/features/drills/services/weakness_report.dart

Says what the learner is worst at, from the papers they have actually sat.

Pure, and **derived rather than stored**. A weakness written down once would be a verdict the learner
could not shake off; recomputing it from the last few attempts is what makes practice able to move
it, which is the only reason a report like this is worth showing at all.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | Say what a learner is worst at, from the papers they have sat. |
| `weaknessRecentAttempts` | constant | B | How many recent attempts the report looks at. |
| `weaknessMinAsked` | constant | B | How many times something must be asked before it is a weakness. |
| `weaknessMaxPoints` | constant | B | How many weak points the report names. |
| `WeaknessTally` | class | B | One thing that was asked, and how it went. |
| `WeaknessTally.plus` | method | B | Add one result. |
| `WeaknessReport` | class | B | What the learner is worst at, over their recent attempts. |
| [`weakestItems`](#weakestitems) | getter | A | The weakest catalog items, worst first. |
| `weakestTypes` | getter | B | The weakest 大問, worst first. |
| [`build`](#build) | static method | A | Build the report from what the learner has sat. |
| [`prioritizedIds`](#prioritizedids) | method | A | Name the ids worth pushing to the front of the review queue. |

## Documentation

### `List<MapEntry<String, WeaknessTally>> get weakestItems` <a id="weakestitems"></a>

- **Kind:** getter
- **Purpose:** The weakest catalog items, worst first.
- **Inputs:** None beyond the receiver.
- **Returns:** At most `weaknessMaxPoints` entries.
- **Side effects:** None.
- **Algorithm:** Keep the items asked at least `weaknessMinAsked` times and got wrong at least once,
  sort by accuracy ascending, break ties on the id, take the first ten.
- **Usage:** The weakness page, the three chips on the Learn card, and `prioritizedIds`.
- **Notes:** **A run of perfect answers is not a weakness however few of them there were**, so the
  "got wrong at least once" filter is not an optimization — without it a word answered right three
  times out of three would sit at the top of a list of things to go and study. Ties break on the id
  so the order is total: two items with the same accuracy cannot swap places between builds, which
  would make the page appear to change when nothing had.

### `static WeaknessReport build({required List<ExamAttempt> attempts, required Map<String, DrillQuestion> questions, String? level, int recent = weaknessRecentAttempts})` <a id="build"></a>

- **Kind:** static method
- **Purpose:** Build the report from what the learner has sat.
- **Inputs:** `attempts`, newest first; every shipped drill `question` by id; the `level` to report
  on, or null for every level; `recent` — how many attempts to look at.
- **Returns:** `WeaknessReport`; `empty` when nothing qualifies.
- **Side effects:** None.
- **Algorithm:** Filter to the level, take the most recent `recent`, then for every answered question
  add one result to the section tally, the type tally and each of the question's item tallies.
- **Usage:** `weaknessReportProvider`.
- **Notes:** Three rules do the work.

  **The join happens here rather than being stored.** An attempt keeps only which questions were
  asked and what was answered; which section, which 大問 and which catalog items are read from the
  shipped files now — so a content correction reaches the report as well as the history.

  **A question the files no longer have is skipped**, not counted under nothing. That is one fewer
  data point, which is the honest cost; counting it would put a weakness against a 大問 the app can
  no longer name.

  **An unanswered question does not count at all.** The clock took it away, and a report that read a
  time-out as a gap in the learner's Japanese would send them to study the wrong thing.

### `Set<String> prioritizedIds(ContentCatalog? catalog)` <a id="prioritizedids"></a>

- **Kind:** method
- **Purpose:** Name the catalog ids worth pushing to the front of the review queue.
- **Inputs:** The `catalog`, so an id no longer shipped is not prioritized.
- **Returns:** `Set<String>`.
- **Side effects:** None.
- **Algorithm:** The `weakestItems` ids, filtered to those the catalog still has.
- **Usage:** `reviewQueueProvider`, into `ReviewQueue.build(prioritized:)`.
- **Notes:** The queue orders by this **before** it orders by how overdue something is. A word the
  learner keeps getting wrong on a paper is a better use of the next five minutes than a word whose
  interval merely happens to have elapsed. It only reorders: nothing is added to the queue and
  nothing is removed from it, so a report that is empty — or still loading — costs the learner the
  old ordering and nothing else.
