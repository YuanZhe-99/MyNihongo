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
- **端侧 AI 依赖：** `com.google.mlkit:genai-prompt:1.0.0-beta4`、`com.google.mlkit:genai-proofreading:1.0.0-beta1` 与 `org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2`，全部精确锁定，因为 ML Kit GenAI API 处于 beta 且没有弃用政策。`genai-prompt` 这个锁定是应用*能问出什么*的下限——即指名一个模型变体——它不代表任何设备会怎么回答；那是运行时探测出来的。见 [`android-aicore.md`](android-aicore.md)。
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
- `ios/` 文件夹带有图标集和 `CFBundleDisplayName` `MyNihongo!!!!!`；见下文 *iOS*。

## Windows

Windows 在发布标签和手动触发时由 CI 构建——一个 x64 安装包和一个 ARM64 安装包（见 [`ci-cd.md`](ci-cd.md)）——同时也是本工程的本地开发与测试目标。

- `windows/` 由 `flutter create --platforms=windows,macos .` 生成；`CMakeLists.txt`（`BINARY_NAME my_nihongo`）与 `Runner.rc` 从模板出来就带有组织名和工程名，只有 `runner/main.cpp` 被修改。
- **单实例：** `main.cpp` 取用命名互斥体 `MyNihongo_SingleInstance_A1B2C3D4`；再次启动会恢复并聚焦已有窗口，而不是打开第二个。查找时同时传入 runner 的窗口类（`FLUTTER_RUNNER_WIN32_WINDOW`）和标题，因此不会匹配到无关窗口。
- **初始窗口 1000×720**，而非同系列应用的手机形状 400×860：在该宽度下参考列表和设置页已是双列，这正是桌面端值得查看的布局。见 [`adaptive-layout.md`](adaptive-layout.md)。
- **图标：** `windows/runner/resources/app_icon.ico`，由 `flutter_launcher_icons` 以 `icon_size: 256` 从与其他平台相同的 `assets/icon/app_icon.png` 生成。
- **安装包：** 仓库根目录的 `installer.iss`，用 Inno Setup 构建。一份脚本生成两种架构——x64 用 `iscc installer.iss`，ARM64 用 `iscc /DARM64 installer.iss`——输出到 `build/installer/`。它没有 `[Registry]` 段：本应用不声明任何文件类型。它的三个版本字段随 `pubspec.yaml` 变动，不一致时 `test/release_versions_test.dart` 会失败。
- **MSIX：** `pubspec.yaml` 中的 `msix_config` 是为了与同系列应用的版本位置保持一致。没有工作流构建 MSIX；`dart run msix:create` 是手动步骤。
- **ARM64：** stable 3.44.2 能构建 `windows-arm64`，因此没有任务使用 Flutter master。目标架构取决于 Dart SDK 自身的架构，而不是某个标志：ARM64 主机构建出 `build/windows/arm64/`，也只产出 ARM64 安装包。CI 通过在 ARM64 runner 上于 stable 标签处克隆 Flutter 来获得 ARM64 Dart SDK；原因见 `ci-cd.md`。
- **未签名。** 安装包没有代码签名。首次运行时 Windows SmartScreen 会显示「Windows 已保护你的电脑」；点*更多信息 → 仍要运行*即可安装。每个兄弟应用的安装包都是如此。

### 输入

- **测验可以用键盘作答。** 数字选择，Enter 检查并继续，Backspace 取回一个片段，`R` 重播，`S` 跳过一道生成的题目；完整的表格和规则在 [`features/quizzes.md`](features/quizzes.md#from-a-keyboard)。在桌面上，选项带着各自的数字，检查按钮下方有一行文字列出按键（`showsKeyboardHints`）。
- **滚动使用 SDK 的默认行为。** `MaterialScrollBehavior` 在 Windows、macOS 和 Linux 上给每个纵向可滚动组件包上滚动条，鼠标滚轮无需改动拖动设备就能滚动。应用以前安装过一个从 MyAnime 复制来的自定义行为，把拖动设备替换为触摸、鼠标和触控板。它没有为桌面增加任何必需的东西，反而让滚动视图内的文本选择变得别扭；在 Android 上，它还悄悄丢掉了手写笔拖动，以及 Voice Access 所用的 `unknown` 设备。它在 0.5.1 中被移除。MyAnime 里仍有同一个类。
- **一个已知缺口：** PageUp、PageDown 和方向键只有在参考列表内部某个东西取得焦点之后才能滚动它。桌面上没有列表挂到主滚动控制器上，所以这些按键从外部无处可达。

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

使用 Visual Studio 18（MSVC 14.51 及以上）时，构建还需要环境中有 `CL=/D_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS`：`flutter_local_notifications_windows` 仍然包含已弃用的 `<experimental/coroutine>` 头文件，而该编译器会把它变成错误。CI 设置了同一个变量。

## macOS

- `macos/` **由 CI 编译，从未运行过**：本工程能用到的 Mac 都无法构建它。下文关于 Mac 上运行时行为的每一句，都是从插件与 Apple 的资料中读出来的，而非观察所得。DMG 未签名、未公证：首次打开时 Gatekeeper 会拒绝它，用户需在「系统设置 → 隐私与安全性 → *仍要打开*」中放行。
- `Runner/Configs/AppInfo.xcconfig`：`PRODUCT_NAME = MyNihongo!!!!!`，`PRODUCT_BUNDLE_IDENTIFIER = com.yuanzhe.myNihongo`（与 iOS 相同的标识符）。
- `MACOSX_DEPLOYMENT_TARGET = 13.0`，与同系列应用一致。
- 图标由 `flutter_launcher_icons` 生成到 `Runner/Assets.xcassets/AppIcon.appiconset`。

权利（entitlement）及各自的理由。`Release.entitlements` 与 `DebugProfile.entitlements` 带有同一组权利，只是 debug 文件保留了模板中的 `cs.allow-jit` 和 `network.server`，调试器的 VM service 需要它们。

| 权利 | 理由 |
|---|---|
| `app-sandbox` | 模板默认值；每个兄弟应用都以沙盒方式发布 |
| `network.client` | WebDAV 同步。若 `Release` 中缺失，同步只在 release 构建中失败 |
| `device.audio-input` | 麦克风，用于发音练习 |
| `files.user-selected.read-write` | ZIP 导出与导入的文件选择器。缺少它时 `file_picker` 10.3.7 返回 `ENTITLEMENT_NOT_FOUND`，Dart 侧收到 `null`，设置中的这两行静默地什么也不做 |

**`Release` 中刻意没有 `network.server`。** 兄弟应用的本地 API 服务器需要它；本应用不监听任何东西。

`Info.plist` 带有 `NSMicrophoneUsageDescription`、`NSSpeechRecognitionUsageDescription` 和 `NSLocalNetworkUsageDescription`。最后一项用于向本地网络上的服务器进行 WebDAV 同步；见下文 *Apple 网络访问*。

macOS 上的提醒走 `local_notifier`，与 Windows 同一条路径：`platformSchedulesReminders` 只对移动端为真，因此在 Mac 上永远不会走到 `flutter_local_notifications` 的 Darwin 分支。见 [`features/reminders.md`](features/reminders.md)。

## iOS

- `ios/` **由 CI 以 `--no-codesign` 编译，从未运行过**，原因与 macOS 相同。`IPHONEOS_DEPLOYMENT_TARGET = 13.0`。
- `Info.plist` 中的 `CFBundleDisplayName` 为 `MyNihongo!!!!!`；图标见上文*应用图标*。
- `Info.plist` 带有 `NSMicrophoneUsageDescription`、`NSSpeechRecognitionUsageDescription` 和 `NSLocalNetworkUsageDescription`，文字与 macOS 相同。
- `AppDelegate.swift` 把通知中心的委托设为应用委托，也就是 MyDay 已发布的那一行。让提醒生效的并不是它——排程与投递都不需要委托，插件和引擎也都不设置委托。它只让提醒横幅在应用处于前台时也能出现。`FlutterAppDelegate` 本就遵循 `UNUserNotificationCenterDelegate`。
- **IPA 是侧载构建**：未签名，因此只能通过侧载工具安装，由该工具用用户自己的 Apple ID 重新签名。App Store 构建需要签名与描述文件（provisioning），CI 不做这些。
- 当设备上没有日语端侧模型时，Apple 上的语音识别可能拒绝只用离线的请求；见 [`features/pronunciation.md`](features/pronunciation.md)。

### Apple 网络访问

- **App Transport Security 不适用于本应用的同步**，因此 `Info.plist` 没有 `NSAppTransportSecurity` 块。ATS 管辖的是 Apple 的 URL Loading System。这里的 WebDAV 流量走 `package:http` → `IOClient` → `dart:io` 套接字，而 Dart 自己那套由 plist 驱动的网络策略已在 Flutter 2.2 中被撤回；本仓库的 Dart SDK 没有不安全连接检查。iOS 引擎仍会解析 `NSAppTransportSecurity` 块，但没有任何东西执行解析结果，所以加一个键看上去像策略，实际什么也不做。因此 `http://` 的 WebDAV 服务器不会被阻止；如果将来要拒绝对公网主机的明文 HTTP，那应当是 WebDAV 页面里的校验。
- **本地网络隐私确实适用。** 根据 Apple 的文档（TN3179），它也涵盖 BSD 套接字——iOS 14 及以上、macOS 15 及以上——并且对本地地址走 HTTPS 与走 HTTP 同样会触发。第一次连接局域网服务器会显示系统提示；`dart:io` 无法等待用户作答，因此第一次同步可能失败，在允许访问后重试即可成功。这出自 Apple 的文档，本工程尚未在设备上观察到。

## 分发：Android 以外一律未签名

发布附带的每个桌面与 Apple 产物都**未签名、未公证**。用户会看到的是：Windows SmartScreen 的「Windows 已保护你的电脑」（*更多信息 → 仍要运行*）、macOS Gatekeeper 的拒绝（在「隐私与安全性」中*仍要打开*），以及一个只能用侧载工具安装的 IPA。签名需要本工程没有的证书；兄弟应用也是这样发布的。

## Dart 中的平台分支

`lib/shared/utils/platform_capabilities.dart` 是 `lib/` 中**唯一**按平台分支的文件。它读取 `defaultTargetPlatform` 而非 `dart:io` 的 `Platform`，因此每个分支都能通过 `debugDefaultTargetPlatformOverride` 在 widget 测试中触达——这对唯一开发主机是 Windows 的工程尤其重要。

| Getter | 为真的条件 | 用途 |
|---|---|---|
| `isMobilePlatform` | Android、iOS | 下面各项的平台族判断 |
| `isDesktopPlatform` | Windows、macOS、Linux、Fuchsia | — |
| `showsStorageLocation` | 非移动端 | 设置 → 数据在手机上隐藏存储路径：那里的路径指向用户既无法浏览也无法处置的沙盒。自定义存储路径本身在所有平台仍然有效，隐藏的只是显示 |
| `canOpenSystemSpeechSettings` | Android、Windows | 把"安装日语语音"作为一个动作而非一句说明提供 |
| `platformMayRecognizeSpeech` | 非 Linux、非 Fuchsia | 粗粒度判断；识别器是否真的存在是运行时问题 |
| `platformMayHaveOnDeviceModel` | Android | AICore 只存在于 Android；其他平台的设置页省略「端侧 AI」整节，分析器也不挂接增强器。某台 Android 设备究竟能否提供模型，是运行时问题 |
| `platformSchedulesReminders` | Android、iOS | 提醒走 `flutter_local_notifications`，由操作系统排程 |
| `platformRemindsFromInsideTheApp` | Windows、macOS、Linux | 提醒在应用运行期间由定时器经 `local_notifier` 发出 |

`test/platform_capabilities_test.dart` 在每个 `TargetPlatform` 上固定每个 getter 的结果，因此改动此表的一个单元格，在那里也只是一行改动。

## 其他平台

- **Web** 不是目标。
