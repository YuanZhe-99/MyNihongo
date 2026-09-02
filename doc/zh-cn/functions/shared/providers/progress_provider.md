# lib/shared/providers/progress_provider.dart

声明 `progressDataProvider`，覆盖 `NihongoStorage.load()` 的 `FutureProvider<ProgressData>`。显示进度的页面监视它，并在保存后或 `AutoSyncService` 报告同步写入了本地数据时刷新它。见 [../../../features/learning-progress.md](../../../features/learning-progress.md)。

## 声明

该文件只包含一个带普通文档注释的顶层 `final`，没有函数，因此不携带函数解释层条目。

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `progressDataProvider` | 顶层 `final FutureProvider<ProgressData>` | — | 从磁盘读取的用户进度文件。 |
