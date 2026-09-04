# lib/features/writing/views/writing_practice_page.dart

写作练习：来自课程单元的题目、一个输入框，以及一次对每句运行句子实验室自身分析的检查。功能本身在
[`../../../../features/writing-practice.md`](../../../../features/writing-practice.md) 中描述。

`/writing` 上的整屏路由，在外壳之外，从带有 `writingPrompt` 的单元进入。

使用方：`router.dart`；由 `lesson_path_view.dart` 打开。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `WritingPrompt` | 类 | B | 一个写作练习是关于什么的，作为路由的 `extra` 传入。 |
| `writingWordTarget` | 顶层常量 | B | 一份写作应当用上本单元多少个词。 |
| `WritingPracticePage` | 类 | B | 页面本身。 |
| `_onAiChanged` | 方法 | B | 端侧 AI 状态变化时重建。 |
| [`build`](#build) | 方法 | A | 以单栏或双栏构建页面。 |
| `_buildInput` | 方法 | B | 题目、输入框与按钮行。 |
| `_canExplain`、`_canProofread` | getter | B | 可以提供哪一项端侧功能。 |
| `_aiText` | 方法 | B | 措辞表述模型产出的内容。 |
| [`_deterministic`](#deterministic) | 方法 | A | 显示应用自己能说的话。 |
| `_catalog` | getter | B | 内容目录，加载中时为 null。 |
| [`_unitWordsUsed`](#unitwordsused) | 方法 | A | 统计学习者实际用到的本单元词。 |
| [`_check`](#check) | 方法 | A | 对所写内容运行确定性流水线。 |
| `_remember` | 方法 | B | 把所写内容加入历史记录。 |
| `_openHistory` | 方法 | B | 把一份被记住的写作放回并重新检查。 |
| `_deleteHistory` | 方法 | B | 忘掉一份被记住的写作。 |
| [`_ask`](#ask) | 方法 | A | 请模型改进所写内容。 |
| `_askPrompt` | 方法 | B | 向 Prompt API 索取改写与说明。 |
| [`_askProofreader`](#askproofreader) | 方法 | A | 请校对器逐句改正。 |

## 文档

### `Widget build(BuildContext context)` <a id="build"></a>

- **种类：** 方法
- **用途：** 按所处窗口排布页面。
- **输入：** 构建 context。
- **返回：** `Widget`。
- **副作用：** 在按下按钮之前无。
- **算法：** 先构建一次反馈列表，然后要么是一个上限为 `pageMaxContentWidth` 的 `ListView`，要么是一个 `Row`：宽度为 `labInputPaneWidth` 的输入栏加占据其余部分的反馈，由 `canSplitLayout` 对整块屏幕判定。
- **用法：** `/writing` 路由。
- **注意：** 与句子实验室同一条规则，理由也相同：关于某一句的反馈是一条链，保持单列；而题目、输入框和历史记录在有地方时进入自己那一栏。低于门槛时历史记录移到顶栏按钮后面。`_buildInput` 由两个分支共用，因此两种布局不可能各自漂移。

### `List<Widget> _deterministic(BuildContext context, AppLocalizations l10n)` <a id="deterministic"></a>

- **种类：** 方法
- **用途：** 显示应用自己的答案，它在没有模型时就是完整的练习。
- **输入：** `context`、`l10n`；读取分析结果与单元。
- **返回：** 确定性部分的各个 widget。
- **副作用：** 无。
- **算法：** 练习来自单元时先给出用词计数，然后每句一个 `AnalysisResultView`，多于一句时编号。
- **用法：** `build`。
- **注意：** 改用 `AnalysisResultView` 而不是私有布局，这正是 `v0.3.2` 的改动：本页此前画的是没有标题的词块和光秃秃的问题列表，于是学过句子实验室的人在这里遇到的是同一份答案的更薄版本。只有一句时不编号，因为有「第 1 句」却没有第 2 句只是噪音。

### `Set<String> _unitWordsUsed()` <a id="unitwordsused"></a>

- **种类：** 方法
- **用途：** 统计这份写作实际用上了本单元多少个词。
- **输入：** 无；读取分析结果与单元。
- **返回：** 目录 id 的 `Set<String>`。
- **副作用：** 无。
- **算法：** 收集所有落在本单元词表内的 token `refId`。
- **用法：** `_deterministic`。
- **注意：** 计数来自**分词结果**而不是在文本里搜索，所以变形也算：写了 食べました 的人用到了 食べる。子串搜索会漏掉这一点，还会把一个词匹配到另一个词内部。

### `Future<void> _check()` <a id="check"></a>

- **种类：** 方法
- **用途：** 分析输入框里的内容。
- **输入：** 无；读取输入框。
- **返回：** 无。
- **副作用：** 未构建时构建分析器；写入历史记录；触发重建。
- **算法：** 按日语句号切分，逐段分析，保留分析器的 enhancer，然后记住这段文本。
- **用法：** 检查按钮，以及 `_openHistory`。
- **注意：** 切分而不是整体分析，因为分析器是为一次一句设计的。这里不会为写作得分写入任何进度记录——一份写作不是带复习间隔的条目。被写下的是文本，写进历史，且那里的失败会被吞掉：屏幕上的反馈才是功能本身。

### `Future<void> _ask()` <a id="ask"></a>

- **种类：** 方法
- **用途：** 用设备拥有的那个模型提供改写。
- **输入：** 无。
- **返回：** 无。
- **副作用：** 在设备上运行模型。
- **算法：** 有 Prompt API 时走 `_askPrompt`，否则走 `_askProofreader`。
- **用法：** 改写按钮，它在任一功能就绪时出现。
- **注意：** 两条路径，因为两项端侧功能回答的是不同问题，而设备可能拥有其中任一项。在 `v0.3.2` 之前这里只由 Prompt API 决定，于是一台校对功能可用的设备什么也得不到。按钮文案随路径改变，因为两者承诺的分量不同。

### `Future<void> _askProofreader()` <a id="askproofreader"></a>

- **种类：** 方法
- **用途：** 用校对模型改正每一句。
- **输入：** 无；读取分析结果。
- **返回：** 无。
- **副作用：** 每句一次推理，按顺序进行；触发重建。
- **算法：** 若尚未分析过任何内容则先运行 `_check`，然后调用 `proofreadSentences`。返回 null 时显示「没有给出不同写法」那一行。
- **用法：** 在只有校对功能的设备上由 `_ask` 调用。
- **注意：** 句子必须先经过分析，因为交给校对器的是分析所指的那句**归一化**文本；因此没有按过「检查」的学习者会得到自动为他跑一遍的确定性流程，而不是一个错误。串行顺序与「未改动即不提供」的规则见 [`../../ai/services/writing_rewrite.md`](../../ai/services/writing_rewrite.md)。
