# lib/features/progress/models/learner_profile.dart

学习者的目标级别、每日目标与学习连续天数——唯一一份既不是设备偏好、也不是某个条目进度的用户状态。

它以 id `profile:me` 存为一条普通的 `StudyRecord`，负载放在该记录的 `extraJson` 里。为什么用这种形态而不是第二个数据模块或顶层对象，见 [`../../../../data-formats.md`](../../../../data-formats.md)。

使用方：`learnerProfileProvider`、`NihongoStorage.recordAnswers` 与 `saveProfile`、学习设置各行，以及冲突对话框。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| 库头 | 库文档 | B | 学习者自己的设置与连续天数，随进度一同同步。 |
| `learnerProfileId` | 顶层常量 | B | 档案始终使用的记录 id。 |
| `defaultDailyNewLimit`、`defaultDailyReviewLimit` | 顶层常量 | B | 从未打开过设置的学习者所得到的额度。 |
| `LearnerProfile` | 类 | B | 目标级别、每日目标与连续天数。 |
| `localDateKey` | 静态方法 | B | 把本地日期格式化为 `YYYY-MM-DD`。 |
| [`fromRecord`](#fromrecord) | 静态方法 | A | 从进度文件中读出档案。 |
| [`toRecord`](#torecord) | 方法 | A | 把档案写回它的记录。 |
| `withStreakTouched` | 方法 | B | 为有作答的一天推进连续天数。 |
| `copyWith` | 方法 | B | 创建替换了部分字段的副本。 |

## 文档

### `static LearnerProfile fromRecord(StudyRecord? record)` <a id="fromrecord"></a>

- **种类：** 静态方法
- **用途：** 从进度文件中读出档案。
- **输入：** `profile:me` 记录，尚不存在时为 null。
- **返回：** `LearnerProfile`；缺失或不可读时全部取默认值。
- **副作用：** 无。
- **算法：** 读取 `extraJson['profile']`；若它不是映射则返回默认值。逐字段独立读取，遇到类型不对或负数时按字段回退。
- **使用：** `learnerProfileProvider`、`NihongoStorage.loadProfile`、冲突对话框。
- **说明：** 从不抛出。逐字段读取而不是全有或全无，正是让新版本写入的档案能在这里加载的原因：本版本认识的字段被使用，其余原封不动地留在 `extraJson` 中。从未打开过设置的学习者与负载损坏的学习者得到同一个答案，而这在两种情况下都是正确的。

### `StudyRecord toRecord(StudyRecord? existing, DateTime now)` <a id="torecord"></a>

- **种类：** 方法
- **用途：** 把档案写回它的记录。
- **输入：** 文件中已有的记录（若有）；`now`。
- **返回：** 可交给 `upsertRecords` 的 `StudyRecord`。
- **副作用：** 无。
- **算法：** 以原有负载映射为基础重建，覆盖已知字段，再放回记录 `extraJson` 副本的 `profile` 键下。`copyWith` 会把 `modifiedAt` 设为 `now`，这正是让改动对同步合并可见的原因。
- **使用：** `NihongoStorage.recordAnswers` 与 `saveProfile`。
- **说明：** 以原有负载而不是空映射为起点，与 `extraJson` 在上一层执行的是同一条规则：没有它，旧版本会在学习者第一次修改每日上限时，悄悄丢掉新版本写入的档案字段。
