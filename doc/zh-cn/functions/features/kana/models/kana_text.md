# lib/features/kana/models/kana_text.dart

把日语文本化为可比较的平假名，并切分成音拍。它是为发音评分而写的：在那里，对照的两侧本就会以不同字体到达——识别器视平台答以片假名或汉字，而目录保存的是平假名读音。

本模块只依赖 `dart:core`，因此每条规则都可直接单元测试（`test/kana_text_test.dart`）。规则本身的推导见 [../../../../algorithms/pronunciation-scoring.md](../../../../algorithms/pronunciation-scoring.md)。

使用方：`pronunciation_scorer.dart`、`lexicon.dart`。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| [`toHiragana`](#tohiragana) | 顶层函数 | A | 把日语字符串化为纯平假名。 |
| [`splitMorae`](#splitmorae) | 顶层函数 | A | 把平假名切分成音拍。 |
| `_isDroppable` | 顶层函数 | B | 判断一个字符是否不承载发音。 |
| `_Characters.characters` | 扩展 getter | B | 逐码位遍历字符串。 |

## 文档

### `String toHiragana(String text)` <a id="tohiragana"></a>

- **种类：** 顶层函数
- **用途：** 把对照的两侧化为同一种形态。
- **输入：** 平假名、片假名、汉字、ASCII 与各类符号的任意混合。
- **返回：** 平假名，汉字保持原样。
- **副作用：** 无。
- **算法：** 全角 ASCII 转 ASCII；长音符转为前一音拍的元音；片假名按码位偏移转平假名；空白与标点丢弃。
- **使用：** `PronunciationScorer.score`、`Lexicon.build` 与 `Lexicon.byReading`。
- **说明：** **汉字刻意不动。** 本函数读不了汉字；需要汉字表层对应假名的调用方先经 `Lexicon.toKana` 解析，而未能解析的汉字会进入音拍列表并消耗一次编辑，而不是凭空消失。

### `List<String> splitMorae(String hiragana)` <a id="splitmorae"></a>

- **种类：** 顶层函数
- **用途：** 产出发音实际被评分的单位。
- **输入：** [`toHiragana`](#tohiragana) 的输出。
- **返回：** 每个音拍一个条目。
- **副作用：** 无。
- **算法：** 小书假名并入它前面的音拍；其余一律另起一拍。
- **使用：** `PronunciationScorer.score`。
- **说明：** 促音与拨音**不在**小书假名集合中，这是刻意的：两者都是完整音拍，漏掉任何一个正是评分要指出的错误，因此必须有代价。
