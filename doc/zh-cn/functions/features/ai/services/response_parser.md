# lib/features/ai/services/response_parser.dart

判断模型返回的东西是否值得展示，值得的话再把它清理干净。

一个被要求写四句白话的小模型，有时会回以标题、项目符号列表、代码围栏、把提示词复述一遍，或者什么都不回。这里的一切都是纯函数并有单元测试，这正是把它留在 widget 之外、平台通道之外的意义。

使用方：`aicore_sentence_enhancer.dart`。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `ResponseParser` | 类 | B | 清理规则。 |
| `maxExplanationChars` | 常量 | B | 展示的解释最长可以多长。 |
| [`explanation`](#explanation) | 静态方法 | A | 把原始输出变成一段话，或 null。 |
| [`correction`](#correction) | 静态方法 | A | 挑出唯一值得提供的改写。 |
| `_stripFences` | 静态方法 | B | 去掉包住整个回答的代码围栏。 |
| `_stripLineMarkup` | 静态方法 | B | 去掉项目符号、编号、标题与强调。 |
| `_isEcho` | 静态方法 | B | 判断回答是否只是提示词的复述。 |
| `_capAtSentence` | 静态方法 | B | 在放得下的最后一个句末处截断长文本。 |
| `_normalize` | 静态方法 | B | 为比较而归一化文本。 |

## 文档

### `static String? explanation(String raw, {String? prompt})` <a id="explanation"></a>

- **种类：** 静态方法
- **用途：** 把原始输出变成值得放到页面上的东西。
- **输入：** `raw`，以及它所回答的 `prompt`。
- **返回：** `String?` —— 没有可用内容时为 null。
- **副作用：** 无。
- **算法：** 去空白、拆围栏、逐行去标记、合并空行、拒绝复述、在句子边界截断。
- **使用：** `AiCoreSentenceEnhancer.explain`。
- **说明：** 拒绝复述是其中最关键的一步。用学习者自己的句子作答的模型并没有回答，而把它**标注为解释**再展示回去既教不了东西又损耗信任。标记被剥除而不是渲染，因为卡片画的是纯文本，落下的星号就会原样显示成星号。强调用 `replaceAllMapped` 而非 `replaceAll` 去除——Dart 的字符串替换不会展开 `$1`，本文件的第一版就一直原样打印 `$1`，直到一个测试发现它。

### `static String? correction(List<String> suggestions, String original)` <a id="correction"></a>

- **种类：** 静态方法
- **用途：** 判断校对器到底有没有提出什么。
- **输入：** 模型给出的 `suggestions` 与 `original` 原句。
- **返回：** `String?` —— 没有一条说出新东西时为 null。
- **副作用：** 无。
- **算法：** 返回第一条在去掉空白后与输入不同的建议。
- **使用：** `AiCoreSentenceEnhancer.suggestCorrection`。
- **说明：** 校对器拿到一个**正确**的句子时会原样返回该句子。把它当作修改建议端出来等于告诉学习者他们正确的句子写错了，所以它被丢弃，界面改说无需修改。比较前把空白**去掉**而不是合并，因为日语本来就不写空格，模型也可能随意增删空格——只在空格上不同的建议同样不是修改。这一点已在设备上确认：校对 API 对一个写法正确的句子返回的正是原句。
