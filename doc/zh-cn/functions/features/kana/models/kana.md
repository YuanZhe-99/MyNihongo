# lib/features/kana/models/kana.dart

假名目录：`KanaScript`、`KanaEntry`、`KanaRow`、列标题常量、三张 `const` 表（`kanaBasicRows`、`kanaVoicedRows`、`kanaYoonRows`），以及其上的两个辅助函数。从页面中抽出，使测验、发音练习和进度目录共享同一来源。假名的进度 id 是 `kana:<hiragana>`。见 [../../../../features/kana-reference.md](../../../../features/kana-reference.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| 库头 | 库文档 | B | 假名目录——应用教授的每一对平假名/片假名，按页面绘制的三张表排列。 |
| `KanaEntry.new` | 构造函数 | B | 创建假名条目（平假名、片假名、罗马音）。 |
| `KanaEntry.progressId` | getter | B | 返回进度记录使用的稳定 id：`kana:` 加平假名形式。 |
| `KanaEntry.kana` | 方法 | B | 以请求的书写体系返回此条目。 |
| `KanaEntry.matches` | 方法 | B | 测试小写查询是否为平假名、片假名或小写罗马音的子串。 |
| `KanaRow.new` | 构造函数 | B | 创建带标签的行；`null` 槽位标记不存在的组合。 |
| `allKanaEntries` | 顶层函数 | B | 按表顺序列出三张表中的每个假名条目，每个一次。 |
| `matchingKanaEntries` | 顶层函数 | B | 修剪并转小写查询，返回每个匹配的条目；空白查询返回空。 |
| `kanaEntryById` | 顶层函数 | B | 通过惰性构建的映射，把 `kana:` 进度 id 解析回其表内条目。 |
