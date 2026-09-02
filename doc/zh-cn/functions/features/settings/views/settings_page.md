# lib/features/settings/views/settings_page.dart

`SettingsPage` 是第五个标签。它显示三个节——通用（主题分段按钮、语言下拉）、数据（存储位置）、关于（版本、隐私政策、许可证、开源许可证）——并按 `canSplitLayout` 以一个或两个窗格（pane）布局自身。私有的 `_SettingsDetail` 枚举命名通向二级页面的行（`privacy`、`license`）；WebDAV 和备份在 `PLAN.md` M1.1 中加入。见 [../../../../adaptive-layout.md](../../../../adaptive-layout.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `SettingsPage.new` | 构造函数 | B | 创建设置页面实例。 |
| `SettingsPage.createState` | 方法 | B | 为此组件创建可变状态对象。 |
| `_SettingsPageState.initState` | 方法 | B | 启动版本和存储路径的加载。 |
| `_SettingsPageState._loadVersion` | 方法 | B | 从 `PackageInfo.fromPlatform()` 读取应用版本供关于节显示。 |
| `_SettingsPageState._loadStoragePath` | 方法 | B | 读取活动存储目录以供显示。 |
| `_SettingsPageState._detailPage` | 方法（widget 辅助） | B | 构建设置行通向的二级页面。 |
| [`_SettingsPageState._open`](#open) | 方法 | A | 以当前布局要求的方式打开二级页面。 |
| [`_SettingsPageState._buildDetailPane`](#builddetailpane) | 方法（widget 辅助） | A | 构建双栏布局的右侧窗格。 |
| `_SettingsPageState._buildSection` | 方法（widget 辅助） | B | 在一组设置行上方渲染节标题。 |
| `_SettingsPageState.build` | 方法（widget build） | B | 以一个或两个窗格构建设置页面。 |
| `_SettingsPageState._buildSettingsList` | 方法（widget 辅助） | B | 构建滚动的设置节列表。 |

## 文档

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
