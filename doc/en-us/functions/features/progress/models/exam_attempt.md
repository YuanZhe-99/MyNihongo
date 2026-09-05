# lib/features/progress/models/exam_attempt.dart

One sitting of a JLPT paper, modelled as a record inside the progress file, so an attempt made on one
device is in the history on another.

Stored as ordinary `StudyRecord`s under `exam:<timestamp>-<suffix>` ids with the payload in the
record's `extraJson` — a record rather than a second data module, for the reason the learner profile
and the sentence history are records: a record gets the per-record three-way merge, the conflict
dialog, sync and backup for free, while a second module means a second remote file, a second backup
entry and eleven golden transcripts re-recorded.

**Only the input is stored.** Which questions were asked and what was answered — never the score of
each, never the question text. Everything a results screen shows is joined back from the shipped
files at read time, so a content update that corrected an answer key corrects the history too rather
than leaving a score the files no longer agree with.

The section keys are plain strings so `progress/` does not import `drills/`; a section this build has
no enum for still round-trips.

Consumers: `NihongoStorage.recordExam`, `examAttemptsProvider` and `askedQuestionsProvider`,
`ExamHistoryPage`, `resolveStudyItemLabel` and the conflict dialog.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | The JLPT attempts that ride in the progress file. |
| `examMaxMockEntries` | top-level constant | B | How many mock attempts are kept (40) — lower than the practice cap because a mock is the heavier record and the thing a learner looks back at is the trend. |
| `examMaxPracticeEntries` | top-level constant | B | How many practice attempts are kept (80). |
| `examUnanswered` | top-level constant | B | The answer value (-1) for a question the clock ran out on — neither right nor wrong. |
| `_examPayloadKey` | private constant | B | The `extraJson` key the payload lives under. |
| `ExamMode` | enum | B | Whether an attempt was untimed practice or a timed mock; the name is written into the payload. |
| `ExamSectionResult` | class | B | One section's tally and its clock. |
| `ExamSectionResult.new` | constructor | B | Hold one section's `asked`/`right`, and `seconds`/`limitSeconds` where the section was timed. |
| `ExamSectionResult.accuracy` | getter | B | Accuracy from 0 to 1; 0 for a section with nothing in it. |
| `ExamSectionResult.fromJson` | static method | B | Read one section out of the payload; null for anything unreadable. |
| `ExamSectionResult.toJson` | method | B | Write one section into the payload, omitting the clock keys where the section was untimed. |
| `ExamAttempt` | class | B | One sitting of a paper. |
| `ExamAttempt.new` | constructor | B | Describe one attempt — id, level, mode, scale, timestamps, sections and answers. |
| `asked`, `right`, `accuracy` | getters | B | Fold the section tallies into paper-wide totals. |
| [`buildId`](#buildid) | static method | A | Derive the id for a new attempt. |
| [`fromRecord`](#fromrecord) | static method | A | Read an attempt out of a progress record. |
| [`toRecord`](#torecord) | method | A | Write the attempt back into its record. |
| [`examAttempts`](#examattempts) | top-level function | A | Collect the attempts out of the progress file, newest first. |
| `_int`, `_time` | private functions | B | Read a JSON value as an integer or a UTC timestamp. |

## Documentation

### `static String buildId(DateTime startedAt, String suffix)` <a id="buildid"></a>

- **Kind:** static method
- **Purpose:** Build the record id for a new attempt.
- **Inputs:** `startedAt`, and `suffix` — four hex digits.
- **Returns:** `String` — `exam:20260904T101500Z-3f2a`.
- **Side effects:** None.
- **Algorithm:** Take `startedAt` in UTC and format it as a compact basic-format stamp with
  zero-padded fields, then append the suffix.
- **Usage:** The quiz page when it records an attempt.
- **Notes:** The timestamp sorts the ids the way the attempts happened, which makes a file diff
  readable and means an id is self-describing in a bug report. The suffix is what keeps two attempts
  started in the same second on two devices from merging into one — unlike the sentence history, two
  sittings of the same paper are genuinely two things and must not collapse into one record.

### `static ExamAttempt? fromRecord(StudyRecord? record)` <a id="fromrecord"></a>

- **Kind:** static method
- **Purpose:** Read an attempt out of a progress record.
- **Inputs:** `record`, or null.
- **Returns:** `ExamAttempt?` — null when the record is not an exam record or its payload cannot be
  read.
- **Side effects:** None.
- **Algorithm:** Refuse anything whose id is not `StudyKind.exam`, read the `exam` map out of
  `extraJson`, and refuse a payload with no level. `mode` is `mock` only for the exact string
  `mock`; `scale` defaults to `short`; `startedAt` falls back to the record's `createdAt`; the
  sections and answers are read entry by entry, dropping any that will not parse.
- **Usage:** `examAttempts`, and through it every consumer of the history.
- **Notes:** Never throws, and every field is read independently, so a payload written by a newer
  build still loads with the fields this one knows. A section this build has no enum for keeps its
  string key and round-trips.

### `StudyRecord toRecord(StudyRecord? existing, DateTime now)` <a id="torecord"></a>

- **Kind:** method
- **Purpose:** Write the attempt back into its record.
- **Inputs:** The `existing` record already in the file, if any, and `now`.
- **Returns:** `StudyRecord` ready for `upsertRecords`.
- **Side effects:** None.
- **Algorithm:** Rebuild the payload starting from whatever was there, write the known fields over
  it (`v`, level, mode name, scale, the timestamps, the serialized sections and the answer map), keep
  the rest of `extraJson`, and `copyWith` the totals and `modifiedAt`.
- **Usage:** `NihongoStorage.recordExam`.
- **Notes:** Unknown payload keys are preserved, the rule every record in this file follows: an older
  build must not drop a newer one's fields the first time it touches a record. `correct` and `wrong`
  carry the paper's totals even though the payload holds them too — they are what an older build's
  conflict dialog reads, and an attempt showing "0 / 0" there would be telling that build something
  false about a record it cannot otherwise interpret. `finishedAt` is written only when set.

### `List<ExamAttempt> examAttempts(Iterable<StudyRecord> records, {String? level, ExamMode? mode})` <a id="examattempts"></a>

- **Kind:** top-level function
- **Purpose:** Collect the exam attempts out of the progress file, newest first.
- **Inputs:** The `records`; `level` and `mode` to narrow the list.
- **Returns:** `List<ExamAttempt>`, newest first.
- **Side effects:** None.
- **Algorithm:** Parse every record that reads as an attempt, drop the ones the filters exclude, then
  sort by `startedAt` descending with the id as a tie-break.
- **Usage:** `examAttemptsProvider`, and `NihongoStorage.recordExam` when it prunes.
- **Notes:** The tie-break makes the order total, so two attempts started in the same second cannot
  swap places between builds — which matters because the prune drops from the end of this list. A
  null `level` or `mode` is the unfiltered list, not "attempts belonging to no level".
