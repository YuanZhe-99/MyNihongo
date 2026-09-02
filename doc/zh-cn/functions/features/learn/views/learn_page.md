# lib/features/learn/views/learn_page.dart

`LearnPage` 是第一个标签和应用的首页：四张卡片的仪表盘——目录计数（假名、单词、语法点）、进度计数（已记录和已掌握的条目，或诚实的「尚无学习记录」）、三个参考标签的快速链接，以及路线图。它监视 `contentCatalogProvider` 和 `progressDataProvider`；卡片按 `ruleCardMinWidth` 排成一或两列，以 `canSplitLayout` 为门控。第三阶段本页成为学习路径。见 [../../../../features/learning-progress.md](../../../../features/learning-progress.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `LearnPage.new` | 构造函数 | B | 创建学习页面实例。 |
| `LearnPage.build` | 方法（`ConsumerWidget` build） | B | 构建首页标签：应用有什么、用户做了什么、从哪里开始。 |
| `LearnPage._card` | 方法（widget 辅助） | B | 渲染一张仪表盘卡片（图标、标题、正文）。 |
| `LearnPage._line` | 方法（widget 辅助） | B | 在卡片内渲染一行正文。 |
| `LearnPage._link` | 方法（widget 辅助） | B | 渲染一行用 `context.go` 跳转到标签的快速开始项。 |
