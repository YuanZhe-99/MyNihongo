# lib/shared/widgets/history_list.dart

一个页面里被记住的句子，点一下取回，点一下忘掉。

由句子实验室和写作练习共用，因为两者想要的完全是同一份列表。不同的只是把它*放在哪里*——宽窗口上放在结果旁边的一栏里，窄窗口上放在顶栏按钮后的 sheet 里——那是页面的决定，记录在
[`../../adaptive-layout.md`](../../adaptive-layout.md)。

使用方：`sentence_lab_page.dart`、`writing_practice_page.dart`。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `HistoryList` | 类 | B | 一个页面的历史记录列表。 |
| [`build`](#build) | 方法 | A | 构建列表，或那句「这里还没有内容」。 |
| `_formatTime` | 静态方法 | B | 用读者所在时区说明条目写于何时。 |
| [`showHistorySheet`](#showhistorysheet) | 顶层函数 | A | 在底部 sheet 中显示一个页面的历史记录。 |
| `_SheetHistory` | 类 | B | sheet 自己那份列表副本。 |
| `_SheetHistoryState.build` | 方法 | B | 渲染副本，并从中移除被删掉的行。 |

## 文档

### `Widget build(BuildContext context)` <a id="build"></a>

- **种类：** 方法
- **用途：** 画出各个条目，最新的在前。
- **输入：** 构建 context；widget 的条目与回调。
- **返回：** `Widget`。
- **副作用：** 无。
- **算法：** 空列表返回「这里还没有内容」那一行。否则是一个由紧凑 tile 构成的 `ListView.builder`：文本单行显示并按需省略，时间在其下，末尾是删除按钮。
- **用法：** 放在可滚动栏内时用 `shrinkWrap`，放在 sheet 里时由列表自己拥有滚动。
- **注意：** 空历史会明说而不是什么都不画，理由和问题列表相同：缺席需要读者去解读，而一句话不需要。`shrinkWrap` 会连带用上 `NeverScrollableScrollPhysics`，因为把可滚动组件放进高度无界的可滚动组件里，是把列表弄到不可用的经典做法。

### `Future<void> showHistorySheet(BuildContext context, {...})` <a id="showhistorysheet"></a>

- **种类：** 顶层函数
- **用途：** 在窄到放不下第二栏的窗口上显示历史记录。
- **输入：** `context`、`entries`，以及打开与删除两个回调。
- **返回：** sheet 关闭时完成的 future。
- **副作用：** 打开一个模态路由。
- **算法：** 一个高度上限为屏幕 60% 的模态底部 sheet，里面是带标题的 `_SheetHistory`。打开某个条目时先关闭 sheet。
- **用法：** 低于分栏门槛时，两个页面顶栏上的历史按钮。
- **注意：** 这是布局决策中「窄」的那一半：没有地方放第二栏，而一份要让学习者划过去才能够到输入框的列表，等于为了少数情形把常见情形弄糟。打开条目时关闭 sheet，是因为它产生的结果就在它背后的页面上。sheet 保留**自己**的列表副本，因为它是独立的路由，而页面背后的 provider 重建的是页面而不是它——就地移除那一行，正是让删除看起来立刻生效、而不必等待文件写完的做法。
