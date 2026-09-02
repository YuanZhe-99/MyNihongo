# WebDAV 同步

同步引擎不在此仓库。`WebDavSyncEngine`、WebDAV 客户端、上传锁、三方合并和自动同步调度器位于 `packages/myapps_data` 下的共享 `myapps_data` 包中，文档在 `packages/myapps_data/doc/en-us/`——从它的 `architecture.md` 和 `invariants.md` 开始。本页只记录 MyNihongo!!!!! 接入该引擎的部分，以及用户看到的东西。

## 同步什么

一个数据模块，在 `lib/app/data_modules.dart` 中声明一次：

| 本地与远程文件 | 备份模块 id | 默认远程路径 |
|---|---|---|
| `nihongo_progress.json` | `progress` | `/MyNihongo` |

别无其他。内容目录随应用发布，设备偏好留在 `storage_config.json`，也没有图像，因此引擎的图像同步在这里无事可做。

## 一次同步如何运行

工作由引擎完成：获取远程 `.lock`（60 秒 TTL，20 秒心跳），下载远程文件，与本地文件和 `.sync_base/` 中的基线快照比较，合并，本地写入，上传，保存新基线，释放锁。两条路径与本应用相关：

- **原始快速路径。** 如果本地和远程字符串完全相同，就不合并也不上传。这就是 `NihongoStorage.save()` 与引擎都写两空格美化 JSON 的原因；格式差异会让每次同步永远重新上传一个未改动的文件。
- **模块合并。** 字符串不同时，引擎调用 `mergeProgressModule`，它包装 `mergeProgressData`（`lib/shared/services/sync_merge.dart`）：把本地、远程和基线解析为 `ProgressData`，运行包里以 `id` 为键、按 `modifiedAt` 比较的通用 `mergeRecords<StudyRecord>`，然后把两侧的未知 JSON 重新附上。只在一侧改动的记录取那一侧；一侧删除、另一侧未动的记录被删除；自基线以来**两侧**都改动的记录是**冲突**。

## 冲突呈现给用户

冲突绝不静默解决——`autoResolve` 在每个调用点都是 false，这是与兄弟应用共享的不变量。引擎返回挂起结果；`WebDAVService` 把它包装成携带有类型 `ProgressMergeResult` 的 `PendingSync`，因此冲突对话框（在 `PLAN.md` M1.1 中移植）可以展示每条记录的两个副本——通过目录把 id 解析为它命名的假名、词条或句型，两侧各附计数器和 `modifiedAt`——并让用户逐记录保留本地或远程副本。关闭对话框即中止解决。`finalizePendingSync` 重新下载远程文件，并在新锁下上传解决后的数据；基线快照只在该上传成功后保存。

没有决定的冲突回落到本地记录（`ProgressMergeResult.buildResolved`），与兄弟应用使用的回落相同。

## 自动同步

`AutoSyncService` 是包内 `AutoSyncScheduler` 的门面（facade）：启动时、恢复时、每 15 分钟、以及最后一次保存后 30 秒同步（`NihongoStorage.save()` 调用 `notifySaved()`）。它的两个应用钩子都运行每日自动备份检查，因此跨过午夜仍开着的设备依然会得到备份。后台同步同样绝不自动解决；后台发现的冲突会设置 `hasPendingConflicts`，由设置 UI 呈现。

## 强制操作

`forceUpload` 用本地数据覆盖远程；`forceDownload` 用远程覆盖本地数据。两者都在锁下运行，都会丢掉另一侧自上次同步以来的更改，因此 UI 在两者之前都会确认。写入了数据的备份恢复之后，应用禁用自动同步并提供强制上传，使恢复的旧数据不会把删除传播到其他设备（系列不变量 I5）。

## 文件

- `webdav_config.json` — 服务器 URL、凭据、远程路径、自动同步标志。永不同步。
- `.sync_base/nihongo_progress.json` — 基线快照。更改存储路径时把它留在原地，会让下次同步复活其他设备已删除的记录，这正是 `NihongoStorage.setStoragePath` 迁移整个文件夹的原因。
- `.sync_base/upload_lock.json` — 检测中途中断的上传。
