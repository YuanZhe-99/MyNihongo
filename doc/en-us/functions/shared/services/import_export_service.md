# lib/shared/services/import_export_service.dart

`ImportExportService` is a static facade over the shared `ZipTransfer`, configured strictly
(`rejectUnknownEntries`, `strictUtf8`, `validateBeforeWrite`, `atomicWrites` all true) because this
app has no lenient installed base to protect. Archives are named
`mynihongo_export_<yyyyMMdd_HHmmss>.zip`. See [../../../backup-restore.md](../../../backup-restore.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | MyNihongo's ZIP export/import API, a facade over the shared engine. |
| `ImportExportService.exportZIP` | static method | B | Export the registry's data files as a ZIP in `destDir`; null on failure. |
| `ImportExportService.importZIP` | static method | B | Import a previously exported ZIP; rejects anything outside the allowlist without writing. |
