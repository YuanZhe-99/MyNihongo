# lib/features/speech/services/tts_backend.dart

[`TtsService`](tts_service.md) 与平台语音引擎之间的接缝。只声明本应用会用到的调用，并在此把插件宽松的 `dynamic` 返回值规范化，使这层之上的代码永远看不到它们。

这道接缝之所以存在，是因为 `flutter_test` 运行没有语音引擎：值得测试的一切——优先使用假名读音、同一时刻只有一段朗读、把语音过滤为日语、在没有引擎的设备上存活——都在服务那一侧。

使用方：`tts_service.dart`。

M3.0 为它增加了三个引擎相关方法。`setVoice` 现在也返回 `bool`：引擎是否接受该语音是关键信息，因为拒绝语音的引擎会继续用它上次停留的语言朗读。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `TtsBackend` | 抽象类 | B | 声明应用会发起的引擎调用。 |
| `TtsBackend.setLanguage` | 方法 | B | 设置后续朗读所用的语言。 |
| `TtsBackend.isLanguageAvailable` | 方法 | B | 报告引擎能否朗读某种语言。 |
| `TtsBackend.setSpeechRate` | 方法 | B | 以引擎单位设置速度。 |
| `TtsBackend.voices` | 方法 | B | 以 `name`/`locale` 映射列出引擎的语音。 |
| `TtsBackend.setVoice` | 方法 | B | 选择语音。 |
| `TtsBackend.speak` | 方法 | B | 朗读字符串，音频结束时完成。 |
| `TtsBackend.stop` | 方法 | B | 停止当前朗读。 |
| [`FlutterTtsBackend`](#fluttertsbackend) | 类 | A | 真实后端，包装 `flutter_tts`。 |
| `FlutterTtsBackend._asBool` | 静态方法 | B | 读取插件宽松类型的真值答复。 |

## 文档

### `class FlutterTtsBackend implements TtsBackend` <a id="fluttertsbackend"></a>

- **种类：** 类
- **用途：** 在接缝之后包装 `flutter_tts`。
- **输入：** 测试可传入 `FlutterTts`，否则自行创建。
- **返回：** —
- **副作用：** 在构造时打开 `awaitSpeakCompletion`，使 `speak` 在音频结束时完成，而非在调用入队时完成。
- **算法：** 直接转发，外加两处规范化：真值答复在 Android 上是 `1`/`0`，在桌面后端是 bool；语音映射带有非字符串值（Android 的 `network_required`、Windows 的性别枚举），一律转成字符串。
- **使用：** 默认的 `TtsService.instance`。
- **说明：** 构造函数中的 `awaitSpeakCompletion` 调用是发后即忘，并刻意吞掉失败。`flutter_test` 运行时通道后面没有插件，会返回 `MissingPluginException`，否则每个恰好构建了应用的测试都会冒出一个未处理的异步错误。
