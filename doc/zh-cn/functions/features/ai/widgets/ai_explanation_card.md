# lib/features/ai/widgets/ai_explanation_card.dart

端侧模型给出的一个回答，或者没有回答的原因。

本应用中生成的一切都显示在这样一张卡片里，每一张都带着同一句标注。这正是这个 widget 的全部意义。

使用方：`sentence_lab_page.dart`。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `AiExplanationCard` | 类 | B | 承载一个生成回答的带标注卡片。 |
| [`build`](#build) | 方法 | A | 构建卡片。 |
| [`messageFor`](#messagefor) | 静态方法 | A | 为学习者措辞一种失败。 |

## 文档

### `Widget build(BuildContext context)` <a id="build"></a>

- **种类：** 方法
- **用途：** 画出标注、标题，以及加载指示、回答或失败说明三者之一。
- **输入：** 构建 context。
- **返回：** `Widget`。
- **副作用：** 无。
- **算法：** 一张 tertiary container 的 `Card`：生成标注与可选的关闭按钮，然后是标题，然后是三种状态之一。
- **使用：** 应用中每一个生成的回答。
- **说明：** 标注放在回答**上方**而不是下方，因为已经读过的文字无法收回——提醒必须先到达才起作用。卡片画在 tertiary container 上，使它明显区别于周围的分节；标注又用文字重复了颜色所表达的意思，因此这个区别对色觉障碍读者和灰度截图同样成立。

### `static String messageFor(AppLocalizations l10n, GenAiFailure? failure)` <a id="messagefor"></a>

- **种类：** 静态方法
- **用途：** 把一种失败、或失败的缺席，变成一句话。
- **输入：** 本地化对象与可选的失败原因。
- **返回：** `String`。
- **副作用：** 无。
- **算法：** 对六种失败加 null 做 switch。
- **使用：** `build`，并可被今后任何生成界面复用。
- **说明：** **null** 失败且没有文本，意味着模型跑了，却没答出可用的东西。它显示为那句通用文案而不是错误，因为说「出错了」会让学习者去找一个并不存在的故障。`cancelled` 共用同一句话则是出于相反的理由：学习者自己离开页面而取消的请求根本不需要解释。
