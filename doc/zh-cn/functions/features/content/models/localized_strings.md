# lib/features/content/models/localized_strings.dart

内容模型共享的两个值类型。`LocalizedStrings` 是语言代码到字符串列表的映射——内容文件存放释义、说明和例句翻译的方式——带感知语言的 `resolve`、仅用于显示的 `resolveTranslation`（它让日语读者在日语文本下看不到任何外语行，而不是看到一行外语）、说明 `resolve` 取自哪种语言的 `resolvedKey`，以及跨语言的 `matches`。`ContentExample` 是一句日语，附可选的假名读音和翻译；除 `ja` 和 `reading` 以外的每个 JSON 键都视为一种语言。见 [../../../../data-formats.md](../../../../data-formats.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `LocalizedStrings.new` | 构造函数 | B | 创建本地化字符串实例。 |
| `LocalizedStrings.fromJson` | 工厂构造函数 | B | 解析语言代码到字符串或字符串列表的映射，或视为英语的裸字符串；非字符串成员被丢弃。 |
| `LocalizedStrings.isEmpty` | getter | B | 报告是否没有任何语言有任何字符串。 |
| [`LocalizedStrings.lookupOrder`](#lookuporder) | 静态方法 | A | 按优先顺序列出某个 locale 应查找的内容键。 |
| [`LocalizedStrings.resolve`](#resolve) | 方法 | A | 为语言选择字符串，回落到英语、再回落到任一语言。 |
| `LocalizedStrings.resolveJoined` | 方法 | B | 为语言选择字符串并拼接用于显示。 |
| [`LocalizedStrings.resolveTranslation`](#resolvetranslation) | 方法 | A | 为读者选择一段日语文本的译文；日语读者只会得到 `ja`，或者什么都没有。 |
| `LocalizedStrings.resolvedKey` | 方法 | B | 说明 `resolve` 对某个 locale 取自哪个语言键（没有值时为 null），以便显示处用注音绘制日语释义。 |
| `LocalizedStrings.resolveTranslationJoined` | 方法 | B | 为读者选择译文并拼接用于显示；日语读者没有可显示的内容时为空。 |
| `LocalizedStrings.matches` | 方法 | B | 测试任一语言的任一字符串是否包含小写查询。 |
| `ContentExample.new` | 构造函数 | B | 创建内容例句实例。 |
| `ContentExample.fromJson` | 静态方法 | B | 解析 `{ja, reading?, <lang>: …}`；没有日语句子时为 null。 |
| `ContentExample.listFromJson` | 静态方法 | B | 解析例句列表，跳过畸形成员。 |

## 文档

### `static List<String> lookupOrder(Locale locale)` <a id="lookuporder"></a>

- **类型：** `LocalizedStrings` 的静态方法
- **源码：** `lib/features/content/models/localized_strings.dart`
- **Purpose：** 说明某个 locale 应按什么顺序读取内容键。
- **Inputs：** `locale`。
- **Returns：** 繁体中文为 `['zh_TW', 'zh', 'en']`，简体中文为 `['zh', 'en']`，英语为 `['en']`。
- **Side effects：** 无。
- **Algorithm：** 有国家代码时先用完整的 `language_COUNTRY` 标签，然后是裸语言码，最后是 `en`——除非语言本身就是 `en`。
- **Usage：** `resolve`、`token_chips.dart` 中的功能词释义对话框，以及提示词构建器对指令块的选择。
- **Notes：** 完整标签在前、裸语言码在后，这正是关键所在：繁体中文回退到简体文本而不是英语，因为内容中每个 `zh_TW` 字符串都由旁边的 `zh` 生成，缺少它意味着这一条根本没有中文。它是公开的，因为提示词模板与功能词释义是普通的 map 而不是 `LocalizedStrings`，而三处各自决定这件事正是它们开始互相矛盾的方式。

### `List<String> resolve(Locale locale)` <a id="resolve"></a>

- **类型：** `LocalizedStrings` 的方法
- **源码：** `lib/features/content/models/localized_strings.dart`
- **Purpose：** 选择 UI 语言应显示的字符串。
- **Inputs：** `locale`——通常是 `Localizations.localeOf(context)`。
- **Returns：** [`lookupOrder`](#lookuporder) 中第一个存在的键对应的列表；否则第一个存在的语言；否则空列表。
- **Side effects：** 无。
- **Algorithm：** 遍历 [`lookupOrder`](#lookuporder)，再回落到第一个存在的语言。
- **Usage：**
  ```dart
  entry.meanings.resolveJoined(locale)
  ```
  （来自 `vocab_page.dart` 中的单词条目卡片）
- **Notes：** 英语回落是每个条目必须携带 `en` 的原因；任一语言回落的存在是为了让不完整的条目仍显示点什么，而不是空白。显示*日语文本*译文的地方改为调用 [`resolveTranslation`](#resolvetranslation)。

### `List<String> resolveTranslation(Locale locale)` <a id="resolvetranslation"></a>

- **类型：** `LocalizedStrings` 的方法
- **源码：** `lib/features/content/models/localized_strings.dart`
- **Purpose：** 为读者选择一段日语文本的译文。
- **Inputs：** `locale`。
- **Returns：** `List<String>`；没有可显示的内容时为空。
- **Side effects：** 无。
- **Algorithm：** 对 `ja` locale，返回 `ja` 条目或空列表；对其他每个 locale，完全等同于 [`resolve`](#resolve)。
- **Usage：** 仅用于显示处，经由 `resolveTranslationJoined`，或用一个 `isNotEmpty` 测试隐藏该行：目录例句下的译文（`reference_widgets.dart` 中的 `exampleList`）、练习题文章及其各行（`drill_passage_view.dart`）、情景的台词与回复选项（`scenario_page.dart`）、生成的例句（`generated_examples.dart`），以及 `question_generator.dart` 中的填空副标题。
- **Notes：** 有 `ja` 条目时日语读者看到它（生成例句的简单日语的改写），否则**什么都看不到**：在日语界面里，日语句子下的一行英文只是噪音，而 `resolve` 最后兜底的第一个值甚至可能是中文。把译文当作*素材*使用的题目逻辑不得调用它；它们另行决定没有译文时怎么办（见 `question_generator.dart` 中的 `_materialTranslation` 和 `quiz_question.dart` 中的 `translationQuizModes`）。
