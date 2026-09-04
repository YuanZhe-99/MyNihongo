# lib/features/speech/widgets/voice_picker_sheet.dart

一个底部面板，列出每个日语语音的可读名称、它有什么不同、它的原始引擎名称，以及一个用该语音朗读样例的按钮。

它取代了原来那个由引擎标识符组成的下拉框——后者无法完成选择语音真正要做的那件事：听出差别。在这里，试听和选择是两个动作：样例通过 `TtsService.preview` 播放，它随后会恢复学习者自己的语音，因此试听绝不会悄悄改变应用的朗读方式。

从设置 → 语音的「日语语音」一行打开，该行仅在引擎提供多于一个日语语音时出现。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| [`showVoicePickerSheet`](#showvoicepickersheet) | 顶层函数 | A | 显示选择面板并回报每一次选择。 |
| `_VoicePickerSheet` | 类 | B | 面板自己的控件，使一次选择只重绘面板而不重建设置页。 |
| `_choose` | 方法 | B | 应用一次选择并保持面板打开。 |
| `build` | 方法 | B | 构建「自动选择」一行和每个语音一行。 |
| `_voiceRow` | 方法 | B | 构建一个语音行及其试听按钮。 |

## 文档

### `Future<void> showVoicePickerSheet(BuildContext context, {required String previewText, required String? selected, required ValueChanged<String?> onChanged})` <a id="showvoicepickersheet"></a>

- **种类：** 顶层函数
- **用途：** 让学习者听过每个日语语音之后再选一个。
- **输入：** `previewText`——每个语音朗读的样例；`selected`——已选语音名称，null 表示自动选择；`onChanged`——每次选择都会被调用。
- **返回：** 面板关闭时完成的 future。
- **副作用：** 显示一个模态底部面板；面板打开期间会发出声音。
- **算法：** 一个 `RadioGroup` 包住「自动选择」行与来自 `TtsService.japaneseVoices` 的每个语音行，该列表已经排好序。每一行显示编号名称、限定词、原始引擎名称，以及一个调用 `TtsService.preview` 的播放按钮。
- **使用：** `speech_settings_tiles.dart`。
- **说明：** 选择之后面板刻意保持打开：正在比较两个语音的学习者不应该为此重新打开它。面板高度上限为屏幕的 70%，因此在手机上绝不会盖住整个应用。`onChanged` 按每次选择触发，而不是在关闭时触发一次，因此设置在做出的那一刻就生效，用手势滑走面板也不会丢失。
