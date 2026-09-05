# lib/features/quiz/widgets/quiz_runner.dart

在屏幕上运行一次会话：题目、作答控件，以及两者之间的反馈。窗口形状合适时分成两栏，否则堆叠；门控是 `canSplitLayout`，与应用里其他每处分栏所用的相同。

题目栏可以在题面上方带一个页头，也可以为题目所关于的东西带一个前置组件，而且屏幕上的即时判分可以关掉——这正是计时的 JLPT 部分需要、而练习测验不需要的三样东西。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| [`QuizRunner`](#runner) | 类 | A | 在屏幕上运行一次会话。 |
| `_submit` | 方法 | B | 提交已组合好的作答，键入的答案还会请模型给出第二意见。 |
| `_advanceIfUnmarked` | 方法 | B | 在屏幕上不即时判分时直接前进。 |
| `_continue` | 方法 | B | 越过反馈进入下一题。 |
| `build` | 方法 | B | 构建题目与作答控件，分栏或堆叠。 |
| [`_feedback`](#feedback) | 方法 | A | 说明作答是否正确，以及正确答案是什么。 |
| `_QuestionPane` | 类 | B | 屏幕上提问的那一半：页头、进度、前置组件、题面。 |
| `didUpdateWidget` | 方法 | B | 题目变化时重新朗读，比较的除条目与模式外还有 `questionId`。 |
| [`_instruction`](#instruction) | 方法 | A | 用文字说明学习者被要求做什么。 |
| `_modeInstruction` | 方法 | B | 为没有自带说明的题目，说明这种模式在问什么。 |
| `QuizModeLabel` | 扩展 | B | 用学习者的语言为测验模式命名。 |

## 文档

### `class QuizRunner` <a id="runner"></a>

- **种类：** 类
- **用途：** 在屏幕上运行一次会话。
- **输入：** 要运行的 `session` 与 `onFinished`；可选的题面上方 `header`、为题目所关于之物准备的 `leadingBuilder`、是否 `showFeedback`，以及布局分栏时使用的 `questionPaneWidth`。
- **返回：** 一个组件（widget）。
- **副作用：** 它自己没有；判定作答是会话的副作用。
- **算法：** 构建题目栏与作答列，然后要么把它们堆进一个 `ListView`，要么并排放置，题目栏取 `questionPaneWidth(content)`。
- **使用：** `quiz_page.dart`，以及考试页。
- **说明：** 会话由上层页面拥有，并由它销毁。这四个可选参数是为考试页而设的，其默认值就是每一个既有调用方本来得到的东西，因此练习测验没有任何变化。

  `leadingBuilder` 是一个构建器而不是一个组件，因为它随题目变化，而只有运行器知道屏幕上是哪一道题。`showFeedback` 在模拟考试中为 false，那里的卷子是最后统一判分的：每答一道就被告知结果是练习教人的方式，也恰恰是真实考试最明显不做的事，所以同一个运行器必须两者都能做。`questionPaneWidth` 默认为 `quizQuestionPaneWidth`；考试页传入 `drillPassagePaneWidth`，因为阅读题比一个词需要更多空间。

### `Widget _feedback(BuildContext context, AppLocalizations l10n, QuizOutcome outcome, QuizQuestion question)` <a id="feedback"></a>

- **种类：** 方法
- **用途：** 说明作答是否正确，以及正确答案是什么。
- **输入：** 已判定的结果，以及它所关于的那道题。
- **返回：** `Widget`。
- **副作用：** 无。
- **算法：** 用主色或错误色显示一个图标和一个词，答错时另附期望答案，有模型评语时附上评语，并就学习者所选的那个选项给出 `WhyWrong`。
- **使用：** 位于作答控件与「继续」按钮之间，且仅在 `showFeedback` 开着时。
- **说明：** 答错之后总是显示正确答案。条目会在会话内被重新排队，而没被告知答案就重排的条目只会被再猜一次，而不是学会。`showFeedback` 关闭时，题目之间没有任何东西可读，所以 `_advanceIfUnmarked` 直接前进，而不是把学习者的时间花在一个「继续」按钮上。

### `String _instruction(AppLocalizations l10n)` <a id="instruction"></a>

- **种类：** 方法
- **用途：** 说明学习者被要求做什么。
- **输入：** `l10n`。
- **返回：** `String`。
- **副作用：** 无。
- **算法：** 题目自带非空的 `instruction` 时返回它；否则交给 `_modeInstruction`，由它按模式分支。
- **使用：** `_QuestionPane` 中题面上方那行灰色文字。
- **说明：** 每种模式都用文字说明，而不是依赖题目的外形，因为活用题的空格和助词题的空格长得一模一样。自带说明文字的题目保留它自己的：卷子是逐个大問写说明的，而两个在屏幕上看起来一模一样的大問要求的是不同的事情——「＿の言葉の読み方」与「＿の言葉の書き方」是同一个句子标记了同一段。把按模式分支的部分拆到 `_modeInstruction` 里，正是让这两条规则不至于纠缠在一起的做法：一条回答「这道题要求什么」，另一条回答「这种模式要求什么」，而只有后者有默认值。
