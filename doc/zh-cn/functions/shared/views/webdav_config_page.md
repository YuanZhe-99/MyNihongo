# lib/shared/views/webdav_config_page.dart

WebDAV 服务器表单与手动同步控件。移植自 MyAnime!!!!! 的同名页面，使两个应用的同步界面行为一致。见
[../../../sync.md](../../../sync.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| 库头注释 | `library` | B | 配置用户的 WebDAV 服务器并手动执行同步。 |
| `WebDAVConfigPage` | 构造函数 | B | 创建 WebDAV 配置页面实例。 |
| `WebDAVConfigPage.createState` | 方法 | B | 创建可变状态对象。 |
| `_WebDAVConfigPageState.initState` | 方法 | B | 订阅同步状态并开始读取配置。 |
| `_WebDAVConfigPageState._refreshSyncStatus` | 方法 | B | 后台同步状态变化时刷新本页。 |
| `_WebDAVConfigPageState._loadConfig` | 方法 | B | 用已存储的配置填充表单。 |
| `_WebDAVConfigPageState.dispose` | 方法 | B | 释放监听器与控制器。 |
| `_WebDAVConfigPageState._currentConfig` | getter | B | 用表单当前内容构建配置。 |
| `_WebDAVConfigPageState._saveConfig` | 方法 | B | 持久化表单；自动同步开启时立即请求同步。 |
| `_WebDAVConfigPageState._testConnection` | 方法 | B | 检查服务器是否接受这组凭据。 |
| `_WebDAVConfigPageState._syncNow` | 方法 | B | 立即执行双向同步。 |
| `_WebDAVConfigPageState._showSyncResult` | 方法 | B | 展示非冲突的同步或强制操作结果。 |
| `_WebDAVConfigPageState._forceUpload` | 方法 | B | 确认并执行强制上传。 |
| `_WebDAVConfigPageState._forceDownload` | 方法 | B | 确认并执行强制下载。 |
| `_WebDAVConfigPageState._confirmForceAction` | 方法 | B | 请用户确认破坏性的强制操作。 |
| `_WebDAVConfigPageState._progressText` | 方法 | B | 把同步进度快照映射为本地化状态行。 |
| `_WebDAVConfigPageState._resolveConflicts` | 方法 | A | 请用户逐条解决冲突，然后上传。 |
| `_WebDAVConfigPageState._disconnect` | 方法 | B | 忘记已存储的服务器并清空表单。 |
| `_WebDAVConfigPageState._fillNextcloud` | 方法 | B | 用 Nextcloud 的地址形式预填表单。 |
| `_WebDAVConfigPageState._syncStatusText` | 方法 | B | 构建简短的同步健康摘要。 |
| `_WebDAVConfigPageState.build` | 方法 | B | 构建当前控件子树。 |

### `_resolveConflicts`

- **Purpose:** 请用户逐条解决待定冲突，然后上传解决后的数据。
- **Inputs:** `result` —— 携带待定合并的冲突同步结果。
- **Returns:** 无。
- **Side effects:** 每条冲突显示一个对话框；全部解决后在同步唤醒锁下完成同步并记录结果。
- **Algorithm:** 遍历 `pending.allConflicts`，通过内容库把每个 id 解析为标签，并显示
  [`showStudyConflictDialog`](../widgets/study_conflict_dialog.md)。返回 null 即中止：重新记录结果使冲突
  保持待定，显示失败提示，且不上传任何内容。否则在唤醒锁下调用 `WebDAVService.finalizePendingSync`，把结果
  交给 `recordFinalizeResult`，并请求进度 provider 重新读取。
- **Usage:** 当 `result.hasConflicts` 时由 `_syncNow` 调用。
- **Notes:** 中止绝不能默认把记录解决为本地版本 —— 那会悄悄丢弃另一台设备的学习记录。

在保存包含服务器地址与凭据的配置之前，同步控件、状态卡片、进度条、自动同步开关与断开按钮都不显示。
