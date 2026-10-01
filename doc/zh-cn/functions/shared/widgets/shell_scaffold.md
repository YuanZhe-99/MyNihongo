# lib/shared/widgets/shell_scaffold.dart

`ShellScaffold` 用应用的导航包裹每个标签页：窄窗口时的底栏（界面风格为 Expressive 时是紧凑悬浮胶囊 `_ExpressiveNavBar`，Material 3 时是经典通栏 `NavigationBar`），`NavigationRail`——默认在左侧，可通过设置放到右侧。自 0.6.1 起，由仅限本设备的导航位置设置（`NavPlacement`，两种风格都适用）决定：任何窗口都用底栏（默认）、仅宽窗口用导航栏，或任何窗口都用导航栏。两种形式都从同一个五目的地列表构建，顺序为 `ShellScaffold.routes`。文件还定义了私有的 `_ShellDestination` 值类型、`_ExpressiveNavBar` 和 `_ExpressiveNavItem`。见 [../../../adaptive-layout.md](../../../adaptive-layout.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `ShellScaffold.new` | 构造函数 | B | 围绕子页面创建外壳脚手架实例。 |
| `ShellScaffold._currentIndex` | 方法 | B | 找出当前 `GoRouterState` 位置属于哪个标签；无匹配时为 0。 |
| `ShellScaffold._destinations` | 方法 | B | 一次性描述五个目的地的图标和标签，按路由顺序。 |
| [`ShellScaffold.build`](#build) | 方法（widget build） | A | 围绕当前标签的页面构建外壳：按 `useNavigationRail` 和三个导航设置选择底部栏或 rail。 |
| `_ExpressiveNavBar` | 私有类 | B | Expressive 底栏：紧贴内容宽度的紧凑悬浮 stadium 胶囊，键为 `floatingNavBarIsland`。 |
| `_ExpressiveNavBar.new` | 构造函数 | B | 创建 Expressive 导航栏。 |
| `_ExpressiveNavBar.build` | 方法（组件构建） | B | 构建浮岛：边距、`surfaceContainer` 色 stadium、由各项组成的 `Row`；过窄时整体缩小而不溢出。 |
| `_ExpressiveNavItem` | 私有类 | B | 导航栏的一个目的地：选中时图标加文字，未选中时只有图标。 |
| `_ExpressiveNavItem.new` | 构造函数 | B | 创建一个 Expressive 导航项。 |
| `_ExpressiveNavItem.build` | 方法（组件构建） | B | 构建导航项：带动画的 tonal 胶囊，含图标和（仅选中时的）文字；未选中项带 tooltip 和语义标签。 |
| `_ShellDestination.new` | 构造函数 | B | 创建外壳目的地（图标、选中图标、标签）。 |

## 文档

### `Widget build(BuildContext context, WidgetRef ref)` <a id="build"></a>

- **类型：** `ShellScaffold` 的方法（widget build）
- **Purpose：** 按宽度和设置要求的形式渲染导航。
- **Inputs：** `context`、`ref`（监听 `appSettingsProvider` 的 `uiStyle`、`navPlacement` 和 `navRailOnRight`）。
- **Returns：** Expressive 且无 rail 时是带 `_ExpressiveNavBar` 的 `Scaffold(extendBody: true)`；Material 3 且无 rail 时是带 `NavigationBar` 的 `Scaffold`；有 rail 时是 body 为 rail、`VerticalDivider` 和页面组成的 `Row` 的 `Scaffold`——rail 在前，设置了 `navRailOnRight` 时在后。
- **Side effects：** 选中时 `context.go(route)`，并调用 `NihongoStorage.setLastTab`。
- **Algorithm：** `wide = useNavigationRail(MediaQuery.sizeOf(context).width)`；`showRail = switch (placement) { bottom => false, sideOnWide => wide, side => true }`。rail 放在 `SingleChildScrollView` + `ConstrainedBox(minHeight)` + `IntrinsicHeight` 内，使其在紧凑高度下滚动而不是溢出，`groupAlignment: 0`。Expressive 底栏分支中，body 外包一层 `MediaQuery`，把 `viewPadding.bottom` 至少抬到 `padding.bottom`，因为页面自己的 `Scaffold` 按 `viewPadding` 放置悬浮按钮，而 `extendBody` 不会改变它。
- **Usage：** `router.dart` 中的 `ShellRoute(builder: (context, state, child) => ShellScaffold(child: child))`。
- **Notes：** 先由只看宽度的 rail 决定（刻意不是全应用的分栏规则），再由设置调整。`extendBody` 让页面绘制在悬浮栏后面，并把栏高作为 `MediaQuery.padding.bottom` 报告；每个显式设置了滚动内边距的外壳页面都用 `navBarAwarePadding` 留出这段空间。这里没有任何状态，因此折叠设备会在下一帧把一种形式换成另一种，不发生路由变化。rail 居中是因为它没有前置菜单按钮或 FAB；五个目的地钉在高 rail 的顶部会让下半部分空着。
