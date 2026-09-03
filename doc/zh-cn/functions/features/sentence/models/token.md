# lib/features/sentence/models/token.dart

分析器找到的一个词，以及描述它的两个枚举：它是哪一类词，以及它在语法上经历了什么。

`TokenCategory` 刻意比目录的 23 个词性标注更粗——它是分块器和语法匹配器分支所依据的东西，也是色块着色的依据。原始标注保留在词元上，供需要它们的检查使用。`InflectionForm` 是一条**链**，最内层在前，因此使役被动敬体否定过去会读作五个步骤，而不是一个不透明的标签。

使用方：`features/sentence/` 下的每个文件，以及 `token_chips.dart`。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `TokenCategory` | 枚举 | B | 词元是哪一类词：24 个值，归入 UI 命名的六组。 |
| `InflectionForm` | 枚举 | B | 活用还原得到的一种语法形式。 |
| `Token` | 类 | B | 一个词，带表层、读音、词元、类别、标注、形式、id 与跨度。 |
| `Token.isParticle` | getter | B | 是否是任意一种助词。 |
| `Token.isPredicateHead` | getter | B | 是否能充当谓语中心。 |
| `Token.isNominal` | getter | B | 是否能充当名词短语中心。 |
| [`Token.attachesLeft`](#attachesleft) | getter | A | 是否依附于它前面的词。 |
| `Token.toString` | 方法 | B | fixture 呈现：表层、类别与形式链。 |

## 文档

### `bool get attachesLeft` <a id="attachesleft"></a>

- **种类：** getter
- **用途：** 判断一个词元是否属于已经打开的文节。
- **输入：** 无。
- **返回：** 助词、系动词、助动词、助动词性动词与后缀为 `true`。
- **副作用：** 无。
- **算法：** 一次类别判断。
- **使用：** `Chunker._joins` 与 `Chunker._build`。
- **说明：** 这是文节分组的全部依据：助词属于它前面的词并随之移动，这也正是日语依存关系描述在文节之间而非词之间的原因。它**没有**覆盖的三种情况——数字之后的量词、`suru-verb` 名词之后的动词 する、て形之后的动词——是位置性而非词汇性的，因此由分块器在手握相邻词元时判断。
