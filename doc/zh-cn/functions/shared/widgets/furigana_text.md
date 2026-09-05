# lib/shared/widgets/furigana_text.dart

日语文本，需要注音的字符上方印出读音，无法这样做的地方则显示纯文本。原先画日语 `Text` 的每一处现在都画它，于是一个偏好从一个文件到达整个应用。

使用方：`reference_widgets.dart`、`content_sheets.dart`、`vocab_page.dart`、`token_chips.dart`、`quiz_runner.dart`、`answer_panes.dart`、`generated_examples.dart`、`scenario_page.dart`。

布局是由固定高度的盒子组成的 `Wrap`，每个词段一个，**不是** `WidgetSpan` 组成的 `Text.rich`。一个装着两行 Column 的 span 会把*注音*那一行的基线当成自己的基线，于是夹在汉字之间的假名与注音对齐，整个词渲染成互不相干的两行。每个盒子都预留同样的两个槽位——注音行在上，正文行在下——所以把它们的顶部对齐，就能让每个正文字符落在同一高度，无论它的字形量出来是多少。

两处预留都是精确的，因为**两个槽位都强制了 strut**。这是本文件的第二个 bug，2026-09-04 在 Pixel 10 上发现：注音槽位原先按 `rubyScale × 1.15` 预留——这是在猜「字体的 ascent 加 descent 装得进 1.15 em」——而且没有 strut 把它固定在那个高度上。应用不自带字体，日语来自系统 CJK 字体，它需要约 1.4；而 `SizedBox` 只约束不裁剪，段落又从顶部开始绘制，于是多出来的部分落到了词上面。正文槽位从来没有这个问题，它从写下的那天起就强制了自己的 strut。

字号通过 `MediaQuery.textScalerOf` 读取，因为 `fontSize` 只是样式提出的要求，引擎绘制的是缩放后的值。按标称值预留是同一个 bug 的另一半，也是部件测试能够守住的那一半——测试字体的度量正好是 1.0 em，所以字体度量那一半只有在真机上才能重现。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `FuriganaText` | 类 | B | 汉字上方带读音的日语文本。 |
| [`FuriganaText.build`](#build) | 方法 | A | 构建注音文本，或纯文本。 |
| `_pieces` | 函数 | B | 把对齐结果切成一行所需的那些盒子。 |
| `_RubyBox` | 类 | B | 一段正文，以及上方为它预留的读音。 |
| `_RubyBox.build` | 方法 | B | 两个固定槽位，读音在上，正文在下。 |
| `rubyLineHeight` | 常量 | B | 读音行盒的高度，相对于读音自身字号的倍数。 |
| `baseLineHeight` | 常量 | B | 调用方样式未指定时，正文行的高度。 |

## 文档

### `Widget build(BuildContext context, WidgetRef ref)` <a id="build"></a>

- **种类：** 方法
- **用途：** 构建注音文本；无法构建时构建纯文本。
- **输入：** 构建上下文与 ref；部件的 `text`、`reading`、`style`、`rubyScale`、`forceOff` 与 `bracketFallback`。
- **返回：** `Widget`。
- **副作用：** 无。
- **算法：** 在 `forceOff` 打开、偏好关闭、对齐器返回 null 或没有可印内容时，退回纯 `Text`。否则：用观看者的文本缩放系数缩放基准字号，由它导出注音样式，为读音预留 `rubySize × rubyLineHeight`、为词预留 `size × height`，再把每个词段的一个 `_RubyBox` 放进顶部对齐的 `Wrap`。
- **使用：** 任何显示日语且有读音可用的地方。
- **说明：** 对齐在 build 里重新计算而不缓存：它是两个短字符串的纯函数，内部已有记忆化，比缓存所需的管道更便宜。`forceOff` 用于读音本身就是问题的地方——测验问一个词怎么读时，不能把答案印在它上面。`bracketFallback` 用于那些纯文本形式原本就用括号显示读音的地方，这样关掉注音时得到的正是原来的样子，而不是丢掉读音。**整个字符串是该部件的语义标签**，所以读屏软件念出的是词而不是它的碎片；`find.text` 则不然，测试改为匹配部件本身。
