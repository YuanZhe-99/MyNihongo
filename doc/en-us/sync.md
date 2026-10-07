# WebDAV sync

P3 shared profile ownership and adapters: [shared-ui.md](shared-ui.md). Existing formats and module order are retained.

The sync engine is not in this repository. `WebDavSyncEngine`, the WebDAV client, the upload lock,
the three-way merge and the auto-sync scheduler live in the shared `myapps_data` package at
`packages/myapps_data`, documented in `packages/myapps_data/doc/en-us/` — start at its
`architecture.md` and `invariants.md`. This page records only what MyNihongo!!!!! plugs into that
engine and what the user sees.

## What syncs

Two data modules, declared once in `lib/app/data_modules.dart`. The order is significant: progress first, profile (0.6.0) appended last.

| Local and remote file | Backup module id | Default remote path |
|---|---|---|
| `nihongo_progress.json` | `progress` | `/MyNihongo` |
| `profile.json` (0.6.0) | `profile` | `/MyNihongo` |

Nothing else. The content catalog ships with the app and device preferences stay in
`storage_config.json`. The only images are profile avatars: the profile module's `referencedImages`
hook returns the avatar's basename, so the engine's image phase (additive, by file name, under
`images/`) uploads and downloads it. See [The profile file](#the-profile-file).

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
`PendingSync` carrying the typed `ProgressMergeResult`, so the conflict dialog
(`lib/shared/widgets/study_conflict_dialog.dart`) can show both copies of each record — resolved through the catalog to the kana, headword or
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

## On iPhone and Mac: local network access

Apple asks the user before an app may reach a server on the local network (iOS 14 and later,
macOS 15 and later). According to Apple's documentation (TN3179) the question covers BSD sockets
too, which is what `dart:io` uses underneath the WebDAV client, and it is asked for a local address
over HTTPS as much as over HTTP. `Info.plist` carries `NSLocalNetworkUsageDescription`, which says
that the app connects only to the WebDAV server the learner configured.

The first connection to a LAN server raises the system alert, and `dart:io` cannot wait for the
answer, so that first connection test or sync can fail while the alert is on screen. On iPhone and
Mac a failed **Test Connection** therefore says to allow local network access in the system
settings and try again (`platformAsksForLocalNetwork`); elsewhere it stays "Connection failed".

App Transport Security, Apple's other network rule, does not apply: it governs Apple's URL Loading
System, and this client never goes through it. See [`platform-notes.md`](platform-notes.md). None
of this has been observed on a device; the Apple behaviour described here is from Apple's
documentation.

## The profile file

Since 0.6.0 the registry holds a second module, `profile.json` — the user's display name and avatar
(schema in [`data-formats.md`](data-formats.md#profilejson), feature in
[`features/profile.md`](features/profile.md)). It goes through the same engine steps, after the
progress module, under the same `.lock`, with its own `.sync_base/profile.json`.

- **The merge never produces a conflict, and needs no base.** Each field merges independently by last
  writer wins on its own timestamp: the name by `displayNameUpdatedAt`, the avatar by
  `avatarUpdatedAt`. A strictly later remote timestamp wins, a tie keeps local, and a side that never
  set the field always loses to one that did. A name changed on one device and an avatar changed on
  another therefore both survive. Unknown keys are unioned with local winning, and the higher
  `version` is kept. No conflict dialog is ever shown for it.
- **Removal is explicit.** Clearing the avatar writes `"avatar": null` with a new timestamp (and
  clearing the name writes `"displayName": null`), so the removal wins the merge like any other edit
  instead of being mistaken for a field that was never set.
- **Avatar names are unique.** The avatar is an ordinary file in `images/` and travels through the
  engine's additive image phase (the module's `referencedImages` returns its basename). Image sync
  never overwrites a file that already exists on the other side and never deletes, so every new
  avatar gets a fresh `images/avatar_<uuid>.jpg` name; re-using one name would leave other devices
  showing the old picture. The replaced avatar is deleted on the device that changed it only: **old
  avatars remain on the WebDAV server and on other devices** (a known limitation).
- **Older builds ignore it.** The engine only requests the file names it has registered and never
  lists the remote root, so a build older than 0.6.0 never fetches `profile.json`; the avatar file
  sits harmlessly in `images/`.
- **Cost.** One extra `GET profile.json` per sync (a 404 for a library that never set a profile); the
  recorded WebDAV transcripts were re-recorded and gained only that request.
- Every profile save calls `AutoSyncService.notifySaved`, so the debounced sync runs shortly after an
  edit; after a sync or restore rewrites local data the profile provider reloads.

## Files

- `webdav_config.json` — server URL, credentials, remote path, auto-sync flag. Never synced.
- `.sync_base/nihongo_progress.json` — the base snapshot. Leaving it behind on a storage-path change
  would make the next sync resurrect records other devices deleted, which is why
  `NihongoStorage.setStoragePath` migrates the whole folder.
- `.sync_base/profile.json` — the base snapshot of the profile module (0.6.0).
- `.sync_base/upload_lock.json` — detects an upload interrupted mid-flight.

## AI sources and WebDAV privacy

MyApps-AI v0.5.2 is explicitly split into runtime, platform, models, local UI and llama.cpp packages. Settings uses the unified section skeleton. Global source selection is device-local (`aiSourceSelection`), defaults to system AI, and never chooses online as fallback. Qwen3.5 0.8B/2B Q4_K_M and Gemma 4 E2B Q4_0 run on CPU. Downloads require explicit actions, use pinned URLs and SHA-256, and live under `ai_models/` outside data modules, sync, backup and ZIP. Model leases prevent removal during use. Source switches cancel old work and release model resources. System proofreading remains independent in MyNihongo.

WebDAV notice version 1 must be acknowledged on each device before connection testing, manual/force sync or background sync. The record is in device-local storage_config.json. Existing configurations stay intact while sync is paused; the WebDAV page displays a review banner. Declining saves no configuration and makes no request. JSON/images have no application-level encryption; HTTPS protects transit, HTTP does not. Wire format, locks and conflict policy remain unchanged.
