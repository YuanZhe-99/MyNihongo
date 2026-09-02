# lib/shared/widgets/reference_widgets.dart

单词和语法页面共享的小部件，使两者外观一致：JLPT 等级徽章、等级筛选 chip、例句块和空结果行。见 [../../../features/content-catalog.md](../../../features/content-catalog.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `levelChip` | 顶层函数 | B | 渲染一个小的 JLPT 等级徽章。 |
| `levelFilterRow` | 顶层函数 | B | 渲染选择 chip 的 `Wrap`：全部等级，然后 N5 到 N1；恰好选中一个。 |
| `exampleList` | 顶层函数 | B | 渲染带标题的例句块，含当前语言环境的读音和翻译。 |
| `emptyResults` | 顶层函数 | B | 渲染筛选无匹配时显示的空状态行。 |
