# lib/features/sentence/services/deinflector.dart

把活用后的词干还原成它所来自的词。这是活用还原的第二阶段：词格已经找到了一个助动词，每个助动词都声明了它所接的词干形态，本文件回答它前面的字符可能由哪些目录词条产生。

反向进行正是各表得以保持很小的原因。正向看，每个活用类有十几种形式；反向看，每种形态对每个类只是一次段位变换——而且**词典会否决一切不是词的结果**，因此规则可以放宽。段位表与演算示例见 [../../../../algorithms/sentence-analysis.md](../../../../algorithms/sentence-analysis.md)。

使用方：`tokenizer.dart`。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `DeinflectedStem` | 类 | B | 从活用词干还原出的一个可活用词，附带书写形式的词干。 |
| `Deinflector` | 类 | B | 从活用词干还原出词。 |
| [`stemsFor`](#stemsfor) | 方法 | A | 找出活用词干可能来自哪些词。 |
| `adjectiveStemsFor` | 方法 | B | 从活用词干还原出い形容词。 |
| `_godanFromRow` | 静态方法 | B | 为以已知段位结尾的词干提出五段词元。 |
| [`_teStemGodan`](#testemgodan) | 静态方法 | A | 为て形词干提出五段词元，这是不规则的那一种。 |
| [`_acceptIrregular`](#acceptirregular) | 方法 | A | 接受两个不规则动词，它们不属于任何段位表。 |

## 文档

### `List<DeinflectedStem> stemsFor(String stem, StemShape shape)` <a id="stemsfor"></a>

- **种类：** 方法
- **用途：** 回答一个活用词干可能是哪些词。
- **输入：** 助动词前面的字符，以及该助动词所接的形态。
- **返回：** 所有吻合的目录词条；没有则为空。
- **副作用：** 无。
- **算法：** 按形态分支，提出一段词元、五段段位变换和不规则动词；形容词形态转交 `adjectiveStemsFor`。
- **使用：** `Tokenizer._stemEdges`，以及裸连用形词干边。
- **说明：** 每个候选都要对照词典确认，这正是宽松规则得以安全的原因：一个浊音て形词干会提出三个不同的活用类，只有真正是词的那个能留下。

### `static void _teStemGodan(String stem, {required bool voiced, required void Function(String, Set<ConjClass>) accept})` <a id="testemgodan"></a>

- **种类：** 静态方法
- **用途：** 还原て形，五段动词正是在这里不再规则。
- **输入：** 词干、助动词是否为浊音形，以及接收器。
- **返回：** 无。
- **副作用：** 为词干末尾假名可能所属的每个类调用 `accept`。
- **算法：** 三个五段类塌缩到同一个促音词干上，另外三个塌缩到同一个拨音词干上，再有两个塌缩到同一个い词干上——外加唯一一个て形违背其类别而取促音的动词。
- **使用：** `stemsFor`，两种て形形态都用它。
- **说明：** 提出所有类别并让词典否决非词，比把例外编码进来更短也更诚实：例外清单需要对照目录维护，而目录本来就是权威。

### `void _acceptIrregular(String stem, List<DeinflectedStem> out, {bool masu, bool nai, bool te})` <a id="acceptirregular"></a>

- **种类：** 方法
- **用途：** 还原两个不属于任何段位表的不规则动词。
- **输入：** 词干、输出接收器，以及正在解析哪种形态。
- **返回：** 无。
- **副作用：** 追加到 `out`。
- **算法：** 对每种形态的小词干列表做精确字符串比较，两种写法都涵盖。
- **使用：** `stemsFor`。
- **说明：** 词干必须**精确**匹配。早先的版本用 `endsWith` 判断，于是一段以正确假名结尾的六字跨度被还原成一个不规则动词——一条边以一个词的价钱吞下半句话，而最短路径当然会选它。标注为 `suru-verb` 的名词后面跟着该词干时，改由分块器重新合并：目录里有的是名词，不是复合动词。
