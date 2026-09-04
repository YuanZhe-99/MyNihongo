# lib/features/lessons/models/scenario.dart

单元末尾可以带的情景对话，从 `assets/content/lessons/*.json` 里某个单元的 `scenario` 块解析而来。一个情景就是一段脚本加若干选择点，别无其他：没有状态、没有计分规则、不碰存储。怎么用由页面决定。

这里对畸形行的容忍度与目录其余部分一致。没有日文的行被丢掉而对话本身保留；只有一个选项的分支整个丢掉，因为一个选项算不上选择；没有台词的情景解析为 null，于是单元上不显示按钮，而不是打开一个空页面。

使用方：`lesson_path.dart`、`scenario_page.dart`、`lesson_path_view.dart`。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `_list` | 函数 | B | 读取可能缺失或类型不对的列表。 |
| `Scenario` | 类 | B | 一段情景对话。 |
| `Scenario.new` | 构造函数 | B | 保存标题、台词与分支。 |
| [`Scenario.branchAfter`](#branch) | 方法 | A | 找到脚本某处之后的分支。 |
| `Scenario.fromJson` | 静态方法 | B | 解析一个情景；没有可播放内容时为 null。 |
| `DialogueLine` | 类 | B | 对话中的一行。 |
| `DialogueLine.new` | 构造函数 | B | 保存说话人、日文、读音与译文。 |
| `DialogueLine.fromJson` | 静态方法 | B | 解析一行；没有日文时为 null。 |
| `ScenarioBranch` | 类 | B | 让学习者选择说什么的位置。 |
| `ScenarioBranch.new` | 构造函数 | B | 保存先播放几行，以及各个选项。 |
| `ScenarioBranch.fromJson` | 静态方法 | B | 解析一个分支；不足两个选项时为 null。 |
| `ScenarioChoice` | 类 | B | 学习者可以说的一句话。 |
| `ScenarioChoice.new` | 构造函数 | B | 保存这句话以及它是否是期望的回答。 |
| `ScenarioChoice.fromJson` | 静态方法 | B | 解析一个选项；没有日文时为 null。 |

## 文档

### `ScenarioBranch? branchAfter(int index)` <a id="branch"></a>

- **种类：** 方法
- **用途：** 找到脚本某处之后的分支。
- **输入：** `index`——已经显示了多少行。
- **返回：** `ScenarioBranch?`；脚本直接继续时为 null。
- **副作用：** 无。
- **算法：** 在 `branches` 里线性查找 `after` 相等的一项。一个情景只有一到两个分支，建索引的开销比省下的还多，而且这个列表解析之后再也不变，索引还得跟着维护。
- **用法：** `scenario_page.dart`，在 `initState`（这样第 1 行之后的分支会在出现"下一句"按钮之前先问）和 `_advance` 里各调用一次。
- **备注：** `after` 是**已显示的行数**，不是从零开始的下标。`after: 2` 表示读完两行之后才问，这也是作者在纸上数一段对话的方式。内容门禁会检查它落在脚本范围之内。
