# lib/features/settings/views/backup_page.dart

创建、列出、还原与删除本机备份包。移植自 MyAnime!!!!! 的同名页面，但去掉了它在应用侧的自动同步保护。见
[../../../../backup-restore.md](../../../../backup-restore.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| 库头注释 | `library` | B | 创建、列出、还原与删除本机备份包。 |
| `BackupPage` | 构造函数 | B | 创建备份页面实例。 |
| `BackupPage.createState` | 方法 | B | 创建可变状态对象。 |
| `_BackupPageState.initState` | 方法 | B | 开始首次读取设置与历史记录。 |
| `_BackupPageState._load` | 方法 | B | 重新读取备份设置与备份包列表。 |
| `_BackupPageState._createBackup` | 方法 | B | 用当前数据写出新的备份包。 |
| `_BackupPageState._restoreBackup` | 方法 | A | 从一个备份包中还原用户选择的模块。 |
| `_BackupPageState._handlePostRestoreSync` | 方法 | B | 在配置了 WebDAV 时，还原后提供强制上传。 |
| `_BackupPageState._deleteBackup` | 方法 | B | 确认后删除一个备份包。 |
| `_BackupPageState._toggleAutoBackup` | 方法 | B | 开启或关闭每日自动备份。 |
| `_BackupPageState._setRetention` | 方法 | B | 选择自动备份保留多久。 |
| `_BackupPageState._buildSection` | 方法 | B | 在一组行上方渲染分区标题。 |
| `_BackupPageState.build` | 方法 | B | 构建当前控件子树。 |
| `_RestoreModuleDialog` | 构造函数 | B | 创建还原模块对话框实例。 |
| `_RestoreModuleDialog.createState` | 方法 | B | 创建可变状态对象。 |
| `_RestoreModuleDialogState.initState` | 方法 | B | 初始时选中备份包中的每个模块。 |
| `_RestoreModuleDialogState.build` | 方法 | B | 构建当前控件子树。 |

### `_restoreBackup`

- **Purpose:** 从一个备份包中还原用户选择的模块。
- **Inputs:** `backup` —— 选中的 `BackupInfo`。
- **Returns:** 无。
- **Side effects:** 覆盖本地数据文件、让打开的页面重新读取，并可能在引擎内部关闭 WebDAV 自动同步。
- **Algorithm:** 读取备份包的模块键，在 `_RestoreModuleDialog` 中提供选择，确认后调用
  `BackupService.restoreBackup`。成功后通知 `AutoSyncService` 本地数据已变更，并交给
  `_handlePostRestoreSync`。
- **Usage:** 每条历史记录行上的还原图标。
- **Notes:** 与 MyAnime 的页面不同，本页**不**自行关闭自动同步。`myapps_data v1.0.1` 的
  `BackupEngine.restoreBackup` 已在内部实现不变式 I5 —— 首次写入前关闭自动同步，仅在什么都没写入时才恢复 ——
  在这里重复实现会与引擎争抢同一个配置文件。这是对 `PLAN.md` M1.1 措辞的有意偏离。

保留期限下拉提供 0（永久保留）、3、7、14、30、60 与 90 天。损坏的备份包会在副标题中标出，其还原按钮被禁用，
删除按钮仍可用 —— 删除是对它唯一还能做的事。
