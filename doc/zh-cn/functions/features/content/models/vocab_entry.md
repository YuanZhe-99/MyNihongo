# lib/features/content/models/vocab_entry.dart

`VocabEntry` 是内置内容中的一个单词条目：id、JLPT 级别、词条（有汉字时为汉字，否则为读音）、读音、可选罗马音、词性标签、按语言分键的释义，以及例句。`fromJson` 在缺少 id、级别或读音时返回 null。见 [../../../../features/content-catalog.md](../../../../features/content-catalog.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `VocabEntry.new` | 构造函数 | B | 创建单词条目实例。 |
| `VocabEntry.hasKanji` | getter | B | 报告词条是否与读音不同，决定条目卡片是否显示读音行。 |
| `VocabEntry.fromJson` | 静态方法 | B | 从内容 JSON 解析；缺少 id、级别或读音时为 null；`kanji` 可省略。 |
| `VocabEntry.matches` | 方法 | B | 测试小写查询是否为词条、读音、罗马音或任一语言任一释义的子串。 |

有两个字段随 JMdict 导入（`PLAN.md` M1.2）加入：`aliases` 是该条目曾经使用的 id，`ContentCatalog.vocabById`
会把它们解析到同一条目，使任何用户的进度都不会成为孤儿；`common` 在 JMdict 把所选书写形式标为常用时为 true，
用于排序建议，绝不用于隐藏条目。
