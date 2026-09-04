# lib/features/progress/models/study_record.dart

同步的学习进度模型：`StudyRecord`（每个学过的条目一条——id、计数器、SM-2 状态、UTC 时间戳、保留的未知 JSON）和 `ProgressData`（写入 `nihongo_progress.json` 的 `{records: [...]}` 容器）。记录的类别（`StudyKind`）由其 id 前缀推导，阶段（`StudyStage`）由其复习状态推导；两者都不存储。文件还持有该模式所需的私有 JSON 辅助函数，以及常量 `defaultStudyEase`（2.5）和 `masteredIntervalDays`（21）。见 [../../../../data-formats.md](../../../../data-formats.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| 库头 | 库文档 | B | 同步的学习进度模型——每个学过的条目一条记录，以及写入磁盘的容器。 |
| [`studyKindOf`](#studykindof) | 顶层函数 | A | 从前缀推导记录 id 所属的目录；未知前缀为 `other`。 |
| `_unknownJson` | 顶层函数 | B | 收集本构建不建模的 JSON 键。 |
| `_stringKeyedMap` | 顶层函数 | B | 把动态键的映射强制为字符串键。 |
| `_mergeJsonMaps` | 顶层函数 | B | 深合并多个未知字段映射，后来者胜出；嵌套映射逐键合并。 |
| `_parseUtc` | 顶层函数 | B | 把 ISO-8601 时间戳解析为 UTC `DateTime`；不是可解析字符串时为 null。 |
| `_parseInt` | 顶层函数 | B | 解析整数计数器，接受整数值的 `double`。 |
| `_parseDouble` | 顶层函数 | B | 解析浮点字段。 |
| `StudyRecord.new` | 构造函数 | B | 从 UTC 时间戳和字段创建学习记录实例。 |
| `StudyRecord.create` | 工厂构造函数 | B | 为从未学过的条目创建新记录，两个时间戳都设为现在（或 `now`）。 |
| `StudyRecord.kind` | getter | B | 通过 `studyKindOf` 报告此记录所属的目录。 |
| `StudyRecord.reviews` | getter | B | 报告该条目被回答了多少次。 |
| `StudyRecord.accuracy` | getter | B | 报告正确答案的比例；首次复习前为 0。 |
| `StudyRecord.stage` | getter | B | 从 `lastReviewedAt` 和 `intervalDays` 推导未学 / 学习中 / 已掌握。 |
| [`StudyRecord.fromJson`](#fromjson) | 工厂构造函数 | A | 解析记录，保留本构建读不懂的内容。 |
| [`StudyRecord.toJson`](#tojson) | 方法 | A | 序列化记录，包含未知字段。 |
| [`StudyRecord.copyWith`](#copywith) | 方法 | A | 创建替换了选定字段的副本；`modifiedAt` 默认为现在。 |
| [`StudyRecord.withPreservedUnknownJson`](#withpreservedunknownjson) | 方法 | A | 合并此记录其他副本中的未知 JSON 字段。 |
| `ProgressData.new` | 构造函数 | B | 创建进度数据实例。 |
| `ProgressData.fromJson` | 工厂构造函数 | B | 解析容器；`records` 中的非对象项被跳过，非列表的 `records` 视为空。 |
| `ProgressData.toJson` | 方法 | B | 序列化容器，包含未知字段。 |
| `ProgressData.recordById` | 方法 | B | 按 id 查找记录（线性）。 |
| `ProgressData.withPreservedUnknownJson` | 方法 | B | 合并文件其他副本中的顶层未知字段。 |

## 文档

### `StudyKind studyKindOf(String id)` <a id="studykindof"></a>

- **类型：** 顶层函数
- **Purpose：** 推导记录 id 所属的目录。
- **Inputs：** `id`——`kana:あ`、`vocab:watashi`、`grammar:desu`、`lab:<hash>`……
- **Returns：** `kana`、`vocab`、`grammar`、`profile`、`lesson`、`history` 或 `other`。
- **Side effects：** 无。
- **Algorithm：** 取第一个 `:` 之前的子串（没有时取整个 id）并对其 switch。
- **Usage：** `StudyRecord.kind`；内容测试断言每个目录 id 映射到其类别。
- **Notes：** 类别刻意不存储：推导它使没有任何东西会与 id 脱节，而新版构建带新前缀的记录加载为 `other` 并仍能合并。`lab:` 与 `writing:` 都映射到同一个 `history` 类别：两个页面各自保留列表，但任何对类别做 switch 的地方都不需要区分它们。只有 `studiedKinds`——假名、词汇、语法——才算作学习者学过的东西，因此档案、课程结果与历史记录都在复习队列之外，也不计入已记录条目数。

### `factory StudyRecord.fromJson(Map<String, dynamic> json)` <a id="fromjson"></a>

- **类型：** 工厂构造函数
- **Purpose：** 解析记录，保留本构建读不懂的内容。
- **Inputs：** `json`——`records` 的一个元素。
- **Returns：** 一个 `StudyRecord`。
- **Side effects：** 无。
- **Algorithm：**
  1. `extra = _unknownJson(json, knownKeys)`。
  2. 每个有类型的字段通过局部的 `read(key, parse, {preserveOnFailure})` 读取：缺失时为 null；存在但无法解析时为 null——并且对可空字段 `dueAt` 和 `lastReviewedAt`，原始值以其键放入 `extra`。
  3. 计数器默认为 0，`ease` 默认为 `defaultStudyEase`；`createdAt`/`modifiedAt` 互相回落，再回落到 Unix 纪元。
- **Usage：** `ProgressData.fromJson`，以及经由它的每条合并和校验路径。
- **Notes：** 解析失败的计数器或 SRS 字段取默认值并以该默认值写回——有类型的值和原始值不能共用一个键。缺少 `modifiedAt` 的记录得到纪元，使它输掉每一次合并而不是意外胜出。

### `Map<String, dynamic> toJson()` <a id="tojson"></a>

- **类型：** `StudyRecord` 的方法
- **Purpose：** 为 `jsonEncode` 序列化记录。
- **Inputs：** 无。
- **Returns：** 从 `extraJson` 出发、覆盖已知字段的映射。
- **Side effects：** 无。
- **Algorithm：** 复制 `extraJson`；设置 `id`、计数器、`intervalDays`、`ease`；仅在非空时设置 `dueAt` 和 `lastReviewedAt`（ISO-8601 UTC）；设置 `createdAt` 和 `modifiedAt`。
- **Usage：** `ProgressData.toJson`；`mergeProgressData` 用于内容比较的 `serialize`。
- **Notes：** 由于覆盖在最后，保留的未知键永远不会遮蔽真实字段；为 null 的可空字段把键留成 `extraJson` 中的样子，因此 `fromJson` 无法解析的原始值得以保存。

### `StudyRecord copyWith({...})` <a id="copywith"></a>

- **类型：** `StudyRecord` 的方法
- **Purpose：** 创建替换了选定字段的副本。
- **Inputs：** 任一可变字段；`modifiedAt`。
- **Returns：** 具有相同 `id` 和 `createdAt` 的新记录。
- **Side effects：** 无。
- **Algorithm：** 逐字段 `??`；`modifiedAt` 为 `(modifiedAt ?? DateTime.now()).toUtc()`。
- **Usage：** 复习引擎的 `recordAnswer`（第三阶段）和测试。
- **Notes：** `modifiedAt` 的默认值正是让每次编辑对同步合并可见的原因。对不应算作编辑的改动显式传入现有值。

### `StudyRecord withPreservedUnknownJson(Iterable<StudyRecord?> sources)` <a id="withpreservedunknownjson"></a>

- **类型：** `StudyRecord` 的方法
- **Purpose：** 让此记录其他副本中的未知字段穿过合并。
- **Inputs：** `sources`——通常是本地和远程副本；null 被跳过。
- **Returns：** 同一记录，`extraJson` 替换为并集。
- **Side effects：** 无。
- **Algorithm：** `_mergeJsonMaps([...sources 的 extraJson, this.extraJson])`——冲突时本记录自己的值胜出，嵌套映射逐键合并。
- **Usage：** `mergeProgressData` 对每条合并记录；`ProgressMergeResult.buildResolved` 对每条选中记录。
- **Notes：** 这正是本构建不认识、但合并任一侧存在的字段在合并后幸存的机制。
