# lib/app/data_modules.dart

本应用与共享 `myapps_data` 引擎之间的接缝，也是持久化兼容性契约的**唯一事实来源**：数据文件名 `nihongo_progress.json`、备份模块 id `progress`、默认远程路径 `/MyNihongo`，以及 ZIP 归档前缀 `mynihongo_export_`。它声明 `NihongoStorageAdapter`（覆盖 `NihongoStorage` 的 `StorageAdapter`）、进度模块的校验、编码与合并回调，以及 `nihongoModuleRegistry`——每个门面（facade）都建立在其上的有序注册表。见 [../../architecture.md](../../architecture.md) 和 [../../sync.md](../../sync.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| 库头 | 库文档 | B | 一次性向共享引擎描述 MyNihongo 的可同步数据文件。 |
| `NihongoStorageAdapter` | 类文档 | B | 把共享引擎桥接到 MyNihongo 的存储中枢。 |
| `NihongoStorageAdapter.new` | 构造函数 | B | 创建覆盖 `NihongoStorage` 的适配器，可选的 `appDir` 解析器用于测试接缝。 |
| `NihongoStorageAdapter.getAppDir` | 方法覆写 | B | 解析活动的应用数据目录，优先尊重注入的解析器。 |
| `NihongoStorageAdapter.readConfig` | 方法覆写 | B | 通过中枢读取 `storage_config.json`。 |
| `NihongoStorageAdapter.writeConfig` | 方法覆写 | B | 通过中枢持久化 `storage_config.json`。 |
| `validateProgressJson` | 顶层函数 | B | 在写入前校验 `nihongo_progress.json` 负载；无法解析时抛出。 |
| `encodeProgressData` | 顶层函数 | B | 以存储中枢使用的两空格缩进编码合并后的数据集。 |
| [`mergeProgressModule`](#mergeprogressmodule) | 顶层函数 | A | 为共享同步引擎合并本地/远程/基线进度 JSON，把有类型的结果作为不透明状态携带。 |
| `buildProgressModule` | 顶层函数 | B | 以 `DataModule` 向共享引擎描述 `nihongo_progress.json`。 |
| `nihongoModuleRegistry` | 顶层 `final` | B | 提供 MyNihongo 的有序模块注册表，持有唯一的进度模块。 |

## 文档

### `ModuleMergeOutcome mergeProgressModule({...})` <a id="mergeprogressmodule"></a>

- **类型：** 顶层函数
- **源码：** `lib/app/data_modules.dart`
- **Purpose：** 把应用类型的 `mergeProgressData` 适配为引擎应用中立的 `ModuleMergeOutcome`。
- **Inputs：** `localJson`、`remoteJson`、`baseJson`（可空）、`autoResolve`（生产中为 false）。
- **Returns：** 无冲突时带 `mergedJson` 的完整结果；否则带 `ModuleConflict` 和 `buildResolvedJson` 回调的挂起结果。
- **Side effects：** 无。
- **Algorithm：**
  1. 调用 `mergeProgressData`。
  2. 无冲突：用 `encodeProgressData` 编码 `ProgressData(records: merged, extraJson: extraJson)`，并把有类型的结果作为 `state` 一起返回。
  3. 有冲突：把每个 `RecordConflict<StudyRecord>` 映射为 `ModuleConflict`（id、两侧记录、显示名），并提供一个解析器，它把引擎的 `Map<String, Object?>` 过滤为 `StudyRecord` 值并编码 `result.buildResolved(...)`。
- **Usage：** 在 `buildProgressModule` 中注册为 `merge` 回调；仅当本地与远程字符串不同时由引擎调用。
- **Notes：** `state` 正是让 `WebDAVService._toSyncResult` 在包不知道类型的情况下，把真实的 `StudyRecord` 交给冲突对话框的机制。
