# lib/shared/providers/exam_provider.dart

JLPT 作答历史记录，由进度文件推导而来，好让页面同步地读取它，而不是在 build 方法里加载一个文件。

是普通的 `Provider` 而不是 notifier，形状与 `labHistoryProvider` 相同：进度文件才是状态，这些只是它的函数，因此在这里写下的、从备份还原的，或从另一台设备同步进来的作答，都以同样的方式抵达这个列表，没有第二个需要保持同步的真相来源。

消费方：`exam_history_page.dart`，以及经由 `askedQuestionsProvider` 的抽题器不重复规则。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| 库头 | 库文档 | B | 进度文件中考试记录的两个推导视图。 |
| [`examAttemptsProvider`](#examattemptsprovider) | provider | A | 每一次 JLPT 作答，最新的在前。 |
| [`askedQuestionsProvider`](#askedquestionsprovider) | provider | A | 哪些练习题已经被问过，以及是什么时候问的。 |

## 文档

### `examAttemptsProvider` <a id="examattemptsprovider"></a>

- **种类：** `Provider<List<ExamAttempt>>`
- **用途：** 给历史记录页面提供它的那些作答。
- **输入：** `progressDataProvider`。
- **返回：** 每一次 `exam:` 作答，最新的在前；文件正在加载或读不出来时为空。
- **副作用：** 自身没有；它只读取另一个 provider。
- **算法：** 通过 `asData` 读取进度数据，然后 `examAttempts(progress.records)`。
- **使用：** `ExamHistoryPage`，以及它下面的 `askedQuestionsProvider`。
- **说明：** 通过 **`asData` 而不是 `value`** 读取——在 riverpod 1.x 里，进度文件加载不出来时 `value` 会*重新抛出*，那会让每一个显示历史记录的页面崩掉，而不是显示一个空的。文件仍在加载时为空，也正是一个从未做过卷子的学习者所看到的，因此屏幕上没有任何东西需要把「尚未加载」和「还什么都没有」区分开来。

### `askedQuestionsProvider` <a id="askedquestionsprovider"></a>

- **种类：** `Provider<({Set<String> asked, Map<String, int> lastAsked})>`
- **用途：** 报告学习者已经被问过的每一道练习题，以及是什么时候问的。
- **输入：** `examAttemptsProvider`。
- **返回：** 一个记录，包含 `asked`——题目 id 的集合，以及 `lastAsked`——每个 id 映射到用过它的最近一次作答，单位是自纪元起的毫秒。
- **副作用：** 自身没有。
- **算法：** 从最新开始遍历那些作答，把每一道已作答的题目 id 加进集合，并 `putIfAbsent` 它所属作答的 `startedAt`。因为列表是最新在前，一道题第一次被看到就是它最近的一次作答，后面的不需要覆盖它。
- **使用：** 抽题器的整条不重复规则都读取它；测验页把两个字段都传给 `_drillQuestions`。
- **说明：** 由**已同步的**作答推导而来，这正是让两台设备互相避开对方问过的题、而不是各自把同样的头二十道题磨一遍的东西。于是保留多少次作答的上限，也就是一道题重新变得可问的那个点，而这是对「忘掉它」的一个合理定义。
