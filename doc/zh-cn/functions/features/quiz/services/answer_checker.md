# lib/features/quiz/services/answer_checker.dart

判断一次作答是否正确。

与控件分开，因为判分不是渲染的事；也因为输入型作答比字符串相等更宽容：用日语键盘的学习者产出假名，没有输入法的产出罗马字，两者都不算错。**不**被宽容的是不同的读音——が和か是不同的词，把它们归一化到一起就是在教它们相同。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| 库头 | 库文档 | B | 判断一次作答是否正确。 |
| `QuizAnswer` | 密封类 | B | 学习者对一道题做了什么。 |
| `ChoiceAnswer`、`TypedAnswer`、`OrderAnswer` | 类 | B | 三种作答形状。 |
| `AnswerChecker` | 类 | B | 判分；`const AnswerChecker({toKana})`。 |
| `toKana` | 字段 | B | 可选；通过目录（`Lexicon.toKana`）把一句键入句子的词逐个读成假名。是一个函数而不是词典本身，因此本文件不 import 句子分析器的任何东西。 |
| `check` | 方法 | B | 判一次作答。 |
| `_checkTyped` | 方法 | B | 对照两种可接受写法判输入型作答；`grammarTypeSentence` 题会转去 `_checkSentence`。 |
| `_checkSentence` | 方法 | B | 判一句键入的句子：先用 `toHiragana` 对照可接受集合，再用 `toKana` 把答案读成假名后再对照一次。接受写错了汉字的同音词，永远不接受罗马字。 |
| `_checkOrder` | 方法 | B | 按所选位置是否递增来判排序题。 |
