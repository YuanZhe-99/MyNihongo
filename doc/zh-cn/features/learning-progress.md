# 学习进度

唯一一份同步的用户数据：用户学过的每个条目一条 `StudyRecord`，保存在 `nihongo_progress.json` 中，由共享引擎跨设备合并。模型在 [`../data-formats.md`](../data-formats.md) 中规定，合并在 [`../sync.md`](../sync.md) 中；本页涵盖应用今天如何使用它以及它的去向。

## 今天（第一阶段）

- **存储中枢。** `NihongoStorage`（`lib/features/progress/services/nihongo_storage.dart`）拥有应用目录、`storage_config.json` 和数据文件。`load()` 对缺失或空白文件返回空的 `ProgressData`，但对损坏的文件**抛出**，使之后的保存不会静默覆盖仅仅是无法读取的数据。`save()` 以同步期望的两空格格式原子写入（临时文件，然后重命名），然后调用 `AutoSyncService.instance.notifySaved()`。`upsertRecords()` 按 id 替换记录，并把容器的 `extraJson` 带过去。
- **Provider。** `progressDataProvider` 读取文件一次；页面在保存后或自动同步报告本地数据变更时刷新它。
- **学习仪表盘。** `learn_page.dart` 是首页标签：目录计数（假名、单词、语法点）、进度计数（已记录的条目、已掌握的条目——或诚实的「尚无学习记录」）、三个参考标签的快速链接，以及路线图。它不写任何记录；第一阶段没有任何东西会写。模型及其同步的存在是为了让复习引擎落在一条经过验证的数据路径上，而不是另起炉灶。

## 调度（第三阶段 M3.1）

- **写入一次作答。** `NihongoStorage.recordAnswer(id, correct)`——或成批的 `recordAnswers`——加载文件，对每个作答条目运行 `Sm2Scheduler`，每天推进一次连续天数，然后保存一次。一批就是一次写入，因此也只有一次自动同步通知。尚无记录的条目会得到一条：**记录由它的第一次作答创建**，这正是无需存储计数器也能统计「今天开始的新条目」的前提。
- **调度器**是纯函数，位于 `sm2_scheduler.dart`。它对教科书版 SM-2 的两处偏离——由对错推导评分质量，以及更温和的难度系数惩罚——推导过程见 [`../algorithms/spaced-repetition.md`](../algorithms/spaced-repetition.md)。
- **队列**（`review_queue.dart`）给出现在该学什么：按逾期最久优先排序的到期条目，加上尚未学过的目录 id，两者都受每日上限限制。「到期」按**本地日历日**判断，而 `dueAt` 存储为 UTC 时刻。
- **学习者档案**是同一文件内的一条 `profile:me` 记录，因此普通冲突对话框即可覆盖它。负载格式，以及为什么不用第二个模块、也不用顶层对象，见 [`../data-formats.md`](../data-formats.md)。
- **Provider。** `learnerProfileProvider` 与 `reviewQueueProvider` 派生自 `progressDataProvider` 和内容库，因此一次作答、一次同步或一次恢复都会更新所有显示它们的页面，而不存在第二个真相来源。

## 去向

- **第三阶段（M3.2、M3.3）：** 真正调用 `recordAnswer` 的是测验模式与课程路径；在它们落地之前，调度器虽已写好并测试，但只能经由它们触及。
- **第四阶段：** JLPT 答题是同一文件里的 `exam:` 记录。它们不是被学习的条目，也从不被调度，但它们点名的最薄弱词汇与语法点会交给 `ReviewQueue.build(prioritized:)`，由它把这些排在其他到期内容之前。这是一次考试影响队列的唯一方式：只重排，不增删。见 `algorithms/readiness-estimate.md`。

## 值得记住的不变量

- 每个时间戳都是 UTC。
- `copyWith` 除非被告知否则会推进 `modifiedAt`；不应算作编辑的改动显式传入现有值。
- 记录上和容器上的未知字段在加载、保存和合并中幸存。
- 记录的类别由其 id 推导；新版构建中的新类别在这里加载为 `other` 并被合并，而不是丢弃。
- 冲突被展示，绝不自动解决。
- 学习者档案与课程结果共享该文件，但都不是被学习的条目：`ProgressData.studyRecords` 才是被学习的子集，队列与条目计数都使用它。
- 连续天数是靠作答挣来的。只有 `recordAnswers` 会写它，且每天一次；设置写入会沿用已存储的值，而不是采用调用方给出的值。
