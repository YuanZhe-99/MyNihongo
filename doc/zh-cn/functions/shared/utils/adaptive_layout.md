# lib/shared/utils/adaptive_layout.dart

全应用的自适应布局策略：决定布局是否可以分栏的 `splitMinWidth`、`splitMinHeight` 和 `splitMinAspect` 阈值；外壳用的 `navRailMinWidth` 和 `navRailWidth`；多列列表用的 `listTileGap`、`listMaxColumns` 和 `listColumnsAuto`；`pageMaxContentWidth`、`kanaTableMinWidth`、`ruleCardMinWidth` 和 `referenceTileMinWidth`——本应用自己的按内容最小值，每个都有文档注释说明数字的来源；以及 `settingsRightPaneMinWidth`。九个纯函数辅助建立在它们之上。

该模块刻意只依赖 `dart:core`——没有 Flutter 导入，`canSplitLayout` 接受两个 double 而不是 `Size`——因此每个辅助都可以直接单元测试（`test/adaptive_layout_test.dart`），而渲染结果由 `test/kana_layout_ui_test.dart`、`test/shell_nav_ui_test.dart` 和 `test/widget_test.dart` 在真实设备几何下单独覆盖。数字的推导在 [../../../adaptive-layout.md](../../../adaptive-layout.md)；本页记录声明。

使用者：`shell_scaffold.dart`（`useNavigationRail`）；`kana_page.dart`（`referenceContentWidth`、`canSplitLayout`、以 `kanaTableMinWidth` 和 `ruleCardMinWidth` 调用的 `columnCapacity`）；`vocab_page.dart` 和 `grammar_page.dart`（`referenceColumnCount`、`listRowCount`）；`learn_page.dart`（`canSplitLayout`、以 `ruleCardMinWidth` 调用的 `columnCapacity`）；`settings_page.dart`（`canSplitLayout`、`shellContentWidth`、`settingsLeftPaneWidth`）；每个滚动页面（`shellListBottomInset`）；`adaptive_tile_grid.dart`（`listRowCount`、`listTileGap`）。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| [`canSplitLayout`](#cansplitlayout) | 顶层函数 | A | 报告布局是否可以分成面板或多列。 |
| [`useNavigationRail`](#usenavigationrail) | 顶层函数 | A | 报告外壳是否应显示导航栏（rail）。 |
| `shellContentWidth` | 顶层函数 | B | 返回外壳页面内容实际获得的宽度：屏幕减去显示时的 rail，永不为负。 |
| `shellListBottomInset` | 顶层函数 | B | 返回滚动列表需要的底部内边距：底部栏下为 80，rail 旁为 16。 |
| `referenceContentWidth` | 顶层函数 | B | 返回参考页面的内容宽度：`shellContentWidth` 减去页面内边距，上限为 `pageMaxContentWidth`。 |
| [`columnCapacity`](#columncapacity) | 顶层函数 | A | 返回给定最小宽度的列在内容盒中能放多少列。 |
| [`referenceColumnCount`](#referencecolumncount) | 顶层函数 | A | 返回单词或语法列表渲染的列数。 |
| `listRowCount` | 顶层函数 | B | 返回一组条目在某列数下需要多少行；包含不满的最后一行。 |
| `settingsLeftPaneWidth` | 顶层函数 | B | 返回设置页左面板宽度：内容的 0.44，夹在 300–440，并封顶以让右面板保留 280。 |

## 文档

### `bool canSplitLayout(double width, double height)` <a id="cansplitlayout"></a>

- **类型：** 顶层函数
- **Purpose：** 全应用的形状门。
- **Inputs：** **整个屏幕**的逻辑像素尺寸——`MediaQuery.sizeOf(context)`，绝不是 `Scaffold` body。
- **Returns：** 仅当 `width >= 600`、`height >= 480`、`height > 0` 且 `width / height >= 0.82` 时为 `true`。
- **Side effects：** 无。
- **Algorithm：** 三个独立测试，全部必须通过。
- **Usage：** 每个可以分栏的页面，以及 `referenceColumnCount`。
- **Notes：** 宽高比测试是承重的那个：它让竖持的 Galaxy Z Fold 8（0.755）保持单列，而同一设备横持时分栏，并让接近正方形的 Fold 7 和 Fold 8 Ultra 在两个方向都分栏。宽度下限是 `sw600dp` 平板阈值；高度下限拒绝横持的手机或折叠后的外屏。

### `bool useNavigationRail(double screenWidth)` <a id="usenavigationrail"></a>

- **类型：** 顶层函数
- **Purpose：** 在底部栏和 rail 之间决定。
- **Inputs：** 整个屏幕宽度。
- **Returns：** `screenWidth >= 600`。
- **Side effects：** 无。
- **Algorithm：** 一次比较。
- **Usage：** `ShellScaffold.build`；`shellContentWidth`；`shellListBottomInset`。
- **Notes：** **刻意只看宽度**——不经过 `canSplitLayout`。rail 用宽度（此条件为真时总是充足）换高度（并不充足）；它最能帮到的情形是横持的手机，而分栏规则有意拒绝这种情形。

### `int columnCapacity(double contentWidth, {required double minItemWidth, double gap = listTileGap, int maxColumns = listMaxColumns})` <a id="columncapacity"></a>

- **类型：** 顶层函数
- **Purpose：** Google 为信息流推荐的自适应最小宽度计数，而不是每个断点硬编码一个列数。
- **Inputs：** 内容实际获得的宽度；一列可以多窄；列间距；上限。
- **Returns：** `((contentWidth + gap) / (minItemWidth + gap)).floor()` 夹到 `[1, maxColumns]`；宽度非正时为 1；最小值非正时为上限。
- **Side effects：** 无。
- **Algorithm：** 分子加上一个间距，使算式只为列*之间*的间距付费，而不是每列之后都付一次。
- **Usage：** 五十音表（330，最多 2）、规则和仪表盘卡片（320，最多 2）、`referenceColumnCount`（320，最多 4）。
- **Notes：** 每个调用方带来自己内容需要的最小值，常量的文档注释说明数字的来源。

### `int referenceColumnCount({required double screenWidth, required double screenHeight, required double contentWidth})` <a id="referencecolumncount"></a>

- **类型：** 顶层函数
- **Purpose：** 单词和语法列表的列数。
- **Inputs：** 整个屏幕（门）和列表自己的宽度（容量）。
- **Returns：** `canSplitLayout` 不通过时为 1；否则为 `columnCapacity(contentWidth, minItemWidth: referenceTileMinWidth)`。
- **Side effects：** 无。
- **Algorithm：** 先门，再容量。
- **Usage：** 两个浏览页面中的 `_buildList`。
- **Notes：** 门读屏幕而容量读列表宽度，这是刻意的。目前没有存储的偏好；将来有了，应把它夹到容量内而不是拒绝，这样在桌面上做的选择在折叠的手机上仍然有效。
