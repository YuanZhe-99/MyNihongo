# lib/shared/views/webdav_config_page.dart

The WebDAV server form and the manual sync controls. Ported from MyAnime!!!!!'s page of the same
name so the two apps' sync UI behaves identically. See [../../../sync.md](../../../sync.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | `library` | B | Configure the user's WebDAV server and run syncs by hand. |
| `WebDAVConfigPage` | constructor | B | Create a WebDAV config page instance. |
| `WebDAVConfigPage.createState` | method | B | Create the mutable state object. |
| `_WebDAVConfigPageState.initState` | method | B | Subscribe to sync status and start the configuration read. |
| `_WebDAVConfigPageState._refreshSyncStatus` | method | B | Refresh this page when background sync status changes. |
| `_WebDAVConfigPageState._loadConfig` | method | B | Fill the form from the stored configuration. |
| `_WebDAVConfigPageState.dispose` | method | B | Release listeners and controllers. |
| `_WebDAVConfigPageState._currentConfig` | getter | B | Build a config from what the form holds. |
| `_WebDAVConfigPageState._saveConfig` | method | B | Persist the form and start a sync when auto-sync is on. |
| `_WebDAVConfigPageState._testConnection` | method | B | Check that the server answers with these credentials. |
| `_WebDAVConfigPageState._syncNow` | method | B | Run a two-way sync now. |
| `_WebDAVConfigPageState._showSyncResult` | method | B | Present a non-conflict sync or force result. |
| `_WebDAVConfigPageState._forceUpload` | method | B | Confirm and run a force upload. |
| `_WebDAVConfigPageState._forceDownload` | method | B | Confirm and run a force download. |
| `_WebDAVConfigPageState._confirmForceAction` | method | B | Ask the user to confirm a destructive force action. |
| `_WebDAVConfigPageState._progressText` | method | B | Map a sync progress snapshot to a localized status line. |
| `_WebDAVConfigPageState._resolveConflicts` | method | A | Ask the user to resolve each pending conflict, then upload. |
| `_WebDAVConfigPageState._disconnect` | method | B | Forget the stored server and clear the form. |
| `_WebDAVConfigPageState._fillNextcloud` | method | B | Prefill the form with Nextcloud's URL shape. |
| `_WebDAVConfigPageState._syncStatusText` | method | B | Build a short sync health summary for display. |
| `_WebDAVConfigPageState.build` | method | B | Build the current widget subtree. |

### `_resolveConflicts`

- **Purpose:** Ask the user to resolve each pending conflict, then upload the resolved data.
- **Inputs:** `result` — the conflicting sync result carrying the pending merge.
- **Returns:** None.
- **Side effects:** Shows one dialog per conflict; on full resolution finalizes the sync under the
  sync wake lock and records the outcome.
- **Algorithm:** Loop over `pending.allConflicts`, resolving each id to a label through the content
  catalog and showing [`showStudyConflictDialog`](../widgets/study_conflict_dialog.md). A null
  return aborts: the result is recorded again so the conflict stays pending, a failure snackbar is
  shown, and nothing is uploaded. Otherwise `WebDAVService.finalizePendingSync` runs under the wake
  lock, the outcome goes to `recordFinalizeResult`, and the progress provider is asked to re-read.
- **Usage:** Called from `_syncNow` when `result.hasConflicts`.
- **Notes:** Aborting must never resolve a record to the local version by default — that would
  silently discard the other device's study history.

Sync controls, the status card, the progress bar, the auto-sync switch and the disconnect button
are hidden until a configuration with a server URL and credentials has been saved.
