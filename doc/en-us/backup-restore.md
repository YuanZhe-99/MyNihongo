# Backup, restore, and ZIP transfer

Both engines are the shared package's — `BackupEngine` and `ZipTransfer` in `myapps_data`, documented
at `packages/myapps_data/doc/en-us/`. This page records how MyNihongo!!!!! configures them.

## Local backups

`BackupService` (`lib/shared/services/backup_service.dart`) is a facade over `BackupEngine` built on
the app's module registry.

- **Format:** the shared v2 bundle, `backups/backup_<stamp>.json`, holding each module's raw JSON
  string plus an `_imageRefs` map. MyNihongo has no images, so `_imageRefs` is always empty and the
  content-addressed blob store under `backups/blobs/` is never populated. The format is kept as-is
  so a bundle looks the same to every app in the series.
- **Modules:** one, `progress` → `nihongo_progress.json`, derived from the registry (`BackupService.modules`).
- **Settings:** `autoBackupEnabled` and `backupRetentionDays` in `storage_config.json`, the
  series-wide keys. Auto-backup takes one bundle per day, decided by scanning bundle file names, and
  runs from `main()`, from the auto-sync periodic tick, and on resume. Retention deletes bundles
  older than the configured days; `0` keeps forever.
- **Listing:** newest first; an unparseable bundle is flagged `corrupt` rather than hidden.
- **Restore:** every selected module payload is validated (`validateProgressJson`) **before**
  anything is written, writes are atomic, and WebDAV auto-sync is disabled before the first write
  and re-enabled only when the restore failed without writing anything. The restore result reports
  `ok`, `wroteAnything` and `missingImages` (always 0 here). After a restore that wrote data, the
  backup page offers a force upload so the restored state propagates deliberately rather than
  through a merge that would look like mass deletion elsewhere.

The backup page is `lib/features/settings/views/backup_page.dart`, reached from Settings › Data. It
does not repeat the auto-sync guard in the app: the engine owns invariant I5, and a second
implementation would fight it over the same config file.

## ZIP export and import

`ImportExportService` (`lib/shared/services/import_export_service.dart`) is a facade over
`ZipTransfer`.

- **Export:** `mynihongo_export_<yyyyMMdd_HHmmss>.zip` containing the registry's data files.
  `storage_config.json`, `webdav_config.json`, `.sync_base/` and `backups/` are never included.
- **Import:** strict, because this app has no lenient installed base to protect:
  `rejectUnknownEntries: true` (an archive with anything but the registry's files is refused),
  `strictUtf8: true`, `validateBeforeWrite: true` (the payload must parse as `ProgressData` before
  the file is touched), `atomicWrites: true`. Path traversal is refused outright by the engine
  regardless of these knobs. A rejected archive writes nothing.
- After an import that wrote data, pages are told to reload through
  `AutoSyncService.notifyLocalDataChangedNow()`.

## Storage path

`NihongoStorage.setStoragePath` records the new path in `storage_config.json` (which itself stays in
the platform default directory) and moves **everything** in the old folder — the data file,
`.sync_base/`, `backups/`, `webdav_config.json` — through the package's `migrateStorageContents`.
Existing destination files win and their source copies are left in place, so nothing is discarded on
a guess. The settings page shows the path today; changing it is a desktop feature that arrives with
the desktop targets.
