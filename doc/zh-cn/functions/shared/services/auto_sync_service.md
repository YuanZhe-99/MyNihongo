# lib/shared/services/auto_sync_service.dart

`AutoSyncService` 是共享 `AutoSyncScheduler` 的单例门面（facade）：它拥有触发拓扑（启动时、恢复时、每 15 分钟、以及最后一次保存后 30 秒同步），并暴露设置 UI 读取的状态。它的 `isAutoSyncActive` 钩子检查已保存 WebDAV 配置的 `autoSync` 标志，`runSync` 调用 `WebDAVService.sync`，而 `onPeriodicTick` 和 `onResume` 都运行 `BackupService.runAutoBackupIfNeeded`。每个公开成员都镜像 MyAnime 的门面，使其页面可以原样移植。见 [../../../sync.md](../../../sync.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| 库头 | 库文档 | B | MyNihongo 的自动同步触发服务，共享调度器的门面。 |
| `AutoSyncService._` | 私有构造函数 | B | 阻止直接实例化；用 MyNihongo 的钩子构建共享调度器。 |
| `AutoSyncService.lastSuccessAt` | getter | B | 返回上次成功同步的时间。 |
| `AutoSyncService.lastFailureAt` | getter | B | 返回上次失败同步的时间。 |
| `AutoSyncService.lastError` | getter | B | 返回最近的同步失败消息；成功后为 null。 |
| `AutoSyncService.hasPendingConflicts` | getter | B | 返回后台同步是否发现需要手动解决的冲突。 |
| `AutoSyncService.addOnLocalDataChanged` | 方法 | B | 注册自动同步更新本地数据时调用的回调。 |
| `AutoSyncService.removeOnLocalDataChanged` | 方法 | B | 移除先前注册的本地数据回调。 |
| `AutoSyncService.addOnStatusChanged` | 方法 | B | 注册同步状态变化时调用的回调。 |
| `AutoSyncService.removeOnStatusChanged` | 方法 | B | 移除先前注册的状态回调。 |
| `AutoSyncService.recordSyncResult` | 方法 | B | 记录在自动同步循环之外触发的同步结果。 |
| `AutoSyncService.notifyLocalDataChangedIfNeeded` | 方法 | B | 手动同步或强制操作写入本地数据后通知重新加载监听者。 |
| `AutoSyncService.notifyLocalDataChangedNow` | 方法 | B | 恢复或导入替换了本地数据后无条件通知重新加载监听者。 |
| `AutoSyncService.recordFinalizeResult` | 方法 | B | 记录冲突最终化结果。 |
| `AutoSyncService.start` | 方法 | B | 开始观察应用生命周期并启动同步定时器；幂等。 |
| `AutoSyncService.stop` | 方法 | B | 停止定时器并停止观察生命周期。 |
| `AutoSyncService.notifySaved` | 方法 | B | 存储保存后安排防抖的同步；`start()` 之前忽略。 |
| `AutoSyncService.requestSyncNow` | 方法 | B | 尽快触发同步，跳过防抖。 |
