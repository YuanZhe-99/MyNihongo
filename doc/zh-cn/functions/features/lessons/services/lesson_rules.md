# lib/features/lessons/services/lesson_rules.dart

每个单元处于什么状态、下一个何时开放，以及学习者在一个单元里走了多远。全是对进度文件与路径的纯函数——这里不读存储、不构建部件，因此这些规则可以一口气读完，也可以脱离设备测试。

使用方：`lesson_path_view.dart`、`quiz_page.dart`、`reminder_planner.dart`。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `unitSessionSize` | 常量 | B | 一次练习的题数（12）。 |
| `checkpointSize` | 常量 | B | 单元测验的题数（20）。 |
| `checkpointPassAccuracy` | 常量 | B | 单元测验所需的首答正确率（0.7）。 |
| `UnitState` | 枚举 | B | 锁定、开放或已通过。 |
| `lessonRecordId` | 函数 | B | 命名单元测验结果所写入的记录。 |
| [`unitStates`](#states) | 函数 | A | 判定每个单元处于什么状态。 |
| [`canAttemptCheckpoint`](#attempt) | 函数 | A | 说明单元测验是否可以进入。 |
| [`unitProgress`](#progress) | 函数 | A | 衡量一个单元完成了多少。 |
| `nextUnit` | 函数 | B | 第一个处于开放状态的单元。 |

## 文档

### `Map<String, UnitState> unitStates(LessonPath path, ProgressData progress)` <a id="states"></a>

- **种类：** 函数
- **用途：** 判定路径中每个单元处于什么状态。
- **输入：** `path` 与学习者的 `progress`。
- **返回：** 以单元 id 为键的状态表。
- **副作用：** 无。
- **算法：** 第一个单元开放；此后一个单元在它前面那个通过之后开放，「通过」指存在至少 correct 为一的 `lesson:` 记录。
- **用法：** `lesson_path_view.dart`，以及 `nextUnit`。
- **说明：** 通过一个靠后的单元会开放它之后的那个，因此跳级不会在学习者身后留下空洞——被跳过的单元练习仍然锁定，但它们的单元测验始终开放。

### `bool canAttemptCheckpoint(UnitState state)` <a id="attempt"></a>

- **种类：** 函数
- **用途：** 说明一个单元的测验是否可以进入。
- **输入：** 该单元的状态。
- **返回：** `bool`——始终为真。
- **副作用：** 无。
- **算法：** 无；这是一个常量答案。
- **用法：** `lesson_path_view.dart`，以及把这条规则钉住的那些测试。
- **说明：** 之所以写成函数而不是常量，是因为这条规则值得被命名。单元测验正是学习者跳级的方式，而通过它唯一能做的事，就是解锁刚刚被证明掌握了的内容——把它藏在它本可以跳过的那些单元后面是循环的。

### `double unitProgress(LessonUnit unit, ProgressData progress)` <a id="progress"></a>

- **种类：** 函数
- **用途：** 衡量学习者答对了这个单元的多少。
- **输入：** `unit` 与 `progress`。
- **返回：** 0 到 1 之间的 `double`。
- **副作用：** 无。
- **算法：** 该单元条目中已记录至少一次正确作答的比例。
- **用法：** 每张单元卡片上的进度条。
- **说明：** 比调度器对同一批条目的看法更粗，而且是故意的。一条会因为复习间隔到期而倒退的进度条，是在为时间的流逝惩罚学习者。与每日计数一样，它从记录派生、从不存储。
