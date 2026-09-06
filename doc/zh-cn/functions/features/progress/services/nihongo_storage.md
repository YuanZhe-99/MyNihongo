# lib/features/progress/services/nihongo_storage.dart

`NihongoStorage` 是应用的存储中枢：唯一知道数据在磁盘上何处的地方。它解析应用目录（平台文档目录加 `MyNihongo`，或 `storage_config.json` 中的自定义路径），通过包里的 `atomicWriteString` 原子地读写 `nihongo_progress.json` 和 `storage_config.json`，在每次数据保存后通知自动同步，并在存储路径改变时迁移整个文件夹。共享引擎使用的 `StorageAdapter` 委托给它（见 [../../../app/data_modules.md](../../../app/data_modules.md)）。见 [../../../../data-formats.md](../../../../data-formats.md) 和 [../../../../features/learning-progress.md](../../../../features/learning-progress.md)。

M3.0 在 `ttsVoice` 旁增加了 `ttsEngine` 偏好；两者都是设备本地的，从不同步，因为语音名称与引擎包名在另一台设备上都毫无意义。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `NihongoStorage._getDefaultAppDir` | 静态方法 | B | 解析 `<documents>/MyNihongo`，不存在时创建。 |
| `NihongoStorage._getConfigFile` | 静态方法 | B | 定位始终位于默认目录的 `storage_config.json`。 |
| `NihongoStorage._loadConfig` | 静态方法 | B | 从配置文件加载自定义存储路径，仅一次。 |
| `NihongoStorage.getAppDir` | 静态方法 | B | 解析活动的应用数据目录——设置了则为自定义路径，否则为默认。 |
| `NihongoStorage._getFile` | 静态方法 | B | 定位应用目录内的文件。 |
| `NihongoStorage.getDataFile` | 静态方法 | B | 返回进度数据文件以供直接低层访问。 |
| `NihongoStorage.getStoragePath` | 静态方法 | B | 返回活动存储目录路径以供 UI 显示。 |
| [`NihongoStorage.setStoragePath`](#setstoragepath) | 静态方法 | A | 更改存储目录并把数据迁移过去。 |
| [`NihongoStorage.load`](#load) | 静态方法 | A | 加载进度数据文件；缺失或空白时为空，损坏时抛出。 |
| [`NihongoStorage.save`](#save) | 静态方法 | A | 原子写入进度数据文件并通知自动同步。 |
| `NihongoStorage.upsertRecords` | 静态方法 | B | 按 id 插入或替换学习记录，把容器的 `extraJson` 带过去。 |
| [`NihongoStorage.recordHistory`](#recordhistory) | 静态方法 | A | 记住一条分析过的句子，并裁掉超出上限的最旧条目。 |
| [`NihongoStorage.recordExam`](#recordexam) | 静态方法 | A | 记住一次 JLPT 卷子的作答，并按该模式的上限裁掉最旧的条目。 |
| [`NihongoStorage.deleteRecords`](#deleterecords) | 静态方法 | A | 忘掉学习者删除的记录。 |
| `NihongoStorage._examFileName` | 静态常量 | B | `exam_in_progress.json`——进行中的卷子写入的那个文件。 |
| [`NihongoStorage.loadExamInProgress`](#loadexam) | 静态方法 | A | 读取学习者放下的那份卷子，如果有的话。 |
| `NihongoStorage.saveExamInProgress` | 静态方法 | B | 原子地把卷子写下来，好让它之后能被接着做；刻意不通知自动同步。 |
| `NihongoStorage.clearExamInProgress` | 静态方法 | B | 在卷子做完或被放弃时，扔掉保存的考试。 |
| `NihongoStorage.readConfig` | 静态方法 | B | 读取 `storage_config.json`；缺失或空白时为空。 |
| [`NihongoStorage.writeConfig`](#writeconfig) | 静态方法 | A | 原子写入 `storage_config.json`，排在已经排队的每一次写入之后。 |
| `NihongoStorage._configWrites` | 静态字段 | B | 每一次配置写入都要排进的那个队列，任何时刻只有一次在进行中。 |
| `NihongoStorage._configWriteZone` | 静态字段 | B | 队列所属的 zone；一次写入只等待同一个 zone 里发起的写入。 |
| [`NihongoStorage._updateConfig`](#updateconfig) | 静态方法 | A | 把读取、改动、写回 `storage_config.json` 作为一步来做。 |
| `NihongoStorage._queue` | 静态方法 | B | 让一次配置写入排在已经排队的每一次写入之后运行。 |
| `NihongoStorage._writeConfigNow` | 静态方法 | B | 立刻写配置文件，不排队；只在队列内部调用。 |
| `NihongoStorage._setKey` | 静态方法 | B | 设置或删除一个键；值为 null 时删除它。 |
| `NihongoStorage.getThemeMode` | 静态方法 | B | 读取持久化的主题模式（`light`、`dark`，或表示跟随系统的 null）。 |
| `NihongoStorage.setThemeMode` | 静态方法 | B | 持久化主题模式；默认值被移除而不是存储。 |
| `NihongoStorage.getLocaleTag` | 静态方法 | B | 读取持久化的语言标签（`en`、`zh`、`zh_TW`）。 |
| `NihongoStorage.setLocaleTag` | 静态方法 | B | 持久化语言标签；null 移除它。 |

## 文档

### `static Future<bool> setStoragePath(String? newPath)` <a id="setstoragepath"></a>

- **类型：** 静态方法
- **Purpose：** 更改存储目录并把数据移过去。
- **Inputs：** `newPath`；`null` 重置为默认位置。
- **Returns：** 仅当路径无法记录时为 `false`。
- **Side effects：** 重写 `storage_config.json`；移动旧文件夹的内容。
- **Algorithm：** 记住旧目录；记录（或移除）`storagePath`；解析新目录；若不同，调用 `myapps_data` 的 `migrateStorageContents(from: old, to: new)`。
- **Usage：** 桌面设置控件（随桌面目标到来）；Android 设置页面今天只显示路径。
- **Notes：** 迁移文件夹中的**一切**——数据文件、`.sync_base/`、`backups/`、`webdav_config.json`——不是一份枚举清单。`storage_config.json` 留在原地，因为它保存路径本身。把 `.sync_base/` 留下会让下次同步复活其他设备已删除的记录。已存在的目标文件胜出，其源副本留在原地。

### `static Future<ProgressData> load()` <a id="load"></a>

- **类型：** 静态方法
- **Purpose：** 读取进度文件。
- **Inputs：** 无。
- **Returns：** 文件缺失或空白时为空的 `ProgressData`，否则为解析后的数据。
- **Side effects：** 读取数据文件。
- **Algorithm：** 存在？空白？否则 `ProgressData.fromJson(jsonDecode(raw))`。
- **Usage：** `progressDataProvider`、`upsertRecords`。
- **Notes：** 损坏的文件**抛出**而不是视为空，使之后的保存不会静默覆盖仅仅是无法读取的数据——MyDay 在其 `v1.1.0` 和 `v1.2.5` 中记录的教训。

### `static Future<void> save(ProgressData data)` <a id="save"></a>

- **类型：** 静态方法
- **Purpose：** 写入进度文件。
- **Inputs：** `data`。
- **Returns：** 无。
- **Side effects：** 原子写入（临时文件，然后重命名）；`AutoSyncService.instance.notifySaved()`。
- **Algorithm：** `JsonEncoder.withIndent('  ')`、`atomicWriteString`、通知。
- **Usage：** `upsertRecords`；未来的每条写入路径。
- **Notes：** 两空格格式是共享同步引擎写入的格式，正是它让未改动的文件命中原始相等快速路径而不是重新上传。

## 参考页面偏好（`PLAN.md` M1.3）

在两组私有辅助方法 `_getString`/`_setString` 与 `_getInt`/`_setInt` 之上的五组带类型访问器：
`getLastTab`/`setLastTab`、`getVocabLevel`/`setVocabLevel`、`getGrammarLevel`/`setGrammarLevel`、
`getKanaScript`/`setKanaScript`、`getReferenceListColumns`/`setReferenceListColumns`。

辅助方法为它们统一保证两条性质。默认值会被**移除**而不是写入，因此文件保持精简，将来默认值的调整也能覆盖到从未
改过该设置的设备。类型不对的值按“未设置”读取而不是抛出异常：文件是用户可指定目录中的纯 JSON，可以手工编辑。见
[`../../../../features/reference-preferences.md`](../../../../features/reference-preferences.md)。

## 语音与 AI 偏好（`PLAN.md` M2.1、M2.2、M2.4）

在 `_getDouble`/`_setDouble` 与 `_getBool`/`_setBool` 之上再有四对访问器，遵循同样的两条规则：`getTtsRate`/`setTtsRate`、`getTtsVoice`/`setTtsVoice`、`getSpeechNetworkFallback`/`setSpeechNetworkFallback`，以及 `getAiAssistEnabled`/`setAiAssistEnabled`。

后两对值得在这里点名，因为它们各自把守着一件要么会离开设备、要么会运行模型的事：每一个都**在用户打开之前为 false**，并且把「关闭」存为缺失键而不是 `false`。手工写入的 `"true"` 字符串按未设置读取，与本文件中其他类型不对的值一样——字符串不是布尔值，而这种分量的设置不应该被一个笔误打开。见 [`../../../../features/pronunciation.md`](../../../../features/pronunciation.md) 与 [`../../../../features/ai-assist.md`](../../../../features/ai-assist.md)。

## 开发者选项（v0.4.6）

`_getBool`/`_setBool` 之上又多了一对，遵循同样的两条规则：`getDebugMode` 在没有人解锁开发者选项时返回 false，而 `setDebugMode` 把「关闭」存为缺失的键而不是 `false`。

它位于 `storage_config.json`，并且与这里几乎所有其他偏好不同，它**不同步**。它控制的是*这一台*设备的诊断信息——它服务的是哪个模型变体、装的是哪个 AICore 版本——所以把它带到另一台设备，等于在没人要求的地方打开诊断信息，而那些数字讲的都是另一台手机。它只从一个地方写入，即 `AppSettingsNotifier.setDebugMode`；见 [`../../../shared/providers/app_settings.md`](../../../shared/providers/app_settings.md)。

### `static Future<void> recordHistory(HistoryEntry entry, {DateTime? now})` <a id="recordhistory"></a>

- **种类：** 静态方法
- **用途：** 记住一条分析过的句子或一份写作。
- **输入：** `entry`；`now` 供测试使用。
- **返回：** 无。
- **副作用：** 读取并重写数据文件；只通知自动同步一次。
- **算法：** 按条目的 id upsert，然后取出该种类的全部条目，把超出 `historyMaxEntries` 的部分从最旧的开始移除。一次加载、一次保存。
- **用法：** 句子实验室在分析之后；写作练习在检查之后。
- **注意：** id 由内容决定，所以同一个句子再分析一次会更新已在那里的记录并把它移到最前，而不是新增一条。裁剪发生在同一次写入里——进度文件每次同步都被整份上传，无上限的日志最终会比它所搭载的进度还贵。**按种类**裁剪，使繁忙的句子实验室不会把写作历史清空，而且只会移除历史记录。两个调用方都会吞掉这里的失败：记住是便利，屏幕上的分析才是功能本身。

### `static Future<void> recordExam(ExamAttempt attempt, {DateTime? now})` <a id="recordexam"></a>

- **种类：** 静态方法
- **用途：** 记住一次 JLPT 卷子的作答。
- **输入：** `attempt`；`now` 供测试使用。
- **返回：** 无。
- **副作用：** 读取并重写数据文件；只通知自动同步一次。
- **算法：** 按该次作答的 id upsert，然后取出该**模式**的全部作答，把超出它的上限的部分——模拟考试用 `examMaxMockEntries`，练习用 `examMaxPracticeEntries`——从最旧的开始移除。一次加载、一次保存。
- **用法：** `ProgressNotifier.recordExam`，由测验页在提交卷子时调用。
- **注意：** 形状仿照 `recordHistory`，但有一处重要的差别：**裁剪按模式进行**。一个每天练习、每月模拟考试一次的学习者，否则会把每一次模拟考试都输给练习，而值得回头看的正是那些模拟考试。id 带时间戳并加盐而不是由内容推导，因为同一份卷子的两次作答确实是两次作答，绝不能像同一个句子的两次分析那样合并成一条。

### `static Future<void> deleteRecords(Iterable<String> ids)` <a id="deleterecords"></a>

- **种类：** 静态方法
- **用途：** 移除学习者删除的记录。
- **输入：** `ids`。
- **返回：** 无。
- **副作用：** 读取并重写数据文件；通知自动同步。
- **算法：** 丢弃每一条被点名 id 的记录。集合为空或没有命中时直接返回，不做写入。
- **用法：** 历史记录行上的删除按钮，以及考试历史记录条目卡片上的那个。
- **注意：** 是真删除而不是墓碑：三方合并把「一侧删除、另一侧未改动」的记录视为已删除，所以忘掉一个句子也会在学习者的其他设备上忘掉它。删除按钮必须具备这种行为——一个下次同步又回来的条目，比没有这个按钮更糟。没有改动时不写入，可以避免一次无效删除去碰文件并唤醒同步。


### `static Future<Map<String, dynamic>?> loadExamInProgress()` <a id="loadexam"></a>

- **种类：** 静态方法
- **用途：** 读取学习者放下的那份卷子，如果有的话。
- **输入：** 无。
- **返回：** `Future<Map<String, dynamic>?>`——没有时为 null。
- **副作用：** 读取应用目录下的 `exam_in_progress.json`。
- **算法：** 文件缺失、空白或解析不了时读作 null；否则给出解码后的 map。
- **用法：** 供 Learn 卡片使用的 `savedExamProvider`，以及继续作答时的 `exam_page.dart`。
- **注意：** 它是一个自己的文件而不是一条记录，而且**不同步、不备份、不导出**。另一台设备上的一场未完成的考试没有意义——计时属于这一次作答，而半份卷子不是一个结果。备份与 ZIP 引擎只看得见注册表模块，所以把这个文件留在注册表之外就是全部所需；与它成对的写入方出于同样的理由跳过 `notifySaved()`，因为这个文件的任何内容都不会去往别处。

  与上面的 `load` 不同，解析不了的文件会被当作没有保存的考试，而不是抛出异常。另一种做法是因为一份旧卷子损坏就拒绝开始一份新的，而这里也没有什么值得保护、不让它被覆盖的东西——一场做了一半的考试不是一份学习记录，而其中的每一次作答在当时就已经到达调度器了。

  `saveExamInProgress` 和这里的其他每一次写入一样是原子的，因为它在每一次作答时都会被调用，而一部在写入中途被杀掉的手机必须留下完好的上一份保存，而不是一份被截断的。`clearExamInProgress` 在一份卷子做完时以及学习者放弃一份时运行：做完的卷子已经是一条 `exam:` 记录了，而把保存留在那里会提出继续做一份已经判过分的东西。

### `static Future<void> writeConfig(Map<String, dynamic> config)` <a id="writeconfig"></a>

- **种类：** 静态方法
- **用途：** 原子写入 `storage_config.json`，排在已经排队的每一次写入之后。
- **输入：** `config`——要写入的整份 map。
- **返回：** 无；调用方自己的失败归调用方自己。
- **副作用：** 重写配置文件，排在已经排队的任何一次写入之后。
- **算法：** 通过 `_queue` 加入 `_configWrites`，然后由 `_writeConfigNow` 用两个空格的缩进编码这份
  map，并 `atomicWriteString` 写出去。
- **使用：** `data_modules.dart`，它把整份 map 交给同步引擎。本文件内部一律改用 `_updateConfig`。
- **注意：** 这个入口是给**已经握着整份 map** 的调用方用的。想改一个键的调用方必须走 `_updateConfig`，
  因为读取必须发生在队列内部。

  队列之所以存在，是因为每一个写入方法过去都各自跑一遍「读取—改动—写回」。两个同时跑，读到的是同一份
  文件、写出的是两个不同的后继版本，于是后完成的那个把另一个的键抹掉了。而在 Windows 上它甚至不是悄悄
  失败：后一次写入会把自己的临时文件改名覆盖到前一次还开着的那个文件上，于是 `atomicWriteString` 抛出
  `PathAccessException`。这两半是同一个缺陷，也由同一个队列修好。

  `_queue` 会把它吞掉的失败存下来（`chained.catchError((_) {})`），这样一次抛出异常的写入不会让排在它
  后面的每一次写入都失败。调用方仍然看得到自己的失败，因为返回的是链上的那个 future，而不是被吞掉的那个。

  **一次写入只等待同一个 zone 里发起的写入。** 应用从 `main` 起就只在一个 zone 里跑，所以在应用里这个
  限定词什么也不改变：每一次写入都等它前面那一次，而这正是要的。需要这个限定词的是 widget 测试。每一个
  测试体都有自己的 zone，而从一次点击发起、又没有被 await 的文件 I/O，在测试结束时就悬在那里——它永远不
  会完成，因为再没有人驱动那个 zone 了。不加限定的队列会等它等到进程结束，而它确实等了：这个修复的第一
  版把整个测试套件挂住了。用 `Timer` 给等待设上限也不行，因为 `flutter_test` 会让任何留下未触发定时器的
  测试失败。

### `static Future<void> _updateConfig(void Function(Map<String, dynamic>) change)` <a id="updateconfig"></a>

- **种类：** 静态方法
- **用途：** 把读取、改动、写回 `storage_config.json` 作为一步来做。
- **输入：** `change`——作用在刚读出来的那份 map 上。
- **返回：** 无。
- **副作用：** 重写配置文件，排在已经排队的任何一次写入之后。
- **算法：** 在队列内部：`readConfig`，应用 `change`，`_writeConfigNow`。
- **使用：** 本文件里的每一个写入方法，都经由 `_setKey`。
- **注意：** **读取放在队列内部是有意的。** 一个先读取、再排队的写入方法，仍然会覆盖掉另一个写入方法在
  这中间写下的键——写入不再抛出异常了，而更新照样丢失。只给写入排队，修的是这个缺陷看得见的那一半，留下
  的是沉默的那一半。

  `_setKey` 正是每一个写入方法想要的形状：设置这个键，或者在值为 null 时删除它。删除而不是存下默认值，
  正是让日后默认值的改变能够到达从没碰过这个设置的设备的原因，所以删除是这个辅助函数的一部分，而不是各
  个调用方各自的事。

  `preferences_test.dart` 用一个 `Future.wait` 里的四个写入方法把这一点钉住，之后四个键都在。它在旧代
  码上会失败——而这是知道这项测试确实是在测这件事的唯一办法。
