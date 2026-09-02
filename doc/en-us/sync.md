# WebDAV sync

The sync engine is not in this repository. `WebDavSyncEngine`, the WebDAV client, the upload lock,
the three-way merge and the auto-sync scheduler live in the shared `myapps_data` package at
`packages/myapps_data`, documented in `packages/myapps_data/doc/en-us/` — start at its
`architecture.md` and `invariants.md`. This page records only what MyNihongo!!!!! plugs into that
engine and what the user sees.

## What syncs

One data module, declared once in `lib/app/data_modules.dart`:

| Local and remote file | Backup module id | Default remote path |
|---|---|---|
| `nihongo_progress.json` | `progress` | `/MyNihongo` |

Nothing else. The content catalog ships with the app, device preferences stay in
`storage_config.json`, and there are no images, so the engine's image sync has nothing to do here.

## How a sync runs

The engine does the work: acquire the remote `.lock` (60-second TTL, 20-second heartbeat), download
the remote file, compare it to the local file and the base snapshot in `.sync_base/`, merge, write
locally, upload, save the new base, release the lock. Two paths matter to this app:

- **Raw fast paths.** If the local and remote strings are identical nothing is merged or uploaded.
  This is why `NihongoStorage.save()` and the engine both write two-space pretty-printed JSON; a
  formatting difference would make every sync re-upload an unchanged file forever.
- **The module merge.** When the strings differ, the engine calls `mergeProgressModule`, which
  wraps `mergeProgressData` (`lib/shared/services/sync_merge.dart`): parse local, remote and base
  as `ProgressData`, run the package's generic `mergeRecords<StudyRecord>` keyed by `id` and
  compared by `modifiedAt`, then re-attach unknown JSON from both sides. A record changed on one
  side only takes that side; a record deleted on one side and untouched on the other is deleted; a
  record changed on **both** sides since the base is a **conflict**.

## Conflicts reach the user

Conflicts are never resolved silently — `autoResolve` is false at every call site, an invariant
shared with the sibling apps. The engine returns a pending result; `WebDAVService` wraps it as a
`PendingSync` carrying the typed `ProgressMergeResult`, so the conflict dialog (ported in `PLAN.md`
M1.1) can show both copies of each record — resolved through the catalog to the kana, headword or
pattern the id names, with counters and `modifiedAt` on each side — and let the user keep the local
or the remote copy per record. Dismissing the dialog aborts the resolution. `finalizePendingSync`
re-downloads the remote file and uploads the resolved data under a fresh lock; the base snapshot is
saved only after that upload succeeds.

A conflict without a decision falls back to the local record (`ProgressMergeResult.buildResolved`),
the same fallback the sibling apps use.

## Auto-sync

`AutoSyncService` is a facade over the package's `AutoSyncScheduler`: sync on launch, on resume,
every 15 minutes, and 30 seconds after the last save (`NihongoStorage.save()` calls
`notifySaved()`). Its two app hooks both run the daily auto-backup check, so a device left open
across midnight still gets its backup. Background sync never auto-resolves either; a conflict found
in the background sets `hasPendingConflicts` for the settings UI to surface.

## Force operations

`forceUpload` overwrites the remote with local data; `forceDownload` overwrites local data with the
remote. Both run under the lock and both lose the other side's changes since the last sync, so the
UI confirms before either. After a backup restore that wrote data, the app disables auto-sync and
offers a force upload, so restored-old data cannot propagate deletions to other devices (series
invariant I5).

## Files

- `webdav_config.json` — server URL, credentials, remote path, auto-sync flag. Never synced.
- `.sync_base/nihongo_progress.json` — the base snapshot. Leaving it behind on a storage-path change
  would make the next sync resurrect records other devices deleted, which is why
  `NihongoStorage.setStoragePath` migrates the whole folder.
- `.sync_base/upload_lock.json` — detects an upload interrupted mid-flight.
