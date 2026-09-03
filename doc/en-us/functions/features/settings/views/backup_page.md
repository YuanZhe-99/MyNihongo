# lib/features/settings/views/backup_page.dart

Create, list, restore and delete local backup bundles. Ported from MyAnime!!!!!'s page of the same
name, minus its app-side auto-sync guard. See
[../../../../backup-restore.md](../../../../backup-restore.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | `library` | B | Create, list, restore and delete local backup bundles. |
| `BackupPage` | constructor | B | Create a backup page instance. |
| `BackupPage.createState` | method | B | Create the mutable state object. |
| `_BackupPageState.initState` | method | B | Start the first read of settings and history. |
| `_BackupPageState._load` | method | B | Re-read the backup settings and the bundle list. |
| `_BackupPageState._createBackup` | method | B | Write a new bundle from the current data. |
| `_BackupPageState._restoreBackup` | method | A | Restore the modules the user picks out of one bundle. |
| `_BackupPageState._handlePostRestoreSync` | method | B | Offer a force upload after a restore with WebDAV configured. |
| `_BackupPageState._deleteBackup` | method | B | Delete one bundle after confirmation. |
| `_BackupPageState._toggleAutoBackup` | method | B | Turn the daily automatic backup on or off. |
| `_BackupPageState._setRetention` | method | B | Choose how long automatic bundles are kept. |
| `_BackupPageState._buildSection` | method | B | Render a section heading above a run of rows. |
| `_BackupPageState.build` | method | B | Build the current widget subtree. |
| `_RestoreModuleDialog` | constructor | B | Create a restore module dialog instance. |
| `_RestoreModuleDialog.createState` | method | B | Create the mutable state object. |
| `_RestoreModuleDialogState.initState` | method | B | Start with every module in the bundle selected. |
| `_RestoreModuleDialogState.build` | method | B | Build the current widget subtree. |

### `_restoreBackup`

- **Purpose:** Restore the modules the user picks out of one bundle.
- **Inputs:** `backup` — the chosen `BackupInfo`.
- **Returns:** None.
- **Side effects:** Overwrites local data files, makes open pages re-read, and may turn WebDAV
  auto-sync off inside the engine.
- **Algorithm:** Read the bundle's module keys, offer them in `_RestoreModuleDialog`, confirm, then
  call `BackupService.restoreBackup`. On success notify `AutoSyncService` that local data changed
  and hand off to `_handlePostRestoreSync`.
- **Usage:** The restore icon on each history row.
- **Notes:** Unlike MyAnime's page, this one does **not** disable auto-sync itself.
  `myapps_data v1.0.1`'s `BackupEngine.restoreBackup` implements invariant I5 internally — auto-sync
  is disabled before the first write and turned back on only when nothing was written — so
  repeating it here would fight the engine over the same config file. This is a deliberate
  deviation from the `PLAN.md` M1.1 wording.

The retention dropdown offers 0 (keep forever), 3, 7, 14, 30, 60 and 90 days. A damaged bundle is
flagged in its subtitle, its restore button is disabled and its delete button is not — deleting it
is the only thing left to do with it.
