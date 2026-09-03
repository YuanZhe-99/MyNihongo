# lib/features/content/models/parts_of_speech.dart

目录条目可携带的词性标签的封闭集合。JMdict 自身的标签体系更大也更细；`tool/import_vocab.dart` 把它映射到
这些名称，`content_catalog_test.dart` 会断言每个发布的条目只使用其中的标签。该文件不导入任何内容，以便工具
直接共享它，而不必另存一份会逐渐走样的副本。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| 库头注释 | `library` | B | 命名内容文件使用的词性标签封闭集合。 |
| `vocabPartsOfSpeech` | 顶层 `const Set<String>` | — | `vocab.json` 条目可携带的全部词性标签。 |
