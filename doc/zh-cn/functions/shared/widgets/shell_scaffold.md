# lib/shared/widgets/shell_scaffold.dart

`ShellScaffold` 用应用的导航包裹每个标签页：窄窗口时沿底部的 `NavigationBar`，600 逻辑像素起沿左侧的 `NavigationRail`。两者都从同一个五目的地列表构建，顺序为 `ShellScaffold.routes`。文件还定义了私有的 `_ShellDestination` 值类型。见 [../../../adaptive-layout.md](../../../adaptive-layout.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `ShellScaffold.new` | 构造函数 | B | 围绕子页面创建外壳脚手架实例。 |
| `ShellScaffold._currentIndex` | 方法 | B | 找出当前 `GoRouterState` 位置属于哪个标签；无匹配时为 0。 |
| `ShellScaffold._destinations` | 方法 | B | 一次性描述五个目的地的图标和标签，按路由顺序。 |
| [`ShellScaffold.build`](#build) | 方法（widget build） | A | 围绕当前标签的页面构建外壳：按 `useNavigationRail` 选择底部栏或 rail。 |
| `_ShellDestination.new` | 构造函数 | B | 创建外壳目的地（图标、选中图标、标签）。 |

## 文档

### `Widget build(BuildContext context)` <a id="build"></a>

- **类型：** `ShellScaffold` 的方法（widget build）
- **Purpose：** 以宽度要求的形式渲染导航。
- **Inputs：** `context`。
- **Returns：** 带 `bottomNavigationBar` 的 `Scaffold`，或 body 为 rail、分隔线和页面组成的 `Row` 的 `Scaffold`。
- **Side effects：** 选中时 `context.go(route)`。
- **Algorithm：** `useNavigationRail(MediaQuery.sizeOf(context).width)`；rail 放在 `SingleChildScrollView` + `ConstrainedBox(minHeight)` + `IntrinsicHeight` 内，使其在紧凑高度下滚动而不是溢出，`groupAlignment: 0`。
- **Usage：** `router.dart` 中的 `ShellRoute(builder: (context, state, child) => ShellScaffold(child: child))`。
- **Notes：** 显示哪一个是只看宽度的 rail 决定，刻意不是全应用的分栏规则。这里没有任何状态，因此折叠设备会在下一帧把一个换成另一个，不发生路由变化。rail 居中是因为它没有前置菜单按钮或 FAB；五个目的地钉在高 rail 的顶部会让下半部分空着。
