# 平台注意事项

Android 是第一阶段唯一发布的平台。代码是平台中立的；其他目标在末尾列出，并说明添加每一个需要做什么。

## Android

- 包 `com.yuanzhe.my_nihongo`，启动器标签 `MyNihongo!!!!!`，`MainActivity` 是普通的 `FlutterActivity`。
- **Gradle/AGP 状态镜像自 MyAnime!!!!! 已验证的配置**而不是 `flutter create` 模板，因此本系列共享的插件家族确知可以构建：Gradle wrapper `9.3.1`、AGP `9.1.1`、在 `settings.gradle.kts` 中声明（`apply false`）的 Kotlin `2.2.20`，应用本身不再应用 `kotlin-android`，Java 17 加核心库脱糖，以及一个顶层 `kotlin { compilerOptions { jvmTarget = JvmTarget.JVM_17 } }` 块——刻意**不**用 `jvmToolchain`（需要真实安装 JDK 17），也**不**用 `kotlinOptions`（已移除）。`android/gradle.properties` 保留 Flutter 迁移器的兼容标志 `android.builtInKotlin=false` 和 `android.newDsl=false`，因为若干插件仍直接应用 Kotlin Gradle Plugin；`builtInKotlin=true` 会让它们每一个都失败。
- **`file_picker` 精确固定到 `10.3.7`**（不是脱字号约束），因为它是最后一个既自己应用 KGP（`builtInKotlin=false` 期间必需）又针对 `flutter.compileSdkVersion` 编译（AGP 9 的 AAR 元数据检查必需）的版本。`10.3.9+` 和 `11.x` 依赖 AGP 内置 Kotlin，在兼容模式下失败；`10.3.2` 及更早固定 `compileSdk 34`，通不过元数据检查。
- Keystore 属性使用可空转换（`as String?`）；签名在本地通过 `android/key.properties` 可选，在 CI 中来自 GitHub Secrets。`key.properties` 和 `*.jks` 被 git 忽略。
- **权限：** 仅 `INTERNET`（WebDAV 同步）。`RECORD_AUDIO` 随第二阶段的语音识别到来，在首次使用时附说明请求，绝不在安装时请求。端侧 AI **不需要**任何权限：其背后用到网络的是 AICore 系统服务，不是应用。
- **`minSdk` 为 26，而非 `flutter.minSdkVersion`**（24）。ML Kit GenAI 库需要 API 26，应用中别无他物需要；该值在 `android/app/build.gradle.kts` 中显式设置，理由就写在旁边。
- **两个方法通道**，都由 `MainActivity` 注册：`com.yuanzhe.my_nihongo/system`（打开系统语音设置）和 `com.yuanzhe.my_nihongo/genai`（`GenAiChannel`，通往 AICore 的桥）。两者都用自写通道而不用插件，因为各自接口面都很小，而每多一个 Flutter 插件就多一个可能应用 Kotlin Gradle 插件的插件——正是这条约束已经锁定了 `file_picker` 与 `speech_to_text`。
- **端侧 AI 依赖：** `com.google.mlkit:genai-prompt:1.0.0-beta2`、`com.google.mlkit:genai-proofreading:1.0.0-beta1` 与 `org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2`，全部精确锁定，因为 ML Kit GenAI API 处于 beta 且没有弃用政策。见 [`android-aicore.md`](android-aicore.md)。
- **`android/app/proguard-rules.pro` 只为 ML Kit GenAI 而存在。** R8 会把它压缩成一个运行时 `NullPointerException`，从应用看上去就是「本设备不支持 AI」——而且只出现在 release 构建，debug 构建会把它藏起来。规则保留 `com.google.mlkit.**` 与 `com.google.android.gms.internal.mlkit_**`；只保留 `genai` 那几个包是不够的，因为出错帧在 ML Kit 的共享 SDK 内部。在 Pixel 10 上发现，推理过程写在 `android-aicore.md`。
- **折叠：** activity 的 `configChanges` 包含 `screenLayout|screenSize|smallestScreenSize|density`，因此展开时窗口调整大小而不重建 activity。见 [`adaptive-layout.md`](adaptive-layout.md)。
- 允许**明文流量**（`usesCleartextTraffic="true"`），使家庭网络上走纯 HTTP 的 WebDAV 服务器可用，与兄弟应用相同。

## 应用图标

- 源图：`assets/icon/app_icon.png`（正方形，透明背景）。它不打包进应用；只有启动器资源会随应用发布。
- `tool/generate_ios_icons.dart` 把源图缩放到 iOS 安全区，写出三个 iOS 源：`assets/icon/app_icon_ios.png`（不透明，白色背景）、`app_icon_ios_dark.png`（透明，略微提亮）和 `app_icon_ios_tinted.png`（透明灰度），以及 `build/icon_preview/` 下的审阅预览。
- 随后 `flutter_launcher_icons.yaml` 生成 Android mipmap 和带默认、深色和着色条目的 iOS `AppIcon.appiconset`。更换源图后重新生成：

```bash
dart run tool/generate_ios_icons.dart
dart run flutter_launcher_icons
```

- 同一份源图也生成 Windows 的 `.ico` 和 macOS 的 `AppIcon.appiconset`；`flutter_launcher_icons` 配置中四个平台都已启用。
- `ios/` 文件夹的存在是为了给图标集一个位置，且 `CFBundleDisplayName` 已是 `MyNihongo!!!!!`；除此之外 iOS 仍是计划中的平台，CI 不构建它。

## Windows

Windows 是**本地开发与测试目标**：工程、安装脚本和图标都在仓库中，但没有 CI 任务构建它们（见 [`ci-cd.md`](ci-cd.md)）。

- `windows/` 由 `flutter create --platforms=windows,macos .` 生成；`CMakeLists.txt`（`BINARY_NAME my_nihongo`）与 `Runner.rc` 从模板出来就带有组织名和工程名，只有 `runner/main.cpp` 被修改。
- **单实例：** `main.cpp` 取用命名互斥体 `MyNihongo_SingleInstance_A1B2C3D4`；再次启动会恢复并聚焦已有窗口，而不是打开第二个。查找时同时传入 runner 的窗口类（`FLUTTER_RUNNER_WIN32_WINDOW`）和标题，因此不会匹配到无关窗口。
- **初始窗口 1000×720**，而非同系列应用的手机形状 400×860：在该宽度下参考列表和设置页已是双列，这正是桌面端值得查看的布局。见 [`adaptive-layout.md`](adaptive-layout.md)。
- **图标：** `windows/runner/resources/app_icon.ico`，由 `flutter_launcher_icons` 以 `icon_size: 256` 从与其他平台相同的 `assets/icon/app_icon.png` 生成。
- **安装包：** 仓库根目录的 `installer.iss`，用 Inno Setup 构建。一份脚本生成两种架构——x64 用 `iscc installer.iss`，ARM64 用 `iscc /DARM64 installer.iss`——输出到 `build/installer/`。它没有 `[Registry]` 段：本应用不声明任何文件类型。
- **MSIX：** `pubspec.yaml` 中的 `msix_config` 是为了与同系列应用的版本位置保持一致。没有工作流构建 MSIX；`dart run msix:create` 是手动步骤。
- **ARM64：** 与同系列应用不同，本工程不需要 Flutter master 任务——stable 3.44.2 已将 `windows-arm64` 列为设备，本机的 debug 与 release 构建都是 ARM64（`build/windows/arm64/`）。


## 语音插件

- **`flutter_tts: ^4.2.5`** 与 **`speech_to_text: 7.4.0`**，两者都已针对本工程的 Gradle 状态解析并构建通过。它们仍然自行应用 Kotlin Gradle 插件，而这正是 `android.builtInKotlin=false` 所需要的——与 `file_picker` 被钉版本的约束相同。Android 构建会为 `file_picker`、`flutter_tts`、`package_info_plus`、`speech_to_text` 和 `wakelock_plus` 打印 Flutter 的"插件应用了 KGP"警告；这属于插件侧，在此无法修复。
- **`flutter_tts` 会背着应用覆盖引擎语言**，在它的 Android 插件里有两处：init 回调重放被排队的方法调用，*然后*把语言设成系统默认语音的区域设置；以及服务连接断开后 `speak` 会静默重建 `TextToSpeech` 实例。两者从 Dart 侧都看不见。`TtsService` 绕开了这两处——第一次写入前先探测、每次朗读前重新应用、并显式指定语音而不只是语言。理由写在 `features/pronunciation.md`；不要在读它之前移除其中任何一条。
- **清单为 `com.google.android.aicore` 声明了 `<queries>` 条目。** 否则 Android 11+ 的软件包可见性会把它藏起来，应用就读不到已安装的 AICore 版本——而这正是区分「设备不受支持」与「服务版本过旧」的那项事实。见 `android-aicore.md`。
- **`speech_to_text` 精确钉版本。** 它的主分支已经把 `kotlin-android` 换成了 AGP 的内置 Kotlin，因此使用脱字号约束会在新版本发布的第一时间弄坏 Android 构建。
- `flutter_tts` 声明 `compileSdk 36` 和 `minSdk 24`；这里的 `flutter.compileSdkVersion` 与 `flutter.minSdkVersion` 都满足。
- **两个插件都不会注入权限。** debug 构建后的合并清单中只有 `INTERNET`，因此 `RECORD_AUDIO` 和识别器的 `<queries>` 条目要由应用自己声明。`speech_to_text` README 中列出的蓝牙权限用于耳机路由，这里刻意不声明。

### Windows 前置条件：`nuget.exe`

`flutter_tts` 的 Windows CMake 会调用 `nuget install Microsoft.Windows.CppWinRT`，缺少它时 configure 阶段会以 `nuget.exe not found` 失败。每台开发机安装一次：

```powershell
winget install --id Microsoft.NuGet --exact
```

它必须在 `flutter build windows` 之前位于 `PATH` 上。本工程其他部分都不需要它。

## macOS

- `macos/` 已生成，但**从未编译过**：开发主机是 Windows。下面的配置只经过审阅，未经验证。
- `Runner/Configs/AppInfo.xcconfig`：`PRODUCT_NAME = MyNihongo!!!!!`，`PRODUCT_BUNDLE_IDENTIFIER = com.yuanzhe.myNihongo`（与 iOS 相同的标识符）。
- `com.apple.security.network.client` 同时加入 `DebugProfile.entitlements` 和 `Release.entitlements`；若 Release 中缺失，WebDAV 同步只在 release 构建中失败。
- `MACOSX_DEPLOYMENT_TARGET = 13.0`，与同系列应用一致。
- 图标由 `flutter_launcher_icons` 生成到 `Runner/Assets.xcassets/AppIcon.appiconset`。

## Dart 中的平台分支

`lib/shared/utils/platform_capabilities.dart` 是 `lib/` 中**唯一**按平台分支的文件。它读取 `defaultTargetPlatform` 而非 `dart:io` 的 `Platform`，因此每个分支都能通过 `debugDefaultTargetPlatformOverride` 在 widget 测试中触达——这对唯一开发主机是 Windows 的工程尤其重要。

| Getter | 为真的条件 | 用途 |
|---|---|---|
| `isMobilePlatform` | Android、iOS | 下面各项的平台族判断 |
| `isDesktopPlatform` | Windows、macOS、Linux | — |
| `showsStorageLocation` | 非移动端 | 设置 → 数据在手机上隐藏存储路径：那里的路径指向用户既无法浏览也无法处置的沙盒。自定义存储路径本身在所有平台仍然有效，隐藏的只是显示 |
| `canOpenSystemSpeechSettings` | Android、Windows | 把"安装日语语音"作为一个动作而非一句说明提供 |
| `platformMayRecognizeSpeech` | 非 Linux、非 Fuchsia | 粗粒度判断；识别器是否真的存在是运行时问题 |
| `platformMayHaveOnDeviceModel` | Android | AICore 只存在于 Android；其他平台的设置页省略「端侧 AI」整节，分析器也不挂接增强器。某台 Android 设备究竟能否提供模型，是运行时问题 |

## 其他计划中的平台

- **iOS：** `ios/` 已存在（见*应用图标*），CI 不构建它。
- **Web** 不是目标。
