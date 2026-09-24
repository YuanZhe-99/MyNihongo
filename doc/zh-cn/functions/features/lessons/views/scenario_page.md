# lib/features/lessons/views/scenario_page.dart

一行一行地播放一段情景对话，并在作者标记的位置让学习者选择说什么。它是整窗路由（`/scenario`）而不是标签页：从单元进入，对话结束就离开，和测验一样。

页面只保存三样状态，再无其他——已经显示了多少行、哪个分支正在等待回答、学习者说过什么。不写任何存储。

台词或回复选项下方的译文用 `LocalizedStrings.resolveTranslation` 选取：日语读者在日语下方看不到英文行，也不会在那个位置看到一个空行。

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
| `_ScenarioPageState._saidLine` | 方法 | B | 渲染学习者选择说的那一行；`resolveTranslation` 为这位读者给出译文时，译文显示在它下方。 |
| `_ScenarioPageState.build` | 方法 | B | 构建页面。 |
| `_ScenarioPageState._line` | 方法 | B | 渲染一行台词；`resolveTranslation` 为这位读者给出译文时，译文显示在它下方。 |
| `_ScenarioPageState._onAiChanged` | 方法 | B | 端侧 AI 状态变化时重建。 |
| `_ScenarioPageState._canChat` | getter | B | 模型能否把对话继续下去。 |
| `_ScenarioPageState._partner` | 方法 | B | 学习者在跟谁说话，用脚本给的称呼。 |
| [`_ScenarioPageState._send`](#send) | 方法 | A | 说出学习者打的那句，并取回一句以角色身份的回答。 |
| `_ScenarioPageState._scrollToEnd` | 方法 | B | 让最新一行保持在视野里。 |
| `_ScenarioPageState._composerVisible` | getter | B | 此刻学习者能不能打字说一轮。 |
| `_ScenarioPageState._chatSection` | 方法 | B | 在统计下方构建自由对话。 |
| `_ScenarioPageState._learnerTurn` | 方法 | B | 渲染学习者打的那一行。 |
| `_ScenarioPageState._replyTurn` | 方法 | B | 渲染对方的回话。 |
| `_ScenarioPageState._composer` | 方法 | B | 构建学习者打字用的输入框。 |

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

### `Future<void> _send()` <a id="send"></a>

- **种类：** 方法
- **用途：** 说出学习者打的那句，并取回一句以角色身份的回答。
- **输入：** 无；读取输入框。
- **返回：** `Future<void>`。
- **副作用：** 先后在设备上跑校对与模型，并追加两轮。
- **算法：** 清空输入框并标记为发送中。然后**仅在设备有校对能力时**加载分析器并校对学习者那句——加载一份词库却什么都不用它做，只会把整条回话堵在后面。追加学习者那一轮，于是模型还在写的时候，他自己那句已经在屏幕上。用情景、已有轮次以及本单元的词和语法构建 `forScenarioReply`，交给 `AiPracticeService.run`，解析，然后追加回话或设置失败状态。
- **用法：** 发送按钮，以及输入框自己的提交动作。
- **说明：** **校对先跑并被 await，绝不与回话并行。** AICore 一次只为一个应用提供一次推理，所以与回话并行发出的校对会以 `busy` 返回——而失败的校对会被吞掉，因为对话才是这个功能，缺一条修改建议不值得打断它。

  每个 `await` 之后、任何 `setState` 之前都有一次 `mounted` 检查，这在这里不是例行公事：学习者完全可能在回话还在写的时候离开页面，而一个 widget 测试正是以 `setState() called after dispose()` 抓到了这一点。
