# lib/features/progress/services/review_queue.dart

现在该学什么：哪些条目到期了，以及今日额度还容得下哪些新条目。与旁边的调度器一样是纯函数，因此策略无需设备即可测试。

推导过程见 [`../../../../algorithms/spaced-repetition.md`](../../../../algorithms/spaced-repetition.md)。

使用方：`reviewQueueProvider`，并经由它用于学习页的今日卡片。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| 库头 | 库文档 | B | 决定现在该学什么。 |
| `_newItemOrder` | 顶层常量 | B | 新条目的引入顺序所依据的类别。 |
| `ReviewQueue` | 类 | B | 一份算好的队列。 |
| `isEmpty` | getter | B | 现在是否完全没有可做的。 |
| `reviewLimitReached` | getter | B | 当天额度是否已用尽而仍有条目到期。 |
| [`isDue`](#isdue) | 静态方法 | A | 判断一条记录是否到期。 |
| [`build`](#build) | 静态方法 | A | 构建此刻的队列。 |
| `_newItems` | 静态方法 | B | 挑选接下来未学过的目录条目。 |
| `_dayOf` | 静态方法 | B | 把一个时刻归约为它的日历日。 |

## 文档

### `static bool isDue(StudyRecord record, DateTime now)` <a id="isdue"></a>

- **种类：** 静态方法
- **用途：** 判断一条记录是否到期。
- **输入：** `record`；本地时间的 `now`。
- **返回：** `bool`。
- **副作用：** 无。
- **算法：** 没有 `dueAt` 的记录从未复习过，不算复习。否则按本地时间比较**日历日**，而不是时刻。
- **使用：** `build`，以及固定该边界的控件测试。
- **说明：** 这条两段式规则很重要。`dueAt` 存为纯 UTC 时刻，因此在每台设备上比较一致，磁盘上也不需要任何时区运算。但学习者认为今天到期的东西整天都该能做，而「今天」是他们自己的——因此 23:00 到期的条目从零点起就算到期。调度器存时刻；队列读日子。

### `static ReviewQueue build({required ProgressData progress, required ContentCatalog catalog, required LearnerProfile profile, required DateTime now, Set<StudyKind> kinds})` <a id="build"></a>

- **种类：** 静态方法
- **用途：** 构建此刻的队列。
- **输入：** 进度文件、内容库、学习者档案、本地 `now`，以及哪些类别可以提供新条目。
- **返回：** `ReviewQueue`。
- **副作用：** 无。
- **算法：**
  1. 对 `progress.studyRecords` 遍历一次，收集三件事：哪些 id 已学过、今天已经做了多少复习与多少新条目、哪些记录到期。
  2. 把到期列表按 `dueAt` 升序排序——逾期最久的在最前。
  3. 用档案的上限减去今日计数，得到剩余额度。
  4. 取相应数量的到期记录，并从内容库补足新条目列表。
- **使用：** `reviewQueueProvider`。
- **说明：** **今日计数是推导的，从不存储。** 今天答过的复习，是 `lastReviewedAt` 落在今天本地日期的记录；今天开始的新条目，是 `createdAt` 为今天的记录——之所以成立，是因为记录由它的第一次作答创建。存储式的按天计数器需要在午夜重置、会多出一个两台设备可能不一致的字段，还会漏掉从另一台设备同步进来的学习量——而共享的每日目标不能漏掉它。`overdueTotal` 与 `due.length` 分开上报，这样界面可以说「今日 20 项，共 300 项」，而不是假装积压比实际更少。
