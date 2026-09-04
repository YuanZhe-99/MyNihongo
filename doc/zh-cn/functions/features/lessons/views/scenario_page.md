# lib/features/lessons/views/scenario_page.dart

一行一行地播放一段情景对话，并在作者标记的位置让学习者选择说什么。它是整窗路由（`/scenario`）而不是标签页：从单元进入，对话结束就离开，和测验一样。

页面只保存三样状态，再无其他——已经显示了多少行、哪个分支正在等待回答、学习者说过什么。不写任何存储。

使用方：`router.dart`（`/scenario`）、`lesson_path_view.dart`（推入它的按钮）。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `ScenarioArgs` | 类 | B | 路由携带的内容：一个情景和它所属的单元。 |
| `ScenarioArgs.new` | 构造函数 | B | 保存两者。 |
| `ScenarioPage` | 组件 | B | 显示一段对话。 |
| `ScenarioPage.new` | 构造函数 | B | 保存参数。 |
| `_ScenarioPageState._advance` | 方法 | B | 显示下一行，或它之前的分支。 |
| [`_ScenarioPageState._choose`](#choose) | 方法 | A | 记录回答并继续。 |
| `_ScenarioPageState._saidLine` | 方法 | B | 渲染学习者选择说的那一行。 |
| `_ScenarioPageState.build` | 方法 | B | 构建页面。 |
| `_ScenarioPageState._line` | 方法 | B | 渲染一行台词。 |

## 文档

### `void _choose(ScenarioChoice choice)` <a id="choose"></a>

- **种类：** 方法
- **用途：** 记录学习者选的回答，让对话继续下去。
- **输入：** `choice`。
- **返回：** 无。
- **副作用：** 重建。
- **算法：** 把选项以该分支的 `after` 为键存进 `_said`，并清空 `_asking`。这个键正是把回答放回它被说出的位置的东西——把它丢掉的记录读起来就像对方自顾自地说下去。结尾的统计读 `_said.values`。
- **用法：** `build` 里的选项按钮。
- **备注：** **选错不会结束对话，也不会让对话分叉。** 脚本是线性的；学习者说了什么只改变结尾的统计，别的什么都不改。说错一句就中断的对话，教不会人该说什么；而按选项分叉的脚本，每条分叉都要写、都要过门禁——那是每个单元都要付的内容成本，而这堂课的意义恰恰在于读一段真实的交流。

  这里不碰调度器。从三个选项里挑一个不是回忆，回忆是在单元自己的练习会话里测量的——见 [`learning-progress.md`](../../../../features/learning-progress.md)。
