# lib/features/ai/services/aicore_sentence_enhancer.dart

用 Android AICore 填上 `SentenceEnhancer` 这个接缝。

这是三个部分唯一相遇的地方：`PromptBuilder` 把确定性分析变成提示词，`AiAssistService` 决定设备是否可以运行它，`ResponseParser` 决定回来的东西是否值得展示。让流水线各阶段对这三者一无所知，正是这个接缝的意义——设备上没有模型时，本文件以上的任何东西都不需要改变。

使用方：`sentence_analyzer.dart`，它把一个实例挂到 `SentenceAnalyzer.enhancer` 上。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `AiCoreSentenceEnhancer` | 类 | B | 该接缝的唯一实现。 |
| [`isAvailable`](#isavailable) | 方法 | A | 此刻是否可以生成解释。 |
| [`explain`](#explain) | 方法 | A | 解释某个问题点，或整个句子。 |
| [`suggestCorrection`](#suggestcorrection) | 方法 | A | 给出句子的修改写法。 |

## 文档

### `Future<bool> isAvailable()` <a id="isavailable"></a>

- **种类：** 方法
- **用途：** 报告这项操作是否值得提供。
- **输入：** 无。
- **返回：** `Future<bool>`。
- **副作用：** 无——读取服务最近已知的状态。
- **算法：** 返回 `service.canExplain`。
- **使用：** 接缝的契约；实验室直接读服务。
- **说明：** 底下其实是同步的，这是刻意的。真正的能力检查在每一次生成调用内部进行，所以这里只决定是否*提供*该操作——而 build 方法不能为了决定要不要画一个按钮去 await 一次平台调用。

### `Future<String?> explain(SentenceAnalysis, Issue?, String?, String languageCode)` <a id="explain"></a>

- **种类：** 方法
- **用途：** 解释某个问题点，或整个句子。
- **输入：** 分析结果；当请求针对某个问题时，还有该问题及其已措好辞的说明；以及界面语言码。
- **返回：** `Future<String?>` —— 没有可用内容时为 null。
- **副作用：** 在设备上运行 Gemini Nano。
- **算法：** 构建提示词、运行、解析回答。
- **使用：** `SentenceLabPage` 的逐问题与整句两种操作。
- **说明：** `GenAiException` 被放行，以便界面为原因措辞；**null 表示的是另一回事**——模型跑了，但没说出值得展示的话。两者在屏幕上读起来不同，把它们合并会让学习者去找一个并不存在的故障。

### `Future<String?> suggestCorrection(SentenceAnalysis analysis)` <a id="suggestcorrection"></a>

- **种类：** 方法
- **用途：** 给出句子的修改写法。
- **输入：** 分析结果。
- **返回：** `Future<String?>` —— 模型没给出不同写法时为 null。
- **副作用：** 在设备上运行校对模型。
- **算法：** 准备句子，过长则拒绝，执行推理，挑一条建议。
- **使用：** `SentenceLabPage`。
- **说明：** 送出的是**归一化后**的句子，也就是词元偏移和整个页面所指的那一个；送原始输入会得到一条与上方分析对不齐的建议。超过长度上限的句子抛 `tooLong` 而不是被截短，这样学习者会被告知，而不是悄悄拿到一条针对片段的修改建议。
