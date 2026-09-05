# lib/shared/providers/app_settings.dart

作为 Riverpod 状态的设备本地 UI 偏好：`AppSettings`（主题模式、语言）和 `AppSettingsNotifier`，一个在构造时通过 `NihongoStorage` 从 `storage_config.json` 加载两者、并持久化每次变更的 `StateNotifier`。`appSettingsProvider` 暴露它；`MyNihongoApp` 监视它。这里没有任何东西被同步。见 [../../../data-formats.md](../../../data-formats.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `AppSettingsNotifier.new` | 构造函数 | B | 创建 notifier 并开始加载持久化的设置。 |
| `AppSettingsNotifier._loadPersisted` | 方法 | B | 从磁盘加载持久化的主题模式和语言并替换状态。 |
| `AppSettingsNotifier.setThemeMode` | 方法 | B | 更新并持久化主题模式；`system` 存为缺失的键。 |
| `AppSettingsNotifier.setLocale` | 方法 | B | 以 `language` 或 `language_COUNTRY` 更新并持久化语言；null 跟随系统。承载 `zh_TW` 的正是国家代码。 |
| `AppSettingsNotifier.setAiAssistEnabled` | 方法 | B | 打开或关闭端侧 AI；应用到 `AiAssistService` 并持久化，关闭存为缺失键。 |
| `AppSettingsNotifier.setPreferFastModel` | 方法 | B | 选择较大或较快的端侧模型；重新探测并持久化。 |
| `AppSettings.aiAssistEnabled` | 字段 | B | 用户是否打开了端侧 AI。未打开则为 false。 |
| `AppSettings.preferFastModel` | 字段 | B | 设备同时提供两种规格时，是否优先使用较快的端侧模型。 |
| `AppSettings.new` | 构造函数 | B | 创建应用设置实例。 |
| `AppSettings.copyWith` | 方法 | B | 创建替换了选定字段的副本；`clearLocale` 存在是因为 null 已经表示「保留」。 |

`appSettingsProvider` 是没有文档注释的顶层 `final StateNotifierProvider`；不计入。

## 参考页面偏好（`PLAN.md` M1.3）

`AppSettings` 还承载 `vocabLevel`、`grammarLevel`、`kanaScript` 与 `referenceListColumns`，notifier 上
对应 `setVocabLevel`、`setGrammarLevel`、`setKanaScript` 与 `setReferenceListColumns`。它们集中在一个对象里，
使页面能从 provider 同步读取，而不必各自发起异步读取并与自己的首帧竞争——在首次加载完成之前点选的筛选不会被它
覆盖。见 [`../../../features/reference-preferences.md`](../../../features/reference-preferences.md)。
