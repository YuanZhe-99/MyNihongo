# lib/features/ai/services/writing_rewrite.dart

在只有校对模型的设备上，写作练习所提供的那份改写。

两项 GenAI 功能有各自的设备列表，而 Prompt API 的那份更窄，所以一台设备可能有校对而没有解释——多数非 Pixel 硬件都是如此，Galaxy Z Fold 8 也在其中。在 `v0.3.2` 之前，写作页面向 Prompt API 索取「改写加说明」，并在其不可用时隐藏按钮，于是一个能用的模型被闲置。需要 Prompt API 的是那些说明；改写本身恰恰就是校对器给出的东西。

使用方：`writing_practice_page.dart`。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| 库头 | 库文档 | B | 仅由校对器给出的改写。 |
| [`proofreadSentences`](#proofreadsentences) | 顶层函数 | A | 逐句校对并把结果拼起来。 |

## 文档

### `Future<String?> proofreadSentences(SentenceEnhancer enhancer, List<SentenceAnalysis> analyses)` <a id="proofreadsentences"></a>

- **种类：** 顶层函数
- **用途：** 用校对模型为整份写作给出改写。
- **输入：** `enhancer`，以及按书写顺序排列的 `analyses`。
- **返回：** `Future<String?>`——改写后的文本；当没有任何一句得到不同的建议时为 null。
- **副作用：** 每句一次推理，按顺序进行。
- **算法：** 依次对每份分析调用 `suggestCorrection`。非空白的建议替换该句并把结果标记为已改动；其余情况把学习者自己那句归一化后的原文带过。最后拼接，若毫无改动则返回 null。
- **用法：** 写作页面的 `_askProofreader`，在 `canProofread` 成立而 `canExplain` 不成立时。
- **注意：** **刻意串行。** AICore 每个应用一次只服务一次推理，`AiAssistService` 会以 `busy` 拒绝第二次，所以并发发出会让第一句之后的每一句都失败；有测试断言并发峰值为 1。把未改动的句子原样带过，才让结果读起来像一整份写作，而不是一份「哪些地方变了」的清单。当*毫无*改动时返回 null，和 `ResponseParser.correction` 在单句上遵循的是同一条规则：把学习者正确的文字当作改正还回去，等于告诉他们那是错的。`GenAiException` 被放行，好让页面去措辞说明原因。
