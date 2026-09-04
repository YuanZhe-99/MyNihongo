# lib/features/speech/widgets/voice_labels.dart

把引擎的语音映射变成学习者读得懂的东西。引擎的语音名称是标识符——`ja-jp-x-jab#male_1-local`——而且在不同引擎上并不相同，所以应用改为给排好序的列表编号，并描述每一项有什么不同。

使用方：`voice_picker_sheet.dart`、`speech_settings_tiles.dart`。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| [`voiceDisplayName`](#voicedisplayname) | 顶层函数 | A | 按语音在排序列表中的位置为它命名。 |
| `voiceQualifiers` | 顶层函数 | B | 说明一个语音有什么不同：先可用性，再音质。 |
| `voiceDefaultLabel` | 顶层函数 | B | 说明「自动选择」这一项，以及它实际解析到哪个语音。 |
| `_engineNames` | 顶层常量 | B | 已知的 Android 语音引擎，用以显示品牌名而非包名。 |
| `engineDisplayName` | 顶层函数 | B | 为菜单命名一个语音引擎。 |

## 文档

### `String voiceDisplayName(AppLocalizations l10n, List<Map<String, String>> voices, int index)` <a id="voicedisplayname"></a>

- **种类：** 顶层函数
- **用途：** 用学习者可以据以行动的方式为日语语音命名。
- **输入：** `l10n`；已由 `sortJapaneseVoices` 排好序的 `voices`；正在命名的 `index`。
- **返回：** 「日语语音 1」「日语语音 2」等等。
- **副作用：** 无。
- **算法：** 排序列表中从 1 开始的位置。
- **使用：** 设置里的语音行，以及选择面板的每一行。
- **说明：** 引擎自己的名称是标识符而不是名字：它说不出这个声音是什么样，同一个语音在另一个引擎上又叫别的名字。编号之所以稳定，只因为顺序是完全确定的——见 [`../models/voice_ordering.md`](../models/voice_ordering.md)。原始名称仍然显示，在面板中以小字排在下面，因为反馈问题和系统语音设置需要的正是它。
