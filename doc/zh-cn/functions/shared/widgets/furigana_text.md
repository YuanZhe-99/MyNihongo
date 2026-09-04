# lib/shared/widgets/furigana_text.dart

带读音的日语文本：能注音处把读音印在需要它的字上方，不能注音处按普通文本绘制。原先用 `Text` 绘制日语的每一处都改用它，于是一个偏好从一个文件抵达全应用。

使用方：`reference_widgets.dart`、`content_sheets.dart`、`vocab_page.dart`、`token_chips.dart`、
`quiz_runner.dart`。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `FuriganaText` | 类 | B | 读音印在汉字上方的日语文本。 |
| [`FuriganaText.build`](#build) | 方法 | A | 构建注音文本，或普通文本。 |
| `_Ruby` | 类 | B | 一段汉字及其上方的假名。 |
| `_Ruby.build` | 方法 | B | 把一条读音叠在一段字符之上。 |
| `_tight` | 常量 | B | 不让注音行额外增加行距。 |

## 文档

### `Widget build(BuildContext context, WidgetRef ref)` <a id="build"></a>

- **种类：** 方法
- **用途：** 构建注音文本；无法构建时构建普通文本。
- **输入：** 构建上下文与 ref；组件的 `text`、`reading`、`style`、`rubyScale`、`forceOff` 与 `bracketFallback`。
- **返回：** `Widget`。
- **副作用：** 无。
- **算法：** 设了 `forceOff`、偏好为关、对齐器返回 null 或没有可注音之处时，退回普通 `Text`。否则构建 `Text.rich`：汉字段是承载两行 `Column` 的 `WidgetSpan`，按表意基线对齐以使正文仍落在行上；假名段仍是普通 `TextSpan`，于是句子仍可在其间换行。
- **用法：** 任何显示日语且有读音可用之处。
- **说明：** 对齐在 build 里重算而不缓存：它是两个短字符串的纯函数，内部已记忆化，比缓存所需的管线更省。`forceOff` 用于读音本身即答案之处——问一个词怎么读的测验，不能把答案印在它上方。`bracketFallback` 用于原本就把读音写在括号里的地方，这样关掉注音后得到的正是从前的样子，而不是丢掉读音。**整串文本是该组件的语义标签**，因此读屏软件读到的是这个词而不是它的碎片；测试里的 `find.text` 读不到，所以测试改为匹配组件本身。
