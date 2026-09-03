# lib/features/speech/services/speech_backend.dart

[`SpeechRecognitionService`](speech_recognition_service.md) 与平台识别器之间的接缝，以及跨越它的两个小类型：一个结果，和会话失败的原因。

它存在的理由与语音合成的接缝相同——`flutter_test` 运行没有识别器，而状态机与端侧策略都在服务那一侧。

使用方：`speech_recognition_service.dart`。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `SpeechHeard` | 类 | B | 一次识别结果：文本，以及它是否为最终结果。 |
| `SpeechFailure` | 枚举 | B | 会话失败的原因：noMatch、languageUnavailable、permissionDenied、unavailable。 |
| `SpeechBackend` | 抽象类 | B | 声明应用会发起的识别器调用。 |
| `SpeechBackend.initialize` | 方法 | B | 启动识别器并报告它能否被使用。 |
| `SpeechBackend.hasPermission` | 方法 | B | 报告麦克风权限是否已授予。 |
| `SpeechBackend.localeIds` | 方法 | B | 列出识别器支持的区域 id。 |
| `SpeechBackend.listen` | 方法 | B | 聆听一段朗读，按要求只用离线。 |
| `SpeechBackend.stop` | 方法 | B | 停止聆听并保留结果。 |
| `SpeechBackend.cancel` | 方法 | B | 停止聆听并丢弃结果。 |
| `SpeechToTextBackend` | 类 | B | 真实后端，包装 `speech_to_text`。 |
| [`_mapError`](#maperror) | 静态方法 | A | 把插件的错误 id 翻译成本应用会处理的失败。 |

## 文档

### `static SpeechFailure _mapError(String errorMsg)` <a id="maperror"></a>

- **种类：** 静态方法
- **用途：** 把识别器的错误字符串转成 UI 可以据以行动的东西。
- **输入：** `errorMsg`——插件的错误 id，在 Android 上就是 `SpeechRecognizer` 自己的那一套。
- **返回：** `SpeechFailure`。
- **副作用：** 无。
- **算法：** 按顺序做子串判断：先权限，再未匹配与语音超时，再语言，其余一律归为 `unavailable`。
- **使用：** 传给 `initialize` 的错误回调。
- **说明：** 真正有分量的是 `languageUnavailable`。它正是没有下载日语模型的设备对只用离线的请求给出的答复，练习表会把它转成一条同时给出两种修复方式的提示，而不是一句笼统的失败。这份映射紧挨着产生这些字符串的插件，因此插件升级时只有一处需要检查。
