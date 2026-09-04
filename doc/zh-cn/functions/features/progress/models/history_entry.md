# lib/features/progress/models/history_entry.dart

句子实验室与写作练习的历史记录：写过什么、什么时候写的、属于哪个课程单元。

它以普通 `StudyRecord` 的形式存放在 `lab:<hash>` 和 `writing:<hash>` 这样的 id 下，载荷放在记录的
`extraJson` 里——与学习者档案同一套做法，理由也相同。
[`../../../../data-formats.md`](../../../../data-formats.md) 说明了这个形状、由内容推导的 id
以及一百条上限。

**只保存输入。** 分析会从文本和随应用发布的目录重新算出来，模型生成的任何内容都绝不写在这里。

使用方：`NihongoStorage.recordHistory`、`labHistoryProvider` 与 `writingHistoryProvider`、
`HistoryList`、句子实验室与写作练习两个页面、`resolveStudyItemLabel` 以及冲突对话框。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| 库头 | 库文档 | B | 搭载在进度文件里的、被记住的句子。 |
| `HistoryKind` | 枚举 | B | 条目来自哪个页面，以及它的记录 id 前缀。 |
| `historyMaxEntries` | 顶层常量 | B | 每一种保留多少条。 |
| `HistoryEntry` | 类 | B | 一条被记住的句子或写作。 |
| [`buildId`](#buildid) | 静态方法 | A | 推导由内容决定的记录 id。 |
| `normalizeText` | 静态方法 | B | 在哈希或保存前去除首尾空白并压缩内部空白。 |
| [`fromRecord`](#fromrecord) | 静态方法 | A | 从进度记录中读出一个条目。 |
| `kindOf` | 静态方法 | B | 判断一个记录 id 属于哪个页面。 |
| [`toRecord`](#torecord) | 方法 | A | 把条目写回它的记录。 |
| `forInput` | 静态方法 | B | 为学习者刚提交的文本建立条目。 |
| [`historyEntries`](#historyentries) | 顶层函数 | A | 取出某一种历史，最新的在前。 |
| `_fnv1a64Hex`、`_fnv1a32`、`_fnvPrime` | 私有函数 | B | 把字符串哈希成 16 位十六进制。 |

## 文档

### `static String buildId(HistoryKind kind, String text, {String? unitId})` <a id="buildid"></a>

- **种类：** 静态方法
- **用途：** 为一个条目构造记录 id。
- **输入：** `kind`、`text`，以及存在时的 `unitId`。
- **返回：** `String`——`<前缀>:<16 位十六进制>`。
- **副作用：** 无。
- **算法：** 用换行把单元 id 和做过空白归一化的文本连起来，用两条仅偏移基不同的 FNV-1a 32 位通道哈希，再把结果拼成十六进制。
- **用法：** `forInput`，以及任何需要为某段文本找到既有条目的调用方。
- **注意：** 由内容而非随机决定，这买到三样东西。同一个句子分析两次会更新同一条记录并把它移到最前，而不是让历史里塞满重复项；两台设备分析了同一句话会得到相同的 id，从而合并成一条而不是产生冲突；同一个句子为两个练习写下时仍是两份作业，因为单元也是键的一部分。先做归一化，是为了不让一个多余的空格造出第二条。这个哈希是去重键，不是安全原语：一次碰撞的代价是一条历史被另一条遮住。

### `static HistoryEntry? fromRecord(StudyRecord? record)` <a id="fromrecord"></a>

- **种类：** 静态方法
- **用途：** 从进度记录中读出一个条目。
- **输入：** `record`，或 null。
- **返回：** `HistoryEntry?`——当记录不是历史记录、或其载荷读不出来时为 null。
- **副作用：** 无。
- **算法：** 匹配 id 前缀，从 `extraJson` 中取出 `history` 映射，再各自独立地读 `text` 与 `unitId`。`at` 取记录的 `modifiedAt`。
- **用法：** `historyEntries`、冲突对话框、`resolveStudyItemLabel`。
- **注意：** 绝不抛异常。由更新的构建写入、带有本构建读不懂字段的载荷仍然能加载，因为每个字段都是各自读取的。文本缺失或为空白的条目会被拒绝，而不是显示成一行学习者无从辨认的空白。

### `StudyRecord toRecord(StudyRecord? existing, DateTime now)` <a id="torecord"></a>

- **种类：** 方法
- **用途：** 把条目写回它的记录。
- **输入：** 已存在的 `existing` 记录（若有）与 `now`。
- **返回：** 可直接 upsert 的 `StudyRecord`。
- **副作用：** 无。
- **算法：** 以原有内容为底重建载荷，把已知字段覆盖上去，并保留 `extraJson` 的其余部分。`modifiedAt` 变为 `now`，这正是把条目移到最前的方式。
- **用法：** `NihongoStorage.recordHistory`。
- **注意：** 未知的载荷键会被保留，与档案遵循同一条规则：更旧的构建不得在第一次编辑时丢掉更新构建的字段。计数器保持为零——被记住的句子不是任何人作答过的东西，`studyRecords` 也因此把它排除在外。

### `List<HistoryEntry> historyEntries(Iterable<StudyRecord> records, {required HistoryKind kind, String? unitId})` <a id="historyentries"></a>

- **种类：** 顶层函数
- **用途：** 从进度文件中取出某一种历史。
- **输入：** `records`、想要的 `kind`，以及用于把写作历史收窄到某一个练习的 `unitId`。
- **返回：** `List<HistoryEntry>`，最新的在前。
- **副作用：** 无。
- **算法：** 读出每一条能解析成该种类条目的记录，再按 `modifiedAt` 降序排序，以 id 作为并列时的次序依据。
- **用法：** 两个 provider，以及 `NihongoStorage.recordHistory` 裁剪时。
- **注意：** 并列依据让顺序成为全序，因此在同一毫秒写入的两条不会在不同构建之间互换位置——这一点很重要，因为裁剪正是从这个列表的末尾丢弃的。`unitId` 为 null 表示不过滤，而不是「不属于任何单元的条目」。
