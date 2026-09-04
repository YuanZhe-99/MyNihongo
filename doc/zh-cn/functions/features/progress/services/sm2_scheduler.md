# lib/features/progress/services/sm2_scheduler.dart

一次对错作答会对一个条目的日程做什么。纯函数：接收一个 `StudyRecord` 并返回一个新的，因此整套策略无需设备、时钟或文件即可测试。

其算术以及对教科书版 SM-2 的两处偏离，推导过程见 [`../../../../algorithms/spaced-repetition.md`](../../../../algorithms/spaced-repetition.md)。本页只讲声明。

使用方：`NihongoStorage.recordAnswers`，仅此而已——应用中的每一次作答都经由这一条写入路径到达调度器。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| 库头 | 库文档 | B | 根据一次对错作答安排该条目的下次复习。 |
| `minStudyEase` | 顶层常量 | B | 难度系数下限 1.3；低于它条目会永远每天回来。 |
| `maxIntervalDays` | 顶层常量 | B | 间隔上限，一年。 |
| `easeBonusStreak` | 顶层常量 | B | 获得难度系数加成所需的连对次数。 |
| `Sm2Scheduler` | 类 | B | 安排一个条目的下次复习。 |
| [`apply`](#apply) | 方法 | A | 在一次作答后推进一条记录。 |
| [`_nextEase`](#nextease) | 方法 | A | 为一次作答调整难度系数。 |
| `_nextInterval` | 方法 | B | 算出下一个间隔：先 1，再 6，此后乘以难度系数。 |

## 文档

### `StudyRecord apply(StudyRecord record, {required bool correct, required DateTime now})` <a id="apply"></a>

- **种类：** 方法
- **用途：** 在一次作答后推进一条记录。
- **输入：** `record`；本次是否 `correct`；`now`，这次作答的时刻。
- **返回：** 一个新的 `StudyRecord`。
- **副作用：** 无。
- **算法：** 先算出新的连对次数（加一，或归零），再由它算出新的难度系数，然后是间隔——答错时一律为一天。把 `dueAt` 写为 `now + 间隔`，`lastReviewedAt` 与 `modifiedAt` 写为 `now`，并推进相应的累计计数。
- **使用：** `NihongoStorage.recordAnswers`，每个作答条目调用一次。
- **说明：** `now` 是必填而不是有默认值，这样一批作答共用同一个时刻，且每个测试都是确定性的。`modifiedAt` 也显式设为同一时刻，而不是交给 `copyWith` 的默认值，理由相同。累计的 `correct` 与 `wrong` 从不回退：它们记录发生过什么，不属于日程。

### `double _nextEase(double ease, {required bool correct, required int streak})` <a id="nextease"></a>

- **种类：** 方法
- **用途：** 为一次作答调整难度系数。
- **输入：** 当前 `ease`、本次是否 `correct`，以及作答后的 `streak`。
- **返回：** `double`，永不低于 `easeFloor`。
- **副作用：** 无。
- **算法：** 答错减 0.20。答对在连对达到 `easeBonusStreak` 后加 0.10，否则不变。最后夹到下限。
- **使用：** `apply`。
- **说明：** **是 0.20 而不是 SM-2 的 0.54，这个差异是刻意的。** 教科书上的惩罚假定有 0–5 的自评，因此最重的值留给真正毫无印象的作答。在二值评分下每一次失误都会吃到它，而三次失误就会把一个条目从 2.5 压到 1.3 的下限——在那里它会永远每天回来，无论学习者之后表现多好。按 0.20 计算，同样三次失误只到 1.9，条目还能回升。普通的答对对难度系数是中性的，因此它只为真正掌握的条目上浮，而不是每答对一次就上浮。
