# lib/features/ai/services/ai_assist_service.dart

持有端侧 AI 的策略：它是否可以运行、每项功能此刻能做什么，以及同时只跑一个的规则。

与 `TtsService` 和 `SpeechRecognitionService` 一样，是一个可注入后端的单例，因此 widget 测试无需设备就能驱动每一条分支。

使用方：`aicore_sentence_enhancer.dart`、`ai_settings_tiles.dart`、`sentence_lab_page.dart`、`app_settings.dart`、`sentence_analyzer.dart`。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `GenAiDownload` | 类 | B | 一次模型下载进行到哪里。 |
| `GenAiDownload.fraction` | getter | B | 完成比例，总量未知时为 null。 |
| `AiAssistService` | 类 | B | 策略持有者。 |
| `AiAssistService.instance` | 字段 | B | 全应用共用的实例。 |
| `setInstanceForTest` | 静态方法 | B | 在测试中替换单例。 |
| `AiAssistService.defaultMaxOutputTokens` | 常量 | B | 调用方没有指定预算时，回答可以有多长。 |
| `AiAssistService.preferFast` | getter | B | 设备同时提供两种规格时，是否优先使用较小、较快的模型。 |
| `AiAssistService.setPreferFast` | 方法 | B | 选择较大或较快的模型，并立即重新探测。 |
| `AiAssistService.timeout` | 常量 | B | 一次生成允许耗时多久。 |
| `statusOf` | 方法 | B | 某项功能最近一次询问到的状态。 |
| `canExplain`、`canProofread` | getter | B | 此刻是否可以提供各自的操作。 |
| [`needsDownload`](#needsdownload) | getter | A | 指向设置的那行提示是否适用。 |
| [`setEnabled`](#setenabled) | 方法 | A | 打开或关闭该功能。 |
| `refreshStatus` | 方法 | B | 询问设备每项功能能做什么。 |
| `download` | 方法 | B | 请求系统获取某项功能的模型。 |
| [`explain`](#explain) | 方法 | A | 生成一段解释。 |
| `proofread` | 方法 | B | 为一个句子索取修改后的写法。 |
| `cancel` | 方法 | B | 停止正在进行的操作。 |
| `_requireEnabled` | 方法 | B | 功能关闭时拒绝每一个生成调用。 |
| [`aiAssistServiceProvider`](#provider) | provider | A | 该服务，供设置页与实验室读取。 |

## 文档

### `Future<void> setEnabled(bool value)` <a id="setenabled"></a>

- **种类：** 方法
- **用途：** 打开或关闭端侧 AI。
- **输入：** `value`。
- **返回：** 无。
- **副作用：** 打开时刷新状态；关闭时取消正在进行的操作并忘掉所有状态。
- **算法：** 忽略无变化的调用，然后分支。
- **使用：** `AppSettingsNotifier.setAiAssistEnabled`，以及首次加载。
- **说明：** 关闭是立即且彻底的——不再向设备请求任何东西，实验室在下一次构建时就不再提供那些操作。持久化这个选择是 `AppSettingsNotifier` 的职责，与其他每一项偏好一样；本类从不写盘。

### `Future<String> explain(String prompt)` <a id="explain"></a>

- **种类：** 方法
- **用途：** 生成一段解释。
- **输入：** 已拼装好的 `prompt`。
- **返回：** `Future<String>`；失败时抛出 `GenAiException` 而不是返回失败值。
- **副作用：** 在设备上运行模型。
- **算法：** 关闭则拒绝，忙碌则拒绝，重新询问状态，不可用则拒绝，然后在超时保护下调用后端。
- **使用：** `AiCoreSentenceEnhancer.explain`。
- **说明：** **闸门的顺序才是关键。** 关闭状态在询问状态之前就被拒绝，因此即便设备上已有模型，开关关着时也什么都不做——后端不是被调用后忽略，而是根本没有被调用，`test/ai_assist_service_test.dart` 断言的正是这一点。状态每次都重新询问，因为系统可能在两次请求之间移除模型，而记住的「可用」会把这变成学习者无法理解的失败。生成的内容不会被存到任何地方。

### `bool get needsDownload` <a id="needsdownload"></a>

- **种类：** getter
- **用途：** 判断实验室是否显示「模型尚未下载」那行提示。
- **输入：** 无。
- **返回：** `bool`。
- **副作用：** 无。
- **算法：** 功能已开启、无法解释、且存在可下载或正在下载的功能时为真。
- **使用：** `SentenceLabPage._buildAiActions`。
- **说明：** 最后一个条件正是让这行提示不出现在根本无法运行模型的设备上的原因。让那位用户去下载什么东西是一个空头承诺——那里没有可修的东西，诚实的做法是干脆什么都不说。

### `final aiAssistServiceProvider` <a id="provider"></a>

- **种类：** provider
- **用途：** 把单例交给需要它的 widget。
- **输入：** 无。
- **返回：** `Provider<AiAssistService>`。
- **副作用：** 无。
- **算法：** 返回 `AiAssistService.instance`。
- **使用：** `sentence_analyzer.dart`、`ai_settings_tiles.dart`、`sentence_lab_page.dart`。
- **说明：** 是普通的 `Provider`，**不是** `ChangeNotifierProvider`，理由值得记下：riverpod 会在作用域消失时销毁 `ChangeNotifierProvider` 所持有的 notifier，而对一个全应用单例来说，这意味着下一个 `ProviderScope`——下一个测试，或重建后的根——拿到的是一个已销毁的服务。使用方改为自己添加监听，与语音服务的监听方式一致。
