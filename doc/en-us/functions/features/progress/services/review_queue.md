# lib/features/progress/services/review_queue.dart

What to study now: which items are due, and which new ones today's allowance still has room for.
Pure, like the scheduler beside it, so the policy is testable without a device.

Derived in [`../../../../algorithms/spaced-repetition.md`](../../../../algorithms/spaced-repetition.md).

Consumers: `reviewQueueProvider`, and through it the Learn tab's today card.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | Decide what to study now. |
| `_newItemOrder` | top-level constant | B | The kinds new items are introduced from, in order. |
| `ReviewQueue` | class | B | One computed queue. |
| `isEmpty` | getter | B | Whether there is anything at all to do right now. |
| `reviewLimitReached` | getter | B | Whether the day's allowance is used up while items remain due. |
| [`isDue`](#isdue) | static method | A | Decide whether a record is due. |
| [`build`](#build) | static method | A | Build the queue for right now. |
| `_newItems` | static method | B | Choose the next unstudied catalog items; the switch over `StudyKind` breaks on `profile`, `lesson`, `history`, `exam` and `other`. |
| `_dayOf` | static method | B | Reduce an instant to its calendar day. |

## Documentation

### `static bool isDue(StudyRecord record, DateTime now)` <a id="isdue"></a>

- **Kind:** static method
- **Purpose:** Decide whether a record is due.
- **Inputs:** The `record`; `now` in local time.
- **Returns:** `bool`.
- **Side effects:** None.
- **Algorithm:** A record with no `dueAt` has never been reviewed and is not a review. Otherwise
  compare **calendar days** in local time, not instants.
- **Usage:** `build`, and the widget tests that pin the boundary.
- **Notes:** The two-part rule matters. `dueAt` is stored as a plain UTC instant so it compares
  identically on every device and needs no timezone arithmetic on disk. But a learner expects
  anything due today to be available all day, and their "today" is their own — so an item due at
  23:00 is due from midnight. The scheduler stores instants; the queue reads days.

### `static ReviewQueue build({required ProgressData progress, required ContentCatalog catalog, required LearnerProfile profile, required DateTime now, Set<StudyKind> kinds, Set<String> prioritized})` <a id="build"></a>

- **Kind:** static method
- **Purpose:** Build the queue for right now.
- **Inputs:** The progress file, the catalog, the learner profile, local `now`, which kinds may
  supply new items, and `prioritized` — the ids the weakness report says to put first.
- **Returns:** `ReviewQueue`.
- **Side effects:** None.
- **Algorithm:**
  1. One pass over `progress.studyRecords` collecting three things: which ids are already studied,
     how many reviews and new items today has already seen, and which records are due.
  2. Sort the due list: prioritized ids first, then `dueAt` ascending — most overdue first.
  3. Subtract today's counts from the profile's limits to get the remaining allowances.
  4. Take that many due records, and fill the new-item list from the catalog.
- **Usage:** `reviewQueueProvider`.
- **Notes:** **Today's counts are derived, never stored.** A review answered today is a record whose
  `lastReviewedAt` falls on today's local date; a new item started today is a record `createdAt`
  today, which works because a record is created by its first answer. A stored per-day counter would
  need resetting at midnight, would add a field two devices can disagree about, and would miss work
  synced in from another device — which a shared daily goal must not. `overdueTotal` is reported
  separately from `due.length` so the UI can say "20 of 300 today" rather than pretending the backlog
  is smaller than it is.

  **`prioritized` reorders the queue and nothing else.** A word the learner keeps getting wrong on a
  JLPT paper is a better use of the next five minutes than a word whose interval merely happens to
  have elapsed — and within each group the longest-forgotten item is the one whose recall is decaying
  fastest, so a learner who stops halfway has spent the time well either way. Nothing is added to the
  queue and nothing is removed, so an empty set — no attempts yet, or a report whose files have not
  loaded — is exactly the old sort.

  `_newItems` switches exhaustively over `StudyKind`, so every kind that is not a catalog item has to
  name itself and break. `exam` is one of them: an attempt is a record of something that happened,
  not an item anybody studies, and it never enters the queue — the questions it asked already moved
  their own items' intervals as they were answered. Exhaustiveness is the point of the switch; a new
  kind is a compile error rather than a silent entry in the queue.
