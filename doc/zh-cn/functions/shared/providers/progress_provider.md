# lib/shared/providers/progress_provider.dart

声明 `ProgressNotifier` 与 `progressDataProvider`，即覆盖 `NihongoStorage.load()` 的
`StateNotifierProvider<ProgressNotifier, AsyncValue<ProgressData>>`。显示进度的页面监视它，并在保存后调用
`reload()`。同步、备份还原与 ZIP 导入通过 `AutoSyncService` 的本地数据变更回调抵达这里，该回调由 notifier
注册，而不是由每个页面注册。见
[../../../features/learning-progress.md](../../../features/learning-progress.md) 与
[../../../features/sync-and-backup.md](../../../features/sync-and-backup.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| 库头注释 | `library` | B | 把用户的进度文件暴露给控件树，并保持其最新。 |
| `ProgressNotifier` | 构造函数 | B | 创建 notifier 并开始首次读取。 |
| `ProgressNotifier.reload` | 方法 | B | 重新读取进度文件并发布结果。 |
| `ProgressNotifier.recordExam` | 方法 | B | 记录一次 JLPT 卷子的作答，然后重新加载。 |
| `ProgressNotifier._onLocalDataChanged` | 方法 | B | 响应同步、还原或导入写入文件。 |
| `ProgressNotifier.dispose` | 方法 | B | 释放服务回调。 |
| `progressDataProvider` | 顶层 `final` | — | 从磁盘读取并保持最新的用户进度文件。 |

首次读取之后，重新加载不会把状态退回 `loading`，因此后台同步不会让已经显示数据的页面变空白。

`recordExam` 是 `NihongoStorage.recordExam` 的一层薄封装，和这里其他写入方法一样：先写入，再重新加载。一次作答不经过调度器——它问过的那些题，已经在被作答时逐个推动了各自条目的间隔——而且它在最后被写入一次，而不是每答一题写一次，因为半份考试算不上一次作答。
