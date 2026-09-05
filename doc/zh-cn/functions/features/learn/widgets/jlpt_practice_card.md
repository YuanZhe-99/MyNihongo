# lib/features/learn/widgets/jlpt_practice_card.dart

学习标签页通往 JLPT 练习的入口：每个部分一行、继续一份保存的考试的提议，以及模拟考试与结果两个按钮——现在两个都能用了，分别通往 `/exam` 与 `/exam-history`。

它取代了此前预告这件事的路线图卡片。一张说某功能即将到来的卡片，应该在真正发布它的那个版本里被删掉，否则应用就是在向一个已经在用这东西的学习者做广告。

整张卡片被包在一个针对 `TtsService.instance.ready` 的 `ValueListenableBuilder` 里。在首次构建时读 `hasJapaneseVoice`，在每一台设备上得到的都是「没有」，因为探测还没有跑——而这张卡片于是会告诉一台 Pixel 它做不了听力练习，并且再也不收回。现在 `build` 只剩那个包装，`_card` 才是卡片，拆出来只是为了让那个 listenable 能包住它。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `JlptPracticeCard` | 类 | B | 学习标签页通往 JLPT 练习的入口。 |
| [`build`](#build) | 方法 | A | 把卡片包进语音引擎的就绪状态里。 |
| [`_card`](#card) | 方法 | A | 构建练习行、保存的考试的提议，以及模拟考试与结果按钮。 |
| [`_startMock`](#startmock) | 方法 | A | 开始一场新的模拟考试，如果已经保存了一份就先询问。 |
| `_discard` | 方法 | B | 扔掉保存的考试，在一个说明什么会留下的对话框之后。 |
| [`_sectionRow`](#row) | 方法 | A | 渲染某一个部分的练习行。 |
| `_icon` | 方法 | B | 为一个部分挑一个图标。 |
| `DrillSectionLabel` | 扩展 | B | 用学习者的语言为部分命名。 |
| `drillSectionName` | 方法 | B | 为一个部分命名，穷尽 `DrillSection` 的所有取值。 |

## 文档

### `Widget build(BuildContext context, WidgetRef ref)` <a id="build"></a>

- **种类：** 方法
- **用途：** 在语音引擎的就绪状态已知之后构建这张卡片。
- **输入：** `context`、`ref`。
- **返回：** 当前状态对应的组件树。
- **副作用：** 根据当前状态创建 UI 组件。
- **算法：** 读取学习者的目标级别并为它监听 `drillLevelProvider`，然后返回一个针对 `TtsService.instance.ready` 的 `ValueListenableBuilder`，它的 builder 就是 `_card`。
- **使用：** `learn_page.dart`。
- **说明：** 保持这个方法开销小，因为 Flutter 可能会频繁调用它。级别来自学习者自己的目标，而不是这张卡片上的选择器：它已经是一项设置了，而同一件事有两个地方能改，正是它们后来不一致的由来。

  这个 listenable 是对一个由设备发现的 bug 的修复。在语音探测跑完之前 `TtsService.hasJapaneseVoice` 是 false，而「因为还没问所以是 false」与「因为确实没有所以是 false」并不是同一个回答。在首次构建时读它，会告诉一台 Pixel 它做不了听力练习，并让它一直这么说着；监听 `ready` 则意味着引擎真正给出回答时卡片会重建。见 [`../../speech/services/tts_service.md`](../../speech/services/tts_service.md)。

### `Widget _card(…, bool ready)` <a id="card"></a>

- **种类：** 方法
- **用途：** 构建练习行、保存的考试的提议，以及它们下方的两个按钮。
- **输入：** `context`、`ref`、`l10n`、`theme`、`level`、已加载时它的 `files`，以及引擎是否已经被问过的 `ready`。
- **返回：** `Widget`。
- **副作用：** 在控件被使用之前没有；这些控件会压入路由、清掉保存，或打开一个对话框。
- **算法：** 在 `!ready` 期间把 `hasVoice` 当作 true，然后是一个 `Card`，里面放着标题、正文那一行、每个 `DrillSection` 取值一个 `_sectionRow`、一条分隔线、`savedExamProvider` 有卷子时的「继续／放弃」这一对，最后是模拟考试与结果按钮。
- **使用：** `build`，经由那个 `ValueListenableBuilder`。
- **说明：** 仅在本文件内部使用的辅助函数。拆出来只是为了让那个 listenable 包住它；理由全都写在 `build` 里。

  没有随包发布文件的部分是**禁用并把原因写在旁边**，而不是隐藏：一个找不到読解练习的学习者没有办法判断究竟是它不存在，还是自己没找到。同一条规则也适用于没有日语语音的设备上的听力——但在探测给出回答之前，听力算作「仍在加载」，所以这一行不会作出它还没有核实过的断言。

  保存的考试会**先于**新的考试被提出来。无论哪种，开始一场新的模拟考试都只有一次点击之遥，但一个半小时前放下一份卷子的学习者不该还得自己记着它的存在。那一行写出级别、这一部分和剩余的分钟数，全都直接读自那份保存，不必碰内容文件。

  结果按钮也不再是禁用的了：它会打开 `/exam-history`，在第一份卷子作答之前，那里是空的，而不是不存在。

### `Future<void> _startMock(BuildContext context, WidgetRef ref, AppLocalizations l10n, JlptLevel level)` <a id="startmock"></a>

- **种类：** 方法
- **用途：** 开始一场新的模拟考试，如果已经保存了一份就先询问。
- **输入：** `context`、`ref`、`l10n`、`level`。
- **返回：** 无。
- **副作用：** 可能清掉保存的考试并刷新 `savedExamProvider`；导航到 `/exam`。
- **算法：** 先捕获路由器。有保存的考试时，询问是否要替换它，回答是否定的就返回；否则清掉保存并刷新 provider。然后带着这个级别的一个 `ExamConfig` 压入 `/exam`。
- **使用：** 模拟考试按钮。
- **说明：** 仅在本文件内部使用的辅助函数。每台设备只有一份保存的考试，所以开始第二份就得替换掉第一份。这值得先问一句：学习者可能已经忘了有一份卷子做了一半，而它是这里唯一一件找不回来的东西。

  **经由路由器，而不是经由本地的 navigator。** `/exam` 注册在标签页外壳之外，而在这里压入一个 `MaterialPageRoute` 会把一个走着的计时摆在一条邀请学习者离开的导航栏之上。路由器是在对话框之前捕获的，而不是跨着 await 去取。

  它旁边的 `_discard` 是同样的形状，只是没有导航，而它的对话框会说明什么会留下：已经作答过的每一道题当时都已经过了调度器，所以放弃这份卷子丢掉的是卷子，不是学习。

### `Widget _sectionRow(BuildContext context, AppLocalizations l10n, ThemeData theme, {…})` <a id="row"></a>

- **种类：** 方法
- **用途：** 渲染某一个部分的练习行。
- **输入：** `context`、`l10n`、`theme`；`level`、`section`、已加载时的 `file`、这一行是否仍在 `loading`，以及 `hasVoice`。
- **返回：** `Widget`。
- **副作用：** 点击时压入测验路由。
- **算法：** 一个部分在它的文件有题目、且不是在无声设备上的听力时才算就绪。就绪的一行显示它的题目数量，并带着该级别与部分的 `DrillSource` 压入 `/quiz`；未就绪的一行被禁用，并说明原因。
- **使用：** `_card`，每个 `DrillSection` 取值一次。
- **说明：** 仅在本文件内部使用的辅助函数。之所以显示数量，是因为它是衡量一个部分能提供什么的诚实尺度：「20 道题」和「120 道题」是不一样的提议，而正在挑选练什么的学习者有权知道自己拿到的是哪一个。文件还在加载时既没有原因也没有数量，所以这一行不会在拿到内容之前先闪一下「没有内容」——而听力在语音探测给出回答之前一直算作加载中，理由相同。
