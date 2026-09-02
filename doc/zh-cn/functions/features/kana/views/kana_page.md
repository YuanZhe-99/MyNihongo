# lib/features/kana/views/kana_page.dart

`KanaPage` 是第二个标签：覆盖 `features/kana/models/kana.dart` 中目录的纯 UI 平假名/片假名速查。它渲染书写体系切换、搜索框、三张表（查询为空时）、搜索结果网格（查询非空时），以及一组发音规则卡片，按窗口排成一列或两列。该文件还定义了 `_KanaRule`，即一张规则卡的显示数据。见 [../../../../features/kana-reference.md](../../../../features/kana-reference.md) 和 [../../../../adaptive-layout.md](../../../../adaptive-layout.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `KanaPage.new` | 构造函数 | B | 创建五十音页面实例。 |
| `KanaPage.createState` | 方法 | B | 为此组件创建可变状态对象。 |
| `_KanaPageState.dispose` | 方法 | B | 释放搜索控制器。 |
| [`_KanaPageState.build`](#kanabuild) | 方法（widget build） | A | 以一列或两列构建页面：书写体系切换、搜索框，以及表格或结果，加上规则卡。 |
| `_KanaPageState._buildKanaTable` | 方法（widget 辅助） | B | 渲染一张带标题的假名表（表头行 + 数据行）。 |
| `_KanaPageState._buildHeaderRow` | 方法（widget 辅助） | B | 渲染表的列标签表头行。 |
| `_KanaPageState._buildKanaRow` | 方法（widget 辅助） | B | 渲染一个辅音行的假名格及其标签。 |
| `_KanaPageState._buildKanaCell` | 方法（widget 辅助） | B | 渲染一个假名/罗马音格，或为缺失槽位渲染空白。 |
| `_KanaPageState._buildSearchResults` | 方法（widget 辅助） | B | 渲染搜索结果，或空状态消息。 |
| `_KanaPageState._buildResultTile` | 方法（widget 辅助） | B | 把一个假名条目渲染为搜索结果卡片。 |
| [`_KanaPageState._buildRules`](#kanabuildrules) | 方法（widget 辅助） | A | 把七张发音规则卡排成一列或两列。 |
| `_KanaPageState._buildRuleCard` | 方法（widget 辅助） | B | 渲染一张发音规则卡（图标、标题、正文）。 |
| `_KanaPageState._sectionTitle` | 方法（widget 辅助） | B | 渲染表格与规则共用的节标题（图标 + 标签）。 |
| `_KanaRule.new` | 构造函数 | B | 创建规则卡的显示数据（图标、标题、正文、颜色）。 |

## 文档

### `Widget build(BuildContext context)` <a id="kanabuild"></a>

- **类型：** `_KanaPageState` 的方法（widget build）
- **源码：** `lib/features/kana/views/kana_page.dart`
- **Purpose：** 按窗口以一列或两列构建页面。
- **Inputs：** `context`。
- **Returns：** 页面的组件树。
- **Side effects：** 除构建组件外无。
- **Algorithm：**
  1. `contentWidth = referenceContentWidth(screen.width)`——内容减去导航栏和页面边距，上限 `pageMaxContentWidth`。
  2. `twoColumn = canSplitLayout(screen.width, screen.height) &&
     columnCapacity(contentWidth, minItemWidth: kanaTableMinWidth, maxColumns: 2) >= 2`。
  3. 把书写体系选择器、搜索框、三张表和规则节构建为局部变量。
  4. 页头：`twoColumn` 时在一个 `Row` 中并排，否则堆叠。
  5. 主体：有查询时是搜索结果加规则；否则 `twoColumn` 时是（基础表、拗音表）与（浊音表、规则）的两列 `Row`；否则按堆叠顺序。
- **Usage：**
  ```dart
  GoRoute(path: '/kana', builder: (context, state) => const KanaPage()),
  ```
  （来自 `lib/app/router.dart` 中的 `appRouter`）
- **Notes：** **刻意双重门控。** 第一道门控是全应用的形状规则；第二道问两张至少 330 逻辑像素的表是否真能放下。第二道正是让较窄的展开态折叠屏——Z Fold 5 有 546 的内容，而两张表需要 672——保持单列、无需自己断点的原因。两列是指定而不是流式排布的，以便平衡：高的基础表和拗音表在左，对矮的浊音表加规则在右。

### `Widget _buildRules(ThemeData theme, AppLocalizations l10n)` <a id="kanabuildrules"></a>

- **类型：** `_KanaPageState` 的方法（widget 辅助）
- **源码：** `lib/features/kana/views/kana_page.dart`
- **Purpose：** 把七张发音规则卡排成一列或两列。
- **Inputs：** `theme`、`l10n`。
- **Returns：** 节标题之上、固定宽度卡片的 `Wrap`。
- **Side effects：** 除构建组件外无。
- **Algorithm：** 在 `LayoutBuilder` 内取 `columnCapacity(constraints.maxWidth, minItemWidth: ruleCardMinWidth, maxColumns: 2)`，用它除以扣掉间隙后的可用宽度，并给每张卡该宽度。
- **Usage：** 来自 `build` 的 `final rules = _buildRules(theme, l10n);`。
- **Notes：** 度量的是这一节实际得到的宽度——单列时是整页宽，两列时是一半——因此卡片自行重排，无需知道页面处于哪种模式。上限两列，因为它们是段落。
