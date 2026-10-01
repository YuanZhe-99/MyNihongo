# lib/app/app.dart

`MyNihongoApp` 是根组件（widget）：一个接到 `appRouter`、亮色与暗色 `AppTheme`（仅在 Android 上用平台动态方案构建，由 `DynamicColorBuilder` 包裹，并使用 `appSettingsProvider` 中的界面风格）、来自 `appSettingsProvider` 的主题模式与语言、生成的 `AppLocalizations` delegate，以及 `DevicePreview.appBuilder` 的 `MaterialApp.router`。它**不**设置 `scrollBehavior`：SDK 的默认行为在桌面上已经能用鼠标滚轮滚动并绘制滚动条，在 Android 上也让手写笔和无障碍拖动继续可用。曾有一个自定义行为把拖动设备替换为触摸、鼠标和触控板，它在 0.5.1 中被移除，因为它恰恰丢掉了这些设备；见 [../../platform-notes.md](../../platform-notes.md)。见 [../../architecture.md](../../architecture.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `MyNihongoApp.new` | 构造函数（`MyNihongoApp`） | B | 创建根应用组件。 |
| `MyNihongoApp.build` | 方法（`ConsumerWidget` build） | B | 用设置 provider 中的主题、语言和路由构建 `MaterialApp.router`。 |

动态取色仅限 Android（`!kIsWeb && defaultTargetPlatform == TargetPlatform.android`）：桌面端插件会返回系统强调色，会盖掉应用自己的种子色。
$1 [locale_resolution.md](locale_resolution.md) 中的 `resolveAppLocale`，它决定一台没有被指定语言的设备使用两种中文中的哪一种。
