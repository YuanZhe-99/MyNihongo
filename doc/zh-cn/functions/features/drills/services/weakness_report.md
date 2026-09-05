# lib/features/drills/services/weakness_report.dart

根据学习者实际做过的卷子，说出他们最薄弱的地方。

纯函数，而且是**推导出来的，不是存下来的**。一旦把薄弱点写进文件，它就成了学习者甩不掉的判决；
从最近几次作答重新算出来，才让练习真的能改变它——这也是这样一份报告唯一值得展示的理由。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| library header | library doc | B | 根据做过的卷子说出学习者最薄弱的地方。 |
| `weaknessRecentAttempts` | 常量 | B | 报告回看多少次作答。 |
| `weaknessMinAsked` | 常量 | B | 一样东西被问过多少次才算薄弱点。 |
| `weaknessMaxPoints` | 常量 | B | 报告最多点名多少个薄弱点。 |
| `WeaknessTally` | 类 | B | 一样被问过的东西，以及答得如何。 |
| `WeaknessTally.plus` | 方法 | B | 加入一个结果。 |
| `WeaknessReport` | 类 | B | 最近几次作答里学习者最薄弱的地方。 |
| [`weakestItems`](#weakestitems) | getter | A | 最薄弱的目录条目，最差的排在最前。 |
| `weakestTypes` | getter | B | 最薄弱的大问，最差的排在最前。 |
| [`build`](#build) | 静态方法 | A | 根据学习者做过的卷子构建报告。 |
| [`prioritizedIds`](#prioritizedids) | 方法 | A | 点名值得提到复习队列最前面的条目。 |

## 文档

### `List<MapEntry<String, WeaknessTally>> get weakestItems` <a id="weakestitems"></a>

- **种类：** getter
- **用途：** 最薄弱的目录条目，最差的排在最前。
- **输入：** 除接收者外无。
- **返回：** 最多 `weaknessMaxPoints` 个条目。
- **副作用：** 无。
- **算法：** 保留被问过至少 `weaknessMinAsked` 次、且至少答错过一次的条目，按正确率升序排序，
  同分按 id 排序，取前十个。
- **用法：** 薄弱点页面、学习页卡片上的三个标签，以及 `prioritizedIds`。
- **注意：** **答对次数再少，全对也不是薄弱点**，所以"至少答错过一次"这一条不是优化——没有它，
  三次全对的词会排在"该去学的东西"列表最上面。同分按 id 排序是为了让顺序完全确定：正确率相同的两
  个条目不会在两次构建之间互换位置，否则页面看起来会在什么都没发生时自己变了。

### `static WeaknessReport build({required List<ExamAttempt> attempts, required Map<String, DrillQuestion> questions, String? level, int recent = weaknessRecentAttempts})` <a id="build"></a>

- **种类：** 静态方法
- **用途：** 根据学习者做过的卷子构建报告。
- **输入：** `attempts`，最新的在前；按 id 索引的全部内置题目 `questions`；要报告的 `level`，
  为 null 时不限级别；`recent`——回看多少次作答。
- **返回：** `WeaknessReport`；没有符合条件的内容时返回 `empty`。
- **副作用：** 无。
- **算法：** 先按级别筛选，取最近 `recent` 次，然后对每一道作答过的题目，把一个结果分别记入它所属
  部分、它的大问，以及它关联的每一个目录条目。
- **用法：** `weaknessReportProvider`。
- **注意：** 有三条规则在起作用。

  **连接是在这里做的，不是存下来的。** 一次作答只保存问了哪些题、答了什么；属于哪个部分、哪个大
  问、关联哪些目录条目，都是现在从内置文件读出来的——所以内容更正会同时反映到报告和历史里。

  **内置文件里已经没有的题目会被跳过**，而不是记到"无"名下。这少了一个数据点，是诚实的代价；记进
  去则会把薄弱点算在一个应用已经无法命名的大问上。

  **没作答的题完全不计入。** 是时钟把题目拿走的，把超时读成学习者日语上的漏洞，会让他们去学错误
  的东西。

### `Set<String> prioritizedIds(ContentCatalog? catalog)` <a id="prioritizedids"></a>

- **种类：** 方法
- **用途：** 点名值得提到复习队列最前面的目录 id。
- **输入：** `catalog`，好让已经不再内置的 id 不被提前。
- **返回：** `Set<String>`。
- **副作用：** 无。
- **算法：** `weakestItems` 的 id，筛掉目录里已经没有的。
- **用法：** `reviewQueueProvider`，传入 `ReviewQueue.build(prioritized:)`。
- **注意：** 队列**先**按这个排序，再按逾期程度排序。一个在卷子上反复答错的词，比一个只是恰好到
  期的词更值得接下来的五分钟。它只负责重排：不往队列里加东西，也不从里面拿掉东西，所以一份空的
  ——还没作答过，或者文件还没加载完的——报告，只是让学习者用回旧的排序，别无损失。
