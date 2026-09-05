# Android AICore 与 ML Kit GenAI API

**最后核实：2026-09-04**，在 Pixel 10（Android 17）上，以及经由用户报告在 Galaxy Z Fold 8 上。 见文末的[如何刷新本页](#如何刷新本页)——核对过资料的 agent 必须在同一次提交中更新**两种语言**版本顶部的日期，哪怕别的什么都没有改。

本页是一份**与具体项目无关的参考**。它面向 MyApps 系列中任何考虑端侧生成式 AI 的 Flutter 或 Android 项目，而不只是 MyNihongo!!!!!。本应用具体拿它做了什么，写在 [`features/ai-assist.md`](features/ai-assist.md)；平台事实写在这里。

## AICore 是什么

`com.google.android.aicore` 是一个 Android 系统服务，它持有端侧基础模型，并为其他应用执行推理。应用自己既不打包也不加载模型：它请求 AICore，由 AICore 拥有模型文件、下载、内存与调度。这就是端侧 GenAI 只让应用多出几百 KB 客户端库、而不是几 GB 资源的原因，也是那句隐私声明可以说得很准确的原因——文本交给的是**同一台设备上的系统服务**，而不是服务器。

**ML Kit GenAI** 是它之上的客户端库家族（`com.google.mlkit:genai-*`）。没有受支持的方式绕过它直接访问 AICore。

动手设计之前有两点值得知道：

- **可用性是运行时问题，且逐功能不同。** 同一台手机上的两项功能可以有不同状态。每次使用前都要问，而不是问一次。
- **模型下载是应用触发、但并非应用执行的网络操作。** 由 AICore 从 Google 获取。任何隐私政策都必须说明这一点，任何应用都不应在用户没有要求时启动它。

## 要求

| 要求 | 取值 |
|---|---|
| Android API | Prompt API 需要 26+；功能类 API 类似，但要逐项核对 |
| AICore 应用 | 必需，且版本要能提供所请求的功能 |
| Bootloader | **必须已锁定。** 在解锁 bootloader 的设备上这些 API 会拒绝运行 |
| Play 服务 | 实际使用中存在；这些库通过 Google 的 Maven 解析 |
| 设备 | 每个 API 有各自公布的列表；见下文 |

bootloader 必须锁定这一条最容易让人意外：已 root 或刷了第三方 ROM 的开发机根本无法测试这些 API，而且失败看起来是「不可用」，不像权限错误。在下结论说某台设备因别的原因不受支持之前，先查 `ro.boot.verifiedbootstate`（应为 `green`）和 `ro.boot.flash.locked`（应为 `1`）。

还有一个首次运行的注意点：设备刚完成初始设置或 AICore 刚被重置时，该服务可能需要联网、有时还需要重启，之后才会返回 `UNAVAILABLE` 以外的结果。

## 这些 API

截至核实日期共六个。四个「功能类」API 是任务型的，返回 `ListenableFuture`；Prompt API 是自由形式的，基于协程。

| API | 构件 | 用途 | 输入上限 |
|---|---|---|---|
| Prompt | `com.google.mlkit:genai-prompt:1.0.0-beta4` | 自由文本或图文 → 文本 | < 4000 token |
| 摘要 | `com.google.mlkit:genai-summarization` | 文章或对话 → 要点摘要 | 见文档 |
| 校对 | `com.google.mlkit:genai-proofreading:1.0.0-beta1` | 修正短文本的语法与拼写 | < 256 token |
| 改写 | `com.google.mlkit:genai-rewriting:1.0.0-beta1` | 换一种语气或风格重述 | < 256 token |
| 图像描述 | `com.google.mlkit:genai-image-description` | 图片 → 一句描述 | — |
| 语音识别 | `com.google.mlkit:genai-speech-recognition` | 音频 → 文本；基础模式 API 31+，高级模式限 Pixel 10/11 | — |
| 结构化输出 | `com.google.mlkit:genai-schema:1.0.0-alpha1` | 供 Prompt API 按其解码的输出 schema | — |

它们都依赖 `com.google.mlkit:genai-common`（`1.0.0-beta4`），`FeatureStatus`、`DownloadCallback`、`DownloadStatus`、`StreamingCallback` 和 `GenAiException` 都在那里。Prompt API 的 POM 会自己拉取配套的 `genai-common`，所以只钉住 `genai-prompt` 就够了。

全部是 **beta**：没有 SLA，没有弃用政策。请锁定确切版本。

### 语言

校对与改写文档中列出的是**英语、日语、法语、德语、意大利语、西班牙语和韩语**。Prompt API 没有公布这样的列表——它是通用模型，对任一具体语言，务实的答案是「在设备上试，然后读输出」。Google 自己的说法是「具体的语言支持可能因设备配置而异」。

### 设备

功能类 API（摘要、校对、改写、图像描述）列出了 Pixel 9 及更新机型，外加一大批骁龙、Tensor 和天玑设备——三星 Galaxy S25 与 S26 系列、Galaxy Z Flip8、Z Fold8 和 Z Fold8 Ultra，以及荣耀、iQOO、联想、摩托罗拉、一加、OPPO、POCO、realme、夏普、索尼、vivo、小米的机型。

**Prompt API 的列表更窄，并且按 Gemini Nano 版本分层**——调用失败时，这一点才是关键：

| Nano | 设备（节选） |
|---|---|
| nano-v2 | 荣耀、iQOO、摩托罗拉、一加、OPPO、POCO、realme、三星 Z Fold7 与 Z TriFold、vivo、小米 |
| nano-v3 | Pixel 10 系列、荣耀、iQOO、联想、摩托罗拉、一加、OPPO、realme、三星 S26 系列、夏普、索尼、vivo |
| nano-v4 | Pixel 11 系列；**三星 Galaxy Z Flip8、Z Fold8、Z Fold8 Ultra** |

**nano-v4 设备需要 `genai-prompt` 1.0.0-beta4 或更新版本。** 更早的客户端在这类设备上调用 `checkStatus()` 会抛出 `FEATURE_NOT_FOUND`——beta4 的发布说明写得很明白：「修复了与 Gemini Nano v4 的兼容性……使用 `checkStatus()` 时抛出 `GenAiException`」。这个失败看起来和「设备不支持」一模一样，但它不是。见下面的 Z Fold 8 现场记录。

这次升级**必要但不充分**。新客户端能把问题问出口；但除非明确告诉它，它仍然只请求四个模型变体中的一个，而运行 `beta4` 的 Z Fold 8 拒绝的正是那一个。见[选择模型](#选择模型发布阶段与规格偏好)与下面 Z Fold 8 的实地记录。

请把公布的设备列表当作下限，把运行时状态当作事实——但在相信一次拒绝之前，先看客户端库的版本，也看你究竟请求了哪一个变体。

## 选择模型：发布阶段与规格偏好

不带参数的 `Generation.getClient()` 并不是「这台设备上的模型」。它是一个很具体的请求——**stable** 发布阶段、**full** 规格偏好——而不提供这一确切组合的设备会回答 `UNAVAILABLE`，这与「根本没有端侧模型」在表现上完全无法区分。

用 `javap -public` 对 `genai-prompt:1.0.0-beta4` 核实过的写法：

```kotlin
Generation.getClient(
    GenerationConfig.Builder().apply {
        modelConfig = ModelConfig.builder().apply {
            releaseStage = ModelReleaseStage.PREVIEW   // STABLE = 0, PREVIEW = 1
            preference = ModelPreference.FAST          // FAST = 1, FULL = 2
        }.build()
    }.build(),
)
```

一共四种组合，而且**没有任何 API 能问出设备提供其中哪几种**。唯一的办法是为每一种建一个客户端，各调用一次 `checkStatus()`。Google 自己的指引只用一句话说了同样的事：不是每台设备都支持每一种阶段与偏好的组合，`UNAVAILABLE` 是*那一个变体*的回答而不是设备的回答，应用应当始终实现回退策略。

所以可行的形态是探测，而不是配置：

1. 尝试**每一个**变体，而不只是第一个成功之前的那些。
2. 保留第一个 `checkStatus()` 不是 `UNAVAILABLE` 的；其余立刻关闭，因为开着的客户端会占用一个 AICore 会话。
3. **报告哪一个变体应答了、哪些提供了服务、哪些被拒绝了。**

第 1 步之所以不提前退出，是因为**用户是否有得选，本身就是一个事实**，而一个在第一次成功时就返回的循环不可能知道它。第 3 步也不是锦上添花——没有它，「本设备不支持」这一句话就同时覆盖四个不同的请求，任何现场反馈都无法把它们区分开。本应用会在被拒绝的行下面打印 `FeatureStatus=0 · refused: stable/full, stable/fast, preview/full, preview/fast`，在正常工作的行下面打印 `stable/fast · nano-v4-fast · 4096 tok`。

把四个都重新探一遍，每个要一次往返，所以它只在明确的刷新时进行——开关打开、设置页打开、**重新检查**——而一次生成则信任已经在服务的那个变体。

### 下载下来的模型归谁

归 AICore。这一点值得说准确，因为下载完成之后最自然的下一个问题就是怎么删掉它。

模型文件属于 `com.google.android.aicore` 系统服务，并且**与所有请求同一模型的应用共享**：第二个应用请求它时不会重新下载。应用自身的存储不会变大。而且**两个 ML Kit 客户端都没有提供任何删除它的办法**——用 `javap` 看 `genai-prompt` 与 `genai-proofreading`，只有 `download`、`close`、`clearImplicitCaches`，没有别的；`close()` 释放的是推理会话，不是文件。

所以应用不应该提供「移除」按钮。它要么什么都不做，要么万一真的成功了，就是把别的应用正在用的模型删掉。应当引导用户去 Android 自带的 AICore 设置。

`ModelReleaseStage.PREVIEW` 值得一试，也值得理解清楚：它只在加入了 **AICore 开发者预览**的设备上才能拿到模型，而应用无法让一台设备加入——它做什么都不会让普通用户那里出现预览模型。问它一次只花一次状态调用，偶尔能在开发者自己的手机上应答，所以它排在顺序的最后，而不是被删掉。

因此支持范围更应该写成一条规则而不是一份名单：**已安装的客户端能够指名的每一个变体，按应用偏好的顺序。** 公布的设备列表是一张有日期的快照；一秒钟前回来的 `FeatureStatus` 不是。

### 有模型在服务之后还能问什么

| 调用 | 形态 | 用途 |
|---|---|---|
| `getBaseModelName()` | `suspend`，`String` | 客户端背后实际是哪个模型 |
| `getTokenLimit()` | `suspend`，`Int` | 真实的输入预算，而不是文档上的 |
| `isThinkingModeAvailable()`、`isSystemPromptAvailable()`、`isStructuredOutputFeatureAvailable()`、`isCachingFeatureAvailable()` | `suspend`，`Boolean` | beta3/beta4 客户端新增的逐项能力探测 |
| `warmup()` | `suspend` | 在学习者开始等待之前先付掉加载成本 |

这些都只有在某个变体已经在服务时才有意义；在拒绝服务的设备上它们会抛异常。把它们当作可以展示的诊断信息，永远不要当作依赖它们的开关。

### 读懂一次失败

`GenAiException.getErrorCode()` 返回 `GenAiException.ErrorCode` 中的常量，拿它来分支远比拿 `message` 的英文文本来分支可靠：

| 代码 | 常量 | 含义 |
|---|---|---|
| 8 | `NOT_AVAILABLE` | 此处不提供该功能 |
| 16 | `NOT_SUPPORTED` | 该模型不支持这个请求 |
| -101 | `AICORE_INCOMPATIBLE` | AICore 本身无法服务这台设备 |
| 604 | `NEEDS_SYSTEM_UPDATE` | 该更新的是系统，不是应用 |
| 12 | `REQUEST_TOO_LARGE` | 超出 token 上限 |
| 9 | `BUSY` | 另一次推理正在进行 |
| 7 | `CANCELLED` | 调用方取消了 |

另外还有 `com.google.mlkit.genai.common.internal.GenAiUtils.isAiCoreCompatible(context)`。它是**内部** API，所以要把调用包起来，并把类缺失当作「未知」——但在一台拒绝了每个模型变体的设备上，它是唯一能区分「这里根本没有 AICore 或版本太旧」与「AICore 没问题，只是不提供这个模型」的东西。这个区别值得一次允许消失的内部调用。

## 两种 API 形态

以下由 `javap` 对已发布 AAR 反查确认，而不只是照抄文档。

### Prompt（协程）

```kotlin
val model: GenerativeModel = Generation.getClient()          // or getClient(GenerationConfig)

when (model.checkStatus()) {                                  // suspend, returns Int
    FeatureStatus.UNAVAILABLE -> {}
    FeatureStatus.DOWNLOADABLE -> model.download().collect { status ->
        when (status) {
            is DownloadStatus.DownloadStarted -> status.bytesToDownload
            is DownloadStatus.DownloadProgress -> status.totalBytesDownloaded
            is DownloadStatus.DownloadFailed -> status.e
            DownloadStatus.DownloadCompleted -> {}
        }
    }
    FeatureStatus.DOWNLOADING -> {}
    FeatureStatus.AVAILABLE -> {}
}

val response = model.generateContent(
    generateContentRequest(TextPart(prompt)) {
        temperature = 0.2f
        topK = 16
        candidateCount = 1
        maxOutputTokens = 256
    }
)
val text = response.candidates.firstOrNull()?.text

model.close()
```

`generateContentStream(request)` 返回 `Flow<GenerateContentResponse>` 用于流式输出。`com.google.mlkit.genai.prompt.java` 中还有 `GenerativeModelFutures` 供 Java 调用方使用。

**Android 上没有结构化输出，也没有工具调用。** 请求文本，然后自己解析。

### 功能类 API（ListenableFuture），以校对为例

```kotlin
val proofreader: Proofreader = Proofreading.getClient(
    ProofreaderOptions.builder(context)
        .setLanguage(ProofreaderOptions.Language.JAPANESE)
        .setInputType(ProofreaderOptions.InputType.KEYBOARD)
        .build()
)

proofreader.checkFeatureStatus()                    // ListenableFuture<Integer>
proofreader.downloadFeature(callback)               // ListenableFuture<Void>, DownloadCallback
proofreader.runInference(request)                   // ListenableFuture<ProofreadingResult>
proofreader.close()
```

`ProofreadingResult.getResults()` 给出若干 `ProofreadingSuggestion`，每个有 `getText()`。`runInference(request, StreamingCallback)` 为流式版本。

在同一个 Kotlin 文件里混用这两种形态需要一个 `ListenableFuture.await()`。自己写那十来行 `suspendCancellableCoroutine` 比引入 `kotlinx-coroutines-guava` 更可取——后者会为这一个函数把整个 Guava 拖进 APK。

## 配额与并发

AICore **每个应用同一时刻只服务一次推理**，并施加应用级推理配额。请照此设计：用你自己的「忙」回答拒绝第二个并发请求，而不是让该服务产生一个更难解释的错误。宿主组件消失时要关闭客户端——未关闭的客户端会占住其他应用可能要用的会话。

## 在 Flutter 中使用

有若干 0.x 插件（`google_mlkit_genai_prompt`、`flutter_local_ai`、`edge_gen_ai`、`gemini_nano_android`）。它们只封装了 Prompt API，而且每一个都可能是又一个应用 Kotlin Gradle 插件的插件——这对任何运行 Flutter `android.builtInKotlin=false` 兼容模式的项目都要紧，在该模式下每个应用 KGP 的插件都会约束整个构建。

对这么小的接口面来说，**在应用自己的 Kotlin 里写一个方法通道比加一个依赖风险更小**：两个客户端、五个方法，没有插件，没有需要跟踪的版本。MyNihongo 就是这么做的，见 `android/app/src/main/kotlin/com/yuanzhe/my_nihongo/GenAiChannel.kt`，这个形状值得照搬。

在 `android/app/build.gradle.kts` 中显式设置 `minSdk = 26`——Flutter 的默认值是 24。

```kotlin
implementation("com.google.mlkit:genai-prompt:1.0.0-beta4")
implementation("com.google.mlkit:genai-proofreading:1.0.0-beta1")
implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
```

不需要任何清单权限：用到网络的是 AICore，不是应用。

把策略——是否开启的开关、提示词内容、对回答的解析——留在 Dart 一侧。那里的一切都能在没有 Android 设备的机器上测试；Kotlin 里的一切都不能。

## 用 adb 检查一台设备

```bash
adb shell pm list packages | grep aicore
adb shell dumpsys package com.google.android.aicore | grep versionName
adb shell getprop ro.boot.verifiedbootstate     # want: green
adb shell getprop ro.boot.flash.locked          # want: 1
adb shell getprop ro.build.version.sdk          # want: >= 26
adb logcat | grep -i aicore
```

一台设备可能报告两个 AICore 条目——一个 `/product/priv-app` 预置桩，以及覆盖其上的更新版本。真正提供服务的是更新的那个，所以读 `versionName` 较高的那条。

### 诊断「本设备不支持」

这是最需要一套流程的失败，因为至少四种互不相关的原因都会让应用显示这一句。按顺序排查；前两步不用接线。

1. **先读应用自己的状态行。** 每一行下面都带着设备的原始回答——AICore 被问到并拒绝时是 `FeatureStatus=0`，根本调不通时是异常类名与消息；正常工作的那一行则写明正在服务的变体与模型名。分区底部还有一行写明已安装的 AICore 版本、设备型号，以及 AICore 是否自认为能在此提供模型。这些事实足以区分下面的每一种情况。
2. **看有哪些模型变体被拒绝了。** Prompt API 提供发布阶段与规格偏好的四种组合，一台设备可能一个都不提供，也可能提供其中若干个。拒绝行会列出每一个尝试过的组合。四个都被拒绝而 `compatible` 报告为真，说明这是一台装了 AICore 却没有被提供 Prompt 模型的设备；四个都被拒绝而 `compatible` 为假，那是 AICore 的问题，不是模型的问题。见[选择模型](#选择模型发布阶段与规格偏好)。
3. **当错误是 `FEATURE_NOT_FOUND` 时，看客户端库的版本。** 在 Gemini Nano v4 设备上——Galaxy Z Fold8 系列、Pixel 11 系列——任何早于 `1.0.0-beta4` 的 `genai-prompt` 从 `checkStatus()` 抛出的正是这个错误。它读起来像「本设备没有这项功能」，实际含义是「这个客户端问不了这台设备」。这一步是必要的，但正如下面 Z Fold 8 的记录所示，它本身并不充分。
4. **对比两项功能。** 它们的设备列表不同。「解释」用 Prompt API，其列表更窄；「改写建议」用校对 API，其列表宽得多。一台设备在其中一份列表上而不在另一份上时，一行可用、另一行不可用是很平常的答案——这也正是界面从不把「AI」当成一个整体开关的原因。
5. **检查 bootloader。** `verifiedbootstate` 必须是 `green`，`flash.locked` 必须是 `1`。解锁的 bootloader 会以「不可用」失败，且不会提示这就是原因。
6. **给准备过程时间和网络。** 刚完成设备初始化、重置过 AICore 或系统更新之后，该服务可能一直回答 `UNAVAILABLE`，直到它取回所需内容为止，有时还需要重启。要重新检查而不是直接下结论——设置里的**重新检查**按钮就是为此存在的，它会把整个探测重跑一遍。
7. **核对 AICore 版本与设备。** 厂商通过自己的更新渠道分发 AICore，所以手机很新而它的 AICore 很旧是可能的。
8. **最后才怀疑构建本身。** `logcat -s MyNihongoGenAi` 会打印尝试过的每一个变体、每一次状态回答，以及每一次失败及其异常类。如果失败只出现在 release 构建而 debug 构建正常，先去看 [R8 那条实地记录](#实地记录)。

应用正是为此加了埋点：`GenAiChannel.status` 捕获自己的异常并回答 `unreachable`，附带异常类名，而不是让它们塌缩成 `unavailable`；`GenAiChannel.probePrompt` 记录它尝试过的每一个变体；AICore 包版本则通过清单里的 `<queries>` 条目读取。没有那个条目，在 API 30 及以上该包不可见，每台设备看起来都像没有装 AICore。

## 诚实地谈隐私

值得说准确，因为「端侧 AI」很容易被夸大：

- 推理在设备上进行。提示词和回答都不离开设备。
- **模型下载确实用到网络**，由 AICore 执行，从 Google 获取。它应当由用户发起，并明确披露。
- 输出是生成的文字。它可能有误，凡是展示的地方都应加标注。
- 没有任何理由要求应用保存生成的内容，而教学类应用不应该保存：留下来的错误答案会被再读一遍。

## 实地记录

来自真实使用的观察，随发现随补。每条都注明设备与日期，因为其中没有一条保证能推广。

- **Pixel 10（`frankel`），Android 17，2026-09-03。** AICore 同时以 `/product` 预置桩（`aicore_20260302.01_RC00`）和更新版本（`aicore_20260723.00_RC11`）存在；应答的是更新的那个。`verifiedbootstate=green`、`flash.locked=1`，即原厂设备满足 bootloader 锁定这一条。
- **R8 会把它弄坏，而失败看起来像设备不受支持。** 这一条最值得带到别的项目去。使用默认压缩的 release 构建，在第一次调用时就从 ML Kit 深处抛出 `Objects.requireNonNull` 的 `NullPointerException`；同样的代码在 debug 构建中回答正常——于是应用在一台完全支持的手机上报告「本设备不支持」。AAR 自带的 consumer 规则只覆盖它们生成的 proto。只保留 `com.google.mlkit.genai.**` **是不够的**：R8 的 `mapping.txt` 指出出错帧是 `com.google.mlkit.common.sdkinternal.LazyInstanceMap`，所以 ML Kit 的共享 SDK 内部也必须保留。可行的写法：

  ```proguard
  -keep class com.google.mlkit.** { *; }
  -keep class com.google.android.gms.internal.mlkit_** { *; }
  -dontwarn com.google.mlkit.**
  ```

  这个方法可以推广：当 release 构建在混淆代码内部失败时，去 `build/app/intermediates/mapping/release/*/mapping.txt` 里读出那一帧，而不要靠猜决定保留哪个包。
- **两项功能开箱都是 `DOWNLOADABLE`（1）**，点击下载后几秒内变为 `AVAILABLE`（3）——Pixel 10 上基础模型已经在机器里，所以拉取的很小，某些设备需要的那种数 GB 首次下载在这里没有发生。
- **延迟大约 20–30 秒**，无论是 Prompt API 生成几句话的首次回答，还是校对。慢到界面必须显示加载指示并禁用其他操作；又没慢到一分钟以内的超时不安全。本应用给 45 秒。
- 当提示词要求时，**英文与简体中文输出都正确且地道**，模型为 `nano-v3`。Prompt API 没有公布语言列表；这是一个数据点，不是保证。
- **三星 Galaxy Z Fold 8，2026-09-04：埋点回答了这个问题。** 该设备报告 `AICore 0.release.qc.prod_aicore_20260723.00_RC11 · samsung SM-F971U1`——注意其中的 `qc`，这是高通版本——而两行状态现在不同了：

  | 功能 | 状态 |
  |---|---|
  | 解释（Prompt） | `GenAiException: [ErrorCode 606] AICore failed with error type 3-PREPARATION_ERROR and error code 606-FEATURE_NOT_FOUND: Feature 636 is not available.` |
  | 改写建议（校对） | 可以使用 |

  **这里一开始读错了，而这条更正才是本记录有用的部分。** 原先的结论是：`FEATURE_NOT_FOUND` 是 AICore 在说 Prompt 这项功能在本设备上根本不存在，并且在非 Pixel 硬件上被拒绝就是预期结果。这两点都是错的。

  Z Fold 8 **是**受支持的 Prompt API 设备：它在公布的 nano-v4 列表上，与 Z Flip8、Z Fold8 Ultra 和 Pixel 11 系列并列。这个错误的真正含义是：**客户端库太旧，无法与 nano-v4 设备对话**。`genai-prompt` `1.0.0-beta4`（2026-07-21）的发布说明是「修复了与 Gemini Nano v4 的兼容性」，并把 `checkStatus()` 抛出 `GenAiException` 列为症状。而应用当时钉在 `1.0.0-beta2`。

  已在 `v0.3.2` 中通过升级这一个依赖修复。Kotlin 代码无需改动，这一点是用 `javap` 对比两个 AAR 核实过的，不是想当然。**尚未在设备上确认：** 本机没有三星硬件，所以已核实的是应用能够构建，而不是那一行变绿了。

  有两点值得带到别的项目去。**公布的设备列表是关于设备的证据，不是关于你的客户端的**——运行时状态才是事实，但前提是库新到足以把问题问出口。还有，**看起来说得通的解释才是危险的那个**：「这台硬件不在列表上」符合当时掌握的每一条事实，被当作定论写了下来，并且让调查停了一天。

  这对应用改变了什么：什么都没有，而这正是要点。那一行显示的就是设备自己说的话，另一行照常工作，而**重新检查**可以在不切换开关的情况下再问一次。这对本页的读者改变了什么：下面那个猜测，现在是一次实测。

- **Pixel 10，`v0.4.1` release 构建，2026-09-04：两台设备提供的变体正好相反，而这正是「要探测」的全部理由。**
  探测结果：

  | 变体 | Pixel 10 | Galaxy Z Fold 8 |
  |---|---|---|
  | `stable/full` | **提供**（`nano-v3`） | 拒绝 |
  | `stable/fast` | 拒绝 | **提供**（`nano-v4-fast`） |
  | `preview/full` | 拒绝 | 拒绝 |
  | `preview/fast` | 拒绝 | 拒绝 |

  没有任何一个固定的变体能同时服务这两台手机，而只挑其中一个，都会让另一台看起来不受支持。过去两个版本发生的正是这件事。

  两台设备都不会看到规格开关，因为两台都只提供一种规格。

- **模型比应用活得久，这就是判断它归谁的办法。** 卸载并重新安装应用——这会清空它的数据，AI 开关也回到关闭——之后 Prompt 模型仍然是
  `AVAILABLE`。是 AICore 把它留住了。应用拒绝提供「移除」按钮，依据就是这个观察。

- **R8 删掉了 ML Kit 需要的一个协程桥接方法，而只有 release 构建会发现。** 在 Pixel 10 上点击「下载」抛出

  ```
  java.lang.NoSuchMethodError: No static method cancel$default(
      Lkotlinx/coroutines/Job;Ljava/util/concurrent/CancellationException;
      ILjava/lang/Object;)V in class Lkotlinx/coroutines/Job;
  ```

  来自 `mlkit_genai_prompt` 内部。Kotlin 会把省略默认参数的调用编译成一个合成的静态 `…$default` 桥接方法；ML Kit 的 dex 代码调用了
  `Job` 上的那个，而本应用从不调用，于是 R8 把它删了。下载其实还是完成了——那是 AICore 在做——但应用被告知失败了。

  这是同一项功能里**第二次** R8 故障，上面那条是 `LazyInstanceMap`，教训相同：要保留的是库会调用的东西，不是你自己代码调用的东西。规则是
  `-keep class kotlinx.coroutines.** { *; }`，整包保留，因为这些桥接方法是生成的，没有可以逐个列举的公开清单。代价约 0.2 MB 的 APK 体积。

- **三星 Galaxy Z Fold 8，设备上装的是 `v0.3.2`，2026-09-04：beta4 也不是那个修复。** 这次升级改变的是症状，不是结果。`checkStatus()` 不再抛异常了；它返回 `0`，那一行读作「本设备不支持 · `FeatureStatus=0`」。校对依然可以使用。

  **也就是说，第二个看起来说得通的解释同样是错的。**「客户端太旧问不出口」严丝合缝地解释了 `FEATURE_NOT_FOUND` 异常，有 Google 自己 beta4 的发布说明佐证，并且被当作定论写进了本页和 `build.gradle.kts`。它是对的，但它不充分：旧客户端根本问不出口，而新客户端也只问了四个模型变体中的**一个**。不带配置的 `Generation.getClient()` 请求的是 stable、full 规格的模型，而这台设备不提供它。

  `v0.4.0` 对此的做法刻意不是第三个猜测。应用会探测每一个变体，保留第一个应答的，并把被拒绝的那些打印出来——于是这台设备的下一份反馈说的是*究竟发出了哪四个请求*，而不只是「有东西不可用」。如果四个全被拒绝，那就是诚实的结果，应用会列出这些拒绝，而不是给出一个原因。

  这条记录存在的意义在于一条规则：**连续两次诊断错误，说明该修的是埋点。** 两个解释都说得通、都有证据、都让调查就此结束。两个都无法用应用自己的输出证伪，而这才是下一个理论之前最该修的性质。

- **三星 Galaxy Z Fold 8，2026-09-03 反馈：AICore 已安装，两项功能都显示「不可用」。** 未在此复现——本机没有三星设备——记录下来是因为这份反馈的*形状*才是有用的部分。这里猜测的两种原因——设备不在列表上，或 AICore 落后于手机——都是错的；上面那条记录里有实测出的原因和修复方式。真正让它无法诊断的是应用，不是设备：所有失败路径都回答同一句话，于是「AICore 说不行」「调用抛异常」「这个构建看不见该包」三者无法区分。[诊断小节](#诊断本设备不支持)描述的埋点就是为这份反馈加的；**把公布的设备列表当作下限，把运行时状态当作事实**，并且预期在 Prompt API 不支持的硬件上校对功能仍然可用。
- 校对 API 拿到一个**正确**的句子时，会原样返回该句子，所以客户端必须自己比较并说「无需修改」——否则就是在告诉学习者他们正确的句子写错了。

## 如何刷新本页

这些 API 处于 beta 且在变动。接手涉及端侧 AI 的工作的 agent 应当重新核对下列来源，更新任何变化——版本、上限、语言列表、设备列表、方法签名——并**在同一次提交中把英文版与中文版顶部的「最后核实」日期一并改掉**，即使别的什么都不需要改。没有被推进的日期比没有日期更糟，因为它让过时的事实看起来像被核实过。

来源，按值得阅读的顺序：

- 总览与 API 列表 —— <https://developers.google.com/ml-kit/genai>
- Prompt API 及其入门指南 —— <https://developers.google.com/ml-kit/genai/prompt/android>
- 校对 —— <https://developers.google.com/ml-kit/genai/proofreading/android>
- 改写 —— <https://developers.google.com/ml-kit/genai/rewriting/android>
- Android 上的 Gemini Nano —— <https://developer.android.com/ai/gemini-nano>

当签名很重要时，**不要只信文档**：从 `https://dl.google.com/dl/android/maven2/com/google/mlkit/<artifact>/<version>/<artifact>-<version>.aar` 下载 AAR，解压 `classes.jar`，对 `com/google/mlkit/` 下的类运行 `javap -public`。参考站点并不总能提供类页面，而 AAR 不可能和自己不一致。
