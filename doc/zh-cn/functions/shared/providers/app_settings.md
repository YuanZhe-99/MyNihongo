# lib/shared/providers/app_settings.dart

作为 Riverpod 状态的设备本地 UI 偏好：`AppSettings`（主题模式、语言）和 `AppSettingsNotifier`，一个在构造时通过 `NihongoStorage` 从 `storage_config.json` 加载两者、并持久化每次变更的 `StateNotifier`。`appSettingsProvider` 暴露它；`MyNihongoApp` 监视它。这里没有任何东西被同步。见 [../../../data-formats.md](../../../data-formats.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `AppSettingsNotifier.new` | 构造函数 | B | 创建 notifier 并开始加载持久化的设置。 |
| `AppSettingsNotifier._loadPersisted` | 方法 | B | 从磁盘加载持久化的主题模式和语言并替换状态。 |
| `AppSettingsNotifier.setThemeMode` | 方法 | B | 更新并持久化主题模式；`system` 存为缺失的键。 |
| `AppSettingsNotifier.setLocale` | 方法 | B | 以 `language` 或 `language_COUNTRY` 更新并持久化语言；null 跟随系统。 |
| `AppSettings.new` | 构造函数 | B | 创建应用设置实例。 |
| `AppSettings.copyWith` | 方法 | B | 创建替换了选定字段的副本；`clearLocale` 存在是因为 null 已经表示「保留」。 |

`appSettingsProvider` 是没有文档注释的顶层 `final StateNotifierProvider`；不计入。
