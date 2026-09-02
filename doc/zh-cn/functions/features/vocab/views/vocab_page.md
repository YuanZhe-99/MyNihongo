# lib/features/vocab/views/vocab_page.dart

`VocabPage` 是第三个标签：覆盖 `ContentCatalog.vocab` 的可搜索、可按级别筛选的浏览器。它监视 `contentCatalogProvider`，在目录不可用时显示加载指示或错误行，否则在自适应列数的条目卡片列表上方渲染页头（搜索框、级别筹片、计数）；点击卡片打开带完整条目的底部面板。它通过 `reference_widgets.dart` 与语法页面共享筹片、徽章和例句渲染。见 [../../../../features/content-catalog.md](../../../../features/content-catalog.md) 和 [../../../../adaptive-layout.md](../../../../adaptive-layout.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `VocabPage.new` | 构造函数 | B | 创建单词页面实例。 |
| `VocabPage.createState` | 方法 | B | 为此组件创建可变状态对象。 |
| `_VocabPageState.dispose` | 方法 | B | 释放搜索控制器。 |
| `_VocabPageState.build` | 方法（widget build） | B | 围绕目录 provider 的三种状态构建单词浏览器。 |
| [`_VocabPageState._buildList`](#buildlist) | 方法（widget 辅助） | A | 以虚拟化的 `ListView.builder` 构建带页头的、筛选后的自适应列数列表。 |
| `_VocabPageState._buildHeader` | 方法（widget 辅助） | B | 构建搜索框、级别筹片和结果计数。 |
| `_VocabPageState._buildTile` | 方法（widget 辅助） | B | 构建一张单词条目卡片：词条、读音/罗马音行、一行释义、级别徽章。 |
| `_VocabPageState._showDetail` | 方法（widget 辅助） | B | 在模态底部面板中显示单词的完整条目。 |

## 文档

### `Widget _buildList(BuildContext context, AppLocalizations l10n, ContentCatalog catalog)` <a id="buildlist"></a>

- **类型：** `_VocabPageState` 的方法
- **源码：** `lib/features/vocab/views/vocab_page.dart`
- **Purpose：** 把目录加当前筛选变成滚动的自适应列数列表。
- **Inputs：** `context`、`l10n`、`catalog`。
- **Returns：** 一个 `ListView.builder`。
- **Side effects：** 无。
- **Algorithm：**
  1. 按选中的级别和修剪、转小写后的查询（`VocabEntry.matches`）筛选 `catalog.vocab`。
  2. `columns = referenceColumnCount(screen, referenceContentWidth(screen.width))`；`rowCount = listRowCount(filtered.length, columns)`。
  3. 第 0 项是页头；筛选无匹配时第 1 项是空状态行；否则第 1…rowCount 项是 `adaptiveTileRow`，各自居中在 `pageMaxContentWidth` 内。
- **Usage：** 在 provider 的 `data` 分支中由 `build` 调用。
- **Notes：** 行而不是卡片是列表项，因此 `ListView.builder` 在两列及以上时仍然虚拟化。屏幕门控分栏；内容宽度决定容量。纯假名词省去读音行，使卡片不重复自己。
