# lib/features/sentence/views/sentence_lab_page.dart

句子实验室：输入一个句子，看看它由什么组成。位于 `/lab` 的全屏路由，在导航外壳之外。

功能描述见 [../../../../features/sentence-lab.md](../../../../features/sentence-lab.md)；本页记录各项声明。

使用方：`router.dart`。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `SentenceLabPage` | 类 | B | 实验室页面，可带一个待分析的句子打开。 |
| `_SentenceLabPageState.initState` | 方法 | B | 当页面带句子打开时，安排第一次分析。 |
| `_analyze` | 方法 | B | 分析输入框中的内容。 |
| [`build`](#build) | 方法 | A | 构建页面。 |
| `_buildResult` | 方法 | B | 构建四个结果部分。 |

## 文档

### `Widget build(BuildContext context)` <a id="build"></a>

- **种类：** 方法
- **用途：** 排布页面。
- **输入：** 构建 context；监听 `contentCatalogProvider`。
- **返回：** `Widget`。
- **副作用：** 无。
- **算法：** 一个位于 `pageMaxContentWidth` 的 `ConstrainedBox` 内的 `ListView`：输入框、分析按钮，然后是空状态提示或四个结果部分，最后是限制说明。
- **使用：** `/lab` 路由。
- **说明：** **在任何窗口尺寸下都是单列**，这是对应用惯常"放得下就分栏"规则的刻意例外，并已在 `adaptive-layout.md` 中如此记录。各部分是一条链——结构引用词，语法引用结构，问题引用两者——把引用放在被引用旁边会让阅读顺序变得含混。底部的限制说明是页面的一部分而不是一个提示气泡，理由与练习表相同：一个会猜测的工具必须在猜测被阅读的地方说明这一点。
