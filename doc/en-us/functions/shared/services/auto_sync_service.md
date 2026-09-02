# lib/shared/services/auto_sync_service.dart

`AutoSyncService` is a singleton facade over the shared `AutoSyncScheduler`: it owns the trigger
topology (sync on launch, on resume, every 15 minutes, and 30 seconds after the last save) and
exposes the status the settings UI reads. Its `isAutoSyncActive` hook checks the saved WebDAV
config's `autoSync` flag, `runSync` calls `WebDAVService.sync`, and both `onPeriodicTick` and
`onResume` run `BackupService.runAutoBackupIfNeeded`. Every public member mirrors MyAnime's facade
so its pages port unchanged. See [../../../sync.md](../../../sync.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | MyNihongo's auto-sync trigger service, a facade over the shared scheduler. |
| `AutoSyncService._` | private constructor | B | Prevent direct instantiation; build the shared scheduler with MyNihongo's hooks. |
| `AutoSyncService.lastSuccessAt` | getter | B | Return the last successful sync time. |
| `AutoSyncService.lastFailureAt` | getter | B | Return the last failed sync time. |
| `AutoSyncService.lastError` | getter | B | Return the most recent sync failure message; null after success. |
| `AutoSyncService.hasPendingConflicts` | getter | B | Return whether background sync found conflicts needing manual resolution. |
| `AutoSyncService.addOnLocalDataChanged` | method | B | Register a callback invoked when auto-sync updates local data. |
| `AutoSyncService.removeOnLocalDataChanged` | method | B | Remove a previously registered local-data callback. |
| `AutoSyncService.addOnStatusChanged` | method | B | Register a callback invoked when sync status changes. |
| `AutoSyncService.removeOnStatusChanged` | method | B | Remove a previously registered status callback. |
| `AutoSyncService.recordSyncResult` | method | B | Record a sync result triggered outside the auto-sync loop. |
| `AutoSyncService.notifyLocalDataChangedIfNeeded` | method | B | Notify reload listeners after a manual sync or force operation wrote local data. |
| `AutoSyncService.notifyLocalDataChangedNow` | method | B | Notify reload listeners unconditionally after a restore or import replaced local data. |
| `AutoSyncService.recordFinalizeResult` | method | B | Record a conflict-finalization result. |
| `AutoSyncService.start` | method | B | Begin observing the app lifecycle and start the sync timers; idempotent. |
| `AutoSyncService.stop` | method | B | Stop the timers and stop observing the lifecycle. |
| `AutoSyncService.notifySaved` | method | B | Schedule a debounced sync after a storage save; ignored before `start()`. |
| `AutoSyncService.requestSyncNow` | method | B | Trigger a sync as soon as possible, skipping the debounce. |
