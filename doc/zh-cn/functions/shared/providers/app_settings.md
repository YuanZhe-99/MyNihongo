# lib/shared/providers/app_settings.dart

作为 Riverpod 状态的设备本地 UI 偏好：`AppSettings`（主题模式、语言）和 `AppSettingsNotifier`，一个在构造时通过 `NihongoStorage` 从 `storage_config.json` 加载两者、并持久化每次变更的 `StateNotifier`。`appSettingsProvider` 暴露它；`MyNihongoApp` 监视它。这里没有任何东西被同步。见 [../../../data-formats.md](../../../data-formats.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `AppSettingsNotifier.fixed` | 构造函数 | B | 创建持有固定设置且不做 I/O 的 notifier，供覆盖 `appSettingsProvider` 的测试使用。 |
| `AppSettingsNotifier._loadPersisted` | 方法 | B | 从磁盘加载持久化的主题模式和语言并替换状态；存储的 locale 标签用 `localeFromTag` 解析。提醒开启时，它最后会在后台重新规划提醒（`_rescheduleReminders`），因此每次启动都会重建排程；这从不请求权限。 |
| `AppSettingsNotifier._rescheduleReminders`、`_reminderL10n` | 方法 | B | 在没有 `BuildContext` 的情况下重新规划提醒：措辞取自所选语言的 `lookupAppLocalizations`，或取自用 `resolveAppLocale` 解析出的设备语言列表。失败被吞掉。 |
| `AppSettingsNotifier.setThemeMode` | 方法 | B | 更新并持久化主题模式；`system` 存为缺失的键。 |
| `AppSettingsNotifier.setUiStyle` | 方法 | B | 选择界面风格（0.6.0）；持久化，应用据此重建主题，外壳据此重建底栏。 |
| `AppSettingsNotifier.setNavPlacement` | 方法 | B | 选择导航放在哪里（0.6.1）：全部底部（默认）、宽窗口侧边或全部侧边；持久化 `navPlacement`（默认值会移除该键）。 |
| `AppSettingsNotifier.setNavRailOnRight` | 方法 | B | 选择侧边导航栏位于窗口哪一侧（0.6.1）；持久化 `navRailRight`（只存储 `true`）。 |
| `AppSettingsNotifier.setAiAssistEnabled` | 方法 | B | 打开或关闭端侧 AI；应用到 `AiAssistService` 并持久化，关闭存为缺失键。 |
| `AppSettingsNotifier.setPreferFastModel` | 方法 | B | 选择较大或较快的端侧模型；重新探测并持久化。 |
| `AppSettingsNotifier.setDebugMode` | 方法 | B | 解锁或重新隐藏开发者选项；只在本设备上持久化该选择。 |
| `AppSettings.uiStyle` | 字段 | B | 界面风格（0.6.0）：Expressive（默认，紧凑悬浮底栏）或 Material 3（经典底栏）。设备本地，不同步。 |
| `AppSettings.navPlacement` | 字段 | B | 外壳把导航放在哪里（0.6.1）：一个 `NavPlacement`（`bottom`、`sideOnWide`、`side`）；默认 bottom；两种风格都适用。 |
| `AppSettings.navRailOnRight` | 字段 | B | 导航栏是否位于窗口右侧（0.6.1）。默认关（左侧）；两种风格都适用。 |
| `AppSettings.aiAssistEnabled` | 字段 | B | 用户是否打开了端侧 AI。未打开则为 false。 |
| `AppSettings.preferFastModel` | 字段 | B | 设备同时提供两种规格时，是否优先使用较快的端侧模型。 |
| `AppSettings.debugMode` | 字段 | B | 本设备上是否已解锁开发者选项。在有人连点版本号那一行八次之前为 false。 |
| `AppSettings.new` | 构造函数 | B | 创建应用设置实例。 |
| `AppSettings.copyWith` | 方法 | B | 创建替换了选定字段的副本；`clearLocale` 存在是因为 null 已经表示「保留」。 |

`appSettingsProvider` 是没有文档注释的顶层 `final StateNotifierProvider`；不计入。

## 开发者选项（v0.4.6）

`debugMode` 和这里其他字段一样——一个默认为 `false` 的构造函数参数、一个 `copyWith` 参数，以及 `_readPersisted` 里读取 `NihongoStorage.getDebugMode()` 的一行——而 `setDebugMode` 就是 `setAiAssistEnabled` 与 `setPreferFastModel` 旁边那样一个普通的 setter，写穿到 `NihongoStorage.setDebugMode`。值得说的是它为什么属于*这个*对象而不是同步的档案：它是**设备本地、不同步的**，因为它揭示的是*这一台*手机的诊断信息——它服务的是哪个模型变体、装的是哪个 AICore 版本——把它带到另一台设备，等于在没人要求的地方打开诊断信息，而其中每一个数字讲的都是另一台设备。关闭存为缺失的键，因此从未解锁过它的设备的 `storage_config.json` 里根本没有 `debugMode` 这一行。它只从一个地方设置，即 [`../../features/settings/views/settings_page.md`](../../features/settings/views/settings_page.md) 里版本号行的点击处理函数，并由 [`../../features/ai/widgets/ai_settings_tiles.md`](../../features/ai/widgets/ai_settings_tiles.md) 读取。

## 参考页面偏好（M1.3）

`AppSettings` 还承载 `vocabLevel`、`grammarLevel`、`kanaScript` 与 `referenceListColumns`，notifier 上
对应 `setVocabLevel`、`setGrammarLevel`、`setKanaScript` 与 `setReferenceListColumns`。它们集中在一个对象里，
使页面能从 provider 同步读取，而不必各自发起异步读取并与自己的首帧竞争——在首次加载完成之前点选的筛选不会被它
覆盖。见 [`../../../features/reference-preferences.md`](../../../features/reference-preferences.md)。
