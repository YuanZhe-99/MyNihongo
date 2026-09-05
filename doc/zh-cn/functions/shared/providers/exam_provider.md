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
| `drillQuestionsProvider` | provider | B | 按 id 索引的全部内置练习题——报告与结果界面都需要的那次连接。 |
| [`weaknessReportProvider`](#weaknessreportprovider) | provider | A | 学习者在自己级别的最近几份卷子上最薄弱的地方。 |
| [`readinessProvider`](#readinessprovider) | provider | A | 学习者对目标级别看起来准备到什么程度。 |
| `_coverage` | 函数 | B | 说出学习者接触过一个级别目录里多大比例的内容。 |
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

### `weaknessReportProvider` <a id="weaknessreportprovider"></a>

- **种类：** `Provider<WeaknessReport>`
- **用途：** 报告学习者在自己级别的最近几份卷子上最薄弱的地方。
- **输入：** `drillQuestionsProvider`、`examAttemptsProvider`、`learnerProfileProvider`。
- **返回：** `WeaknessReport`；它需要的东西还在加载时返回 `empty`。
- **副作用：** 自身没有。
- **算法：** 对这些作答调用 `WeaknessReport.build`，与全部内置题目做连接。
- **使用：** 薄弱点页面、学习页卡片上的标签、`readinessProvider`，以及经由 `prioritizedIds` 的 `reviewQueueProvider`。
- **说明：** 加载期间为空，也正是一个什么都没做过的学习者看到的样子，所以屏幕上没有任何东西需要区分这两种情况。这里之所以安全，恰恰是因为报告只重排复习队列而不往里加东西——在练习题文件读完之前构建的队列是旧的排序，不是错的排序。

  `drillQuestionsProvider` 会读取每个级别的四个文件。它是一个 `FutureProvider`，所以没有东西会因它阻塞；它也是"一次作答里**只保存输入**"这条规则的连接点：部分、大问和目录 id 全都来自今天的文件。

### `readinessProvider` <a id="readinessprovider"></a>

- **种类：** `Provider<ReadinessEstimate>`
- **用途：** 说出学习者对目标级别看起来准备到什么程度。
- **输入：** `learnerProfileProvider`、`jlptStructureProvider`、`weaknessReportProvider`、`contentCatalogProvider`、`progressDataProvider`，以及 `TtsService.instance.hasJapaneseVoice`。
- **返回：** `ReadinessEstimate`；结构文件加载完成之前是 `unknown`。
- **副作用：** 自身没有。
- **算法：** 带着该级别的结构、报告、`_coverage` 和设备是否有日语语音调用 `ReadinessEstimate.build`。
- **使用：** 学习页卡片。
- **说明：** 是一个档位，从来不是一个数字，也从来不称作 JLPT 成绩——为什么没有应用能算出成绩，见
  [`../../features/drills/services/readiness_rules.md`](../../features/drills/services/readiness_rules.md)
  与 `algorithms/readiness-estimate.md`。

  目录或进度文件还没加载完时 `_coverage` 返回 1，所以启动慢的时候显示的是卷子挣来的档位，而不是一个没有解释的压制。那里的"接触过"指的是存在学习记录——至少答过一次——而不是已经掌握：这个估计只用它来压住一个"可以了"的档位，所以宽松的读法才是对的。

### `askedQuestionsProvider` <a id="askedquestionsprovider"></a>

- **种类：** `Provider<({Set<String> asked, Map<String, int> lastAsked})>`
- **用途：** 报告学习者已经被问过的每一道练习题，以及是什么时候问的。
- **输入：** `examAttemptsProvider`。
- **返回：** 一个记录，包含 `asked`——题目 id 的集合，以及 `lastAsked`——每个 id 映射到用过它的最近一次作答，单位是自纪元起的毫秒。
- **副作用：** 自身没有。
- **算法：** 从最新开始遍历那些作答，把每一道已作答的题目 id 加进集合，并 `putIfAbsent` 它所属作答的 `startedAt`。因为列表是最新在前，一道题第一次被看到就是它最近的一次作答，后面的不需要覆盖它。
- **使用：** 抽题器的整条不重复规则都读取它；测验页把两个字段都传给 `_drillQuestions`。
- **说明：** 由**已同步的**作答推导而来，这正是让两台设备互相避开对方问过的题、而不是各自把同样的头二十道题磨一遍的东西。于是保留多少次作答的上限，也就是一道题重新变得可问的那个点，而这是对「忘掉它」的一个合理定义。
