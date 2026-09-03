# lib/features/kana/models/kana_note.dart

某个假名除罗马字之外还需要的教学说明：笔画数、要点，以及容易混淆的假名。它是文字说明而非表格数据，因此做成
资源文件（`assets/content/kana_notes.json`）并会被翻译。只有需要说明的假名才有条目。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| 库头注释 | `library` | B | 承载假名在罗马字之外所需的教学说明。 |
| `KanaNote` | 构造函数 | B | 创建假名注释实例。 |
| `KanaNote.fromJson` | 静态方法 | B | 从内容 JSON 解析一条注释。 |
| `KanaNote.mapFromJson` | 静态方法 | B | 解析整个注释文件，返回以假名进度 id 为键的映射。 |

所有字段均可选：只有混淆列表的注释仍然有用，而只有要点的注释是常见情形。格式有误的注释会被跳过而不是让整个
文件失败，`content_catalog_test.dart` 会在发布前发现坏条目。
