# CI/CD 与构建命令

## 工作流

`.github/workflows/build.yml` 在每次推送到 `main`、`v*` 标签推送、面向 `main` 的 pull request 以及 `workflow_dispatch` 时运行。只有标签推送会创建 GitHub Release；分支推送止于上传的工件。

检出步骤传 `submodules: recursive`。没有它，`flutter pub get` 会因缺失的 `packages/myapps_data` 路径依赖而失败。相对子模块 URL 在 CI 中解析到公共 GitHub 副本，因此默认的 `GITHUB_TOKEN` 就足够了。

## 任务

- `android` — `flutter pub get`、`flutter gen-l10n`、`flutter analyze`、`flutter test`，然后是 APK（full 风味）和 AAB（store 风味）。仅当 `KEYSTORE_BASE64` secret 存在时配置签名。
- `release` — 标签推送时下载工件，并创建带生成说明的 GitHub Release。

桌面、iOS 和 macOS 任务随其平台添加（`PLAN.md`，第五阶段），从 MyAnime 的工作流复制。

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

尚无。`PLAN.md` M1.2 添加 `tool/import_vocab.dart`，即重新生成单词资源的离线 JMdict + JLPT 列表导入；与兄弟应用的生成器一样，它将是确定性的，因此输入不变时重跑不产生差异。
