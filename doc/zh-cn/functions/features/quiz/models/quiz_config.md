# lib/features/quiz/models/quiz_config.dart

一次测验会话的内容与长度。作为 `extra` 传给 `/quiz` 路由。

来源是一个密封类层次，因为进入测验的五种方式确实是不同的问题——哪些到期、哪些是新的、这些假名行、这个级别、这些 id——而单一的「所有字段可空」的类会允许其中两个同时被设置。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| 库头 | 库文档 | B | 说明一次测验会话的内容。 |
| `QuizSource` | 密封类 | B | 会话的条目从哪里来。 |
| `DueReviews`、`NewItems` | 类 | B | 复习队列的两半。 |
| [`KanaRows`](#kanarows) | 类 | B | 假名表中选中的行。 |
| `LevelSource` | 类 | B | 某个内容库某个 JLPT 级别的全部内容。 |
| `IdsSource` | 类 | B | 一个显式的目录 id 列表。 |
| `QuizConfig` | 类 | B | 一次会话的设置。 |

## 文档

### `class KanaRows` <a id="kanarows"></a>

行是**按下标**选取的，而不是按标签。`kanaBasicRows` 里有两行都标为 `n`——な行和ん——因此标签不是键，按标签寻址会悄悄测到错误的行。
