# lib/features/ai/services/genai_backend.dart

应用与平台生成式模型之间的接缝，以及基于 `com.yuanzhe.my_nihongo/genai` 方法通道的真实实现。

它存在的理由与语音识别、语音合成的接缝相同：`flutter_test` 运行时没有 AICore，而值得测试的一切——开关闸门、状态处理、提示词、解析——都在服务这一侧。

使用方：`ai_assist_service.dart`，以及 `sentence_lab_page.dart` 与 `ai_settings_tiles.dart`（使用其中的枚举）和测试。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `GenAiFeature` | 枚举 | B | 一次调用针对两个端侧模型中的哪一个。 |
| `GenAiStatus` | 枚举 | B | 某项功能此刻在本设备上能做什么。 |
| `GenAiFailure` | 枚举 | B | 一次尝试为何没有产出答案。 |
| `GenAiException` | 类 | B | 调用无法产出结果时抛出。 |
| `GenAiBackend` | 抽象类 | B | 接缝本身。 |
| `GenAiBackend.status` | 方法 | B | 询问某项功能能做什么。 |
| [`GenAiBackend.download`](#download) | 方法 | A | 请求系统获取某项功能的模型。 |
| `GenAiBackend.explain` | 方法 | B | 生成一个回答。 |
| `GenAiBackend.proofread` | 方法 | B | 为一个句子索取修改后的写法。 |
| `GenAiBackend.cancel` | 方法 | B | 停止正在进行的操作。 |
| `MethodChannelGenAiBackend` | 类 | B | 基于方法通道的真实后端。 |
| [`MethodChannelGenAiBackend.status`](#status) | 方法 | A | 询问平台，或不经平台直接作答。 |
| `MethodChannelGenAiBackend.download` | 方法 | B | 启动下载并转发进度。 |
| `MethodChannelGenAiBackend.explain` | 方法 | B | 把一个提示词送过通道。 |
| `MethodChannelGenAiBackend.proofread` | 方法 | B | 把一个句子送过通道。 |
| `MethodChannelGenAiBackend.cancel` | 方法 | B | 尽力取消。 |
| `_handlePlatformCall` | 方法 | B | 接收来自平台的下载进度。 |
| `_failureFor` | 静态方法 | B | 把平台错误码映射为失败原因。 |

## 文档

### `Future<bool> download(GenAiFeature feature, {void Function(int, int)? onProgress})` <a id="download"></a>

- **种类：** 方法
- **用途：** 请求系统获取某项功能的模型。
- **输入：** `feature`，以及 `onProgress`，参数为已下载字节数和总量（未知时为 -1）。
- **返回：** `Future<bool>` —— 完成后模型是否就绪。
- **副作用：** **系统**通过网络下载一个模型。
- **算法：** 只注册一次进度处理器，调用通道，随后清除。
- **使用：** `AiAssistService.download`，来自设置中的按钮。
- **说明：** 应用自己从不下载任何东西；它请求 AICore 去下载，而 AICore 从 Google 获取。这个区别正是隐私政策所陈述的内容，也是本文件中唯一会触及网络的方法。进度是反方向的调用，因此处理器是惰性注册的——这条通道上没有别的东西会回调。

### `Future<GenAiStatus> status(GenAiFeature feature)` <a id="status"></a>

- **种类：** 方法
- **用途：** 报告某项功能在本设备上能做什么。
- **输入：** `feature`。
- **返回：** `Future<GenAiStatus>`。
- **副作用：** 一次通道调用，仅在 Android 上。
- **算法：** 在不可能有端侧模型的平台上直接短路为 `unsupported`；否则把平台的四个字符串、以及任何错误，映射到枚举上。
- **使用：** `AiAssistService.refreshStatus`，以及每次生成之前。
- **说明：** 平台错误回答 `unavailable` 而不是抛出：问不出来**就是**「本设备不能」这个答案，而在这里抛异常只会迫使每个调用方捕获后说同一句话。`unsupported` 短路则保证了在 Windows、macOS 和 iOS 上根本不触碰通道——那里没有这个通道，任何调用都会抛 `MissingPluginException`。
