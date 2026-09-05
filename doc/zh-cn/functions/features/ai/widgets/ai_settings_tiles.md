# lib/features/ai/widgets/ai_settings_tiles.dart

设置中配置端侧 AI 辅助的那几行：主开关、每项功能一行状态，以及说明由谁执行模型下载的那句话。

构建方式与「语音」分节相同，出于同样的理由没有放进 `settings_page.dart`。

使用方：`settings_page.dart`，它仅在 Android 上纳入这一节。

自 M3.0 起，无法提供功能的那一行还会显示设备的原话——原始的 `FeatureStatus` 值，或调用失败时的异常类名——并带一个**重新检查**按钮，因为 AICore 会在设备初始化之后自行准备，有时还要重启一次。分区底部有一行写明已安装的 AICore 版本与设备型号。见 [`../../../../features/ai-assist.md`](../../../../features/ai-assist.md)。

自 v0.4.6 起，上述每一行诊断信息都藏在开发者选项之后。学习者看到的只有那句状态说明，别的什么都没有：不翻译的 `_diagnostic` 行写的是模型变体与 token 上限，AICore 那一行写的是一个包版本号，而学习者对其中任何一项都无从下手——「就绪」就是他们需要知道的全部。在标志之后，这些行仍然是一份缺陷反馈最先需要的东西，所以它们一行都没有删。`_featureRow` 把这个标志作为必填参数 `debug` 接收，`_statusLabel` 作为可选参数接收，于是调用方不会因为忘记传而漏出一行诊断信息；AICore 那一行则在调用处由 `settings.debugMode` 把关。标志是 `AppSettings.debugMode`，通过连点版本号那一行八次解锁——见 [`../../../shared/providers/app_settings.md`](../../../shared/providers/app_settings.md) 与 [`../../settings/views/settings_page.md`](../../settings/views/settings_page.md)。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `AiSettingsTiles` | 类 | B | 「端侧 AI」分节。 |
| [`initState`](#initstate) | 方法 | A | 跟随服务，并询问其模型能做什么。 |
| `dispose` | 方法 | B | 停止跟随服务。 |
| `_onServiceChanged` | 方法 | B | 状态或下载变化时重建。 |
| [`build`](#build) | 方法 | A | 构建开关与各行。 |
| [`_featureRow`](#featurerow) | 方法 | A | 构建某项功能的状态行；只有设置了 `debug` 时才带诊断行。 |
| `_statusLabel` | 静态方法 | B | 用学习者的语言命名一种状态；未设置 `debug` 时 `unknown` 读作不支持。 |
| `_diagnostic` | 静态方法 | B | 状态行下面那行不翻译的文字：是什么在服务，或者什么被拒绝了。 |
| `_coreLine` | 静态方法 | B | 命名这些功能背后的 AICore 安装——版本、设备，以及它能否提供模型。 |
| `_progressLabel` | 静态方法 | B | 说明一次下载进行到哪里。 |
| `_iconFor` | 静态方法 | B | 为一种状态挑选图标。 |

## 文档

### `void initState()` <a id="initstate"></a>

- **种类：** 方法
- **用途：** 订阅服务并刷新状态。
- **输入：** 无。
- **返回：** 无。
- **副作用：** 添加监听；**仅在**功能已开启时查询 AICore。
- **算法：** 添加监听，若已开启则在首帧之后刷新。
- **使用：** 设置页。
- **说明：** 开关关闭时不会向设备请求任何东西，因此从未开启过它的用户打开设置页时不会触碰任何模型。该服务被直接监听而不是通过 riverpod watch，因为它是全应用单例——为什么它不是 `ChangeNotifierProvider`，见 `aiAssistServiceProvider`。

### `Widget build(BuildContext context)` <a id="build"></a>

- **种类：** 方法
- **用途：** 构建这一节。
- **输入：** 构建 context。
- **返回：** `Widget`。
- **副作用：** 在使用控件之前无。
- **算法：** 在没有端侧模型的平台上只显示一行说明；否则显示开关，开启后再显示每项功能一行以及下载说明。
- **使用：** `settings_page.dart`。
- **说明：** `settings_page.dart` 在 Android 以外整节省略，所以那行说明是给其他调用方的兜底，用户通常看不到它。按钮下方的下载说明不是脚注：下载模型是本功能唯一用到网络的动作，它由系统而非应用执行，且只在点击时发生。把这三点写在按钮旁边，才让打开开关成为一个知情的选择。那句说明下面的 AICore 行只在 `if (settings.debugMode)` 时构建：装的是哪个 AICore 版本是诊断的另一半——功能 API 与 Prompt API 由同一个包的不同版本提供——但它是诊断而不是信息，所以它和其余诊断信息一起等在开发者选项之后。每个 `_featureRow` 收到的 `debug` 也正是 `settings.debugMode`。

### `Widget _featureRow(BuildContext, AiAssistService, GenAiFeature, String label, {required bool debug})` <a id="featurerow"></a>

- **种类：** 方法
- **用途：** 显示某项功能的状态，并提供它的下载。
- **输入：** context、服务、功能与它的标签，外加 `debug`——必填，两处调用都传入 `settings.debugMode`。
- **返回：** `Widget`。
- **副作用：** 在使用「下载」之前无。
- **算法：** 图标与副标题取自状态或正在进行的下载；只有当系统说模型可以获取时才出现下载按钮。**只有**设置了 `debug` 时才调用 `_diagnostic`，而且只有在它确实产出了一行时该行才是三行高。
- **使用：** `build`，两次。
- **说明：** 仅在本文件内使用的辅助函数。`debug` 是必填而不是带默认值，因为忘记传它应当是一个编译错误，而不是给学习者看的一行诊断信息。它把关的那一行刻意不翻译：它是用来在缺陷反馈中引用的标识符，不是给人读的说明。没有它，「本设备不支持」这一句在下面三种情况下都一模一样：设备不在公布的支持列表上、一个模型变体被拒绝而另外三个从未尝试、或者调用抛了异常——而这三者的修法各不相同。用两行而不是一行，是因为这两项功能有各自的模型和各自的下载——一台设备可能有解释而没有校对，此时单独一行「AI：就绪」就是谎话。任何下载进行期间按钮都被禁用，因为 AICore 同时只服务一个，两个加载指示会暗示相反的事。进度用 MB 而非百分比：系统并不总会报告总量，而一个中途必须消失的百分比比一个只增不减的数字更糟。
