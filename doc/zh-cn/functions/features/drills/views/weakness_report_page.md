# lib/features/drills/views/weakness_report_page.dart

把最近的卷子说明的薄弱之处展示给学习者。

三张表，从粗到细：先按部分，再按大问，最后是具体的词汇和语法点。这正是学习者能据以行动的顺序——
"听力是弱项"会改变他们今晚练什么，而"这个词老是坑我"在他们知道该打开哪个部分之前什么也改变不了。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| library header | library doc | B | 展示最近的卷子说明学习者薄弱在哪里。 |
| `WeaknessReportPage` | 类 | B | 接下来该练什么。 |
| `WeaknessReportPage` 构造函数 | 构造函数 | B | 创建页面。 |
| [`build`](#build) | 方法 | A | 构建三张表，或者说明现在还没有内容。 |
| `_heading` | 方法 | B | 渲染一个表头。 |
| `_nothingWeak` | 方法 | B | 说明这张表里目前还没有符合条件的内容。 |
| `_row` | 方法 | B | 渲染一行统计和它的正确率条。 |
| [`_itemRow`](#itemrow) | 方法 | A | 渲染一个薄弱的目录条目，名称取自目录。 |

## 文档

### `Widget build(BuildContext context, WidgetRef ref)` <a id="build"></a>

- **种类：** 方法
- **用途：** 构建三张表，或者说明现在还没有内容。
- **输入：** `context`、`ref`。
- **返回：** 当前状态对应的控件树。
- **副作用：** 根据当前状态创建 UI 控件。
- **算法：** 监听 `weaknessReportProvider` 和目录。报告为空时是一句居中的说明；否则是一个
  `ListView`，包含依据行和三张表，每一行是标题、得分和一条确定进度的正确率条。
- **用法：** `/weakness` 路由，从学习页卡片进入。
- **注意：** 空报告**会说清楚什么能填满它**，而不只是说它是空的：一个从按钮进来、什么都不显示也
  什么都不解释的页面，读起来就是坏了。表内同理——一个标题下面一片空白，比标题下面一句"只有被问过
  足够多次并且答错过才会被点名"要糟。

  报告在每次构建时都从最近几次作答重新算出来，所以学习者已经补上的薄弱点会自己消失，不需要谁去
  清除。

  正确率条是**确定进度**的 `LinearProgressIndicator`。它有确定的值，所以会稳定下来；不确定进度的
  那种永远不会，这一点已经让本项目挂过一次测试。

### `Widget _itemRow(BuildContext context, AppLocalizations l10n, ThemeData theme, ContentCatalog? catalog, MapEntry<String, WeaknessTally> entry)` <a id="itemrow"></a>

- **种类：** 方法
- **用途：** 渲染一个薄弱的目录条目，名称取自目录。
- **输入：** `context`、`l10n`、`theme`、`catalog`，以及统计条目 `entry`。
- **返回：** `Widget`。
- **副作用：** 无。
- **算法：** 对 id 调用 `resolveStudyItemLabel`，再用它的标题和副标题调用 `_row`。
- **用法：** 第三张表。
- **注意：** 仅在本文件内使用的内部辅助函数。走的是同步冲突对话框和学习日历用的同一个函数，所以一
  个已经换成 JMdict 键的旧词 id 在这里仍然能显示出它的词条。目录里已经没有的 id 会退回显示 id 本
  身而不是消失——学习者确实答错了它，一行因为内容修改而凭空消失，比一行难看的内容更糟。

大问用日语名称显示，取自 `DrillTypeName.jaName`，下面配本地化的部分名称。这些是 jlpt.jp 印的官方
标题，所以学习者拿这个页面和真卷子对照时，看到的是同一批字。
