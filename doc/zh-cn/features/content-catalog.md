# 内容目录

内置的只读单词和语法内容、解析它们的模型，以及展示它们的两个浏览页面。schema 本身见 [`../data-formats.md`](../data-formats.md)；本页关于规则和 UI。

## 文件与模型

| 资源 | 解析为 | 模型 |
|---|---|---|
| `assets/content/vocab_seed.json` | `ContentCatalog.vocab` | `VocabEntry` |
| `assets/content/grammar_seed.json` | `ContentCatalog.grammar` | `GrammarPoint` |

`ContentRepository.load()` 通过 `rootBundle` 读取两者，`contentCatalogProvider` 把结果暴露给页面。共享值类型：`JlptLevel`（N5–N1，标签和大小写不敏感解析）、`LocalizedStrings`（按语言分键的列表，回落到英语）、`ContentExample`（一句日语、可选读音、翻译）。

## 每个条目遵循的规则

由 `test/content_catalog_test.dart` 强制：

1. **唯一、带前缀的 id。** `vocab:` 和 `grammar:` 前缀；假名目录的 `kana:` id 共享同一命名空间。`studyKindOf(id)` 必须返回匹配的类别。
2. **两种发布语言都有。** 每条释义、说明和例句翻译都带 `en` 和 `zh`。一种 UI 语言绝不能显示另一种没有的空白。
3. 每个条目都有**一个 JLPT 级别**。
4. **每个语法点都有例句**，句中含汉字时带读音。
5. **日语经人核对。** 错误的例句教的是错误的东西。

属于政策而非测试的规则：

- **已发布的 id 绝不改变。** 进度以它们为键。退役的 id 保留为别名（别名机制随 JMdict 导入到来）。
- **内容是数据。** Dart 代码中没有词表；假名表是唯一刻意的例外，因为它固定且极小。

## 种子内容及其替换

种子是手写的：24 个 N5 单词和 8 个 N5 语法点，足以让页面真实、让测试有意义。`PLAN.md` M1.2 用 JMdict 派生的目录（EDRDG，CC BY-SA 4.0）联结一份开放许可的 JLPT 列表替换单词，由离线 `tool/` 脚本构建，并逐级手写扩充语法。目录变大时，解析移到 `compute` 并为查找建索引；如果中端手机上的加载时间超过约 300 ms，资源变为预构建的 SQLite 文件，JSON 只保留为构建输入。

### 许可与署名

种子内容是原创的，随应用以 GPL-3.0 发布。第三方内容只在其许可和署名记录于此处和应用内许可证页面时才提交：

| 来源 | 许可 | 状态 |
|---|---|---|
| 手写种子 | GPL-3.0（随应用） | 已发布 |
| JMdict / EDRDG | CC BY-SA 4.0 | 计划中（M1.2） |

## 浏览页面

`vocab_page.dart` 和 `grammar_page.dart` 形状相同，并通过 `lib/shared/widgets/reference_widgets.dart` 共享筹片、徽章、例句渲染和空状态。

- **搜索** — 单词匹配词条、读音、罗马音或任一语言的任一释义；语法匹配句型、结构或释义（刻意不搜索说明——它会在常用词上几乎匹配一切）。查询修剪并转小写一次。
- **级别筛选** — 一个选择筹片的 `Wrap`：全部级别，然后 N5 到 N1。恰好选中一个。
- 筹片下方的**结果计数**。
- **条目卡片** — 词条（或句型）、一行读音 / 罗马音（或结构）、UI 语言的一行释义，以及级别徽章。纯假名词省去读音行，以免重复自己。
- **详情面板** — 带完整条目的模态底部面板：全部释义、词性、结构、说明，以及带读音和翻译的例句。用面板而不是路由，使列表位置得以保留，同一组件在单列和多列下都能工作。
- **布局** — 行而不是卡片是 `ListView.builder` 的项，因此列表在两列及以上时仍然虚拟化。列数是 `referenceColumnCount`；见 [`../adaptive-layout.md`](../adaptive-layout.md)。

内容以 UI 语言（`Localizations.localeOf`）显示，回落到英语，再回落到条目拥有的任何语言。
