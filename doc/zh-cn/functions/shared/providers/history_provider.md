# lib/shared/providers/history_provider.dart

句子实验室与写作练习的历史记录，从进度文件派生而来，使两个页面可以同步读取，而不必在 build 方法里加载文件。

使用方：`sentence_lab_page.dart`、`writing_practice_page.dart`。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| 库头 | 库文档 | B | 进度文件中历史记录的两个派生视图。 |
| [`labHistoryProvider`](#labhistoryprovider) | provider | A | 实验室中每一条被记住的句子，最新的在前。 |
| [`writingHistoryProvider`](#writinghistoryprovider) | provider family | A | 某个单元下每一份被记住的写作。 |

## 文档

### `labHistoryProvider` <a id="labhistoryprovider"></a>

- **种类：** `Provider<List<HistoryEntry>>`
- **用途：** 给句子实验室提供它的历史记录。
- **输入：** `progressDataProvider`。
- **返回：** `lab:` 条目，最新的在前；文件仍在加载或读不出来时为空。
- **副作用：** 自身无。
- **算法：** 通过 `asData` 读取进度数据，再对 `HistoryKind.lab` 调用 `historyEntries`。
- **用法：** 实验室页面监听它；在此写入的条目、从备份恢复的条目、从另一台设备同步进来的条目，都以同一条路径到达这个列表。
- **注意：** 用普通 `Provider` 而不是 notifier，与 `learnerProfileProvider` 形状相同：进度文件才是状态，这里只是它的函数，因此没有第二处需要保持同步的事实来源。它通过 **`asData` 而不是 `value`** 读取——在 riverpod 1.x 中，当文件加载失败时 `value` 会*重新抛出*，那会让每一个显示历史的页面崩掉，而不是显示一份空列表。存储读不出来的设备有比空历史更大的麻烦，而它上面的页面仍然能用。

### `writingHistoryProvider` <a id="writinghistoryprovider"></a>

- **种类：** `Provider.family<List<HistoryEntry>, String?>`
- **用途：** 给一个写作练习提供属于它自己的历史记录。
- **输入：** `progressDataProvider`；单元 id 作为 family 参数。
- **返回：** 该单元的 `writing:` 条目，最新的在前。
- **副作用：** 自身无。
- **算法：** 同上，再按 `unitId` 收窄。
- **用法：** 写作页面以 `widget.prompt.unit?.id` 监听它。
- **注意：** 以单元为键，因为一个写作题目是关于它自己那个单元的，旁边的历史也应当是为*这个*练习写下的东西，而不是曾经写过的一切。family 参数为 null 时返回不过滤的列表，这正是在单元之外打开的题目会得到的结果。
