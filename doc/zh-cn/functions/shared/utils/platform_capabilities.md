# lib/shared/utils/platform_capabilities.dart

`lib/` 中唯一按平台分支的地方。五个顶层 getter 回答"本平台能否做 X"，且每一个都读取 `defaultTargetPlatform` 而非 `dart:io` 的 `Platform`，因此 widget 测试可以通过 `debugDefaultTargetPlatformOverride` 触达任意分支。这一点在这里很关键：本工程唯一的开发主机是 Windows，否则仅 Android 的行为将无法测试。

本模块只导入 `package:flutter/foundation.dart`。在 `lib/` 的其他任何地方添加平台分支都是 bug：给该能力命名，把 getter 放在这里，然后按名字调用——与 `adaptive_layout.dart` 对宽度比较所施加的规则相同。每个答案背后的平台事实见 [../../../platform-notes.md](../../../platform-notes.md)。

使用方：`settings_page.dart`（`showsStorageLocation`）。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `isMobilePlatform` | 顶层 getter | B | 报告应用是否运行在手机或平板上（Android 或 iOS）。 |
| `isDesktopPlatform` | 顶层 getter | B | 报告应用是否运行在桌面上（`isMobilePlatform` 的补集）。 |
| [`showsStorageLocation`](#showsstoragelocation) | 顶层 getter | A | 决定设置页是否显示存储位置一行。 |
| `canOpenSystemSpeechSettings` | 顶层 getter | B | 报告是否存在指向系统语音设置的深链接（Android、Windows）。 |
| `platformMayRecognizeSpeech` | 顶层 getter | B | 报告本平台是否可能存在语音识别。 |

## 文档

### `bool get showsStorageLocation` <a id="showsstoragelocation"></a>

- **种类：** 顶层 getter
- **用途：** 决定"设置 → 数据"是否构建存储位置一行。
- **输入：** 无；读取 `defaultTargetPlatform`。
- **返回：** Android 和 iOS 上为 `false`，其他平台为 `true`。
- **副作用：** 无。
- **算法：** `!isMobilePlatform`。
- **使用：** `settings_page.dart`——既用于该行本身，也用于 `_loadStoragePath`：当该行不会被构建时不去读盘。
- **说明：** 只有*显示*是按平台区分的。`NihongoStorage.getAppDir()` 和自定义存储路径在所有平台上行为一致；在手机上解析出的路径指向一个用户既无法浏览也无法处置的应用沙盒，显示它只是噪声。隐藏该行也移除了手机上唯一会把文件系统路径打印到屏幕上的位置。
