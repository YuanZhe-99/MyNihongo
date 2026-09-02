# lib/features/progress/services/nihongo_storage.dart

`NihongoStorage` 是应用的存储中枢：唯一知道数据在磁盘上何处的地方。它解析应用目录（平台文档目录加 `MyNihongo`，或 `storage_config.json` 中的自定义路径），通过包里的 `atomicWriteString` 原子地读写 `nihongo_progress.json` 和 `storage_config.json`，在每次数据保存后通知自动同步，并在存储路径改变时迁移整个文件夹。共享引擎使用的 `StorageAdapter` 委托给它（见 [../../../app/data_modules.md](../../../app/data_modules.md)）。见 [../../../../data-formats.md](../../../../data-formats.md) 和 [../../../../features/learning-progress.md](../../../../features/learning-progress.md)。

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
| `NihongoStorage.readConfig` | 静态方法 | B | 读取 `storage_config.json`；缺失或空白时为空。 |
| `NihongoStorage.writeConfig` | 静态方法 | B | 原子写入 `storage_config.json`。 |
| `NihongoStorage.getThemeMode` | 静态方法 | B | 读取持久化的主题模式（`light`、`dark`，或表示跟随系统的 null）。 |
| `NihongoStorage.setThemeMode` | 静态方法 | B | 持久化主题模式；默认值被移除而不是存储。 |
| `NihongoStorage.getLocaleTag` | 静态方法 | B | 读取持久化的语言标签。 |
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
