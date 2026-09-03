# lib/features/content/services/content_links.dart

假名、单词与语法之间的关联，让学习者可以在内容库中横向移动，而不只是上下浏览。纯字符串匹配，由
`test/content_links_test.dart` 在真实内容库上测试。见
[../../../../features/content-catalog.md](../../../../features/content-catalog.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| 库头注释 | `library` | B | 找出假名、单词与语法之间的关联。 |
| `grammarMatchCore` | 顶层函数 | B | 把句型精简为句中会出现的文字。 |
| `effectiveMatchForms` | 顶层函数 | B | 决定用哪些字面字符串在句中标出语法点。 |
| `_isUsableForm` | 顶层函数 | B | 判断推导出的形式是否足够具体。 |
| [`grammarPointsInExample`](#grammarpointsinexample) | 顶层函数 | A | 找出例句演示了哪些语法点。 |
| [`vocabInExamples`](#vocabinexamples) | 顶层函数 | A | 找出语法点的例句使用了哪些单词。 |
| [`vocabStartingWithKana`](#vocabstartingwithkana) | 顶层函数 | A | 找出以某个假名开头的示例单词。 |

日语没有词边界，因此这些是子串匹配而非句法分析。这在第一阶段是有意为之：真正的分词器属于第三阶段的句子分析器，
在它出现之前，一个错误的关联比没有关联代价更小。每个函数都限制结果数量，因为页面只显示少量标签，而在 7,700 个
条目上扫描必须避开关键路径。

### `grammarPointsInExample` <a id="grammarpointsinexample"></a>

- **Purpose:** 找出例句演示了哪些语法点。
- **Inputs:** `catalog`、`example`、`limit`（3）。
- **Returns:** `List<GrammarPoint>`，最长匹配在前。
- **Side effects:** 无。
- **Algorithm:** 对每个语法点取其匹配形式中被句子包含的最长者；按该长度排序，长度相同时按 id 排序以保证稳定。
- **Usage:** 单词例句下方的标签。
- **Notes:** 最长优先，因为含有〜てもいいです的句子同时含有です，而值得关联的是更长的那一个。匹配同时针对句子及
  其假名读音，因此用假名书写的语法点在含汉字的句子中也能被找到。

### `vocabInExamples` <a id="vocabinexamples"></a>

- **Purpose:** 找出语法点的例句使用了哪些单词。
- **Inputs:** `catalog`、`point`、`limit`（12）。
- **Returns:** 按目录顺序的 `List<VocabEntry>`。
- **Side effects:** 无。
- **Algorithm:** 扫描目录一次；汉字词头匹配句子，长度不少于两个假名的读音匹配读音行。
- **Usage:** 语法点例句下方的标签。
- **Notes:** 只取不高于该语法点等级的词，因为教 N5 语法的句子不该把读者引向 N1 的词。两个假名的下限避免 あ 和
  を 匹配到一切。

### `vocabStartingWithKana` <a id="vocabstartingwithkana"></a>

- **Purpose:** 找出以某个假名开头的示例单词。
- **Inputs:** `catalog`、`kana`、`limit`（8）。
- **Returns:** `List<VocabEntry>`，由易到难、常用优先。
- **Side effects:** 无。
- **Algorithm:** 按读音匹配，然后依次按等级、JMdict 是否标为常用、读音排序。
- **Usage:** 假名详情弹层。
- **Notes:** 按读音而非书写形式匹配，因为目的是展示这个假名被读出来的样子。排序才是弹层有用的关键：没有它，初学
  者点 あ 会得到文件顺序中的第一个 N1 条目。
