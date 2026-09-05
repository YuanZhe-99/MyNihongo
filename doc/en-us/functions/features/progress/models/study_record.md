# lib/features/progress/models/study_record.dart

The synced learning-progress model: `StudyRecord` (one per studied item — id, counters, SM-2 state,
UTC timestamps, preserved unknown JSON) and `ProgressData` (the `{records: [...]}` container written
to `nihongo_progress.json`). The kind of a record (`StudyKind`) is derived from its id prefix, and
its stage (`StudyStage`) from its review state; neither is stored. The file also holds the private
JSON helpers the pattern needs and the constants `defaultStudyEase` (2.5) and
`masteredIntervalDays` (21). See [../../../../data-formats.md](../../../../data-formats.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | The synced learning-progress model — one record per studied item, and the container written to disk. |
| [`studyKindOf`](#studykindof) | top-level function | A | Derive the catalog a record id belongs to from its prefix; `other` for an unknown prefix. |
| `_unknownJson` | top-level function | B | Collect the JSON keys this build does not model. |
| `_stringKeyedMap` | top-level function | B | Coerce a dynamically keyed map to string keys. |
| `_mergeJsonMaps` | top-level function | B | Deep-merge several unknown-field maps, later sources winning; nested maps merge key by key. |
| `_parseUtc` | top-level function | B | Parse an ISO-8601 timestamp into a UTC `DateTime`; null when not a parseable string. |
| `_parseInt` | top-level function | B | Parse an integer counter, accepting a whole `double`. |
| `_parseDouble` | top-level function | B | Parse a floating-point field. |
| `StudyRecord.new` | constructor | B | Create a study record instance from UTC timestamps and fields. |
| `StudyRecord.create` | factory constructor | B | Create a fresh record for an item never studied, both timestamps set to now (or `now`). |
| `StudyRecord.kind` | getter | B | Report which catalog this record belongs to, via `studyKindOf`. |
| `StudyRecord.reviews` | getter | B | Report how many times the item has been answered. |
| `StudyRecord.accuracy` | getter | B | Report the share of correct answers; 0 before the first review. |
| `StudyRecord.stage` | getter | B | Derive fresh / learning / mastered from `lastReviewedAt` and `intervalDays`. |
| [`StudyRecord.fromJson`](#fromjson) | factory constructor | A | Parse a record, preserving what this build cannot read. |
| [`StudyRecord.toJson`](#tojson) | method | A | Serialize the record, unknown fields included. |
| [`StudyRecord.copyWith`](#copywith) | method | A | Create a copy with selected fields replaced; `modifiedAt` defaults to now. |
| [`StudyRecord.withPreservedUnknownJson`](#withpreservedunknownjson) | method | A | Merge unknown JSON fields from other copies of this record. |
| `ProgressData.new` | constructor | B | Create a progress data instance. |
| `ProgressData.fromJson` | factory constructor | B | Parse the container; non-object entries of `records` are skipped, a non-list `records` is treated as empty. |
| `ProgressData.toJson` | method | B | Serialize the container, unknown fields included. |
| `ProgressData.recordById` | method | B | Look a record up by id (linear). |
| `ProgressData.withPreservedUnknownJson` | method | B | Merge top-level unknown fields from other copies of the file. |

## Documentation

### `StudyKind studyKindOf(String id)` <a id="studykindof"></a>

- **Kind:** top-level function
- **Purpose:** Derive the catalog a record id belongs to.
- **Inputs:** `id` — `kana:あ`, `vocab:watashi`, `grammar:desu`, `lab:<hash>`, `exam:<stamp>-<suffix>`, …
- **Returns:** `kana`, `vocab`, `grammar`, `profile`, `lesson`, `history`, `exam`, or `other`.
- **Side effects:** None.
- **Algorithm:** Take the substring before the first `:` (the whole id when there is none) and
  switch on it.
- **Usage:** `StudyRecord.kind`; `ExamAttempt.fromRecord`; the content test asserts every catalog id
  maps to its kind.
- **Notes:** The kind is not stored on purpose: deriving it leaves nothing to fall out of step with
  the id, and a record from a newer build with a new prefix loads as `other` and still merges. Both
  `lab:` and `writing:` map to the one `history` kind: the two pages keep separate lists, but nothing
  that switches on the kind needs to tell them apart. `exam:` gets its own kind because an attempt is
  a different shape of thing from a remembered sentence and the code that reads one must not read the
  other. `studiedKinds` is deliberately **unchanged** by that addition — it is still kana, vocabulary
  and grammar, so the profile, the lesson results, the history and now the exam attempts are all
  outside the review queue and outside any count of items tracked. A sitting of a paper is work the
  learner did, not an item to schedule.

### `factory StudyRecord.fromJson(Map<String, dynamic> json)` <a id="fromjson"></a>

- **Kind:** factory constructor
- **Purpose:** Parse a record, preserving what this build cannot read.
- **Inputs:** `json` — one element of `records`.
- **Returns:** A `StudyRecord`.
- **Side effects:** None.
- **Algorithm:**
  1. `extra = _unknownJson(json, knownKeys)`.
  2. Each typed field is read through a local `read(key, parse, {preserveOnFailure})`: null when
     absent; when present but unparseable, null — and for the nullable fields `dueAt` and
     `lastReviewedAt` the raw value is placed in `extra` under its key.
  3. Counters default to 0, `ease` to `defaultStudyEase`; `createdAt`/`modifiedAt` fall back to each
     other and then to the Unix epoch.
- **Usage:** `ProgressData.fromJson`, and every merge and validation path through it.
- **Notes:** A counter or SRS field that fails to parse takes its default and is written back as
  that default — a typed value and a raw one cannot share a key. A record without `modifiedAt` gets
  the epoch so it loses every merge rather than winning by accident.

### `Map<String, dynamic> toJson()` <a id="tojson"></a>

- **Kind:** method of `StudyRecord`
- **Purpose:** Serialize the record for `jsonEncode`.
- **Inputs:** None.
- **Returns:** A map starting from `extraJson` with the known fields overlaid.
- **Side effects:** None.
- **Algorithm:** Copy `extraJson`; set `id`, counters, `intervalDays`, `ease`; set `dueAt` and
  `lastReviewedAt` only when non-null (as ISO-8601 UTC); set `createdAt` and `modifiedAt`.
- **Usage:** `ProgressData.toJson`; `mergeProgressData`'s `serialize` for content comparison.
- **Notes:** Because the overlay comes last, a preserved unknown key can never shadow a real one; a
  nullable field that is null leaves its key as `extraJson` has it, so a raw value `fromJson` could
  not parse survives.

### `StudyRecord copyWith({...})` <a id="copywith"></a>

- **Kind:** method of `StudyRecord`
- **Purpose:** Create a copy with selected fields replaced.
- **Inputs:** Any of the mutable fields; `modifiedAt`.
- **Returns:** A new record with the same `id` and `createdAt`.
- **Side effects:** None.
- **Algorithm:** `??` per field; `modifiedAt` is `(modifiedAt ?? DateTime.now()).toUtc()`.
- **Usage:** The review engine's `recordAnswer` (Phase 3) and the tests.
- **Notes:** The `modifiedAt` default is what makes every edit visible to the sync merge. Pass the
  existing value explicitly for a change that must not count as an edit.

### `StudyRecord withPreservedUnknownJson(Iterable<StudyRecord?> sources)` <a id="withpreservedunknownjson"></a>

- **Kind:** method of `StudyRecord`
- **Purpose:** Carry unknown fields from other copies of this record through a merge.
- **Inputs:** `sources` — usually the local and remote copies; nulls are skipped.
- **Returns:** The same record with `extraJson` replaced by the union.
- **Side effects:** None.
- **Algorithm:** `_mergeJsonMaps([...sources' extraJson, this.extraJson])` — this record's own
  values win on a clash, nested maps merge key by key.
- **Usage:** `mergeProgressData` on every merged record; `ProgressMergeResult.buildResolved` on
  every chosen record.
- **Notes:** This is how a field unknown to this build, present on either side of a merge,
  survives the merge.
