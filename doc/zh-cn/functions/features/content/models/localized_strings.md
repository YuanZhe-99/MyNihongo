# lib/features/content/models/localized_strings.dart

内容模型共享的两个值类型。`LocalizedStrings` 是语言代码到字符串列表的映射——内容文件存放释义、说明和例句翻译的方式——带感知语言的 `resolve` 和跨语言的 `matches`。`ContentExample` 是一句日语，附可选的假名读音和翻译；除 `ja` 和 `reading` 以外的每个 JSON 键都视为一种语言。见 [../../../../data-formats.md](../../../../data-formats.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `LocalizedStrings.new` | 构造函数 | B | 创建本地化字符串实例。 |
| `LocalizedStrings.fromJson` | 工厂构造函数 | B | 解析语言代码到字符串或字符串列表的映射，或视为英语的裸字符串；非字符串成员被丢弃。 |
| `LocalizedStrings.isEmpty` | getter | B | 报告是否没有任何语言有任何字符串。 |
| [`LocalizedStrings.resolve`](#resolve) | 方法 | A | 为语言选择字符串，回落到英语、再回落到任一语言。 |
| `LocalizedStrings.resolveJoined` | 方法 | B | 为语言选择字符串并拼接用于显示。 |
| `LocalizedStrings.matches` | 方法 | B | 测试任一语言的任一字符串是否包含小写查询。 |
| `ContentExample.new` | 构造函数 | B | 创建内容例句实例。 |
| `ContentExample.fromJson` | 静态方法 | B | 解析 `{ja, reading?, <lang>: …}`；没有日语句子时为 null。 |
| `ContentExample.listFromJson` | 静态方法 | B | 解析例句列表，跳过畸形成员。 |

## 文档

### `List<String> resolve(Locale locale)` <a id="resolve"></a>

- **类型：** `LocalizedStrings` 的方法
- **源码：** `lib/features/content/models/localized_strings.dart`
- **Purpose：** 选择 UI 语言应显示的字符串。
- **Inputs：** `locale`——通常是 `Localizations.localeOf(context)`。
- **Returns：** `locale.languageCode` 对应的列表；否则 `en` 列表；否则第一个存在的语言；否则空列表。
- **Side effects：** 无。
- **Algorithm：** 按顺序三次查找，只按语言代码匹配，因此 `zh_TW` 读取 `zh` 的字符串。
- **Usage：**
  ```dart
  entry.meanings.resolveJoined(locale)
  ```
  （来自 `vocab_page.dart` 中的单词条目卡片）
- **Notes：** 英语回落是每个条目必须携带 `en` 的原因；任一语言回落的存在是为了让不完整的条目仍显示点什么，而不是空白。
