# lib/features/quiz/services/ai_question_generator.dart

向设备上的模型索取关于某个单元的额外题目，并拒绝它可能说出的大部分内容。

这里的每一处写法都是为了让一个坏回答不产生任何代价。生成的题带 `QuizQuestion.generated`，因此不进 SM-2 调度器；索取发生在会话**已经**显示之后，所以等待模型永远不会拖慢第一题；每个回复都要先过 `parse` 里的规则才会变成题目。任何一条不过，就静默丢弃——因为没有它，这个会话本来就是完整的。

使用方：`quiz_page.dart`。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `maxGeneratedQuestions` | 常量 | B | 一个会话最多接收几道生成题（3）。 |
| `AiQuestionGenerator` | 类 | B | 索取关于某单元的额外题目。 |
| `AiQuestionGenerator.new` | 构造函数 | B | 保存单元、目录、提示词构建器、语言与服务。 |
| [`generate`](#generate) | 方法 | A | 题目到达即产出。 |
| `_words` | getter | B | 该单元的词，用来给提示词落地。 |
| [`parse`](#parse) | 静态方法 | A | 把一个模型回复变成题目，或者拒绝它。 |
| `_after` | 静态方法 | B | 取一行里标签之后的内容。 |

## 文档

### `Stream<QuizQuestion> generate({int limit, Set<String> avoid})` <a id="generate"></a>

- **种类：** 方法
- **用途：** 逐个生成题目，到达即产出。
- **输入：** `limit`——索取几道；`avoid`——会话里已有的题面。
- **返回：** 已接受题目的流。
- **副作用：** 每尝试一个语法点，就在设备上跑一次模型。
- **算法：** 按顺序遍历单元的语法点。对每一个构建提示词，交给 `AiPracticeService.runInBackground`（它会给交互请求让路并稍后重试），解析回复，若能解析且题面是新的就产出。到 `limit` 停止。
- **用法：** `quiz_page._generate`，在会话建好之后用 `unawaited` 启动。
- **备注：** 用流而不是列表，因为每道题一存在就有用：会话把它追加进去，学习者可能在下一道还在写的时候就答到了它。`avoid` 由已抽出的题面初始化，所以生成题不会重复题库确定性产出的那些。

### `static QuizQuestion? parse(String raw, {required GrammarPoint point})` <a id="parse"></a>

- **种类：** 静态方法
- **用途：** 把一个模型回复变成题目，或者拒绝它。
- **输入：** 回复 `raw` 和被问的语法点 `point`。
- **返回：** `QuizQuestion?`——只要有一处不对就是 null。
- **副作用：** 无。
- **算法：** 在各行里找 `Q:`、`A:`–`D:`、`Answer:` 和 `Why:`，半角全角冒号都认。然后是五类拒绝，每一类挡住一种具体故障：

  | 拒绝条件 | 原因 |
  |---|---|
  | 没有 `Q:` 行，或它为空 | 模型用散文作答 |
  | 句子里没有 `＿` 或 `_` | 什么也没在问 |
  | 选项不是四个 | 不是四选一 |
  | 有空选项 | 界面上会出现空白选项 |
  | 两个选项相同 | 两个正确答案 |
  | `Answer:` 指向不存在的选项 | 回复自相矛盾 |

- **用法：** `generate`；在 `ai_question_generator_test.dart` 里直接测试。
- **备注：** 这些都不能靠猜来修补，而**猜出来的题比没有题更糟**，因为在屏幕上它看起来和手写的题一样权威。测验界面在生成题上方显示的标注是这件事的另一半：见 [`ai-assist.md`](../../../../features/ai-assist.md)。
