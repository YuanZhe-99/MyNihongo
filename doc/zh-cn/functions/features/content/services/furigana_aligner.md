# lib/features/content/services/furigana_aligner.dart

还原哪些假名属于哪些字，从而把读音印在它所描述的汉字上方。内容库只为每个词、每个句子各存一条读音，没有逐字映射，因此本文件仅凭两个字符串推导它；一旦推导不出，就返回 null 而不猜测：错误的对齐会把假名印在错误的字上，教出一个并不存在的读音。

算法、各种情形与开销见
[`../../../../algorithms/furigana-alignment.md`](../../../../algorithms/furigana-alignment.md)。

使用方：`shared/widgets/furigana_text.dart`、`shared/widgets/reference_widgets.dart`、
`features/vocab/views/vocab_page.dart`、`features/sentence/widgets/token_chips.dart`、
`features/quiz/services/question_generator.dart`。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `FuriganaSegment` | 类 | B | 表面的一段，及属于它的读音。 |
| `FuriganaSegment.isRuby` | getter | B | 该段是否需要注音。 |
| `_readsItself` | 函数 | B | 判断一个字符是否读自己。 |
| `_fold` | 函数 | B | 把字符折成读音里书写它的形式。 |
| `_runs` | 函数 | B | 把表面切成需要读音与不需要读音的段。 |
| [`alignFurigana`](#align) | 函数 | A | 为表面的每一段附上读音。 |
| [`_match`](#match) | 函数 | A | 放置某一段及其后的全部段。 |
| [`readingRangeFor`](#range) | 函数 | A | 找出属于表面某一区间的假名。 |
| [`surfaceReadingOfToken`](#token) | 函数 | A | 按 token 的书写形式而非词元读它。 |
| `_kuruStem` | 函数 | B | 按 token 所处的活用形读 来る 的汉字。 |

## 文档

### `List<FuriganaSegment>? alignFurigana(String surface, String? reading)` <a id="align"></a>

- **种类：** 函数
- **用途：** 为表面的每一段附上读音。
- **输入：** `surface` 为书写形式；`reading` 为假名。
- **返回：** `List<FuriganaSegment>?`——无可行对齐时为 null。
- **副作用：** 无。
- **算法：** 表面被切成两类段：读自己的（假名、标点、空格、测验挖空符）与不读自己的（汉字、数字、拉丁字母、重复符号）。前者是锚点，每一个都必须按顺序恰好出现在读音当前到达的位置；后者每个字至少取一个假名，至多取到后面各段所需之外的部分，先短后长地尝试并回溯，直到读音被完整消耗。
- **用法：** 每一个需要连同读音绘制日语的调用方。
- **说明：** 「完整消耗读音」正是区分 母は/ははは（母 = はは）与 花は/はなは（花 = はな）的依据，局部规则做不到。没有汉字的表面会平凡地对齐成一个无注音的段，因此调用方可以直接传任何词而不必先判断。

### `bool _match(...)` <a id="match"></a>

- **种类：** 函数
- **用途：** 放置第 `index` 段及其后的全部段。
- **输入：** 两个字符串、各段、段下标、读音中已到达的位置、输出列表，以及已被证明失败的状态集合。
- **返回：** `bool`。
- **副作用：** 填充输出列表。
- **算法：** 对段长度做深度优先搜索，并按（段，位置）记忆化。
- **用法：** 仅 `alignFurigana`。
- **说明：** 仅供本文件内部使用的助手。没有记忆化时，搜索随汉字段数呈指数增长，带十几个汉字段的句子会卡住绘制它的那一帧。决定后续搜索的状态只有「第几段」与「读到哪里」，因此失败过一次的组合日后不可能成功。

### `({int start, int end})? readingRangeFor(...)` <a id="range"></a>

- **种类：** 函数
- **用途：** 找出属于表面某一区间的假名。
- **输入：** 已对齐的 `segments`，以及它们所来自表面的一段码元区间。
- **返回：** 读音中的对应区间，或 null。
- **副作用：** 无。
- **算法：** 段边界直接映射；假名段是一个码元对一个码元，因此区间也可以起止于其内部。
- **用法：** `question_generator.dart`，把句子里被挖空的那一段同样从句子读音里挖掉。
- **说明：** 止于汉字段内部的区间没有答案，因为 とうきょう 的一半不是 東 的读音；此时该题不带注音显示，而不是带着一个猜测。

### `String? surfaceReadingOfToken(Token token)` <a id="token"></a>

- **种类：** 函数
- **用途：** 按 token 的书写形式而非词元读它。
- **输入：** `token`。
- **返回：** `String?`——`token.surface` 的读音，或 null。
- **副作用：** 无。
- **算法：** 汉字的读音来自词元与 token 读音的对齐，假名尾巴取自书写形式；来る 由已恢复的活用形判定。
- **用法：** `token_chips.dart`。
- **说明：** token 的读音是辞书形的读音，因此 食べ 带着 たべる——那是去活用所匹配的对象。直接印出来会显示句子里没有的 る。活用链无法判定 来る 时，chip 就不注音，这是诚实的；在学习者正要说 き 的地方印上 く 则不是。
