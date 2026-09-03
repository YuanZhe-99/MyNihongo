# Android AICore 与 ML Kit GenAI API

**最后核实：2026-09-03。** 见文末的[如何刷新本页](#如何刷新本页)——核对过资料的 agent 必须在同一次提交中更新**两种语言**版本顶部的日期，哪怕别的什么都没有改。

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
| Prompt | `com.google.mlkit:genai-prompt:1.0.0-beta2` | 自由文本或图文 → 文本 | < 4000 token |
| 摘要 | `com.google.mlkit:genai-summarization` | 文章或对话 → 要点摘要 | 见文档 |
| 校对 | `com.google.mlkit:genai-proofreading:1.0.0-beta1` | 修正短文本的语法与拼写 | < 256 token |
| 改写 | `com.google.mlkit:genai-rewriting:1.0.0-beta1` | 换一种语气或风格重述 | < 256 token |
| 图像描述 | `com.google.mlkit:genai-image-description` | 图片 → 一句描述 | — |
| 语音识别 | `com.google.mlkit:genai-speech-recognition` | 音频 → 文本；基础模式 API 31+，高级模式限 Pixel 10/11 | — |

它们都依赖 `com.google.mlkit:genai-common`（`1.0.0-beta3`），`FeatureStatus`、`DownloadCallback`、`DownloadStatus`、`StreamingCallback` 和 `GenAiException` 都在那里。

全部是 **beta**：没有 SLA，没有弃用政策。请锁定确切版本。

### 语言

校对与改写文档中列出的是**英语、日语、法语、德语、意大利语、西班牙语和韩语**。Prompt API 没有公布这样的列表——它是通用模型，对任一具体语言，务实的答案是「在设备上试，然后读输出」。Google 自己的说法是「具体的语言支持可能因设备配置而异」。

### 设备

功能类 API 列出了 Pixel 9 及更新机型，外加一批骁龙、Tensor 和天玑设备（其中包括三星 Galaxy S25）。**Prompt API 的列表更窄**，截至核实日期列的是 Pixel 10、10 Pro、10 Pro XL 和 10 Pro Fold。请把公布的设备列表当作下限，把运行时状态当作事实。

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
implementation("com.google.mlkit:genai-prompt:1.0.0-beta2")
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
