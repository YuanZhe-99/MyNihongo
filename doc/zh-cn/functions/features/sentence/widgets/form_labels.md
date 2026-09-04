# lib/features/sentence/widgets/form_labels.dart

用学习者的语言为活用形命名。

句子实验室的 token 芯片此前在所有语言下都把它们打印为 Dart 枚举名——`polite + negative`——这对英文读者是英文，对中文读者则什么都不是。在 M3.2 修复，当时活用测验本来也需要给形式命名。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| [`formLabel`](#formlabel) | 顶层函数 | A | 为一种活用形命名。 |
| `formChainLabel` | 顶层函数 | B | 为整条已恢复的形式链命名。 |

## 文档

### `String formLabel(AppLocalizations l10n, InflectionForm form)` <a id="formlabel"></a>

- **种类：** 顶层函数
- **用途：** 用学习者的语言为活用形命名。
- **输入：** `l10n` 与该形式。
- **返回：** `String`。
- **副作用：** 无。
- **算法：** 对全部 22 个值做穷尽 switch。
- **使用：** 句子实验室的 token 芯片，以及活用测验的题面。
- **说明：** 刻意做成穷尽的——新增一个没有名字的 `InflectionForm` 会是编译错误，而不是让一个英文单词出现在中文界面里。**交给端侧模型的提示词仍然使用枚举名**：那段文字是给模型读的而不是给人读的，而英文名正是它训练时见过的。
