# 平台注意事项

Android 是第一阶段唯一发布的平台。代码是平台中立的；其他目标在末尾列出，并说明添加每一个需要做什么。

## Android

- 包 `com.yuanzhe.my_nihongo`，启动器标签 `MyNihongo!!!!!`，`MainActivity` 是普通的 `FlutterActivity`。
- **Gradle/AGP 状态镜像自 MyAnime!!!!! 已验证的配置**而不是 `flutter create` 模板，因此本系列共享的插件家族确知可以构建：Gradle wrapper `9.3.1`、AGP `9.1.1`、在 `settings.gradle.kts` 中声明（`apply false`）的 Kotlin `2.2.20`，应用本身不再应用 `kotlin-android`，Java 17 加核心库脱糖，以及一个顶层 `kotlin { compilerOptions { jvmTarget = JvmTarget.JVM_17 } }` 块——刻意**不**用 `jvmToolchain`（需要真实安装 JDK 17），也**不**用 `kotlinOptions`（已移除）。`android/gradle.properties` 保留 Flutter 迁移器的兼容标志 `android.builtInKotlin=false` 和 `android.newDsl=false`，因为若干插件仍直接应用 Kotlin Gradle Plugin；`builtInKotlin=true` 会让它们每一个都失败。
- **添加 `file_picker` 时（M1.1），精确固定到 `10.3.7`**（不是脱字号约束）：它是最后一个既自己应用 KGP（`builtInKotlin=false` 期间必需）又针对 `flutter.compileSdkVersion` 编译（AGP 9 的 AAR 元数据检查必需）的版本。`10.3.9+` 和 `11.x` 依赖 AGP 内置 Kotlin，在兼容模式下失败；`10.3.2` 及更早固定 `compileSdk 34`，通不过元数据检查。
- Keystore 属性使用可空转换（`as String?`）；签名在本地通过 `android/key.properties` 可选，在 CI 中来自 GitHub Secrets。`key.properties` 和 `*.jks` 被 git 忽略。
- **权限：** 仅 `INTERNET`（WebDAV 同步）。`RECORD_AUDIO` 随第二阶段的语音识别到来，在首次使用时附说明请求，绝不在安装时请求。
- **折叠：** activity 的 `configChanges` 包含 `screenLayout|screenSize|smallestScreenSize|density`，因此展开时窗口调整大小而不重建 activity。见 [`adaptive-layout.md`](adaptive-layout.md)。
- 允许**明文流量**（`usesCleartextTraffic="true"`），使家庭网络上走纯 HTTP 的 WebDAV 服务器可用，与兄弟应用相同。

## 计划中的平台

- **Windows：** `flutter create --platforms=windows .`，然后是本系列的 `installer.iss`（通过 `#ifdef ARM64` 支持 x64 和 ARM64）、`pubspec.yaml` 中的 `msix_config`、`windows/runner/resources/app_icon.ico`，以及 `AGENTS.md` 中列出的版本位置。ARM64 CI 任务在 stable 发布 ARM64 引擎之前运行在 Flutter master 上，与 MyAnime 的一样。
- **iOS / macOS：** `--platforms=ios,macos`；`CFBundleDisplayName` / `AppInfo.xcconfig` 名称为 `MyNihongo!!!!!`；两个 macOS entitlement 文件中都要有 `com.apple.security.network.client` 以支持 WebDAV；默认、深色和着色模式的带边距 iOS 图标源。
- **语音（第二阶段）：** `flutter_tts` 和 `speech_to_text` 包装 Android 的 `TextToSpeech` / `SpeechRecognizer` 与 Apple 的 `AVSpeechSynthesizer` / `SFSpeechRecognizer`；Windows 通过同一插件有 TTS，但没有内置识别器，因此在选定方案之前，发音反馈仍是移动端功能。
- **Web** 不是目标。
