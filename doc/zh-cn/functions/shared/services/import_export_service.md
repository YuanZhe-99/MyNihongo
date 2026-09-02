# lib/shared/services/import_export_service.dart

`ImportExportService` 是共享 `ZipTransfer` 的静态门面（facade），配置为严格模式（`rejectUnknownEntries`、`strictUtf8`、`validateBeforeWrite`、`atomicWrites` 全为 true），因为本应用没有需要保护的宽松老用户基础。归档命名为 `mynihongo_export_<yyyyMMdd_HHmmss>.zip`。见 [../../../backup-restore.md](../../../backup-restore.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| 库头 | 库文档 | B | MyNihongo 的 ZIP 导出 / 导入 API，共享引擎的门面。 |
| `ImportExportService.exportZIP` | 静态方法 | B | 把注册表的数据文件导出为 `destDir` 中的 ZIP；失败时为 null。 |
| `ImportExportService.importZIP` | 静态方法 | B | 导入先前导出的 ZIP；拒绝允许列表之外的任何内容且不写入。 |
