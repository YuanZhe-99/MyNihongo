# lib/features/sentence/services/sentence_analyzer.dart

运行整条句子流程——分词、分块、匹配语法、检查——并持有为它供料的三个 provider。

每个阶段都是确定性、离线且独立测试的。本文件只把它们串起来，也是可选端侧模型接入的位置，而任何阶段都不依赖它。

使用方：`sentence_lab_page.dart`。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `SentenceAnalyzer` | 类 | B | 流程门面。 |
| `SentenceAnalyzer.enhancer` | 字段 | B | 可选的端侧模型；当前所有构建中均为 null。 |
| [`analyze`](#analyze) | 方法 | A | 分析一个句子。 |
| `functionWordsProvider` | provider | B | 功能词表，每次运行加载一次。 |
| [`lexiconProvider`](#lexiconprovider) | provider | A | 表层到词条的索引，由目录与词表构建一次。 |
| `promptTemplatesProvider` | provider | B | 驱动可选端侧模型的提示词模板。 |
| `sentenceAnalyzerProvider` | provider | B | 可直接使用的分析器，在可能运行模型处挂接增强器。 |

## 文档

### `SentenceAnalysis analyze(String text)` <a id="analyze"></a>

- **种类：** 方法
- **用途：** 把句子变成词、结构、语法点和可能的问题。
- **输入：** 学习者输入的 `text`。
- **返回：** `SentenceAnalysis`。
- **副作用：** 无。
- **算法：** 规范化、分词、分块、匹配、检查。
- **使用：** 句子实验室页面。
- **说明：** 同步执行，且在词典建好之后快到足以每次按键都跑一遍——一个句子只有几十个字符，词格在其上是线性的，每个位置的边数有界。开销大的是构建词典，而那每次运行只发生一次。

### `final lexiconProvider` <a id="lexiconprovider"></a>

- **种类：** provider
- **用途：** 构建索引一次并共享。
- **输入：** 监听 `contentCatalogProvider` 与 `functionWordsProvider`。
- **返回：** `FutureProvider<Lexicon>`。
- **副作用：** 除它所等待的两次加载外无。
- **算法：** 等待两者，然后 `Lexicon.build`。
- **使用：** `sentenceAnalyzerProvider`，以及经由练习表的发音评分。
- **说明：** 同时依赖两者意味着任一被重新加载时它都会重建，绝不会持有过时的一半。功能词表与目录是分开的 provider，因为它只有几 KB 且只有实验室需要它——与 2 MB 的目录一起加载会让每个页面为一个可能永远不会打开的页面付出代价。
