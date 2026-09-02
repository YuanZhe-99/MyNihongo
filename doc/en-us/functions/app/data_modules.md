# lib/app/data_modules.dart

The seam between this app and the shared `myapps_data` engines, and the **single source of truth**
for the persisted compatibility contract: the data-file name `nihongo_progress.json`, the backup
module id `progress`, the default remote path `/MyNihongo`, and the ZIP archive prefix
`mynihongo_export_`. It declares `NihongoStorageAdapter` (a `StorageAdapter` over
`NihongoStorage`), the validation, encoding and merge callbacks for the progress module, and
`nihongoModuleRegistry`, the ordered registry every facade is built on. See
[../../architecture.md](../../architecture.md) and [../../sync.md](../../sync.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | Describe MyNihongo's syncable data files to the shared engines, once. |
| `NihongoStorageAdapter` | class doc | B | Bridge the shared engines to MyNihongo's storage hub. |
| `NihongoStorageAdapter.new` | constructor | B | Create an adapter over `NihongoStorage`, with an optional `appDir` resolver for test seams. |
| `NihongoStorageAdapter.getAppDir` | method override | B | Resolve the active app data directory, honoring the injected resolver first. |
| `NihongoStorageAdapter.readConfig` | method override | B | Read `storage_config.json` through the hub. |
| `NihongoStorageAdapter.writeConfig` | method override | B | Persist `storage_config.json` through the hub. |
| `validateProgressJson` | top-level function | B | Validate a `nihongo_progress.json` payload before it is written; throws when unparseable. |
| `encodeProgressData` | top-level function | B | Encode a merged dataset with the two-space indentation the storage hub uses. |
| [`mergeProgressModule`](#mergeprogressmodule) | top-level function | A | Merge local/remote/base progress JSON for the shared sync engine, carrying the typed result as opaque state. |
| `buildProgressModule` | top-level function | B | Describe `nihongo_progress.json` to the shared engines as a `DataModule`. |
| `nihongoModuleRegistry` | top-level `final` | B | Provide MyNihongo's ordered module registry, holding the single progress module. |

## Documentation

### `ModuleMergeOutcome mergeProgressModule({...})` <a id="mergeprogressmodule"></a>

- **Kind:** top-level function
- **Source:** `lib/app/data_modules.dart`
- **Purpose:** Adapt the app-typed `mergeProgressData` to the engine's app-neutral
  `ModuleMergeOutcome`.
- **Inputs:** `localJson`, `remoteJson`, `baseJson` (nullable), `autoResolve` (false in production).
- **Returns:** A complete outcome with `mergedJson` when there are no conflicts; otherwise a pending
  outcome with `ModuleConflict`s and a `buildResolvedJson` callback.
- **Side effects:** None.
- **Algorithm:**
  1. Call `mergeProgressData`.
  2. No conflicts: encode `ProgressData(records: merged, extraJson: extraJson)` with
     `encodeProgressData` and return it with the typed result as `state`.
  3. Conflicts: map each `RecordConflict<StudyRecord>` to a `ModuleConflict` (id, both records,
     display name), and supply a resolver that filters the engine's `Map<String, Object?>` down to
     `StudyRecord` values and encodes `result.buildResolved(...)`.
- **Usage:** Registered as the `merge` callback in `buildProgressModule`; invoked by the engine only
  when local and remote strings differ.
- **Notes:** The `state` is what lets `WebDAVService._toSyncResult` hand the conflict dialog real
  `StudyRecord`s without the package knowing the type.
