# lib/features/content/models/grammar_point.dart

`GrammarPoint` 是内置内容中的一个语法点：id、JLPT 级别、句型、可选结构、按语言分键的释义与说明，以及例句。`fromJson` 在缺少 id、级别或句型时返回 null。搜索匹配句型、结构和释义，但刻意不匹配说明。见 [../../../../features/content-catalog.md](../../../../features/content-catalog.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `GrammarPoint.new` | 构造函数 | B | 创建语法点实例。 |
| `GrammarPoint.fromJson` | 静态方法 | B | 从内容 JSON 解析；缺少 id、级别或句型时为 null。 |
| `GrammarPoint.matches` | 方法 | B | 测试小写查询是否为句型、结构或任一语言任一释义的子串。 |
