# CI/CD 与构建命令

## 工作流

`.github/workflows/build.yml` 在每次推送到 `main`、`v*` 标签推送、面向 `main` 的 pull request 以及 `workflow_dispatch` 时运行。只有标签推送会创建 GitHub Release；分支推送止于上传的工件。

检出步骤传 `submodules: recursive`。没有它，`flutter pub get` 会因缺失的 `packages/myapps_data` 路径依赖而失败。相对子模块 URL 在 CI 中解析到公共 GitHub 副本，因此默认的 `GITHUB_TOKEN` 就足够了。

## 任务

- `android` — `flutter pub get`、`flutter gen-l10n`、`flutter analyze`、`flutter test`，然后是 APK（full 风味）和 AAB（store 风味）。仅当 `KEYSTORE_BASE64` secret 存在时配置签名。
- `release` — 标签推送时下载工件，并创建带生成说明的 GitHub Release。

**CI 刻意只跑 Android。** Windows 和 macOS 工程用于本地开发与测试（见 [`platform-notes.md`](platform-notes.md)）；为它们添加任务，以及 MSIX 与 Inno Setup 发布产物，属于第五阶段的工作，从 MyAnime 的工作流复制。

## 工作流注意事项

- 让工作流 Flutter 版本（`3.44.2`）与 `pubspec.yaml` 中的 Dart SDK 约束保持一致。
- GitHub `secrets` 不能直接在步骤的 `if` 表达式中使用；它们通过任务级的 `HAS_KEYSTORE` env 路由。
- Action 版本：`actions/checkout@v7`、`actions/setup-java@v5`、`actions/upload-artifact@v7`、`actions/download-artifact@v8`、`softprops/action-gh-release@v3`。在下次标签发布前用一次 `workflow_dispatch` 运行验证工作流变更。
- analyze 和 test 步骤刻意在 CI 中运行：兄弟应用只在本地运行它们，但本应用的内容文件是一次错误编辑就可能静默破坏的数据，而 `test/content_catalog_test.dart` 是守卫。

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

桌面构建仅在本地进行，以下命令都不在 CI 中运行：

```powershell
flutter build windows --release --dart-define=FLAVOR=full   # 需要 PATH 中有 nuget.exe
iscc installer.iss          # x64 安装包，需要 PATH 中有 Inno Setup
iscc /DARM64 installer.iss  # ARM64 安装包
dart run msix:create        # MSIX 包
flutter build macos --release --dart-define=FLAVOR=full   # 需要一台 Mac
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
