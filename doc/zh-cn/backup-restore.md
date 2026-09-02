# 备份、恢复与 ZIP 传输

两个引擎都是共享包的——`myapps_data` 中的 `BackupEngine` 和 `ZipTransfer`，文档在 `packages/myapps_data/doc/en-us/`。本页记录 MyNihongo!!!!! 如何配置它们。

## 本地备份

`BackupService`（`lib/shared/services/backup_service.dart`）是基于应用模块注册表构建的 `BackupEngine` 门面（facade）。

- **格式：** 共享的 v2 bundle，`backups/backup_<stamp>.json`，保存每个模块的原始 JSON 字符串外加一个 `_imageRefs` 映射。MyNihongo 没有图像，因此 `_imageRefs` 始终为空，`backups/blobs/` 下的内容寻址 blob 存储永不填充。格式原样保留，使一个 bundle 在本系列每个应用看来都一样。
- **模块：** 一个，`progress` → `nihongo_progress.json`，从注册表推导（`BackupService.modules`）。
- **设置：** `storage_config.json` 中的 `autoBackupEnabled` 和 `backupRetentionDays`，系列通用的键。自动备份每天取一个 bundle，通过扫描 bundle 文件名判定，并从 `main()`、自动同步的周期性 tick 和恢复时运行。保留策略删除早于配置天数的 bundle；`0` 表示永久保留。
- **列表：** 最新在前；无法解析的 bundle 标记为 `corrupt` 而不是隐藏。
- **恢复：** 每个选中模块的负载在写入任何东西**之前**都经过校验（`validateProgressJson`），写入是原子的，且 WebDAV 自动同步在第一次写入前被禁用，只有当恢复未写入任何东西就失败时才重新启用。恢复结果报告 `ok`、`wroteAnything` 和 `missingImages`（此处始终为 0）。写入了数据的恢复之后，备份页面提供强制上传，使恢复后的状态刻意传播，而不是通过一次在别处看起来像大规模删除的合并。

备份页面本身在 `PLAN.md` M1.1 中移植。

## ZIP 导出与导入

`ImportExportService`（`lib/shared/services/import_export_service.dart`）是 `ZipTransfer` 的门面。

- **导出：** `mynihongo_export_<yyyyMMdd_HHmmss>.zip`，包含注册表的数据文件。`storage_config.json`、`webdav_config.json`、`.sync_base/` 和 `backups/` 永不包含。
- **导入：** 严格，因为本应用没有需要保护的宽松老用户基础：`rejectUnknownEntries: true`（含有注册表文件以外任何内容的归档被拒绝）、`strictUtf8: true`、`validateBeforeWrite: true`（负载必须在触碰文件之前解析为 `ProgressData`）、`atomicWrites: true`。无论这些开关如何，路径穿越都被引擎直接拒绝。被拒绝的归档不写入任何东西。
- 写入了数据的导入之后，通过 `AutoSyncService.notifyLocalDataChangedNow()` 通知页面重新加载。

## 存储路径

`NihongoStorage.setStoragePath` 把新路径记录到 `storage_config.json`（它本身留在平台默认目录），并通过包里的 `migrateStorageContents` 移动旧文件夹中的**一切**——数据文件、`.sync_base/`、`backups/`、`webdav_config.json`。已存在的目标文件胜出，其源副本留在原地，因此不会凭猜测丢弃任何东西。设置页面今天显示该路径；更改它是随桌面目标到来的桌面功能。
