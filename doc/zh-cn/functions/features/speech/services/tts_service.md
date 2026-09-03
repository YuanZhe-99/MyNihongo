# lib/features/speech/services/tts_service.dart

应用的语音合成策略：一个实例、一种语言、同一时刻只有一段朗读。它掌管引擎的语言、速度和语音，并公布当前正在朗读的内容，使整个 UI 保持一致。音频由平台引擎在本地生成，不会离开设备。

它构建在 [`TtsBackend`](tts_backend.md) 之上，因此关键行为无需语音引擎即可测试——`test/tts_service_test.dart` 用一个记录型 fake 驱动每个分支。

使用方：`speak_button.dart`、`speech_settings_tiles.dart`、`kana_page.dart`（长按）、`app_settings.dart`（启动时应用持久化的速度与语音）。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `TtsService` | 类 | B | 通过设备自身的引擎朗读日语。 |
| `setInstanceForTesting` | 静态方法 | B | 在测试中替换全局实例。 |
| [`engineRate`](#enginerate) | 静态方法 | A | 把用户面的速度倍数换算成引擎单位。 |
| [`init`](#init) | 方法 | A | 准备引擎并了解它是否有日语语音。 |
| `setRate` | 方法 | B | 应用朗读速度，并夹到所提供的范围内。 |
| `setVoiceByName` | 方法 | B | 按引擎名称选择日语语音；未知名称回退到默认。 |
| [`speak`](#speak) | 方法 | A | 朗读一段日语，并打断正在播放的内容。 |
| `stop` | 方法 | B | 停止当前朗读并清除共享的朗读状态。 |
| `_isJapanese` | 静态方法 | B | 判断一个语音映射是否描述日语语音。 |

## 文档

### `static double engineRate(double userRate)` <a id="enginerate"></a>

- **种类：** 静态方法
- **用途：** 把用户面的速度倍数换算成引擎需要的值。
- **输入：** `userRate`，1.0 表示正常速度。
- **返回：** `userRate * 0.5`。
- **副作用：** 无。
- **算法：** 一次乘法。
- **使用：** `setRate`。
- **说明：** `flutter_tts` 在其支持的**每个平台上都把 0.5 视为正常**——Android 在交给 `TextToSpeech` 前会翻倍，Apple 的 `AVSpeechSynthesizer` 默认值就是 0.5，Windows 后端加 0.5 得到 WinRT 的 `SpeakingRate` 1.0。在这里加平台分支不只是多余，而是错的。

### `Future<void> init({double? rate, String? voiceName})` <a id="init"></a>

- **种类：** 方法
- **用途：** 配置引擎并发现它的能力。
- **输入：** 持久化的偏好（若有）。
- **返回：** 无。
- **副作用：** 设置引擎语言、速度和语音；查询语音列表。
- **算法：** 发现过程只执行一次，之后的调用仅重新应用偏好。日语语音列表是把引擎语音按 `ja` 语言子标签过滤得到的，该标签在不同平台上表现为 `ja`、`ja-JP` 或 `ja_JP`。
- **使用：** `AppSettingsNotifier._loadPersisted`，在偏好已知之后。
- **说明：** 每次引擎调用都有保护。没有语音引擎的设备会从平台通道抛出异常而不是返回 false，`flutter_test` 运行则返回 `MissingPluginException`；两者都不能阻止应用启动，因此失败只意味着"没有日语语音"。调用方不会 await 它——缺失的引擎不得拖慢首帧。

### `Future<void> speak(String text)` <a id="speak"></a>

- **种类：** 方法
- **用途：** 朗读一段日语。
- **输入：** `text`——调用方有假名读音时就传读音。
- **副作用：** 停止当前朗读、播放音频，并在播放期间把 `speaking` 保持为该文本。
- **返回：** 无。
- **算法：** 去空白；空文本忽略；停止正在播放的内容；若那正是同一段文本则返回——这一次点击是"停止"。否则公布文本、朗读它，并在朗读结束或引擎抛出异常时清除状态。
- **使用：** `SpeakButton`、`kana_page.dart`、速度试听。
- **说明：** 连点同一个按钮是停止而非重复，点击另一个按钮会打断第一个：设备上只有一个声音。`finally` 只在 `speaking` 仍然是本段文本时清除它，因此期间开始的新朗读不会被旧朗读的结束清掉。
