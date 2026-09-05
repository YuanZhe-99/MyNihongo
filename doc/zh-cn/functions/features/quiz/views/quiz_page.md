# lib/features/quiz/views/quiz_page.dart

一次测验会话，作为标签页外壳之外的全屏路由——与句子实验室形状相同，理由也相同：它是带着目的进入、做完就离开的东西，而不是一个可供浏览的地方。

用 `context.push('/quiz', extra: config)` 进入。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `QuizPage` | 类 | B | 作为路由的测验会话。 |
| `_passages` | 字段 | B | 抽出的卷子所引用的文章，以 id 为键，好把正确的那一篇交给运行器。 |
| [`_build`](#build) | 方法 | A | 组装本次会话的题目。 |
| [`_drillQuestions`](#drill) | 方法 | A | 从随包发布的练习题文件里抽出一份卷子的题目。 |
| [`_passageFor`](#passagefor) | 方法 | A | 显示屏幕上这道题所关于的东西。 |
| `_enabledModes` | 方法 | B | 决定可用的模式，无语音时去掉听力模式。 |
| `_itemIds` | 方法 | B | 列出本次会话要提问的目录 id。 |
| `_kanaIds` | 方法 | B | 列出所选各行的假名 id。 |
| `_confirmLeave` | 方法 | B | 放弃进行中的会话前先确认。 |
| `build` | 方法 | B | 构建测验、总结，或说明为何两者都没有。 |
| `_empty` | 方法 | B | 说明没能生成任何题目。 |
| `_summary` | 方法 | B | 显示本次会话的结果。 |

## 文档

### `Future<void> _build()` <a id="build"></a>

- **种类：** 方法
- **用途：** 组装本次会话的题目。
- **输入：** 无；读取配置、内容库与复习队列。
- **返回：** 无。
- **副作用：** 构建 `QuizSession` 并重建页面。
- **算法：** await 内容库；仅当启用了语法模式时才 await 分析器；遍历来源的 id，用任一已启用模式向生成器要题，直到会话装满。
- **使用：** 一次，来自 `initState` 中的 post-frame 回调。
- **说明：** 之所以有条件地 await 分析器，是因为在 7,700 个词条上构建词典要花几十毫秒，而假名测验根本用不上它。在首帧之后而不是在 `initState` 中运行，意味着内容库加载缓慢时会先显示带加载指示的页面，而不是阻塞路由切换。题目通过 `progressDataProvider` 按每次作答记录，而不是在结束时统一记录，因此中途被杀掉的应用仍保留已答的部分。`DrillSource` 走的是完全不同的路径：它的题目来自 `_drillQuestions` 而不是生成器，因为它们是为一份卷子而写的，不是从目录条目派生出来的。

### `Future<List<QuizQuestion>> _drillQuestions(DrillSource source, Locale locale)` <a id="drill"></a>

- **种类：** 方法
- **用途：** 从随包发布的练习题文件里抽出一份卷子的题目。
- **输入：** `source`，以及用来渲染书面文字的 `locale`。
- **返回：** `Future<List<QuizQuestion>>`，按卷子的顺序排列。
- **副作用：** 读取资源；填充 `_passages`。
- **算法：** await 结构文件与该级别的四个文件；取来源所用规模下的题目构成；收窄到所要的部分；然后按 `DrillSection` 的顺序逐个部分，把筛选后的题量交给 `DrillSampler.drawByPassage`，用 `toQuizQuestion` 适配每一道抽出的题，并留下它所引用的那篇文章。
- **使用：** `_build`，用于 `DrillSource`。
- **说明：** 仅在本文件内部使用的辅助函数。题目构成来自 `structure.json` 并按部分筛选，因此只考 文法 的一次会话会按卷子的题量出语法的那些大問，别的都不出。结构文件里没有条目的级别什么也不抽，而不是猜一个题目构成——Learn 卡片本来就拒绝提供没有内容的部分，所以能空着走到这里说明有什么地方出错了，而凭空造一份卷子会把它藏起来。没有日语语音时听力被丢弃，这与 `_enabledModes` 对应用自己的听力模式所施加的规则相同：没人听得见的题目没有答案。

### `Widget? _passageFor(BuildContext context, QuizQuestion question)` <a id="passagefor"></a>

- **种类：** 方法
- **用途：** 显示屏幕上这道题所关于的东西。
- **输入：** `context` 与 `question`。
- **返回：** `Widget?`——题目自成一体时为 null。
- **副作用：** 无。
- **算法：** 在 `_passages` 里查这道题的 `passageId`；听力文章渲染成 `ListeningScriptPlayer`，其余一律渲染成 `DrillPassageView`，以文章 id 为 key，并且只有在会话已有结果之后才展开。
- **使用：** 作为 `leadingBuilder` 传给 `QuizRunner`。
- **说明：** 仅在本文件内部使用的辅助函数。阅读文章是显示出来，听力脚本是播放出来，由**文章**自己的类型而不是题目的类型来决定，因为 文章の文法 是一道关于一段被阅读的文本的语法题。听力原文与译文都只在题目作答之后才展开——在那之前它们就是答案。
