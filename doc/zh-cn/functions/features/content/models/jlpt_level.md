# lib/features/content/models/jlpt_level.dart

`JlptLevel` 枚举五个 JLPT 级别，最简单的在前（`n5` … `n1`），带面向用户的标签（`N5` … `N1`，永不本地化）和内容模型使用的大小写不敏感解析器。见 [../../../../data-formats.md](../../../../data-formats.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `JlptLevel.label` | getter | B | 返回用户所知的级别标签，`N5` 到 `N1`。 |
| `JlptLevel.parse` | 静态方法 | B | 以任意大小写从内容 JSON 解析级别；无法识别时为 null。 |
