# lib/features/content/models/content_catalog.dart

`ContentCatalog` 持有内置内容文件描述的一切——按文件顺序的单词列表和语法列表——并提供按 id 的线性查找。`fromJson` 接收两个解码后的文件，跳过畸形条目而不是失败。见 [../../../../features/content-catalog.md](../../../../features/content-catalog.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `ContentCatalog.new` | 构造函数 | B | 创建内容目录实例。 |
| `ContentCatalog.fromJson` | 工厂构造函数 | B | 解析两个内容文件（`entries` 和 `points` 数组），跳过畸形条目。 |
| `ContentCatalog.vocabById` | 方法 | B | 按 id 查找单词条目（线性；JMdict 到来时建索引）。 |
| `ContentCatalog.grammarById` | 方法 | B | 按 id 查找语法点。 |
