# lib/features/sentence/models/sentence_analysis.dart

分析器产出的一切：文节、语法匹配、问题、承载它们的分析对象，以及端侧模型将来接入的接缝。

使用方：`sentence_analyzer.dart`、`chunker.dart`、`sentence_checks.dart`，以及 `features/sentence/widgets/` 下的四个 widget。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `Bunsetsu` | 类 | B | 一个实词加上依附于它的成分，以及它依附于什么。 |
| `GrammarMatch` | 类 | B | 句中找到的一个已收录语法点，带词元跨度。 |
| `GrammarMatch.span` | getter | B | 匹配覆盖多少词元，用于解决重叠。 |
| `IssueKind` | 枚举 | B | 检查可能提出的五类问题。 |
| `Issue` | 类 | B | 一条定位到句中的可能问题，带可选的建议。 |
| `SentenceAnalysis` | 类 | B | 分析一个句子的完整结果。 |
| `SentenceAnalysis.hasUnknown` | getter | B | 是否存在完全读不出来的内容。 |
| [`toFixtureString`](#tofixturestring) | 方法 | A | 把分析渲染成一行，用于 fixture 比对。 |
| [`SentenceEnhancer`](#enhancer) | 抽象类 | A | 端侧模型将来接入的接缝。 |
| `SentenceEnhancer.isAvailable` | 方法 | B | 报告端侧模型是否存在并已启用。 |
| `SentenceEnhancer.explain` | 方法 | B | 用界面语言、以更多文字解释一条问题或整个句子。 |
| `SentenceEnhancer.suggestCorrection` | 方法 | B | 给出整句的修改写法。 |

## 文档

### `String toFixtureString()` <a id="tofixturestring"></a>

- **种类：** 方法
- **用途：** 把一次完整分析放在一行里，使它的变化能在 diff 中显现。
- **输入：** 无。
- **返回：** 以 ` | ` 分隔的四个字段：词元、文节依存、语法 id、问题类型。
- **副作用：** 无。
- **算法：** 每个字段由对应列表拼接而成；语法或问题列表为空时用一个短横线。
- **使用：** `test/sentence_analyzer_test.dart`。
- **说明：** 刻意可读而非紧凑。fixture 的编写方式是录制之后读 diff，因此错误的解析必须一眼可见——哈希或 JSON 块会让一次回归和一次正常改动同样容易被通过。

### `abstract class SentenceEnhancer` <a id="enhancer"></a>

- **种类：** 抽象类
- **用途：** 声明可选的端侧模型被允许做什么。
- **输入：** —
- **返回：** —
- **副作用：** 实现会在设备上运行模型。
- **算法：** —
- **使用：** `SentenceAnalyzer.enhancer`，在当前所有构建中都为 null。
- **说明：** `PLAN.md` M2.3 把 AICore / Gemini Nano 保留为一项永不成为事实来源的增强。目前没有任何实现。它的存在是为了在"想要加一个"的压力出现之前就把形状定下来，并让分析器有一个安放它的位置——而那个位置**不是**流程中间：无论模型在不在，它之上的每个阶段都保持确定性且可测试。
