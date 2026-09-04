# lib/features/lessons/models/lesson_path.dart

一个级别被划分成的单元，从 `assets/content/lessons/*.json` 解析而来。一个单元就是一个主题：一个名字、它所教的语法与词汇、为它写的句子，以及为它写的题目。

与目录其余部分一样宽容——坏掉的一行只损失那一行，而不是整个文件——只有一个例外：没有 id 的单元或题目会被丢弃，因为 id 正是进度记录所依据的东西。

使用方：`lesson_repository.dart`、`lesson_rules.dart`、`lesson_path_view.dart`、`question_bank.dart`、`reminder_planner.dart`。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `LessonPath` | 类 | B | 一个级别的各单元。 |
| [`LessonPath.fromJson`](#pathjson) | 工厂 | A | 解析一个 lessons 文件。 |
| `LessonPath.unitById` | 方法 | B | 按 id 查找单元。 |
| `LessonUnit` | 类 | B | 一个单元：主题及其所教内容。 |
| `LessonUnit.items` | getter | B | 该单元所教的全部目录 id。 |
| `LessonUnit.fromJson` | 方法 | B | 解析一个单元；无 id 则为 null。 |
| `UnitSentence` | 类 | B | 为某单元写的一个句子。 |
| `UnitSentence.fromJson` | 方法 | B | 解析一个句子；无日文则为 null。 |
| `UnitSentence.toExample` | 方法 | B | 以目录例句的形态呈现它。 |
| `AuthoredQuestion` | 类 | B | 一道手写题。 |
| [`AuthoredQuestion.fromJson`](#qjson) | 方法 | A | 解析一道题，或拒绝它。 |
| `_list` | 函数 | B | 无论是什么，都按列表读取一个 JSON 值。 |

## 文档

### `factory LessonPath.fromJson(Object? json)` <a id="pathjson"></a>

- **种类：** 工厂
- **用途：** 解析一个 lessons 文件。
- **输入：** 已解码的文件。
- **返回：** `LessonPath`——文件读不出来时为空。
- **副作用：** 无。
- **算法：** 读取级别标签与各单元，跳过解析不出来的单元。
- **用法：** `LessonRepository.load`。
- **说明：** 读不出来的文件是一条空路径而不是异常，此时 Learn 标签页会说该级别的单元尚未编写。对于内容没能加载的构建，这是诚实的做法；而对于没人写过的级别，这本来就是普通状态。

### `static AuthoredQuestion? fromJson(Object? json)` <a id="qjson"></a>

- **种类：** 方法
- **用途：** 解析一道手写题，或拒绝它。
- **输入：** 已解码的对象。
- **返回：** `AuthoredQuestion?`。
- **副作用：** 无。
- **算法：** 要求有 id、有 item id、至少两个选项，且答案下标落在选项范围内。
- **用法：** `LessonUnit.fromJson`。
- **说明：** 撰写门禁会在发布前拒绝格式错误的题目，因此这里是手工编辑该文件时的第二道防线。答案下标越界的题目根本无法作答，显示它只会浪费学习者的一轮。
