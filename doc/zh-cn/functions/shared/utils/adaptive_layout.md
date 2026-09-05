# lib/shared/utils/adaptive_layout.dart

全应用的自适应布局策略：决定布局是否可以分栏的 `splitMinWidth`、`splitMinHeight` 和 `splitMinAspect` 阈值；外壳用的 `navRailMinWidth` 和 `navRailWidth`；多列列表用的 `listTileGap`、`listMaxColumns` 和 `listColumnsAuto`；`pageMaxContentWidth`、`kanaTableMinWidth`、`ruleCardMinWidth` 和 `referenceTileMinWidth`——本应用自己的按内容最小值，每个都有文档注释说明数字的来源；以及 `settingsRightPaneMinWidth` 和 `quizAnswerPaneMinWidth`。十一个纯函数辅助建立在它们之上。

该模块刻意只依赖 `dart:core`——没有 Flutter 导入，`canSplitLayout` 接受两个 double 而不是 `Size`——因此每个辅助都可以直接单元测试（`test/adaptive_layout_test.dart`），而渲染结果由 `test/kana_layout_ui_test.dart`、`test/shell_nav_ui_test.dart` 和 `test/widget_test.dart` 在真实设备几何下单独覆盖。数字的推导在 [../../../adaptive-layout.md](../../../adaptive-layout.md)；本页记录声明。

使用方：`shell_scaffold.dart`（`useNavigationRail`）；`kana_page.dart`（`referenceContentWidth`、`canSplitLayout`、以 `kanaTableMinWidth` 和 `ruleCardMinWidth` 调用的 `columnCapacity`）；`vocab_page.dart` 和 `grammar_page.dart`（`referenceColumnCount`、`listRowCount`）；`learn_page.dart`（`canSplitLayout`、以 `ruleCardMinWidth` 调用的 `columnCapacity`）；`settings_page.dart`（`canSplitLayout`、`shellContentWidth`、`settingsLeftPaneWidth`）；句子实验室与写作练习（`labInputPaneWidth`）；每个滚动页面（`shellListBottomInset`）；`adaptive_tile_grid.dart`（`listRowCount`、`listTileGap`）；`quiz_runner.dart`（`canSplitLayout`、`referenceContentWidth`，以及作为其 `questionPaneWidth` 参数默认值的 `quizQuestionPaneWidth`，考试页用 `drillPassagePaneWidth` 覆盖它）。

`drillPassagePaneWidth` 把 `quizQuestionPaneWidth` 所用的比例反了过来。在那边题目是较小的一半，因为它放的是一个词；在这边题目是较大的一半，因为它放的是学习者一边作答一边反复读的一篇文章。取 0.55 而不是 0.5，既给了文本更长的行，又不至于挤压选项，而同样的最终封顶让作答区在最窄的可分栏窗口上仍保有 `quizAnswerPaneMinWidth`。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| [`canSplitLayout`](#cansplitlayout) | 顶层函数 | A | 报告布局是否可以分成窗格或多列。 |
| [`useNavigationRail`](#usenavigationrail) | 顶层函数 | A | 报告外壳是否应显示导航栏（NavigationRail）。 |
| `shellContentWidth` | 顶层函数 | B | 返回外壳页面内容实际获得的宽度：屏幕减去显示时的导航栏，永不为负。 |
| `shellListBottomInset` | 顶层函数 | B | 返回滚动列表需要的底部内边距：底部栏下为 80，导航栏旁为 16。 |
| `referenceContentWidth` | 顶层函数 | B | 返回参考页面的内容宽度：`shellContentWidth` 减去页面内边距，上限为 `pageMaxContentWidth`。 |
| [`columnCapacity`](#columncapacity) | 顶层函数 | A | 返回给定最小宽度的列在内容盒中能放多少列。 |
| [`referenceColumnCount`](#referencecolumncount) | 顶层函数 | A | 返回单词或语法列表渲染的列数。 |
| `listRowCount` | 顶层函数 | B | 返回一组条目在某列数下需要多少行；包含不满的最后一行。 |
| `quizAnswerPaneMinWidth` | 顶层常量 | B | 测验作答窗格允许的最小宽度：280。 |
| `quizQuestionPaneWidth` | 顶层函数 | B | 返回布局分栏时测验题目窗格的宽度；也是运行器所用的默认值。 |
| `drillPassagePaneWidth` | 顶层函数 | B | 返回考试页题目窗格的宽度：内容的 0.55，夹在 360–640，并封顶以让作答区保有 `quizAnswerPaneMinWidth`。 |
| `settingsLeftPaneWidth` | 顶层函数 | B | 返回设置页左窗格宽度：内容的 0.44，夹在 300–440，并封顶以让右窗格保留 280。 |
| `labResultPaneMinWidth` | 顶层常量 | B | 句子实验室分析窗格的最小宽度：360。 |
| `labInputPaneWidth` | 顶层函数 | B | 返回实验室与写作练习输入窗格的宽度：内容宽度的 0.40，夹在 320–460，再封顶以保证结果窗格至少 360。 |

## 文档

### `bool canSplitLayout(double width, double height)` <a id="cansplitlayout"></a>

- **种类：** 顶层函数
- **用途：** 全应用的形状门控。
- **输入：** **整个屏幕**的逻辑像素尺寸——`MediaQuery.sizeOf(context)`，绝不是 `Scaffold` body。
- **返回：** 仅当 `width >= 600`、`height >= 480`、`height > 0` 且 `width / height >= 0.82` 时为 `true`。
- **副作用：** 无。
- **算法：** 三个独立测试，全部必须通过。
- **使用：** 每个可以分栏的页面，以及 `referenceColumnCount`。
- **说明：** 宽高比测试是承重的那个：它让竖持的 Galaxy Z Fold 8（0.755）保持单列，而同一设备横持时分栏，并让接近正方形的 Fold 7 和 Fold 8 Ultra 在两个方向都分栏。宽度下限是 `sw600dp` 平板阈值；高度下限拒绝横持的手机或折叠后的外屏。

### `bool useNavigationRail(double screenWidth)` <a id="usenavigationrail"></a>

- **种类：** 顶层函数
- **用途：** 在底部导航栏和导航栏之间决定。
- **输入：** 整个屏幕宽度。
- **返回：** `screenWidth >= 600`。
- **副作用：** 无。
- **算法：** 一次比较。
- **使用：** `ShellScaffold.build`；`shellContentWidth`；`shellListBottomInset`。
- **说明：** **刻意只看宽度**——不经过 `canSplitLayout`。导航栏用宽度（此条件为真时总是充足）换高度（并不充足）；它最能帮到的情形是横持的手机，而分栏规则有意拒绝这种情形。

### `int columnCapacity(double contentWidth, {required double minItemWidth, double gap = listTileGap, int maxColumns = listMaxColumns})` <a id="columncapacity"></a>

- **种类：** 顶层函数
- **用途：** Google 为信息流推荐的自适应最小宽度计数，而不是每个断点硬编码一个列数。
- **输入：** 内容实际获得的宽度；一列可以多窄；列间距；上限。
- **返回：** `((contentWidth + gap) / (minItemWidth + gap)).floor()` 夹到 `[1, maxColumns]`；宽度非正时为 1；最小值非正时为上限。
- **副作用：** 无。
- **算法：** 分子加上一个间距，使算式只为列*之间*的间距付费，而不是每列之后都付一次。
- **使用：** 五十音表（330，最多 2）、规则和仪表盘卡片（320，最多 2）、`referenceColumnCount`（320，最多 4）。
- **说明：** 每个调用方带来自己内容需要的最小值，常量的文档注释说明数字的来源。

### `int referenceColumnCount({required double screenWidth, required double screenHeight, required double contentWidth})` <a id="referencecolumncount"></a>

- **种类：** 顶层函数
- **用途：** 单词和语法列表的列数。
- **输入：** 整个屏幕（门控）和列表自己的宽度（容量）。
- **返回：** `canSplitLayout` 不通过时为 1；否则为 `columnCapacity(contentWidth, minItemWidth: referenceTileMinWidth)`。
- **副作用：** 无。
- **算法：** 先门控，再容量。
- **使用：** 两个浏览页面中的 `_buildList`。
- **说明：** 门控读屏幕而容量读列表宽度，这是刻意的。目前没有存储的偏好；将来有了，应把它夹到容量内而不是拒绝，这样在桌面上做的选择在折叠的手机上仍然有效。
