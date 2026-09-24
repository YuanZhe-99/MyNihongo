# CI/CD 与构建命令

## 工作流

`.github/workflows/build.yml` 在每次推送到 `main`、`v*` 标签推送、面向 `main` 的 pull request 以及 `workflow_dispatch` 时运行。只有标签推送会创建 GitHub Release；分支推送止于上传的工件。

**什么时候运行什么。** `android` 任务在每种触发下都运行，因为 analyze 和 test 都在它里面。四个桌面与 Apple 任务带有 `if: startsWith(github.ref, 'refs/tags/') || github.event_name == 'workflow_dispatch'`，因此普通推送或 pull request 只占用一个 runner 而不是五个；发布标签或一次有意的 `workflow_dispatch`（手动触发）才会构建全部。兄弟应用只在标签时构建；本应用保留每次推送的 Android 任务，因为它的内容文件是一次错误编辑就可能静默破坏的数据。

检出步骤传 `submodules: recursive`。没有它，`flutter pub get` 会因缺失的 `packages/myapps_data` 路径依赖而失败。相对子模块 URL 在 CI 中解析到公共 GitHub 副本，因此默认的 `GITHUB_TOKEN` 就足够了。

## 任务

| 任务 | Runner | 运行时机 | 产出 |
|---|---|---|---|
| `android` | `ubuntu-latest` | 每种触发 | `flutter gen-l10n` 与已提交本地化文件检查、`flutter analyze`、`flutter test`，然后是 APK（full）和 AAB（store） |
| `windows-x64` | `windows-latest` | 标签、手动触发 | `MyNihongo_X.Y.Z_Setup.exe`（Inno Setup） |
| `windows-arm64` | `windows-11-arm` | 标签、手动触发 | `MyNihongo_X.Y.Z_arm64_Setup.exe`（Inno Setup） |
| `ios` | `macos-latest` | 标签、手动触发 | `MyNihongo_sideload.ipa`，以 `--no-codesign` 构建 |
| `macos` | `macos-latest` | 标签、手动触发 | `MyNihongo.dmg` |
| `release` | `ubuntu-latest` | 仅标签 | 一个 GitHub Release，附上面六个文件和生成的说明 |

仅当 `KEYSTORE_BASE64` secret 存在时配置 Android 签名。**所有桌面与 Apple 产物都未签名、未公证**——用户打开它们时会看到什么，见 [`platform-notes.md`](platform-notes.md)。

**没有 MSIX 任务。** 兄弟应用都没有这个任务，而打包 Store MSIX 需要一张本仓库没有的签名证书（`msix_config` 中的 `install_certificate: false` 表示不使用证书）。`dart run msix:create` 仍是手动命令。

**Windows ARM64 任务在 stable 标签处克隆 Flutter**，而不用 `subosito/flutter-action`。Flutter 不发布 Windows ARM64 SDK 归档：发布清单 `releases_windows.json` 中没有 `dart_sdk_arch: arm64` 的行（2026-09-06 核对），而该 action 的 `architecture` 输入默认取 runner 的架构，因此在 `windows-11-arm` 上它会以 "Unable to determine Flutter version … architecture: arm64" 中止。强制 `architecture: x64` 比中止更糟。x64 归档自带填充好的 `bin/cache`，因此 Dart SDK 永远不会被替换，而 `flutter build windows` 的目标架构取自 Dart VM 自身的 ABI——构建产物落在 `build/windows/x64/`，`iscc /DARM64` 找不到它。克隆没有缓存，所以它的第一条 `flutter` 命令会运行 `bin/internal/update_dart_sdk.ps1`；在 ARM64 主机上该脚本会获取 ARM64 Dart SDK，因为按脚本自己的说法，Flutter Windows 构建取决于 Dart 可执行文件的架构。同一个脚本也为本工程的 ARM64 开发机获取了同一引擎修订版的 ARM64 Dart SDK，这就是该归档存在的主机端证据。在标签处 `--depth 1` 是安全的，因为 `bin/internal/engine.version` 在那里是受跟踪的文件。标签克隆是分离的 HEAD，因此 `flutter doctor` 把渠道报告为 `[user-branch]` 而不是 `stable`。一个守卫步骤会在构建仍落在 `x64/` 时让任务失败，模拟的 x64 shell 就会造成这种情况。不使用 `actions/cache`：MyAnime 每周缓存它的 master 克隆，是为了让引擎 DLL 的哈希保持稳定以维持 Defender 的信誉，而标签本身已经不可变。

**两个 Windows 任务都会在构建前确保 `nuget` 存在**，因为 `flutter_tts` 的 Windows CMake 会调用它，而兄弟应用都没有这个插件。两者都设置 `CL: /D_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS`，因为 `windows/CMakeLists.txt` 以 `/WX` 构建，而 `flutter_local_notifications_windows` 仍会用到已弃用的 `<experimental/coroutine>` 头文件。两个 runner 都有 JDK，因此 `jni` 包的 Windows 分支会构建出一个无用的 `dartjni.dll` 放进安装包（由 `path_provider_android` 引入；Windows 上没有任何东西加载它）。本工程的开发机没有 JDK，从不构建它。

**iOS 任务是本系列中第一次 `pod install`。** `flutter_tts`（iOS 与 macOS）和 `local_notifier`（macOS）只提供 podspec，因此两个 Apple 构建都混用 Swift Package Manager 与 CocoaPods；Podfile 由工具生成。macOS 上的这种混用，每个兄弟应用的 `macos` 任务早已在跑。没有哪个兄弟应用的 iOS 插件集需要 CocoaPods，所以 Flutter 升级后若 iOS 失败，最可能出在这里。

**没有任务重复运行 `flutter gen-l10n`。** 每次 `flutter build` 在编译前都会从 ARB 文件重新生成 `lib/l10n/app_localizations*.dart`（`GenerateLocalizationsTarget` 是 kernel 快照的依赖），由 `l10n.yaml` 触发，并要求 `pubspec.yaml` 中有 `generate: true`。`android` 任务里显式的 `gen-l10n` 是为了它的检查：**已提交的生成文件必须与 ARB 文件一致**，用 `git status --porcelain -- lib/l10n` 检测。不用 `git diff`：要紧的情形是新语言区域的生成文件从未被添加，而 `git diff` 不会列出它。那样在这里能通过 analyze 和 test，却会让全新克隆的 `flutter test` 因缺失的 import 而失败。

**Apple 工程由 CI 编译，从未运行过。** 本工程能用到的 Mac 都无法构建它，因此对 iOS 和 macOS 而言，CI 编译就是上限；见 [`platform-notes.md`](platform-notes.md)。

**CI 中没有任何环节触及 AICore。** 端侧 AI 只在真实且受支持的手机上运行，所以 CI 验证的是它下面那一层：策略、提示词与解析，全部对着假实现。模型本身在设备上人工核对——见 [`android-aicore.md`](android-aicore.md)。

## 工作流注意事项

- 让工作流 Flutter 版本（`3.44.2`）与 `pubspec.yaml` 中的 Dart SDK 约束保持一致。Windows ARM64 任务克隆同名标签，因此一次升级就能让全部五个构建任务一起前进。
- GitHub `secrets` 不能直接在步骤的 `if` 表达式中使用；它们通过任务级的 `HAS_KEYSTORE` env 路由。
- Action 版本：`actions/checkout@v7`、`actions/setup-java@v5`、`actions/upload-artifact@v7`、`actions/download-artifact@v8`、`softprops/action-gh-release@v3`。
- **在下一个标签之前用一次 `workflow_dispatch` 运行验证工作流变更。** 手动触发会运行五个构建任务；`release` 在有标签之前会被跳过，因此它的产物过滤器第一次被执行就是在标签运行本身，而已推送的标签无法再推送一次。
- analyze 和 test 步骤刻意在 CI 中运行：兄弟应用只在本地运行它们，但本应用的内容文件是一次错误编辑就可能静默破坏的数据，而 `test/content_catalog_test.dart` 是守卫。
- `test/release_versions_test.dart` 在五个版本字段不一致时失败。发布流程推送标签时不等待 CI，因此要在打标签前在本地运行它；CI 是最后一道防线。

## 命令

```powershell
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter test test/content_catalog_test.dart
flutter build apk --release --dart-define=FLAVOR=full
flutter build appbundle --release --dart-define=FLAVOR=store
```

桌面构建也在本地运行。**一台 Windows 主机只构建它自己的架构**，原因见上面 ARM64 任务的说明：本工程的 ARM64 开发机产出 `build/windows/arm64/` 和 ARM64 安装包，x64 安装包来自 CI。

```powershell
$env:CL = "/D_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS"   # MSVC 14.51+，与 CI 相同
flutter build windows --release --dart-define=FLAVOR=full   # 需要 PATH 中有 nuget.exe
iscc installer.iss          # x64 安装包（x64 主机），需要 Inno Setup
iscc /DARM64 installer.iss  # ARM64 安装包（ARM64 主机）
dart run msix:create        # MSIX 包，仅手动
flutter build macos --release --dart-define=FLAVOR=full   # 需要一台 Mac
```

在连接的 Android 手机上，用于任何必须看到或听到的东西——语音链路与端侧 AI。`adb` 默认不在 `PATH` 上，它位于 Android SDK 的 `platform-tools`。`scrcpy` 用于投屏，在没有音频设备的主机上需要加 `--no-audio`：

```powershell
flutter devices
flutter run --release -d <device-id> --dart-define=FLAVOR=full
scrcpy --no-audio
adb logcat | Select-String -Pattern "AICore|my_nihongo"
```

用最窄的相关命令集做校验。模型或同步变更包含 `flutter test test/progress_json_test.dart test/data_modules_test.dart`；内容变更用 `flutter test test/content_catalog_test.dart`；布局变更用三个 UI 测试。

`flutter analyze` 在干净的树上报告零问题。保持这样——新的 info 级条目在这里是回归，不是既有噪声。

## 全新克隆

共享引擎包是 git 子模块，因此普通的 `git clone` 会让 `packages/myapps_data` 为空，`flutter pub get` 失败：

```bash
git clone --recurse-submodules <app-url>
# or, after a plain clone:
git submodule update --init
```

## `tool/` 脚本

`tool/generate_ios_icons.dart` 把应用图稿缩放为 iOS 图标源文件（见 `platform-notes.md`）。

`tool/import_vocab.dart` 从 JMdict 与 JLPT 词表重新生成 `assets/content/vocab.json`。它离线运行且具有确定性：输入不变时重跑会留下空的 `git diff`，正是这一性质让重跑变得值得。它需要把 JMdict 本体解包到已 git 忽略的 `tool/data/`；文件缺失时会打印下载地址并以退出码 1 结束。

```bash
dart run tool/import_vocab.dart
dart run tool/import_vocab.dart --overlay-only
```

两个脚本都不在 CI 中运行。它们写出的都是会被提交的文件，CI 至多只能确认提交的 diff 已经显示的内容。

## 黄金记录（golden transcripts）

`test/golden/webdav_golden_test.dart` 让真实的同步、备份与 ZIP 引擎对内存中的 WebDAV 服务器运行，并把记录下的
请求序列与 `test/golden/goldens/mynihongo/` 下的文件比对。`flutter test` 会像验证其他测试一样验证它们，CI 中
不需要额外步骤。协议有意变更后再有意重新录制，然后阅读差异：

```bash
flutter test --dart-define=GOLDEN_RECORD=true test/golden/webdav_golden_test.dart
```

该 define 必须字面为 `true`；`bool.fromEnvironment` 把 `1` 读作 false，运行会静默停留在验证模式。
`test/golden/fake_webdav_server.dart` 与 `request_recorder.dart` 是共享包测试装置的副本 —— 请在那里修复再复制
回来，绝不要在此处编辑。记录按字节比对，因此根目录的 `.gitattributes` 把它们固定为 LF。
