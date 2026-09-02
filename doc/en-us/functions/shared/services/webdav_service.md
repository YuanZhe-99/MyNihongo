# lib/shared/services/webdav_service.dart

`WebDAVService` is a static facade over the shared `WebDavSyncEngine`, built once on the app's
storage adapter, module registry and default remote path `/MyNihongo`. It exposes the engine's
progress notifier and the sync, force, config and connection-test operations, converting engine
results to the app-typed `SyncResult` and `PendingSync` (which carries a `ProgressMergeResult`).
It re-exports `WebDAVConfig`, `WebDAVUploadLock`, `RemoteFile` and `RemoteFileStatus`. The shape
mirrors MyAnime's facade so its WebDAV page and conflict dialog port with the type names unchanged.
See [../../../sync.md](../../../sync.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | MyNihongo's WebDAV sync API, a thin facade over the shared engine. |
| `SyncResult.new` | constructor | B | Create a sync result instance. |
| `SyncResult.hasConflicts` | getter | B | Report whether the result carries unresolved conflicts. |
| `PendingSync.new` | constructor | B | Create a pending sync instance. |
| `PendingSync.allConflicts` | getter | B | List every record conflict across modules (one module today). |
| `WebDAVService.consumeLocalDataChanged` | static method | B | Read and clear the "local data changed" signal. |
| `WebDAVService.loadConfig` | static method | B | Load the saved WebDAV configuration; null when absent or unreadable. |
| `WebDAVService.saveConfig` | static method | B | Save the WebDAV configuration atomically. |
| `WebDAVService.deleteConfig` | static method | B | Delete the saved WebDAV configuration, leaving base snapshots and the client id. |
| `WebDAVService.testConnection` | static method | B | Check that the server is reachable; 207 or 404 count as reachable. |
| `WebDAVService.sync` | static method | B | Run a full two-way sync under the remote upload lock; conflicts are never auto-resolved. |
| [`WebDAVService.finalizePendingSync`](#finalizependingsync) | static method | A | Finalize sync by applying the user's conflict resolutions. |
| `WebDAVService.forceUpload` | static method | B | Overwrite remote data with local data, without merging. |
| `WebDAVService.forceDownload` | static method | B | Overwrite local data with remote data, without merging. |
| [`WebDAVService._toSyncResult`](#tosyncresult) | static method | A | Convert an engine result into the app-typed result. |

`progress` (the engine's `ValueNotifier<SyncProgress>`) carries a plain doc comment and is not
counted.

## Documentation

### `static Future<bool> finalizePendingSync(WebDAVConfig config, PendingSync pending, Map<String, StudyRecord> resolutions)` <a id="finalizependingsync"></a>

- **Kind:** static method
- **Purpose:** Apply the user's per-record decisions and upload the result.
- **Inputs:** `config`; `pending` from an earlier `sync`; `resolutions` — record id → chosen record.
- **Returns:** `false` when the pending state is missing, or applying or uploading fails.
- **Side effects:** Re-acquires the remote lock, re-downloads the remote file, writes local data,
  uploads, saves the base snapshot.
- **Algorithm:** Hand `{progressModuleId: resolutions}` to the engine's `finalizePendingSync`.
- **Usage:** The conflict dialog (ported in `PLAN.md` M1.1).
- **Notes:** The base snapshot is saved only after a successful upload under the held remote
  `.lock`; dismissing the dialog never calls this.

### `static SyncResult _toSyncResult(EngineSyncResult result)` <a id="tosyncresult"></a>

- **Kind:** static method
- **Purpose:** Rebuild the app-typed result from the engine's.
- **Inputs:** `result`.
- **Returns:** `SyncResult`, with `PendingSync` when the engine reports conflicts.
- **Side effects:** None.
- **Algorithm:** Copy `success`, `error`, `warnings`; when `pending` is non-null, read
  `pending.forModuleId(progressModuleId)?.state as ProgressMergeResult?` and keep the engine's
  pending state alongside.
- **Usage:** `sync`, `forceUpload`, `forceDownload`.
- **Notes:** The engine carries the app's `ProgressMergeResult` through as opaque `state`, which is
  what lets the conflict dialog receive real `StudyRecord`s without the package knowing the type.
