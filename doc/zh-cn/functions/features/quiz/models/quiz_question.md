# lib/features/quiz/models/quiz_question.dart

一道题目，其形状为所有模式与所有作答控件所共用。

只用一个类，而不是每种模式一个子类。各模式的差别在于显示什么、选项从哪里来，而不在于怎么作答——作答形状只有三种——所以密封类层次会变成十三个类塞进三个控件后面。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| 库头 | 库文档 | B | 一道题目，其形状为所有模式所共用。 |
| [`QuizMode`](#quizmode) | 枚举 | A | 应用可以提问的每一种方式。 |
| `AnswerKind` | 枚举 | B | 题目如何作答：选择、输入或排序。 |
| `vocabQuizModes`、`kanaQuizModes`、`grammarQuizModes` | 常量 | B | 各内容库支持的模式。 |
| `parsedQuizModes` | 常量 | B | 需要句子分析器、没有它就会被丢弃的模式。 |
| `listeningQuizModes` | 常量 | B | 朗读而非显示的模式。 |
| [`selectableQuizModes`](#selectable) | 常量 | A | 学习者可以关闭的模式，也就是偏好里「所有模式」所指的范围。 |
| [`QuizQuestion`](#question) | 类 | A | 一道题目。 |
| `answerText` | getter | B | 正确选项的文本，用于答错后显示。 |

## 文档

### `enum QuizMode` <a id="quizmode"></a>

- **种类：** 枚举
- **用途：** 为应用可以提问的每一种方式命名。
- **输入：** 无。
- **返回：** 无。
- **副作用：** 无。
- **算法：** 无。
- **使用：** 生成器、设置里的模式开关、`quizModes` 偏好，以及 `DrillQuestion.toQuizQuestion`。
- **说明：** **每个值的名字都是兼容性契约。** 它正是 `quizModes` 偏好所存储的内容，因此重命名某个值会悄悄把学习者关掉的模式重新打开。后来新增的值对所有人默认开启，这也正是偏好键缺失所表示的含义，以及从未主动关闭过它的人所期待的行为。

  `QuizMode.drill` 是例外，它**不可选**。其余十六个是本应用就一个目录条目想出题目的方式，学习者可以逐个开关它们。`drill` 意味着这道题是为一份卷子而写的，它自己就说明了它要什么，所以关掉它只等于拒绝去做这份卷子——而不打开它本来就已经是这个意思了。

### `const selectableQuizModes` <a id="selectable"></a>

- **种类：** 顶层常量
- **用途：** 指明学习者可以关闭的那些模式。
- **输入：** 无；它是 `vocabQuizModes`、`kanaQuizModes` 与 `grammarQuizModes` 的并集。
- **返回：** 无。
- **副作用：** 无。
- **算法：** 无。
- **使用：** 设置里的模式开关，以及每一处需要把「所有模式都开着」明确写出来的地方。
- **说明：** `QuizMode.drill` 刻意不在其中。偏好里「所有模式都开着」指的是这个集合，**不是** `QuizMode.values`，因此一个什么都没关过的学习者保持着空集这一默认值，仍然会得到后续版本新增的任何模式。

### `class QuizQuestion` <a id="question"></a>

- **种类：** 类
- **用途：** 以所有模式与所有作答控件共用的形状持有一道题目。
- **输入：** 全部字段；`itemId`、`mode`、`kind` 与 `prompt` 为必填，其余默认为缺省或空。
- **返回：** 一个不可变值。
- **副作用：** 无。
- **算法：** 无；`answerText` 是唯一的派生值。
- **使用：** `QuestionGenerator`、`QuestionBank`、`AiQuestionGenerator`、`DrillQuestion.toQuizQuestion`；由 `QuizSession`、`QuizRunner` 与 `AnswerPane` 读取。
- **说明：** 自带一条规则的那些字段：

`itemId` 是作答被记到的那个目录 id，它并不总是题目所显示的东西——助词题显示的是一个句子，考的却是一个语法点。

`questionId` 是练习题自己的 id，生成的题为 null：由同一个目录条目造出的两道题，就是同一道题问了两遍。练习题需要它，因为一份卷子会围绕同一个词问好几道不同的题，而会话对它们分别计分——见 `QuizSession.scoreKey`。

`instruction` 是这一道题具体在问什么，用于模式标签本身说不清楚的时候。练习题文件自己写这一行，因为卷子就是这么做的：「＿＿の　ことばは　どう　よみますか」和「（　）に　なにを　いれますか」不是同一个要求，而在运行器看来两者都长得像 `QuizMode.grammarParticle`。

`passageId` 只是一个 id：文章本身属于文件，而且好几道题共用一篇，所以由页面把它接回去。

`generated` 说明这道题是模型写的而不是来自目录。生成的题会带上其他每一样生成之物都带的那个标注，而且**它的作答绝不会到达调度器**：一个词的复习间隔不能取决于一道可能把这个词讲错了的题。
