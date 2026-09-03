# lib/features/speech/services/speech_recognition_service.dart

应用的语音识别策略：只识别日语、除非学习者主动放弃否则在端侧进行、同一时刻只有一次会话、麦克风在首次使用时才申请。它是一个 `ChangeNotifier`，因此练习表能随会话推进而渲染。

它构建在 [`SpeechBackend`](speech_backend.md) 之上，因此状态机与端侧规则无需识别器即可测试——`test/speech_recognition_service_test.dart` 驱动每一次状态转移。

使用方：`pronunciation_practice_sheet.dart`、`speech_settings_tiles.dart`（状态行与网络回退开关）、`app_settings.dart`（启动时应用持久化的开关）。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `SpeechPhase` | 枚举 | B | 聆听会话所处的阶段：idle、listening、processing、failed、done。 |
| `SpeechRecognitionService` | 类 | B | 在端侧聆听一段日语朗读。 |
| `setInstanceForTesting` | 静态方法 | B | 在测试中替换全局实例。 |
| [`ensureAvailable`](#ensureavailable) | 方法 | A | 启动识别器一次并找到日语区域设置。 |
| `hasPermission` | 方法 | B | 报告麦克风权限是否已授予。 |
| [`listen`](#listen) | 方法 | A | 聆听一段朗读。 |
| `stop` | 方法 | B | 结束会话并保留已识别的内容。 |
| `cancel` | 方法 | B | 放弃会话并关闭麦克风。 |
| `reset` | 方法 | B | 回到空闲，准备下一次尝试。 |
| `_onHeard` | 方法 | B | 记录部分或最终结果；空的最终结果视为未识别。 |
| `_onFailure` | 方法 | B | 记录异步识别错误，忽略在最终结果之后到达的那一次。 |
| `_fail` | 方法 | B | 进入失败状态。 |

## 文档

### `Future<bool> ensureAvailable()` <a id="ensureavailable"></a>

- **种类：** 方法
- **用途：** 一次性判断本设备是否可能进行日语识别。
- **输入：** 无。
- **返回：** `Future<bool>`。
- **副作用：** 首次调用会初始化平台识别器——麦克风权限就在那时申请。
- **算法：** 先判断 `platformMayRecognizeSpeech`，因此插件背后没有实现的平台绝不会为一个用不上的麦克风弹窗。随后初始化，再查找语言子标签为 `ja` 的区域 id；找不到就报告不可用。
- **使用：** `listen`（它自己会调用），以及设置页的状态行。
- **说明：** 区域 id 按 `ja` 前缀匹配而非与常量比较，因为 Android 写作 `ja_JP`，Apple 写作 `ja-JP`。结果会被记住：没有识别器的设备不会每次点击都被重新询问。

### `Future<void> listen()` <a id="listen"></a>

- **种类：** 方法
- **用途：** 录制一段朗读并公布识别器的理解。
- **输入：** 无；读取 `networkFallbackAllowed`。
- **返回：** 无；结果经由 `notifyListeners` 送达。
- **副作用：** 打开麦克风。
- **算法：** 确认可用性、清除上一次结果、进入 `listening`，然后以 `onDevice: !networkFallbackAllowed` 请求后端聆听。
- **使用：** 练习表的录音按钮。
- **说明：** **隐私承诺就落实在这里。** `onDevice` 为真意味着只用离线：在 Android 上它对应 `EXTRA_PREFER_OFFLINE`，没有安装日语模型时会失败而不是回退。该失败是诚实的答案，UI 会加以解释；只有在设置中明确打开回退的学习者，才可能发出会到达服务器的请求。
