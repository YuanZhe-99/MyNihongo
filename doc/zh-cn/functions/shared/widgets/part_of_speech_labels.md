# lib/shared/widgets/part_of_speech_labels.dart

用学习者的语言为词性标签命名。

单词详情面板此前在所有语言下都原样打印这些标签——`verb-godan`、`suru-verb`——这对英文读者是术语，对其他所有人则是未翻译的文字。它与 [../../features/sentence/widgets/form_labels.md](../../features/sentence/widgets/form_labels.md) 中的 `formLabel` 是同一种「记号到 ARB」的 switch。

使用方：`content_sheets.dart`（`showVocabDetailSheet`）。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| [`posLabel`](#poslabel) | 顶层函数 | A | 用学习者的语言为词性标签命名。 |

## 文档

### `String posLabel(AppLocalizations l10n, String tag)` <a id="poslabel"></a>

- **种类：** 顶层函数
- **用途：** 用学习者的语言为词性标签命名。
- **输入：** `l10n`，以及来自内容封闭集合（`lib/features/content/models/parts_of_speech.dart` 中的 `vocabPartsOfSpeech`）的 `tag`。
- **返回：** `String`——本地化后的名称；标签不是应用认识的那些时，返回标签本身。
- **副作用：** 无。
- **算法：** 一个 switch，把 23 个标签（`noun`、`pronoun`、`proper-noun`、`verb-godan`、`verb-ichidan`、`verb-irregular`、`suru-verb`、`transitive`、`intransitive`、`auxiliary`、`i-adjective`、`na-adjective`、`no-adjective`、`adnominal`、`adverb`、`particle`、`conjunction`、`interjection`、`expression`、`counter`、`numeric`、`prefix`、`suffix`）各自映射到对应的 `pos…` ARB 字符串，默认值为标签本身。
- **使用：**
  ```dart
  entry.partsOfSpeech.map((tag) => posLabel(l10n, tag)).join(', ')
  ```
  （来自 `showVocabDetailSheet` 中的词性行）
- **说明：** 与 `formLabel` 不同，这个 switch 针对的是 `String` 而不是枚举，所以它无法穷尽，一个没有名称的新标签也不会造成编译错误。回退只是防御性的：`content_catalog_test` 已经会在出现 `vocabPartsOfSpeech` 之外的标签时失败，因此新标签必须加进那个集合——并且应当在同一次改动中在这里给它一个 ARB 名称。
