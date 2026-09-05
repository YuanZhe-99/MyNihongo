# lib/features/ai/services/practice_prompt_builder.dart

为练习类功能构建提示词：写作反馈、给自由作答判分、说明为什么答错、额外的例句、额外的测验题，以及对这道题的第二意见。

每个提示词都落在应用已经算出或已经显示的东西上——学习者自己写的文字、目录自己的解释、屏幕上原样的题目。这是让生成的答案与应用其余部分保持一致的原因，也是为什么这里从不向模型提关于日语的开放问题。

模板来自 `assets/content/prompts/practice.json`，所以措辞、上限和规则都是内容而不是代码。模板缺失或落地材料不可用时，每个方法都返回 null，于是资源加载失败的构建只是不提供 AI 操作，而不会给模型发一条空指令。

使用方：`generated_examples.dart`、`why_wrong.dart`、`quiz_runner.dart`、`writing_practice_page.dart`、`ai_question_generator.dart`。

在 `v0.4.3` 之前，`forExamples` 取的是 `sentence` 与 `expected` 两个标签。它们都存在，所以没有回退、也没有报错——提示词只是把一个词报成「Sentence:」、把它的释义报成「The model answer:」，然后请模型写句子。当时也没有任何测试检查这个资源是否完整；现在 `ai_practice_test` 会检查每个任务都写了三种语言，以及每个构建器会去取的标签都有定义。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `practicePromptAsset` | 常量 | B | 练习提示词模板所在的位置。 |
| `PracticePromptBuilder` | 类 | B | 构建练习类提示词。 |
| `PracticePromptBuilder.new` | 构造函数 | B | 用一组模板构建提示词。 |
| `templates` | 字段 | B | 解析后的模板。 |
| `maxOutputTokens` | getter | B | 这些提示词的回答可以有多长。 |
| `forWriting` | 方法 | B | 请求改写学习者写的内容。 |
| `forGrading` | 方法 | B | 询问自由作答与参考答案是否同义。 |
| `forWhyWrong` | 方法 | B | 询问所选选项为什么是错的。 |
| `forExamples` | 方法 | B | 请求用某个词写例句。 |
| [`forQuizCheck`](#forquizcheck) | 方法 | A | 请模型回答一道生成的题目并对它作出判定。 |
| `forQuiz` | 方法 | B | 就某个单元请求一道额外的四选一题目。 |
| `_build` | 方法 | B | 用任务、标签和正文组装出一个提示词。 |

## 文档

### `String? forQuizCheck({required String question, required List<String> options, required Locale locale})` <a id="forquizcheck"></a>

- **种类：** 方法
- **用途：** 请模型回答一道生成的题目，并判断这道题是否成立。
- **输入：** 会被展示出来的 `question`、它的四个 `options`，以及 `locale`。
- **返回：** `String?` —— 题目为空、选项不是正好四个、或任一选项为空时返回 null。
- **副作用：** 无。
- **算法：** 写出题目，再写出标为 A 到 D 的四个选项，要求第一行只给一个字母，第二行只给 `SOUND` 或 `UNSOUND`。
- **使用：** `AiQuestionGenerator._survivesReview`，每道候选题一次。
- **说明：** **提示词里刻意不包含它给出的答案。** 把答案摆在模型面前问它对不对，它会说对；请模型自己把题做一遍，才会产生能够反对的东西，而只有后者才算检查。两个字母由调用方自己比较，只有一致且判定为 `SOUND` 时才保留这道题。
