# lib/features/speech/widgets/speak_button.dart

一个朗读一段日语的按钮，应用中所有发声之处都用它。它监听 `TtsService.speaking`，因此正在播放其文本的那个按钮显示停止图标，其余保持静止。

使用方：`content_sheets.dart`（词汇词头、假名行）、`example_actions.dart`（每个例句）。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `SpeakButton` | 类 | B | 朗读一段日语的按钮。 |
| [`SpeakButton.build`](#build) | 方法 | A | 为该文本构建朗读/停止按钮。 |

## 文档

### `Widget build(BuildContext context)` <a id="build"></a>

- **种类：** 方法
- **用途：** 按当前所处的三种状态之一渲染按钮。
- **输入：** 构建 context；widget 的 `text`、可选的 `tooltip` 与 `iconSize`。
- **返回：** 位于 `TtsService.speaking` 的 `ValueListenableBuilder` 内的 `IconButton`。
- **副作用：** 点击前无。
- **算法：** 引擎报告有日语语音时启用。当 `speaking` 等于本按钮去空白后的文本时图标为停止符号，否则为喇叭。
- **使用：** 各详情表与例句行。
- **说明：** 没有日语语音时禁用而非隐藏：那是用户可以自行修复的设备状态，而消失的按钮会让人以为功能不存在。工具提示会说明它处于哪种状态。
