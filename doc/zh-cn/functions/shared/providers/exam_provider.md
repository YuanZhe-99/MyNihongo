# lib/shared/providers/exam_provider.dart

JLPT 作答历史记录，由进度文件推导而来，好让页面同步地读取它，而不是在 build 方法里加载一个文件。

是普通的 `Provider` 而不是 notifier，形状与 `labHistoryProvider` 相同：进度文件才是状态，这些只是它的函数，因此在这里写下的、从备份还原的，或从另一台设备同步进来的作答，都以同样的方式抵达这个列表，没有第二个需要保持同步的真相来源。

`savedExamProvider` 是个例外，而且是刻意的：一份进行中的卷子是设备本地的，所以它是从自己的文件读取的，而不是从已同步的进度记录推导出来的。

消费方：`exam_history_page.dart`、`jlpt_practice_card.dart`、`exam_page.dart`，以及经由 `askedQuestionsProvider` 的抽题器不重复规则。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| 库头 | 库文档 | B | 进度文件中考试记录的两个推导视图，外加设备本地的那份进行中的卷子。 |
| [`examAttemptsProvider`](#examattemptsprovider) | provider | A | 每一次 JLPT 作答，最新的在前。 |
| [`savedExamProvider`](#savedexamprovider) | provider | A | 这台设备做了一半的那份卷子，如果有的话。 |
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

### `savedExamProvider` <a id="savedexamprovider"></a>

- **种类：** `FutureProvider<SavedExam?>`
- **用途：** 报告这台设备做了一半的那份卷子，如果有的话。
- **输入：** 无；它直接读取保存文件。
- **返回：** 由 `NihongoStorage.loadExamInProgress()` 解析出的 `SavedExam`；没有保存或本次构建无法继续它时为 null。
- **副作用：** 读取应用目录下的一个文件。
- **算法：** `SavedExam.fromJson(await NihongoStorage.loadExamInProgress())`。
- **使用：** `JlptPracticeCard`——用来提出继续、在替换之前询问，以及放弃——还有 `exam_page.dart`，它在每次保存之后刷新它。
- **说明：** 与本页其他一切不同，它是直接从保存文件读取的，而不是从进度文件：一份进行中的卷子是**设备本地的**，而另一台设备上的一场未完成的考试没有意义——计时属于这一次作答。因此它完全在同步与备份注册表之外；见 [`../../features/progress/services/nihongo_storage.md`](../../features/progress/services/nihongo_storage.md)。

  用 `FutureProvider`，好让 Learn 卡片在文件被读完之前就能渲染，而且是**通过 `invalidate` 而不是通过 watch**：这个文件由考试页写入、由卡片删除，两者都清楚知道自己是什么时候做的。那次刷新不是可有可无的——没有它，卡片会一直拿着它在这份卷子存在之前就解析完的那个 future，在本该提出继续的地方什么也不显示。

  读取 `SavedExam` 不必碰内容文件，正是这一点让卡片可以说出「N5 模拟考试，第 2 个计时部分，还剩 18 分钟」，而不必为此解析四个练习题文件。

### `askedQuestionsProvider` <a id="askedquestionsprovider"></a>

- **种类：** `Provider<({Set<String> asked, Map<String, int> lastAsked})>`
- **用途：** 报告学习者已经被问过的每一道练习题，以及是什么时候问的。
- **输入：** `examAttemptsProvider`。
- **返回：** 一个记录，包含 `asked`——题目 id 的集合，以及 `lastAsked`——每个 id 映射到用过它的最近一次作答，单位是自纪元起的毫秒。
- **副作用：** 自身没有。
- **算法：** 从最新开始遍历那些作答，把每一道已作答的题目 id 加进集合，并 `putIfAbsent` 它所属作答的 `startedAt`。因为列表是最新在前，一道题第一次被看到就是它最近的一次作答，后面的不需要覆盖它。
- **使用：** 抽题器的整条不重复规则都读取它；测验页把两个字段都传给 `_drillQuestions`。
- **说明：** 由**已同步的**作答推导而来，这正是让两台设备互相避开对方问过的题、而不是各自把同样的头二十道题磨一遍的东西。于是保留多少次作答的上限，也就是一道题重新变得可问的那个点，而这是对「忘掉它」的一个合理定义。
