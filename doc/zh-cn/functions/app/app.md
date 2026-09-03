# lib/app/app.dart

`MyNihongoApp` 是根组件（widget）：一个接到 `appRouter`、亮色与暗色 `AppTheme`、来自 `appSettingsProvider` 的主题模式与语言、生成的 `AppLocalizations` delegate，以及 `DevicePreview.appBuilder` 的 `MaterialApp.router`。私有的 `_DesktopScrollBehavior` 让鼠标滚轮和触控板可以拖动可滚动组件，为计划中的桌面目标准备。见 [../../architecture.md](../../architecture.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `_DesktopScrollBehavior.dragDevices` | getter 覆写 | B | 报告哪些指针类型可以拖动可滚动组件：触摸、鼠标、触控板。 |
| `MyNihongoApp.new` | 构造函数（`MyNihongoApp`） | B | 创建根应用组件。 |
| `MyNihongoApp.build` | 方法（`ConsumerWidget` build） | B | 用设置 provider 中的主题、语言和路由构建 `MaterialApp.router`。 |

`localeListResolutionCallback` 是 [locale_resolution.md](locale_resolution.md) 中的 `resolveAppLocale`，它决定一台没有被指定语言的设备使用两种中文中的哪一种。
