# lib/features/speech/services/tts_service.dart

应用的语音合成策略：一个实例、一种语言、同一时刻只有一段朗读。它掌管引擎的选择、语言、速度和语音，并公布当前正在朗读的内容，使整个 UI 保持一致。音频由平台引擎在本地生成，不会离开设备。

**引擎不会保留你给它的语言。** `flutter_tts` 的 Android 插件会在两处把语言覆盖成系统默认：它自己初始化之后，以及它因服务连接断开而静默重建 `TextToSpeech` 实例时。两者从 Dart 侧都看不见，而且都会让应用把日语按设备自身的语言读出来。`init` 中的探测、`speak` 中的重新应用以及 `_recoverEngine` 都是为此存在的；见 [`../../../../features/pronunciation.md`](../../../../features/pronunciation.md)。

它构建在 [`TtsBackend`](tts_backend.md) 之上，因此关键行为无需语音引擎即可测试——`test/tts_service_test.dart` 用一个记录型 fake 驱动每个分支。

使用方：`speak_button.dart`、`speech_settings_tiles.dart`、`voice_picker_sheet.dart`、`kana_page.dart`（长按）、`app_settings.dart`（启动时应用持久化的引擎、速度与语音）。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `TtsService` | 类 | B | 通过设备自身的引擎朗读日语。 |
| `setInstanceForTesting` | 静态方法 | B | 在测试中替换全局实例。 |
| [`engineRate`](#enginerate) | 静态方法 | A | 把用户面的速度倍数换算成引擎单位。 |
| [`init`](#init) | 方法 | A | 准备引擎并了解它是否有日语语音。 |
| `setRate` | 方法 | B | 应用朗读速度，并夹到所提供的范围内。 |
| `setVoiceByName` | 方法 | B | 按引擎名称选择日语语音；未知名称回退到可用的最佳语音。 |
| `setEngine` | 方法 | B | 切换语音引擎，重新读取语音列表，并丢弃已选语音。 |
| [`speak`](#speak) | 方法 | A | 朗读一段日语，并打断正在播放的内容。 |
| `preview` | 方法 | B | 用某个语音朗读样例，随后恢复学习者自己的语音。 |
| `stop` | 方法 | B | 停止当前朗读并清除共享的朗读状态。 |
| `_loadVoices` | 方法 | B | 读取引擎语音，保留日语的，并选出最佳者。 |
| [`_applyEngineState`](#applyenginestate) | 方法 | A | 把语言、语音与语速推给引擎，并报告日语是否真的生效。 |
| `_recoverEngine` | 方法 | B | 重建一个已经不再接受日语的引擎。 |
| `_chosenVoice` | 方法 | B | 找出所选语音名称对应的语音映射。 |
| `_resolveVoiceName` | 方法 | B | 仅在当前引擎仍提供该语音时保留其名称。 |
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

### `Future<void> init({double? rate, String? voiceName, String? engineId})` <a id="init"></a>

- **种类：** 方法
- **用途：** 配置引擎并发现它的能力。
- **输入：** 持久化的偏好（若有）。
- **返回：** 无。
- **副作用：** 可能切换引擎；查询语音列表；设置语言、语音与语速。
- **算法：**
  1. 发现过程只执行一次。列出引擎；持久化的那个若仍已安装则切换过去。
  2. **await 一次 `isLanguageAvailable` 作为探测。** 其返回值被丢弃；await 到它本身才是目的。
  3. 读取语音，保留日语的，按优先顺序排序，取其中已安装的第一个作为默认语音。
  4. 用该列表解析持久化的语音名称，然后 `_applyEngineState`。
- **使用：** `AppSettingsNotifier._loadPersisted`，在偏好已知之后。
- **说明：** **第 2 步是关键，顺序本身就是这次修复。** 平台引擎启动期间，插件会把方法调用排队并在其 init 回调中重放，*然后*把语言覆盖成系统默认。在此之前发出的 `setLanguage` 会被应用并立刻丢弃——这正是引擎把日语按设备自身语言读出来的原因，且时好时坏，取决于哪一边先完成。await 任意一个被排队的调用，就意味着覆盖已经发生。每次引擎调用都有保护：没有语音引擎的设备会从平台通道抛出异常而不是返回 false，`flutter_test` 运行则返回 `MissingPluginException`；两者都不能阻止应用启动。调用方不会 await 它——缺失的引擎不得拖慢首帧。

### `Future<void> speak(String text)` <a id="speak"></a>

- **种类：** 方法
- **用途：** 朗读一段日语。
- **输入：** `text`——调用方有假名读音时就传读音。
- **副作用：** 停止当前朗读、播放音频，并在播放期间把 `speaking` 保持为该文本。
- **返回：** 无。
- **算法：** 去空白；空文本忽略；停止正在播放的内容；若那正是同一段文本则返回——这一次点击是"停止"。随后 `_applyEngineState`；若日语被拒绝且它在本次运行中曾经可用，则 `_recoverEngine` 一次。公布文本、朗读它，并在朗读结束或引擎抛出异常时清除状态。
- **使用：** `SpeakButton`、`kana_page.dart`、速度试听。
- **说明：** 连点同一个按钮是停止而非重复，点击另一个按钮会打断第一个：设备上只有一个声音。`finally` 只在 `speaking` 仍然是本段文本时清除它，因此期间开始的新朗读不会被旧朗读的结束清掉。**每次朗读前都重新应用状态**，因为插件会在服务连接断开时（应用在后台待过之后很常见）背着应用重建 `TextToSpeech`，而重建后的引擎回到了系统默认语言，应用看不到任何征兆。三次引擎调用只花几毫秒；用错语音则会毁掉这个功能。

### `Future<bool> _applyEngineState()` <a id="applyenginestate"></a>

- **种类：** 方法
- **用途：** 把应用想要的语言、语音与语速推给引擎。
- **输入：** 无。
- **返回：** `bool`——日语是否真的被接受。
- **副作用：** 改变引擎状态；更新 `hasJapaneseVoice`。
- **算法：** `setLanguage('ja-JP')`，然后选定已选语音或最佳默认语音，最后设定语速。语言与语音**任一**被接受，日语即视为可达。
- **使用：** `init`、`setVoiceByName`、`setEngine`、`speak`，以及 `preview` 的 `finally`。
- **说明：** 显式选定语音而不只是设定语言，才能阻止引擎退回它上次停留的语音。用「任一」而非「两者」：引擎可能拒绝 `ja-JP` 这个区域设置却仍持有日语语音，而桌面引擎可能接受该区域设置却一个语音都枚举不出来。返回值正是 `speak` 用来判断是否需要重建引擎的依据。
