# 内容目录

内置的只读单词与语法内容、解析它们的模型，以及展示它们的两个浏览页面。数据结构本身见
[`../data-formats.md`](../data-formats.md)；本页讲的是规则、生成这些文件的流水线，以及界面。

## 文件与模型

| 资源 | 解析为 | 模型 |
|---|---|---|
| `assets/content/vocab.json` | `ContentCatalog.vocab` | `VocabEntry` |
| `assets/content/grammar/n5.json`（每级一个文件） | `ContentCatalog.grammar` | `GrammarPoint` |
| `assets/content/kana_notes.json` | `ContentCatalog.kanaNotes` | `KanaNote` |
| `assets/content/vocab_zh.json` | 运行时不解析 | 构建输入，见下文 |
| `assets/content/function_words.json` | `FunctionWordTable`，单独加载 | `FunctionWord` |

`ContentRepository.load()` 在调用方 isolate 上读取字符串，再交给 `compute` 解码，因此约 2 MB 的单词文件
不会在启动时丢帧。单词文件以 `cache: false` 读取：它只解析一次，若留在资源包的字符串缓存中，会在整个进程
生命周期内多占一份副本。控件测试会设置 `ContentRepository.parseInIsolate = false`，因为 `compute` 在
`FakeAsync` 下永远不会完成。

功能词表刻意**不**属于目录：它描述的是把目录中的词组织起来的语法，没有任何进度追踪它，而且只有句子实验室读它，因此由它自己的 `loadFunctionWords` 和自己的 provider 加载。它的 schema 见 [`../data-formats.md`](../data-formats.md)，用途见 [`sentence-lab.md`](sentence-lab.md)。

`contentCatalogProvider` 把结果提供给页面。查找使用构造时建好的映射：`vocabById`、`grammarById` 与
`canonicalId` 都是常数时间，且 `vocabById` 会把别名解析到与主 id 相同的条目对象。共享值类型：`JlptLevel`
（N5 到 N1，带标签与忽略大小写的解析）、`LocalizedStrings`（按语言键的列表，回退到英语）、`ContentExample`
（日语句子、可选读音、译文）。

## 单词流水线

`tool/import_vocab.dart` 离线生成 `vocab.json`；其规则位于 `tool/src/vocab_import_core.dart`，因此无需
117 MB 的词典即可做单元测试。

| 输入 | 位置 | 是否提交 |
|---|---|---|
| 以 JMdict 序号为键的 JLPT 词表 | `tool/content/jlpt/n{1..5}.csv` | 是，与上游逐字节一致 |
| JMdict 本体（`jmdict-eng-<版本>.json`） | `tool/data/` | **否** —— 已 git 忽略，需手动下载 |
| 手写种子词 | `tool/content/vocab_seed.json` | 是 |
| 中文释义覆盖文件 | `assets/content/vocab_zh.json` | 是 |
| OpenCC 转换词典 | `tool/content/opencc/` | 是，与上游逐字节一致 |

```bash
dart run tool/import_vocab.dart
dart run tool/import_vocab.dart --overlay-only
dart run tool/convert_zh_tw.dart
```

词典缺失时，工具以退出码 1 结束并打印下载地址；当词表引用了词典中不存在的序号时，它同样以 1 结束，而不是
写出有缺口的目录。它不写入时间戳，并按等级、读音、id 排序，因此在输入未变时重跑会产生空的 `git diff`。

决定学习者所见内容的规则：

- **等级。** 词表按 N5 优先遍历，因此同时出现在两张表中的词按较易的等级教授，其 id 也在那里确定。
- **书写形式。** 以词表给出的形式为准，除非 JMdict 把它标为不常用或仅供检索的形式而另有常用形式：N5 词表
  给 あかるい 的是 明い，而应用显示 明るい。没有汉字的词，或首个义项标有“通常写作假名”的词，以读音作词头。
- **释义。** 最多三个义项，每个最多连接三条英文释义。古语、生僻、罕用与粗俗义项会被跳过，限定于其他书写
  形式的义项亦然。若某词的义项全部被跳过，则回退到不过滤的读取：让一个词没有释义，比显示它唯一的生僻义
  更糟。
- **词性。** JMdict 细粒度的标签被映射到 `lib/features/content/models/parts_of_speech.dart` 中的封闭集合，
  并按该集合排序以保证输出稳定。未映射的标签会被丢弃并在 stderr 上计数。
- **已知有误的词表行。** 有三行指向同形异义词而非它们本意的词：コップ 指向“警察”，ボタン 指向牡丹，
  だんだん 指向方言的“谢谢”。修正写在工具内的对照表中，这样提交的 CSV 与上游保持一致，每处改动的原因也
  清晰可查。
- **种子词。** 每条都带 `jmdictSeq`。其手写释义与例句优先于 JMdict，其旧的 `vocab:<slug>` id 成为新
  `vocab:jm<序号>` id 的别名，并且无论词表是否收录都会出现在目录中。

### 中文释义

中文按等级逐级写在 `assets/content/vocab_zh.json` 中，以目录 id 为键，由工具合入目录。其 `reviewed` 标志
只用于记录写作进度，绝不进入 `vocab.json`：在母语者校对之前一律为 false。**当前的 N5 中文释义由机器撰写、
尚未校对。** 没有对应条目的词只带英语，界面会回退到英语显示，这也是 N4 及以上目前显示英语的原因。

覆盖文件放在资源目录而不是 `tool/` 下，是为了让测试可以通过 `rootBundle` 读到它，并与目录实际发布的内容
比对，从而发现改了覆盖文件却忘记运行 `--overlay-only` 的情况。

### 繁体中文

繁体中文是**生成**的，而不是撰写的：`tool/convert_zh_tw.dart` 在内容中每一个 `zh` 字符串旁写入一个 `zh_TW` 字符串，结果提交到仓库。它带着与简体释义相同的提醒——无人校对过——以及相同的补救方式：改 `zh`，重新运行工具。

转换用的是 OpenCC 自己的 `s2tw` 链，在 `tool/src/chinese_converter.dart` 中用 Dart 重新实现，这样一个构建期步骤不需要任何原生依赖。有两个决定值得知道：

- **它基于词组，而不是基于单字。** 一个简体字变成哪个繁体字取决于所在的词：干净 → 乾淨，但 干部 → 幹部；头发 → 頭髮，但 发现 → 發現。单字表会弄错这些，这正是那份 1 MB 词组词典被提交的原因。
- **用 `s2tw` 而不是 `s2twp`。** OpenCC 的台湾*词汇*表是领域词汇，大多与计算机有关，它会把普通行文译错：在讲某个助词连接哪个名词的语法说明里，它把 连接 改成 連線、把 对象 改成 物件。这个应用需要的是台湾字形变体；它从不说 软件。

中文行文中以汉字书写的日语词列在 `tool/content/opencc/preserve.txt` 中并原样保留。讲 来る 的语法说明是中文写的，其中引用了这个日语动词；而 來る 在两种语言里都不是词。只要其中之一进入已发布的文件，`test/content_zh_tw_test.dart` 就会失败，因此这份列表不会悄悄落后于内容。

界面文本是另一回事：`lib/l10n/app_zh_TW.arb` 由人工维护，因为台湾用法的差异不只在字形，也在词汇——是 設定 而不是 設置，是 單字 而不是 單詞，是 文法 而不是 語法，是 網路 而不是 網絡。

## 每个条目遵守的规则

由 `test/content_catalog_test.dart` 强制执行：

1. **id 唯一且带前缀**，包括别名。使用 `vocab:` 与 `grammar:` 前缀；假名目录的 `kana:` id 共享同一命名空间。
   `studyKindOf(id)` 必须返回相应的类别。别名不得与任何主 id 冲突。
2. **每个退役 id 仍可解析。** 全部 24 个手写种子 id 都必须找到其条目，并出现在该条目的 `aliases` 中。
3. **每个条目都有英文释义**，且 **N5 与全部种子词都有中文释义**。每个中文字符串旁都有一个生成的繁体字符串，由 `test/content_zh_tw_test.dart` 检查。
4. **每个条目都有 JLPT 等级**，各等级数量合理，且同一等级内不出现重复的词头与读音组合。
5. **只使用已知的词性标签。**
6. **每个语法点都有两种语言**、有例句，句中含汉字处附读音。
7. **假名注释指向存在的假名**，且两种语言齐全。
8. **日语能对着目录自己的词汇解析**，且读音与之对齐。这正是 `test/sentence_analyzer_test.dart`、`test/content_links_test.dart` 与撰写门禁所检查的，也是测试能做到的极限。

**「由人阅读日语」是这份目录没有做到的一条规则。** N5 语法是手写的；其余部分——见 [`content-authoring.md`](content-authoring.md)——由模型撰写并由机器检查。每个这样的文件都在 `source` 字段里写明这一点，每条机器生成的释义都带着 `reviewed: false`。错误的例句依然会教错东西；这里没有任何地方声称相反。

属于约定而非测试的规则：

- **已发布的 id 永不更改。** 进度以它为键。退役的 id 保留为别名。
- **内容即数据。** Dart 代码中不写词表；假名表是唯一有意的例外，因为它固定且很小。

### 许可与署名

原创内容随应用以 GPL-3.0 发布。第三方内容只有在此处与应用内许可证页面记录了许可与署名后才会提交：

| 来源 | 许可 | 状态 |
|---|---|---|
| 语法、例句、假名注释、中文释义、种子词 | GPL-3.0（随应用） | 已发布 |
| 模型撰写的语法、释义、例句与单元（`"source": "model-authored (Claude), unreviewed"`） | GPL-3.0（随应用） | 已发布 |
| OpenCC 转换词典（Carbo Kuo 及贡献者） | Apache-2.0 | 构建输入；其生成的文本随应用发布 |
| JMdict / EDICT（EDRDG，莫纳什大学） | CC BY-SA 4.0 | 已发布 |
| JLPT 词表（stephenmk/yomitan-jlpt-vocab；底层词表来自 Jonathan Waller，CC BY） | CC BY-SA 4.0 | 已发布 |

正因为是 CC BY-SA，应用把署名放在“设置 › 许可证”中可见，而不仅仅写在仓库文件里。

## 浏览页面

`vocab_page.dart` 与 `grammar_page.dart` 形态相同，并通过 `lib/shared/widgets/reference_widgets.dart`
共享标签、徽章、例句渲染与空状态。

- **搜索** —— 单词匹配词头、读音、罗马字或任意语言的释义；语法匹配句型、结构或含义（有意不搜索详解——常用词
  几乎会命中一切）。查询只修剪和转小写一次。
- **等级筛选** —— 一组选择标签：全部等级，然后是 N5 到 N1。始终恰好选中一个。
- **结果计数** 显示在标签下方。
- **卡片** —— 词头（或句型）、读音／罗马字（或结构）行、界面语言的一条释义，以及等级徽章。纯假名词会去掉
  读音行，以免重复。
- **详情弹层** —— 模态底部弹层，展示完整条目：全部释义、词性、结构、详解，以及带读音与译文的例句。用弹层而
  非路由，列表位置得以保留，同一组件在单列与多列下都能工作。
- **布局** —— `ListView.builder` 的条目是行而不是卡片，因此在两列及以上时列表仍保持虚拟化。列数由
  `referenceColumnCount` 决定，见 [`../adaptive-layout.md`](../adaptive-layout.md)。

内容按界面语言（`Localizations.localeOf`）显示，依次回退到英语，再回退到该条目拥有的任意语言。
