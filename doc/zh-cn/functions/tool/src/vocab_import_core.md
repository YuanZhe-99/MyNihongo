# tool/src/vocab_import_core.dart

决定单词目录内容的各项规则。它是纯逻辑：全部文件读写都在 [`../import_vocab.md`](../import_vocab.md) 中，
因此 `test/tool/vocab_import_core_test.dart` 可以在固定样本上做单元测试，而不必依赖 117 MB 的词典。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| 库头注释 | `library` | B | 从 JMdict 与 JLPT 词表构建 `assets/content/vocab.json`。 |
| `JlptRow` | 构造函数 | B | 创建 JLPT 词表行实例。 |
| `ImportResult` | 构造函数 | B | 创建导入结果实例。 |
| `jmdictPosMap` | 顶层 `const` | — | 映射到应用封闭集合的 JMdict 词性标签。 |
| `skippedSenseMisc` | 顶层 `const` | — | 其释义不值得教授的义项标签。 |
| `importLevels` | 顶层 `const` | — | 按导入顺序排列的等级，由易到难。 |
| `jlptSeqCorrections` | 顶层 `const` | — | 指向错误 JMdict 条目的词表行。 |
| `parseJlptCsv` | 顶层函数 | B | 解析一份 JLPT 词表 CSV。 |
| `indexJmdict` | 顶层函数 | B | 按序号为解码后的 JMdict 建索引。 |
| `formsOf` | 顶层函数 | B | 读取 JMdict 词条的书写形式或读音形式。 |
| [`chooseForms`](#chooseforms) | 顶层函数 | A | 决定一个词如何书写与读音。 |
| `_isUsuallyKana` | 顶层函数 | B | 判断 JMdict 是否标注该词通常写作假名。 |
| [`glossesOf`](#glossesof) | 顶层函数 | A | 收集值得展示的英文释义。 |
| `_glosses` | 顶层函数 | B | 读取词条释义，可选择是否过滤无用义项。 |
| `_appliesTo` | 顶层函数 | B | 判断义项的形式限制。 |
| `posOf` | 顶层函数 | B | 把词条的词性标签映射到应用的集合。 |
| [`buildEntries`](#buildentries) | 顶层函数 | A | 从全部输入构建目录条目。 |
| `_entry` | 顶层函数 | B | 以固定的键顺序组装一个目录条目。 |

### `chooseForms` <a id="chooseforms"></a>

- **Purpose:** 决定一个词如何书写与读音。
- **Inputs:** `word` —— JMdict 条目；`row` —— 指向它的词表行。
- **Returns:** 选定的词头、读音、该形式是否常用，以及当词表形式与词典不一致时的警告。
- **Side effects:** 无。
- **Algorithm:** 以词表给出的形式为准，因为考试考的就是词表——但有两个例外。没有汉字的词，或首个义项标有
  “通常写作假名”的词，以读音作词头，因为把 ある 写成 有る 会教错。以及：词表给出的形式若被 JMdict 标为不常
  用，而另有常用形式，则让位于常用形式——N5 词表给 あかるい 的是 明い，那只是常用形式 明るい 的检索用写法。
- **Usage:** 由 [`buildEntries`](#buildentries) 对每个词表行调用一次。
- **Notes:** 每次偏离词表都会产生一行警告，因此 JMdict 更新导致常用形式改变时，会体现在运行输出里而不是悄无
  声息。

### `glossesOf` <a id="glossesof"></a>

- **Purpose:** 收集某个词值得展示的英文释义。
- **Inputs:** `word`、`headword`、`reading`。
- **Returns:** 最多三条释义字符串，每个义项一条，每条用 `; ` 连接该义项的前三条释义。
- **Side effects:** 无。
- **Algorithm:** 跳过标为古语、废弃、生僻、罕用或粗俗的义项，以及限定于其他书写形式或读音的义项，这样以某一
  形式导入的词就不会显示另一形式的含义。若过滤后一无所剩——少数词条的义项全属此类——则回退到不过滤的读取。
- **Usage:** 由 [`buildEntries`](#buildentries) 对每个条目调用一次。
- **Notes:** 让一个词完全没有释义，比显示它唯一的生僻义更糟，回退正是为此；有测试固定这一行为。

### `buildEntries` <a id="buildentries"></a>

- **Purpose:** 从全部输入构建目录条目。
- **Inputs:** `jmdictIndex`、`listsByLevel`、`seedEntries`、`overlay`。
- **Returns:** `ImportResult` —— 条目、日志，以及 JMdict 中不存在的序号。
- **Side effects:** 无。
- **Algorithm:** 按由易到难的顺序遍历等级，因此同时出现在两张表中的词按较易的等级教授，其 id 也在那里确定。
  已占用的序号跳过；同一等级内产生相同书写形式与读音的第二行被丢弃并记录日志。随后补上任何词表未收录的种子
  词，保留其自身等级。最后按等级、读音、id 排序。
- **Usage:** 命令唯一的一次调用。
- **Notes:** 依靠排序而非输入顺序或映射顺序，是输出在多次运行间逐字节稳定的原因。种子条目的手写释义与例句
  优先于 JMdict 的，因为它们是为学习者而不是为词典写的；其旧 id 成为别名，使任何用户的进度都不会成为孤儿。
