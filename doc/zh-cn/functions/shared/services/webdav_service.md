# lib/shared/services/webdav_service.dart

`WebDAVService` 是共享 `WebDavSyncEngine` 的静态门面（facade），在应用的存储适配器、模块注册表和默认远程路径 `/MyNihongo` 上构建一次。它暴露引擎的进度通知器以及同步、强制、配置和连接测试操作，把引擎结果转换为应用类型的 `SyncResult` 和 `PendingSync`（后者携带一个 `ProgressMergeResult`）。它再导出 `WebDAVConfig`、`WebDAVUploadLock`、`RemoteFile` 和 `RemoteFileStatus`。形状镜像 MyAnime 的门面，使其 WebDAV 页面和冲突对话框可以在类型名不变的情况下移植。见 [../../../sync.md](../../../sync.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| 库头 | 库文档 | B | MyNihongo 的 WebDAV 同步 API，共享引擎之上的薄门面。 |
| `SyncResult.new` | 构造函数 | B | 创建同步结果实例。 |
| `SyncResult.hasConflicts` | getter | B | 报告结果是否携带未解决的冲突。 |
| `PendingSync.new` | 构造函数 | B | 创建待处理同步实例。 |
| `PendingSync.allConflicts` | getter | B | 列出所有模块的每个记录冲突（今天只有一个模块）。 |
| `WebDAVService.consumeLocalDataChanged` | 静态方法 | B | 读取并清除"本地数据已变化"信号。 |
| `WebDAVService.loadConfig` | 静态方法 | B | 加载已保存的 WebDAV 配置；不存在或不可读时为 null。 |
| `WebDAVService.saveConfig` | 静态方法 | B | 原子地保存 WebDAV 配置。 |
| `WebDAVService.deleteConfig` | 静态方法 | B | 删除已保存的 WebDAV 配置，保留基线快照和客户端 id。 |
| `WebDAVService.testConnection` | 静态方法 | B | 检查服务器可达；207 或 404 算作可达。 |
| `WebDAVService.sync` | 静态方法 | B | 在远程上传锁下运行完整双向同步；冲突从不自动解决。 |
| [`WebDAVService.finalizePendingSync`](#finalizependingsync) | 静态方法 | A | 应用用户的冲突解决来完成同步。 |
| `WebDAVService.forceUpload` | 静态方法 | B | 用本地数据覆盖远程数据，不合并。 |
| `WebDAVService.forceDownload` | 静态方法 | B | 用远程数据覆盖本地数据，不合并。 |
| [`WebDAVService._toSyncResult`](#tosyncresult) | 静态方法 | A | 把引擎结果转换为应用类型的结果。 |

`progress`（引擎的 `ValueNotifier<SyncProgress>`）带普通文档注释，不计入。

## 文档

### `static Future<bool> finalizePendingSync(WebDAVConfig config, PendingSync pending, Map<String, StudyRecord> resolutions)` <a id="finalizependingsync"></a>

- **类型：** 静态方法
- **Purpose：** 应用用户逐记录的决定并上传结果。
- **Inputs：** `config`；先前 `sync` 得到的 `pending`；`resolutions`——记录 id → 选中的记录。
- **Returns：** 待处理状态缺失、应用或上传失败时为 `false`。
- **Side effects：** 重新获取远程锁，重新下载远程文件，写入本地数据，上传，保存基线快照。
- **Algorithm：** 把 `{progressModuleId: resolutions}` 交给引擎的 `finalizePendingSync`。
- **Usage：** 冲突对话框（在 `PLAN.md` M1.1 中移植）。
- **Notes：** 基线快照只在持有远程 `.lock` 期间成功上传后保存；关闭对话框从不调用它。

### `static SyncResult _toSyncResult(EngineSyncResult result)` <a id="tosyncresult"></a>

- **类型：** 静态方法
- **Purpose：** 从引擎的结果重建应用类型的结果。
- **Inputs：** `result`。
- **Returns：** `SyncResult`，引擎报告冲突时带 `PendingSync`。
- **Side effects：** 无。
- **Algorithm：** 复制 `success`、`error`、`warnings`；当 `pending` 非 null 时，读取 `pending.forModuleId(progressModuleId)?.state as ProgressMergeResult?` 并把引擎的待处理状态一并保留。
- **Usage：** `sync`、`forceUpload`、`forceDownload`。
- **Notes：** 引擎把应用的 `ProgressMergeResult` 作为不透明的 `state` 原样传递，这正是让冲突对话框在包不知道类型的情况下收到真正的 `StudyRecord` 的原因。
