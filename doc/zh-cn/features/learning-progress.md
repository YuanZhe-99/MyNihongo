# 学习进度

唯一一份同步的用户数据：用户学过的每个条目一条 `StudyRecord`，保存在 `nihongo_progress.json` 中，由共享引擎跨设备合并。模型在 [`../data-formats.md`](../data-formats.md) 中规定，合并在 [`../sync.md`](../sync.md) 中；本页涵盖应用今天如何使用它以及它的去向。

## 今天（第一阶段）

- **存储中枢。** `NihongoStorage`（`lib/features/progress/services/nihongo_storage.dart`）拥有应用目录、`storage_config.json` 和数据文件。`load()` 对缺失或空白文件返回空的 `ProgressData`，但对损坏的文件**抛出**，使之后的保存不会静默覆盖仅仅是无法读取的数据。`save()` 以同步期望的两空格格式原子写入（临时文件，然后重命名），然后调用 `AutoSyncService.instance.notifySaved()`。`upsertRecords()` 按 id 替换记录，并把容器的 `extraJson` 带过去。
- **Provider。** `progressDataProvider` 读取文件一次；页面在保存后或自动同步报告本地数据变更时刷新它。
- **学习仪表盘。** `learn_page.dart` 是首页标签：目录计数（假名、单词、语法点）、进度计数（已记录的条目、已掌握的条目——或诚实的「尚无学习记录」）、三个参考标签的快速链接，以及路线图。它不写任何记录；第一阶段没有任何东西会写。模型及其同步的存在是为了让复习引擎落在一条经过验证的数据路径上，而不是另起炉灶。

## 去向

- **第三阶段（`PLAN.md` M3.1）：** `recordAnswer(id, correct)` 更新计数器、连续正确次数和 SM-2 字段（`ease`、`intervalDays`、`dueAt`），推进 `modifiedAt`，然后保存。复习队列是「`dueAt` 已过的记录」加上每日上限内的新条目。
- **学习者档案**（目标级别、每日目标、连续学习天数）：计划作为同一文件内、带自己 `modifiedAt` 的一条记录，使普通冲突对话框覆盖它——而不是采用整文件合并的第二个模块。决策记录在 `PLAN.md` 中。
- **第四阶段：** JLPT 答题作为 `exam:<uuid>` 记录，若文件变大则用第二个模块。

## 值得记住的不变量

- 每个时间戳都是 UTC。
- `copyWith` 除非被告知否则会推进 `modifiedAt`；不应算作编辑的改动显式传入现有值。
- 记录上和容器上的未知字段在加载、保存和合并中幸存。
- 记录的类别由其 id 推导；新版构建中的新类别在这里加载为 `other` 并被合并，而不是丢弃。
- 冲突被展示，绝不自动解决。
