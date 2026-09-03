# lib/shared/widgets/example_actions.dart

一个例句旁边的控件。目前只有朗读按钮；之所以独立成文件，是因为第二阶段其余部分会带来更多逐例句的动作——练习该句、在句子实验室中打开——而三个图标按钮排成一行放不进手机宽度的例句。

使用方：`reference_widgets.dart` 中的 `exampleList`，词汇与语法详情表共用它。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `ExampleActions` | 类 | B | 一个例句旁边的控件。 |
| [`ExampleActions.build`](#build) | 方法 | A | 构建逐例句的控件。 |

## 文档

### `Widget build(BuildContext context)` <a id="build"></a>

- **种类：** 方法
- **用途：** 渲染该例句的动作。
- **输入：** 构建 context；widget 的 `example`。
- **返回：** `Widget`。
- **副作用：** 点击前无。
- **算法：** 一个 `SpeakButton`，朗读例句的假名 `reading`，缺失时回退到表层文本。
- **使用：** `exampleList` 中每个例句行一个。
- **说明：** 传读音而非表层文本，正是阻止引擎猜测汉字读法的关键。后续动作会放进溢出菜单；朗读按钮保持内联，因为它是最常用的一个。
