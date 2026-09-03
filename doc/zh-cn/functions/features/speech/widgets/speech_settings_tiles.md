# lib/features/speech/widgets/speech_settings_tiles.dart

配置日语朗读的设置行：带试听按钮的朗读速度滑块、日语语音下拉框，以及在设备没有日语语音时的说明和打开系统语音设置的按钮。

它没有放进 `settings_page.dart`，因为这一节自成一体，而那个文件已经很长。偏好读自 `appSettingsProvider`——与其他所有偏好同一个来源。

使用方：`settings_page.dart`。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `SpeechSettingsTiles` | 类 | B | 设置 → 语音一节。 |
| `previewText` | 静态常量 | B | 试听按钮朗读的问候语。 |
| [`initState`](#initstate) | 方法 | A | **不触发麦克风授权**地询问识别器能做什么。 |
| [`SpeechSettingsTiles.build`](#build) | 方法 | A | 构建语音设置各行。 |
| `_openSettings` | 方法 | B | 把用户送往平台的语音设置，失败时用 snack bar 报告。 |

## 文档

### `Widget build(BuildContext context, WidgetRef ref)` <a id="build"></a>

- **种类：** 方法
- **用途：** 构建两行配置，或缺少语音时的说明。
- **输入：** 构建 context 与 ref；读取 `appSettingsProvider` 和 `TtsService.instance`。
- **返回：** `Widget`。
- **副作用：** 使用控件前无。
- **算法：** 没有日语语音时无可配置，故把速度与语音两行换成说明，并在存在深链接的平台上加一个按钮。否则：一个从 `TtsService.minRate` 到 `maxRate`、分六档、带试听按钮的滑块，以及仅在引擎提供多于一个日语语音时显示的语音下拉框。
- **使用：** `settings_page.dart` 中整个语音一节。
- **说明：** 下拉框的 null 项表示引擎默认，也是用户未表达偏好时存储的值。在没有深链接的 Apple 平台上，说明中会增加一句指出设置面板位置的文字，而不是按钮。

### `void initState()` <a id="initstate"></a>

- **种类：** 方法
- **用途：** 弄清识别器能做什么，同时不去索要麦克风。
- **输入：** 无。
- **返回：** 无。
- **副作用：** 检查麦克风权限；**仅在**已授予时才初始化识别器。
- **算法：** 平台没有识别器时立即放弃；否则先查权限，之后才调用 `ensureAvailable()`。
- **使用：** 设置页。
- **说明：** 权限检查在前，这个顺序就是全部要点。初始化识别器正是让 Android 弹出麦克风授权的动作，所以此前那个无条件调用 `ensureAvailable()` 的版本，会在设置页一打开时就弹出系统对话框，前面没有任何解释。而这恰恰是 [`../../../../features/pronunciation.md`](../../../../features/pronunciation.md) 承诺绝不会发生的事；练习表自己的说明对话框才应该是弹窗的唯一来源。这个问题是在真机上发现的，也只能在真机上发现——测试主机没有权限模型。状态行因此有**三**种状态：可用、不可用、尚未检查。把第三种报成「不可用」，等于告诉一台完全够用的手机它不能听。`test/speech_settings_tiles_test.dart` 断言权限缺失时后端绝不会被初始化。
