# lib/features/speech/services/pronunciation_scorer.dart

以音拍为单位，把一次朗读尝试与词条本身作对照。纯函数、确定性、离线；在这里的一切运行之前，识别器已经决定了自己听到了什么。

完整推导——为什么用音拍、为什么分母是目标长度、为什么差异在前分数在后——见 [../../../../algorithms/pronunciation-scoring.md](../../../../algorithms/pronunciation-scoring.md)。本页记录的是各项声明。

使用方：`pronunciation_practice_sheet.dart`。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `MoraOp` | 枚举 | B | 一个音拍上发生了什么：correct、substituted、missing、extra。 |
| `MoraDiff` | 类 | B | 一个对齐后的音拍，练习表就是这样显示它的。 |
| `PronunciationResult` | 类 | B | 分数、差异，以及参与对照时两侧的形态。 |
| `PronunciationScorer` | 类 | B | 把一次尝试与一个目标作对照。 |
| [`score`](#score) | 方法 | A | 为一次尝试对一个目标计分。 |
| `_resolve` | 方法 | B | 经由词典把识别器的答案化为可比较的平假名。 |
| [`_align`](#align) | 静态方法 | A | 对齐两个音拍序列并报告每一次操作。 |

## 文档

### `PronunciationResult score({required String target, required String heard})` <a id="score"></a>

- **种类：** 方法
- **用途：** 为一次尝试产出差异和分数。
- **输入：** `target`——词条的假名读音；`heard`——识别器的答案，字体由它自己决定。
- **返回：** `PronunciationResult`。
- **副作用：** 无。
- **算法：** 用 `toHiragana` 规范化目标；尝试一侧先过一遍词典，因为当词条写作汉字时 Android 也会答汉字。把两侧切成音拍、对齐，然后 `round(100 x (1 - 编辑数 / max(目标音拍数, 1)))` 并夹到 0…100。
- **使用：** 练习表，在识别器给出最终结果之后。
- **说明：** 分母是**目标**长度，因此多余音拍会被扣分，同时也不会让一长串胡言乱语超过零分——夹取负责这一点。空白尝试得 0 分且每个目标音拍都报缺失，不过实际中服务会在到达此处之前报告 `noMatch` 失败。

### `static List<MoraDiff> _align(List<String> target, List<String> heard)` <a id="align"></a>

- **种类：** 静态方法
- **用途：** 产出展示给学习者的逐音拍对齐。
- **输入：** 两个音拍列表。
- **返回：** 按目标顺序排列的 `List<MoraDiff>`。
- **副作用：** 无。
- **算法：** 一个 Levenshtein 矩阵加回溯。规模很小——一个长例句也只有几十个音拍——因此平方级矩阵不值得优化。
- **使用：** `score`。
- **说明：** **回溯遇到平局时优先取替换**，而不是一次删除加一次插入，这样说错一个音拍的学习者看到的就是一个错误音拍，而不是一处删除挨着一处新增。正是这一偏好让差异变得可读，也正是这里不直接取用现成库、而把回溯写出来的原因。
