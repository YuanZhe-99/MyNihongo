# lib/features/content/models/content_catalog.dart

`ContentCatalog` 承载内置内容文件描述的一切——单词列表、各等级文件中的语法点，以及假名注释——并提供按 id 的
常数时间查找。目录在 `PLAN.md` M1.2 中从 24 个词增长到约 7,700 个，因此查找改为构造时建好的映射，而不再是种子
阶段负担得起的线性扫描。别名指向与主 id 相同的条目对象，因此调用方无法分辨自己是通过哪个 id 拿到的。见
[../../../../features/content-catalog.md](../../../../features/content-catalog.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| 库头注释 | `library` | B | 承载内置内容文件描述的一切，只解析一次。 |
| `ContentCatalog.new` | 构造函数 | B | 创建内容目录实例并建立 id 查找表。 |
| `ContentCatalog.fromJson` | 工厂构造函数 | B | 解析内容文件，跳过格式有误的条目。 |
| `ContentCatalog.vocabById` | 方法 | B | 以常数时间按 id 或别名查找单词条目。 |
| `ContentCatalog.grammarById` | 方法 | B | 按 id 查找语法点。 |
| `ContentCatalog.canonicalId` | 方法 | B | 把任意 id 解析为目录当前发布所用的 id。 |
| `ContentCatalog.allVocabIds` | getter | B | 列出目录能响应的全部单词 id，包括别名。 |

`fromJson` 以可迭代对象接收语法文件，因为语法按等级分文件发布，使每一级都能单独撰写与校对。`canonicalId`
只用于归类与显示：进度记录始终保留写入时使用的 id，绝不改写。
