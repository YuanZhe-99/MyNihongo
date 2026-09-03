# lib/features/content/services/study_item_labels.dart

把进度记录 id 变成人能认出的名字。目前唯一的调用方是同步冲突对话框；它必须能为收到的每一条记录命名，包括
id 已不在当前构建内容库中的记录。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| 库头注释 | `library` | B | 把进度记录 id 变成人能认出的名字。 |
| `StudyItemLabel` | 构造函数 | B | 创建学习项标签实例。 |
| `resolveStudyItemLabel` | 顶层函数 | A | 查找进度记录 id 的显示名称。 |

### `resolveStudyItemLabel`

- **Purpose:** 查找进度记录 id 的显示名称。
- **Inputs:** `id` —— `kana:`、`vocab:` 或 `grammar:` id；`catalog` —— 已解析的内容，未加载时为 null；
  `locale` —— 界面语言，决定释义使用哪种语言。
- **Returns:** `StudyItemLabel`；永不为 null。
- **Side effects:** 无。
- **Algorithm:** 按 `studyKindOf(id)` 分支。`kana:` 经 `kanaEntryById` 解析为
  `<平假名> · <片假名>` 标题，副标题为罗马字。`vocab:` 经 `ContentCatalog.vocabById` 解析为词头，副标题为
  读音与首条释义；读音与词头相同时省略读音。`grammar:` 解析为句型，副标题为其含义。无法解析的一律返回原始
  id，并置 `resolved == false`。
- **Usage:** `resolveStudyItemLabel(conflict.id, catalog: catalog, locale: locale)`。
- **Notes:** 词汇查找识别别名，因此让位给 JMdict 编号 id 的旧 id 仍能命名其条目。未解析的标签会带
  “未知项”说明显示，而不是被隐藏 —— 进度 id 的寿命长于内容库，记录绝不能悄悄消失。
