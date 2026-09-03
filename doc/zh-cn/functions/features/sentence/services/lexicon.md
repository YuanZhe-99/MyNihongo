# lib/features/sentence/services/lexicon.dart

内置目录与功能词表之上的"表层 → 词条"索引。`ContentCatalog` 按 id 查找词条，这正是参考页面所需要的；而阅读日语文本需要的是反方向——给定一串字符，它可能是哪些词条。

它服务两个调用方：发音评分（用 `toKana` 把识别器给出的汉字答案改写成可比较的读音），以及句子分析器（用其余全部功能）。

使用方：`pronunciation_scorer.dart`、`tokenizer.dart`、`deinflector.dart`、`sentence_analyzer.dart`、`pronunciation_practice_sheet.dart`。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `ConjClass` | 枚举 | B | 词如何活用：九个五段段位、一段、两个不规则动词，以及形容词。 |
| `LexEntry` | 类 | B | 为活用还原准备好的目录词条：词元、读音、类别、词干、类别、标注。 |
| `LexEntry.viaReading` | 字段 | B | 该候选是经由假名读音而非书写形式找到的。 |
| `LexEntry.asReadingMatch` | 方法 | B | 复制本词条，并标记为经由读音找到。 |
| `Lexicon` | 类 | B | 索引本身。 |
| [`build`](#build) | 静态方法 | A | 由目录与词表构建索引。 |
| `entryCount` | getter | B | 索引覆盖多少词条，用于诊断和测试。 |
| `byHeadword`、`byReading` | 方法 | B | 按书写形式或读音查找目录词条。 |
| `entriesAt` | 方法 | B | 查找某表层已准备好的词条——词格的词典查询。 |
| `conjugablesForStem` | 方法 | B | 查找词干恰为此的可活用词条。 |
| `functionWordsAt` | 方法 | B | 查找正是这样书写的功能词。 |
| `toKana` | 方法 | B | 把文本改写为假名，经由目录解析汉字。 |
| [`_classOf`](#classof) | 静态方法 | A | 判断目录词条如何活用。 |
| [`_categoryOf`](#categoryof) | 静态方法 | A | 判断目录词条产生哪种词元类别。 |

## 文档

### `static Lexicon build(ContentCatalog catalog, {FunctionWordTable functionWords})` <a id="build"></a>

- **种类：** 静态方法
- **用途：** 准备分析器与评分器需要的所有查询。
- **输入：** 目录，以及可选的功能词表。
- **返回：** `Lexicon`。
- **副作用：** 无。
- **算法：** 遍历词汇一次，构建五张映射：按书写形式、按读音、按已准备词条、可活用词按词干，以及功能词。
- **使用：** `lexiconProvider`，以及测试中的直接调用。
- **说明：** 在 7,700 词条上耗时数十毫秒，每次运行构建一次——这正是它是一个 provider 而不是页面在 `initState` 中所做之事的原因。经由读音到达的表层被索引为**独立对象**并标记 `viaReading`，因此调用方绝不会忘记它来自哪个索引；分词器为这种情况定更高的价。

### `static ConjClass _classOf(VocabEntry entry)` <a id="classof"></a>

- **种类：** 静态方法
- **用途：** 判断一个词如何活用。
- **输入：** 一个目录词条。
- **返回：** `ConjClass`。
- **副作用：** 无。
- **算法：** 词性标注决定词族；五段动词的段位取自**读音**的最后一个假名。
- **使用：** `build`。
- **说明：** 取读音而非书写形式，因为用汉字书写的动词以送假名结尾，而读音本来就把它拼了出来，且纯假名词条别无来源。标注为 `suru-verb` 的名词刻意**不**赋予动词活用类：目录里有的是名词，不是复合动词，凭空造出复合词会让词典里出现目录打不开的词。

### `static TokenCategory _categoryOf(VocabEntry entry)` <a id="categoryof"></a>

- **种类：** 静态方法
- **用途：** 判断目录词条是哪一类词。
- **输入：** 一个目录词条。
- **返回：** `TokenCategory`。
- **副作用：** 无。
- **算法：** 按固定顺序做标注判断。
- **使用：** `build`。
- **说明：** 这个顺序承载两项决定。名词排在量词、数词、前缀与后缀**之前**，因为同时标注为名词和量词的词绝大多数时候是名词，而量词读法需要前面有数字——分块器看得到，这里看不到。目录的 `auxiliary` 标注则完全不读：它被赋予了十几个只有在て形之后才是助动词的普通动词，在这里读取它会让它们在其他所有地方都不再是动词。
