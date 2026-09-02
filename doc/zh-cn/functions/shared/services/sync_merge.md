# lib/shared/services/sync_merge.dart

合并中应用特有的那一半。它再导出包里通用的 `mergeRecords`、`RecordConflict` 和 `RecordMergeResult`，并定义 `ProgressMergeResult`（合并后的记录、冲突、顶层 `extraJson` 和一个解析器）以及 `mergeProgressData`，后者解析三个 JSON 字符串、运行 `mergeRecords<StudyRecord>`，并把两侧的未知 JSON 重新附上。见 [../../../sync.md](../../../sync.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `ProgressMergeResult.new` | 构造函数 | B | 创建进度合并结果实例。 |
| `ProgressMergeResult.hasConflicts` | getter | B | 报告是否有记录需要手动决定。 |
| [`ProgressMergeResult.buildResolved`](#buildresolved) | 方法 | A | 从冲突解决构建最终合并后的数据集。 |
| [`mergeProgressData`](#mergeprogressdata) | 顶层函数 | A | 把本地、远程和基线进度 JSON 合并为一个感知冲突的结果。 |

## 文档

### `ProgressData buildResolved(Map<String, StudyRecord> resolutions)` <a id="buildresolved"></a>

- **类型：** `ProgressMergeResult` 的方法
- **Purpose：** 在用户决定每个冲突之后组装要写入的文件。
- **Inputs：** `resolutions`——冲突记录 id → 选中的记录。
- **Returns：** 含合并记录外加每个冲突一条记录的 `ProgressData`。
- **Side effects：** 无。
- **Algorithm：** 从 `merged` 出发；对每个冲突取 `resolutions[id] ?? localRecord`，然后 `withPreservedUnknownJson([local, remote])`；用合并的 `extraJson` 包装。
- **Usage：** `mergeProgressModule` 的 `buildResolvedJson`；测试。
- **Notes：** 没有决定的冲突保留本地记录，与兄弟应用使用的回落相同。

### `ProgressMergeResult mergeProgressData(String localJson, String remoteJson, String? baseJson, {bool autoResolve = false})` <a id="mergeprogressdata"></a>

- **类型：** 顶层函数
- **Purpose：** 应用的记录合并。
- **Inputs：** 三个 JSON 字符串（首次同步时 `baseJson` 为 null）和 `autoResolve`，在每个生产调用点都是 false。
- **Returns：** `ProgressMergeResult`。
- **Side effects：** 无。
- **Algorithm：**
  1. 把每个字符串解析为 `ProgressData`。
  2. `mergeRecords<StudyRecord>(getId: id, getModifiedAt: modifiedAt, getDisplayName: id, serialize: jsonEncode(toJson()))`——由包逐记录决定：一侧改动 → 取它；一侧删除、另一侧未动 → 删除；自基线以来两侧都改动 → 冲突，除非 `serialize` 显示内容相同。
  3. 每条合并记录得到 `withPreservedUnknownJson([本地副本, 远程副本])`。
  4. 容器的 `extraJson` 是本地文件的，并针对远程的做保留。
- **Usage：** `data_modules.dart` 中的 `mergeProgressModule`。
- **Notes：** 显示名是 id，因为它是稳定的、非本地化的标签；冲突对话框通过目录把它解析后再显示。
