# lib/shared/services/sync_merge.dart

The app-specific half of the merge. It re-exports the package's generic `mergeRecords`,
`RecordConflict` and `RecordMergeResult`, and defines `ProgressMergeResult` (merged records,
conflicts, top-level `extraJson`, and a resolver) plus `mergeProgressData`, which parses the three
JSON strings, runs `mergeRecords<StudyRecord>`, and re-attaches unknown JSON from both sides. See
[../../../sync.md](../../../sync.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `ProgressMergeResult.new` | constructor | B | Create a progress merge result instance. |
| `ProgressMergeResult.hasConflicts` | getter | B | Report whether any record needs a manual decision. |
| [`ProgressMergeResult.buildResolved`](#buildresolved) | method | A | Build the final merged dataset from conflict resolutions. |
| [`mergeProgressData`](#mergeprogressdata) | top-level function | A | Merge local, remote, and base progress JSON into one conflict-aware result. |

## Documentation

### `ProgressData buildResolved(Map<String, StudyRecord> resolutions)` <a id="buildresolved"></a>

- **Kind:** method of `ProgressMergeResult`
- **Purpose:** Assemble the file to write after the user has decided each conflict.
- **Inputs:** `resolutions` — conflicting record id → the chosen record.
- **Returns:** `ProgressData` with the merged records plus one record per conflict.
- **Side effects:** None.
- **Algorithm:** Start from `merged`; for each conflict take `resolutions[id] ?? localRecord`, then
  `withPreservedUnknownJson([local, remote])`; wrap with the merge's `extraJson`.
- **Usage:** `mergeProgressModule`'s `buildResolvedJson`; the tests.
- **Notes:** A conflict without a resolution keeps the local record, the same fallback the sibling
  apps use.

### `ProgressMergeResult mergeProgressData(String localJson, String remoteJson, String? baseJson, {bool autoResolve = false})` <a id="mergeprogressdata"></a>

- **Kind:** top-level function
- **Purpose:** The app's record merge.
- **Inputs:** The three JSON strings (`baseJson` null on a first sync) and `autoResolve`, false at
  every production call site.
- **Returns:** `ProgressMergeResult`.
- **Side effects:** None.
- **Algorithm:**
  1. Parse each string as `ProgressData`.
  2. `mergeRecords<StudyRecord>(getId: id, getModifiedAt: modifiedAt, getDisplayName: id,
     serialize: jsonEncode(toJson()))` — the package decides per record: one side changed → take
     it; deleted on one side, untouched on the other → delete; changed on both since the base →
     conflict, unless `serialize` shows identical content.
  3. Every merged record gets `withPreservedUnknownJson([local copy, remote copy])`.
  4. The container's `extraJson` is the local file's, preserved against the remote's.
- **Usage:** `mergeProgressModule` in `data_modules.dart`.
- **Notes:** The display name is the id because it is the stable, nonlocalized label; the conflict
  dialog resolves it through the catalog for display.
