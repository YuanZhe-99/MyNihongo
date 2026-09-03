# lib/features/sentence/models/function_word.dart

`assets/content/function_words.json` 的模型：助词、系动词各形、助动词与形式名词，以及各项检查所读的命名词集。

对同一表层而言，该表**优先于词汇目录**。提示助词与一个常见名词写法相同，而它是助词的时候远多于另一种；把两者等量齐观的分析器在大多数句子里都会出错。

使用方：`lexicon.dart`（建索引）、`tokenizer.dart`（据此提出候选）、`deinflector.dart`（词干形态）、`sentence_checks.dart`（词集）、`content_repository.dart`（加载它）。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `FunctionWordCategory` | 枚举 | B | 功能词做什么：四种助词角色、系动词、助动词、形式名词。 |
| [`StemShape`](#stemshape) | 枚举 | A | 助动词前面的词必须是什么形态。 |
| `FunctionWord` | 类 | B | 一个条目：id、表层、读音、类别、词元、所需词干、形式、释义。 |
| `FunctionWord.tokenCategory` | getter | B | 该词产生的词元类别。 |
| `FunctionWord.fromJson` | 静态方法 | B | 解析一个条目；不可用时返回 null 而非抛异常。 |
| `FunctionWord._categoryOf` | 静态方法 | B | 读取类别名。 |
| `FunctionWord._shapeOf` | 静态方法 | B | 读取所需词干形态；未知即 `any`。 |
| `FunctionWord._formOf` | 静态方法 | B | 读取一个形式名。 |
| `FunctionWordTable` | 类 | B | 整张表，外加命名词集与自他动词对。 |
| `FunctionWordTable.set` | 方法 | B | 查一个命名词集；缺失即为空，而非抛异常。 |
| `FunctionWordTable.fromJson` | 静态方法 | B | 解析资源，跳过不可用条目。 |
| `FunctionWordTable.pairsFromJson` | 静态方法 | B | 读取自他动词对，它们是嵌套数组。 |

## 文档

### `enum StemShape` <a id="stemshape"></a>

- **种类：** 枚举
- **用途：** 说明某个助动词接在什么后面。
- **输入：** —
- **返回：** —
- **副作用：** 无。
- **算法：** —
- **使用：** `Deinflector.stemsFor` 按它分支；`Tokenizer._stemEdges` 把它传下去。
- **说明：** **正是它让活用还原可以反向进行。** 敬体助动词声明 `masuStem`，简体过去声明 `teStem`，条件形声明 `eStem`，形容词过去声明 `adjectiveStem`；因此还原器在开始猜测动词类别之前就知道该尝试哪一次段位变换，各表也保持为"每类每形态一条规则"，而不是"每种形式一条"。`any` 是助词，它们接在任何东西后面，根本不需要词干。
