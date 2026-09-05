# lib/features/progress/models/exam_attempt.dart

一次 JLPT 卷子的作答，建模为进度文件里的一条记录，好让在一台设备上做的一次作答出现在另一台设备的历史记录里。

以 `exam:<timestamp>-<suffix>` 为 id 的普通 `StudyRecord` 存储，载荷放在记录的 `extraJson` 里——之所以是一条记录而不是第二个数据模块，理由和学习者档案与句子历史记录是记录的理由相同：记录能免费获得逐记录的三方合并、冲突对话框、同步与备份，而第二个模块则意味着第二个远程文件、第二个备份条目，以及十一份要重新录制的黄金记录。

**只保存输入。** 也就是问了哪些题、作答是什么——从不保存每道题的得分，也从不保存题目文字。结果页面显示的一切都在读取时从随包发布的文件里连回来，因此一次修正了答案键的内容更新会连同历史记录一起修正，而不是留下一个随包文件已经不再认同的分数。

部分的键是普通字符串，所以 `progress/` 不导入 `drills/`；本构建没有对应枚举值的部分仍能原样往返。

消费方：`NihongoStorage.recordExam`、`examAttemptsProvider` 与 `askedQuestionsProvider`、`ExamHistoryPage`、`resolveStudyItemLabel` 以及冲突对话框。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| 库头 | 库文档 | B | 搭载在进度文件里的那些 JLPT 作答。 |
| `examMaxMockEntries` | 顶层常量 | B | 保留多少次模拟考试作答（40）——比练习的上限更低，因为模拟考试是更重的记录，而学习者回头看的是趋势。 |
| `examMaxPracticeEntries` | 顶层常量 | B | 保留多少次练习作答（80）。 |
| `examUnanswered` | 顶层常量 | B | 因为时间用完而未作答的题目所对应的作答值（-1）——既不算对也不算错。 |
| `_examPayloadKey` | 私有常量 | B | 载荷所在的那个 `extraJson` 键。 |
| `ExamMode` | 枚举 | B | 一次作答是不计时的练习还是计时的模拟考试；名称会被写进载荷。 |
| `ExamSectionResult` | 类 | B | 某一个部分的统计与它的计时。 |
| `ExamSectionResult.new` | 构造函数 | B | 持有某一个部分的 `asked`/`right`，以及该部分计时时的 `seconds`/`limitSeconds`。 |
| `ExamSectionResult.accuracy` | getter | B | 0 到 1 的正确率；里面什么都没有的部分为 0。 |
| `ExamSectionResult.fromJson` | 静态方法 | B | 从载荷里读出一个部分；读不懂的一律为 null。 |
| `ExamSectionResult.toJson` | 方法 | B | 把一个部分写进载荷，该部分不计时时省略计时相关的键。 |
| `ExamAttempt` | 类 | B | 一次卷子的作答。 |
| `ExamAttempt.new` | 构造函数 | B | 描述一次作答——id、级别、模式、规模、时间戳、各部分与作答。 |
| `asked`、`right`、`accuracy` | getter | B | 把各部分的统计折叠成整卷的合计。 |
| [`buildId`](#buildid) | 静态方法 | A | 为一次新的作答推导 id。 |
| [`fromRecord`](#fromrecord) | 静态方法 | A | 从一条进度记录里读出一次作答。 |
| [`toRecord`](#torecord) | 方法 | A | 把这次作答写回它的记录。 |
| [`examAttempts`](#examattempts) | 顶层函数 | A | 从进度文件里收集那些作答，最新的在前。 |
| `_int`、`_time` | 私有函数 | B | 把一个 JSON 值读成整数或 UTC 时间戳。 |

## 文档

### `static String buildId(DateTime startedAt, String suffix)` <a id="buildid"></a>

- **种类：** 静态方法
- **用途：** 为一次新的作答构建记录 id。
- **输入：** `startedAt`，以及 `suffix`——四位十六进制数字。
- **返回：** `String`——`exam:20260904T101500Z-3f2a`。
- **副作用：** 无。
- **算法：** 取 UTC 形式的 `startedAt`，把它格式化为各字段零填充的紧凑基本格式时间戳，然后追加后缀。
- **使用：** 测验页记录一次作答时。
- **说明：** 时间戳让这些 id 按作答发生的顺序排列，这既让文件 diff 可读，也意味着一个 id 在缺陷报告里是自解释的。后缀则是阻止两台设备上在同一秒开始的两次作答合并成一条的东西——与句子历史记录不同，同一份卷子的两次作答确实是两件事，绝不能塌缩成一条记录。

### `static ExamAttempt? fromRecord(StudyRecord? record)` <a id="fromrecord"></a>

- **种类：** 静态方法
- **用途：** 从一条进度记录里读出一次作答。
- **输入：** `record`，或 null。
- **返回：** `ExamAttempt?`——记录不是考试记录，或它的载荷读不出来时为 null。
- **副作用：** 无。
- **算法：** 拒绝 id 不是 `StudyKind.exam` 的任何东西，从 `extraJson` 里读出 `exam` 映射，并拒绝没有级别的载荷。只有在字符串恰为 `mock` 时 `mode` 才是 `mock`；`scale` 默认为 `short`；`startedAt` 回落到记录的 `createdAt`；各部分与作答逐项读取，丢弃任何解析不了的项。
- **使用：** `examAttempts`，以及经由它的历史记录的每一个消费方。
- **说明：** 从不抛出，而且每个字段都独立读取，因此由更新的构建写入的载荷在这里仍能带着本构建认识的那些字段加载。本构建没有对应枚举值的部分会保留它的字符串键并原样往返。

### `StudyRecord toRecord(StudyRecord? existing, DateTime now)` <a id="torecord"></a>

- **种类：** 方法
- **用途：** 把这次作答写回它的记录。
- **输入：** 文件里已有的 `existing` 记录（若有），以及 `now`。
- **返回：** 可交给 `upsertRecords` 的 `StudyRecord`。
- **副作用：** 无。
- **算法：** 从原本就在那里的内容出发重建载荷，把已知字段（`v`、级别、模式名、规模、时间戳、序列化后的各部分与作答映射）覆盖上去，保留 `extraJson` 的其余部分，再 `copyWith` 合计与 `modifiedAt`。
- **使用：** `NihongoStorage.recordExam`。
- **说明：** 未知的载荷键会被保留，这是这个文件里每条记录都遵循的规则：旧版构建第一次碰到一条记录时，绝不能丢掉新版构建的字段。`correct` 与 `wrong` 携带整卷的合计，尽管载荷里也有它们——它们是旧版构建的冲突对话框所读取的内容，而一次在那里显示「0 / 0」的作答，会就一条它本来就无法解释的记录向那个构建传达不实的信息。`finishedAt` 只在被设置时才写入。

### `List<ExamAttempt> examAttempts(Iterable<StudyRecord> records, {String? level, ExamMode? mode})` <a id="examattempts"></a>

- **种类：** 顶层函数
- **用途：** 从进度文件里收集考试作答，最新的在前。
- **输入：** `records`；用来收窄列表的 `level` 与 `mode`。
- **返回：** `List<ExamAttempt>`，最新的在前。
- **副作用：** 无。
- **算法：** 解析每一条能读成作答的记录，丢掉被筛选条件排除的那些，然后按 `startedAt` 降序排序，以 id 作为决胜条件。
- **使用：** `examAttemptsProvider`，以及 `NihongoStorage.recordExam` 裁剪时。
- **说明：** 决胜条件让顺序成为全序，因此在同一秒开始的两次作答不会在不同构建之间互换位置——这很重要，因为裁剪是从这个列表的末尾开始丢弃的。`level` 或 `mode` 为 null 表示不筛选的列表，而不是「不属于任何级别的作答」。
