# lib/features/progress/models/history_entry.dart

The sentence lab's and writing practice's history: what was typed, when, and for which lesson unit.

Stored as ordinary `StudyRecord`s under `lab:<hash>` and `writing:<hash>` ids, with the payload in
the record's `extraJson` — the same shape the learner profile uses, and for the same reasons.
[`../../../../data-formats.md`](../../../../data-formats.md) explains the shape, the
content-addressed id and the hundred-entry cap.

**Only the input is stored.** The analysis is recomputed from the text and the shipped catalog, and
nothing a model generated is ever written here.

Consumers: `NihongoStorage.recordHistory`, `labHistoryProvider` and `writingHistoryProvider`,
`HistoryList`, the sentence lab and writing practice pages, `resolveStudyItemLabel` and the conflict
dialog.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | The remembered sentences that ride in the progress file. |
| `HistoryKind` | enum | B | Which page an entry came from, and its record-id prefix. |
| `historyMaxEntries` | top-level constant | B | How many entries of one kind are kept. |
| `HistoryEntry` | class | B | One remembered sentence or piece of writing. |
| [`buildId`](#buildid) | static method | A | Derive the content-addressed record id. |
| `normalizeText` | static method | B | Trim and collapse whitespace before hashing or storing. |
| [`fromRecord`](#fromrecord) | static method | A | Read an entry out of a progress record. |
| `kindOf` | static method | B | Report which page a record id belongs to. |
| [`toRecord`](#torecord) | method | A | Write the entry back into its record. |
| `forInput` | static method | B | Build an entry for text the learner just submitted. |
| [`historyEntries`](#historyentries) | top-level function | A | Collect one kind of history, newest first. |
| `_fnv1a64Hex`, `_fnv1a32`, `_fnvPrime` | private functions | B | Hash a string to 16 hex digits. |

## Documentation

### `static String buildId(HistoryKind kind, String text, {String? unitId})` <a id="buildid"></a>

- **Kind:** static method
- **Purpose:** Build the record id for one entry.
- **Inputs:** The `kind`, the `text`, and the `unitId` when there is one.
- **Returns:** `String` — `<prefix>:<16 hex digits>`.
- **Side effects:** None.
- **Algorithm:** Join the unit id and the whitespace-normalized text with a newline, hash with two
  FNV-1a 32-bit lanes that differ only in their offset basis, and concatenate them as hex.
- **Usage:** `forInput`, and any caller that needs to find an existing entry for some text.
- **Notes:** Content-addressed rather than random, which buys three things. Analysing the same
  sentence twice updates one record and moves it to the top instead of filling the history with
  duplicates; two devices that analysed the same sentence produce the same id and merge into one
  entry rather than conflicting; and the same sentence written for two exercises stays two pieces of
  work, because the unit is part of the key. Normalizing first is what stops a stray space making a
  second entry. The hash is a de-duplication key, not a security primitive: a collision costs one
  entry shadowing another.

### `static HistoryEntry? fromRecord(StudyRecord? record)` <a id="fromrecord"></a>

- **Kind:** static method
- **Purpose:** Read an entry out of a progress record.
- **Inputs:** `record`, or null.
- **Returns:** `HistoryEntry?` — null when the record is not a history record or its payload cannot
  be read.
- **Side effects:** None.
- **Algorithm:** Match the id prefix, read the `history` map out of `extraJson`, and take `text` and
  `unitId` independently. `at` is the record's `modifiedAt`.
- **Usage:** `historyEntries`, the conflict dialog, `resolveStudyItemLabel`.
- **Notes:** Never throws. A payload written by a newer build with fields this one cannot read still
  loads, because every field is read on its own. An entry whose text is missing or blank is refused
  rather than shown as a blank row the learner cannot identify.

### `StudyRecord toRecord(StudyRecord? existing, DateTime now)` <a id="torecord"></a>

- **Kind:** method
- **Purpose:** Write the entry back into its record.
- **Inputs:** The `existing` record if there is one, and `now`.
- **Returns:** `StudyRecord` ready for an upsert.
- **Side effects:** None.
- **Algorithm:** Rebuild the payload from whatever was there, write the known fields over it, and
  keep the rest of `extraJson`. `modifiedAt` becomes `now`, which is what moves the entry to the top.
- **Usage:** `NihongoStorage.recordHistory`.
- **Notes:** Unknown payload keys are preserved, the same rule the profile follows: an older build
  must not drop a newer one's fields on the first edit. The counters stay at zero — a remembered
  sentence is not something anybody answered, and `studyRecords` excludes it for that reason.

### `List<HistoryEntry> historyEntries(Iterable<StudyRecord> records, {required HistoryKind kind, String? unitId})` <a id="historyentries"></a>

- **Kind:** top-level function
- **Purpose:** Collect one kind of history out of the progress file.
- **Inputs:** The `records`, the `kind` wanted, and `unitId` to narrow a writing history to one
  exercise.
- **Returns:** `List<HistoryEntry>`, newest first.
- **Side effects:** None.
- **Algorithm:** Read every record that parses as an entry of that kind, then sort by `modifiedAt`
  descending with the id as a tie-break.
- **Usage:** The two providers, and `NihongoStorage.recordHistory` when it prunes.
- **Notes:** The tie-break makes the order total, so two entries written in the same millisecond
  cannot swap places between builds — which matters because the prune drops from the end of this
  list. A null `unitId` is the unfiltered list, not "entries belonging to no unit".
