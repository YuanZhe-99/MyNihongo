# lib/shared/services/backup_service.dart

`BackupService` is a static facade over the shared `BackupEngine`, built on
`nihongoModuleRegistry` and a `NihongoStorageAdapter` whose directory resolver honors the
`@visibleForTesting appDirProvider` seam on every call. The v2 bundle format carries an `_imageRefs`
map that stays empty here because the app has no images. It re-exports `BackupInfo` and
`RestoreResult`. See [../../../backup-restore.md](../../../backup-restore.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | MyNihongo's local backup API, a facade over the shared engine. |
| `BackupService.appDirProvider` | static field (`@visibleForTesting`) | B | Allow tests to redirect backup I/O to a temporary directory. |
| `BackupService._getAppDir` | static method | B | Resolve the app data directory honoring the test override. |
| `BackupService.loadSettings` | static method | B | Load `autoBackupEnabled` and `backupRetentionDays` from `storage_config.json`. |
| `BackupService.saveSettings` | static method | B | Persist backup settings, preserving unrelated keys. |
| `BackupService.createBackup` | static method | B | Create a v2 backup bundle, then run retention cleanup. |
| `BackupService.runAutoBackupIfNeeded` | static method | B | Take the once-per-day automatic backup when due; no-op when disabled. |
| `BackupService.listBackups` | static method | B | List backups newest first; unparseable bundles are flagged corrupt. |
| `BackupService.getBackupModules` | static method | B | List the module ids a bundle contains. |
| `BackupService.restoreBackup` | static method | B | Restore a bundle, optionally only selected modules, validating before writing and disabling auto-sync first (I5). |
| `BackupService.deleteBackup` | static method | B | Delete one backup bundle. |

`modules` (the file-name → module-id map derived from the registry), `autoBackupEnabled` and
`retentionDays` (getter/setter pairs delegating to the engine) carry plain doc comments and are not
counted.
