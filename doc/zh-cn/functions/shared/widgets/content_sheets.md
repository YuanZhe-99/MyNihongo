# lib/shared/widgets/content_sheets.dart

单词、语法点与假名的详情弹层，并带有指向相邻条目的标签。在 `PLAN.md` M1.3 中从单词与语法页面抽出，使三个页面
都能打开彼此的弹层。见 [../../../features/content-catalog.md](../../../features/content-catalog.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| 库头注释 | `library` | B | 在底部弹层中展示单词、语法点或假名。 |
| `_sectionLabel` | 顶层函数 | B | 在弹层中渲染分区标题。 |
| `_sheetBody` | 顶层函数 | B | 用共享的内边距与滚动包裹弹层内容。 |
| `_chipSection` | 顶层函数 | B | 渲染一组带标题的可点击标签。 |
| [`showVocabDetailSheet`](#showvocabdetailsheet) | 顶层函数 | A | 展示单词，并附其例句使用的语法。 |
| [`showGrammarDetailSheet`](#showgrammardetailsheet) | 顶层函数 | A | 展示语法点，并附其例句使用的单词。 |
| [`showKanaDetailSheet`](#showkanadetailsheet) | 顶层函数 | A | 展示假名，并附其说明与示例单词。 |

用弹层而不是路由，因为弹层保留下方列表的位置，且在单列与多列下表现一致。打开关联的弹层会叠加第二层，关闭它便
回到第一层——这正是这里“返回”应有的含义。

### `showVocabDetailSheet` <a id="showvocabdetailsheet"></a>

- **Purpose:** 展示单词的完整条目，并附其例句使用的语法。
- **Inputs:** `context`、`catalog`、`entry`、`locale`。
- **Returns:** 弹层关闭时完成的 `Future<void>`。
- **Side effects:** 推入模态底部弹层。
- **Algorithm:** 词头、等级、读音与罗马字、词性、界面语言下的全部释义、例句，最后为例句中找到的每个语法点显示一个
  标签（去重）。
- **Usage:** 单词卡片，以及另外两个弹层上的单词标签。
- **Notes:** 标签基于子串匹配而非句法分析，因此以“例句中使用的语法”呈现，而不是作为分析结果；见
  `content_links.dart`。

### `showGrammarDetailSheet` <a id="showgrammardetailsheet"></a>

- **Purpose:** 展示语法点的完整条目，并附其例句使用的单词。
- **Inputs:** `context`、`catalog`、`point`、`locale`。
- **Returns:** `Future<void>`。
- **Side effects:** 推入模态底部弹层。
- **Algorithm:** 句型、等级、含义、结构、详解、例句，最后为例句中找到的每个单词显示一个标签。
- **Usage:** 语法卡片，以及单词弹层上的语法标签。
- **Notes:** 单词标签限定在该语法点自身等级及以下。

### `showKanaDetailSheet` <a id="showkanadetailsheet"></a>

- **Purpose:** 以两种字体展示一个假名，并附说明与示例单词。
- **Inputs:** `context`、`catalog`、`entry`、`locale`。
- **Returns:** `Future<void>`。
- **Side effects:** 推入模态底部弹层。
- **Algorithm:** 大字显示两种字体并在旁标注罗马字；注释文件中有笔画数与要点时一并显示；为易混淆的假名显示标签；
  最后列出以它开头的最简单、最常用的单词。
- **Usage:** 假名表格子、假名搜索结果，以及另一个假名弹层上的易混淆标签。
- **Notes:** 示例单词才是这个弹层的重点。假名表教的是字形；初学者需要在单词中看到这个字形才能读出来。既没有注释也
  没有示例单词的假名会明确说明，而不是显示一个空弹层。
