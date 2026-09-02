# lib/shared/services/backup_service.dart

`BackupService` 是共享 `BackupEngine` 的静态门面（facade），建立在 `nihongoModuleRegistry` 和一个 `NihongoStorageAdapter` 之上，后者的目录解析器每次调用都尊重 `@visibleForTesting appDirProvider` 接缝。v2 bundle 格式携带的 `_imageRefs` 映射在这里保持为空，因为应用没有图像。它再导出 `BackupInfo` 和 `RestoreResult`。见 [../../../backup-restore.md](../../../backup-restore.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| 库头 | 库文档 | B | MyNihongo 的本地备份 API，共享引擎的门面。 |
| `BackupService.appDirProvider` | 静态字段（`@visibleForTesting`） | B | 允许测试把备份 I/O 重定向到临时目录。 |
| `BackupService._getAppDir` | 静态方法 | B | 尊重测试覆盖来解析应用数据目录。 |
| `BackupService.loadSettings` | 静态方法 | B | 从 `storage_config.json` 加载 `autoBackupEnabled` 和 `backupRetentionDays`。 |
| `BackupService.saveSettings` | 静态方法 | B | 持久化备份设置，保留无关的键。 |
| `BackupService.createBackup` | 静态方法 | B | 创建 v2 备份 bundle，然后运行保留清理。 |
| `BackupService.runAutoBackupIfNeeded` | 静态方法 | B | 到期时取每日一次的自动备份；禁用时为空操作。 |
| `BackupService.listBackups` | 静态方法 | B | 列出备份，最新在前；无法解析的 bundle 标记为损坏。 |
| `BackupService.getBackupModules` | 静态方法 | B | 列出 bundle 包含的模块 id。 |
| `BackupService.restoreBackup` | 静态方法 | B | 恢复 bundle，可选只恢复选定模块，写入前校验并先禁用自动同步（I5）。 |
| `BackupService.deleteBackup` | 静态方法 | B | 删除一个备份 bundle。 |

`modules`（从注册表推导的文件名 → 模块 id 映射）、`autoBackupEnabled` 和 `retentionDays`（委托给引擎的 getter/setter 对）带普通文档注释，不计入。
