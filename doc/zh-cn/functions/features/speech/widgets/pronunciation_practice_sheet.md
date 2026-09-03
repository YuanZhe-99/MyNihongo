# lib/features/speech/widgets/pronunciation_practice_sheet.dart

练习表：读出词条，看看哪些音拍对上了。从词汇与假名详情表上的麦克风按钮进入，也可从例句行溢出菜单中的**练习**进入。

它是模态而非页面，理由与详情表相同：练习是针对你正在看的词条做的事，回到它不该需要任何导航。在任何窗口尺寸下都是单列，宽度上限为 `pageMaxContentWidth`——它只包含一行目标、一个按钮和一排音拍色块，这些都不值得分栏。

使用方：`content_sheets.dart`、`example_actions.dart`。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `PracticeTarget` | 类 | B | 正在练习的内容：显示的形态，以及据以评分的假名。 |
| [`showPronunciationPracticeSheet`](#showsheet) | 顶层函数 | A | 为一个词条打开练习表。 |
| `_PracticeSheet` | 类 | B | 表本身。 |
| `_PracticeSheetState.initState` | 方法 | B | 重置共享的识别器并订阅它。 |
| `_PracticeSheetState.dispose` | 方法 | B | 取消任何会话并退订。 |
| `_onSpeechChanged` | 方法 | B | 重建，并在结果最终确定后计分。 |
| [`_startListening`](#startlistening) | 方法 | A | 开始录音，必要时先说明麦克风用途。 |
| `_PracticeSheetState.build` | 方法 | B | 按会话所处状态构建表。 |
| `_buildControl` | 方法 | B | 构建录音按钮和实时的部分转写。 |
| `_buildResult` | 方法 | B | 构建音拍差异、分数和听到的内容。 |
| `_moraChip` | 方法 | B | 渲染一个对齐后的音拍。 |
| `_legend` | 方法 | B | 渲染一条图例。 |
| `_colorsFor` | 方法 | B | 为一种音拍状态选取背景色与前景色。 |
| `_failureMessage` | 方法 | B | 把识别失败转成学习者可以据以行动的内容。 |

## 文档

### `Future<void> showPronunciationPracticeSheet(BuildContext context, PracticeTarget target)` <a id="showsheet"></a>

- **种类：** 顶层函数
- **用途：** 为一个假名、单词或句子打开发音练习。
- **输入：** `context`，以及带有显示形态和假名读音的目标。
- **返回：** 表关闭时完成。
- **副作用：** 呈现一个模态底部表，学习者开始录音后会打开麦克风。
- **算法：** 一个带拖动手柄、可滚动控制的 `showModalBottomSheet`。
- **使用：** 详情表上的麦克风按钮，以及例句的溢出菜单。
- **说明：** 用于评分的是目标的 `reading`，因此调用方传的是目录中的假名而不是汉字表层。表在 `dispose` 中取消任何进行中的会话，因此被关掉的表会关闭麦克风，而不是把分数交给一个已经不在的界面。

### `Future<void> _startListening()` <a id="startlistening"></a>

- **种类：** 方法
- **用途：** 在说明为何需要麦克风之后开始录音。
- **输入：** 无。
- **返回：** 无。
- **副作用：** 可能弹出对话框；打开麦克风。
- **算法：** 当权限尚未授予且本次会话还未展示过说明时，先展示说明，除非学习者选择继续否则停止。随后请求服务开始聆听。
- **使用：** 录音按钮。
- **说明：** `PLAN.md` M2.2 要求麦克风在首次使用时带理由申请，绝不在安装时申请。说明在平台弹窗**之前**出现，因此系统对话框绝不会毫无解释地弹出；一旦权限已存在便完全跳过——每次都展示的说明只是噪声。
