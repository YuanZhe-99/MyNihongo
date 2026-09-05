# lib/features/settings/views/settings_page.dart

`SettingsPage` 是第五个标签。它显示若干节——通用（主题分段按钮、语言下拉：跟随系统、English、简体中文、繁體中文）、数据、关于（版本、隐私政策、许可证、开源许可证）——并按 `canSplitLayout` 以一个或两个窗格（pane）布局自身。数据节现在包含 WebDAV 同步行（带实时状态副标题）、备份行、ZIP 导出与导入，以及存储位置。私有的 `_SettingsDetail` 枚举命名通向二级页面的四行：`webdav`、`backup`、`privacy`、`license`；导出与导入就地执行。见 [../../../../adaptive-layout.md](../../../../adaptive-layout.md)。

从 `v0.4.6` 起，关于节里的版本号那一行可以点击。连点八次解锁开发者选项——顶层常量 `_debugUnlockTaps`，取八是因为 Android 自己就是这么要求的。完全照搬这个手势正是重点：需要这些诊断信息的人本来就知道怎么做，而其他人不会偶然发现它。`_versionTaps` 记录这一连串点击；它存在 state 对象里，因此页面被重新构建时就会归零，这个计数是一连串有意为之的点击，而不是学习者在几周里慢慢攒出来的东西。解锁之后，关于节里会在版本号行下方出现一个**开发者选项** `SwitchListTile`——而且只有在它已经打开时才出现，因为那里放一个「关闭」的行等于一份邀请，而隐藏诊断信息的意义就在于它们不是给没去找过它们的学习者看的。通过那个开关把它关掉也会重置 `_versionTaps`。标志本身位于 `AppSettings.debugMode`（[../../../shared/providers/app_settings.md](../../../shared/providers/app_settings.md)），由 [../../ai/widgets/ai_settings_tiles.md](../../ai/widgets/ai_settings_tiles.md) 读取。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `SettingsPage.new` | 构造函数 | B | 创建设置页面实例。 |
| `SettingsPage.createState` | 方法 | B | 为此组件创建可变状态对象。 |
| `_SettingsPageState.initState` | 方法 | B | 启动版本和存储路径的加载。 |
| `_SettingsPageState._loadVersion` | 方法 | B | 从 `PackageInfo.fromPlatform()` 读取应用版本供关于节显示。 |
| `_SettingsPageState._refreshSyncStatus` | 方法 | B | 后台同步状态变化时重绘 WebDAV 行。 |
| `_SettingsPageState.dispose` | 方法 | B | 移除同步状态监听器。 |
| [`_SettingsPageState._onVersionTapped`](#onversiontapped) | 方法 | A | 记录版本号行上的点击次数，到八次时解锁开发者选项。 |
| `_SettingsPageState._debugCountdown` | 方法 | B | 在这一连串点击已明显是有意为之时，说明还差几次；无话可说时返回 null。 |
| `_SettingsPageState._loadStoragePath` | 方法 | B | 读取活动存储目录以供显示。 |
| `_SettingsPageState._syncSubtitle` | 方法 | B | 为 WebDAV 行的副标题总结同步健康状况。 |
| `_SettingsPageState._exportZip` | 方法 | B | 把每个数据模块写入用户选择目录中的 ZIP。 |
| `_SettingsPageState._importZip` | 方法 | B | 用用户选择的 ZIP 替换本地数据。 |
| `_SettingsPageState._detailPage` | 方法（widget 辅助） | B | 构建设置行通向的二级页面。 |
| [`_SettingsPageState._open`](#open) | 方法 | A | 以当前布局要求的方式打开二级页面。 |
| [`_SettingsPageState._buildDetailPane`](#builddetailpane) | 方法（widget 辅助） | A | 构建双栏布局的右侧窗格。 |
| `_SettingsPageState._buildSection` | 方法（widget 辅助） | B | 在一组设置行上方渲染节标题。 |
| `_SettingsPageState.build` | 方法（widget build） | B | 以一个或两个窗格构建设置页面。 |
| `_SettingsPageState._buildSettingsList` | 方法（widget 辅助） | B | 构建滚动的设置节列表。 |

## 文档

### `void _onVersionTapped()` <a id="onversiontapped"></a>

- **类型：** `_SettingsPageState` 的方法
- **用途：** 记录版本号行上的点击次数，到八次时解锁开发者选项。
- **输入：** 无。
- **返回：** 无。
- **副作用：** 对计数器调用 `setState`；到八次时调用 `setDebugMode(true)`——它会持久化该偏好——并弹出一个 snack bar 说明开发者选项已打开。
- **算法：** `debugMode` 已经打开时立即返回，于是再点一轮什么也不会发生；否则递增 `_versionTaps`，到达 `_debugUnlockTaps`（8）时重置计数器、置位标志并显示 snack bar。
- **使用：** 版本号行的 `onTap`。
- **说明：** 在版本号上连点八次是 Android 自己的手势，完全照搬它正是重点：需要它的人本来就知道怎么做，而其他人不会偶然发现它。倒数由 `_debugCountdown` 给出，显示为版本号行**自己的副标题**而不是 snack bar——这不是风格取舍：snack bar 位于屏幕底部，关于节位于一长串列表的底部，倒数会挡住下一次点击必须落在的那一行。它在还剩三次之前保持沉默，于是误触的双击什么也不会说，而一连串有意为之的点击会告诉按的人它起作用了。

### `void _open(_SettingsDetail detail)` <a id="open"></a>

- **类型：** `_SettingsPageState` 的方法
- **Purpose：** 以布局所处的模式打开二级页面。
- **Inputs：** `detail`。
- **Returns：** 无。
- **Side effects：** 要么选择详情窗格的页面（`setState`），要么在**根**导航器上压入 `MaterialPageRoute`。
- **Algorithm：** `if (_twoPane) select; else push`。
- **Usage：** 每个二级行的 `onTap`。
- **Notes：** 每一行都经过这里，因此两种模式不会漂移。使用根导航器，使压入的页面覆盖外壳的底部导航栏。

### `Widget _buildDetailPane(AppLocalizations l10n)` <a id="builddetailpane"></a>

- **类型：** `_SettingsPageState` 的方法
- **Purpose：** 构建右侧窗格。
- **Inputs：** `l10n`。
- **Returns：** 未选择任何项时是占位（「从左侧列表中选择一项」）；否则是以选择为键的嵌套 `Navigator`，其唯一路由是详情页面。
- **Side effects：** 除构建组件外无。
- **Algorithm：** 选择为 null → 居中的图标和提示；否则 `Navigator(key: ValueKey(detail), onGenerateRoute: …)`。
- **Usage：** 双栏 `build` 中右侧的 `Expanded` 子组件。
- **Notes：** 嵌套 `Navigator` 给承载页面一条真实路由，因此调用 `Navigator.pop` 的页面仍能工作，而只有一条路由的导航器报告 `canPop == false`，因此承载页面的应用栏不会长出返回箭头。以选择为键使每次变化都销毁并重建。窗口收窄回单窗格时选择被保留，因此把设备合上再打开会恢复它。
