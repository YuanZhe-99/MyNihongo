# lib/features/learn/views/learn_page.dart

P2：布局函数传入页面上下文并使用实际导航内容约束；
全窗口路由不扣除不存在的导航。

`LearnPage` 是第一个标签和应用的首页：四张卡片的仪表盘——目录计数（假名、单词、语法点）、进度计数（已记录和已掌握的条目，或诚实的「尚无学习记录」）、三个参考标签的快速链接，以及路线图。它监视 `contentCatalogProvider` 和 `progressDataProvider`；卡片按 `ruleCardMinWidth` 排成一或两列，以 `canSplitLayout` 为门控。第三阶段本页成为学习路径。见 [../../../../features/learning-progress.md](../../../../features/learning-progress.md)。

自 0.6.0 起，它的应用栏在标题左侧以 `leading` 放置个人资料头像（`ProfileAvatar`，半径 16）；点击执行 `context.go('/settings')`。这是唯一带该头像的页面。

自 0.6.1 起，列表的 padding 是 `navBarAwarePadding(context, EdgeInsets.fromLTRB(16, 8, 16, shellListBottomInset(width)))`：Expressive 悬浮底栏时页面绘制在栏的后面，这层包装加上栏高，使最后的内容可以滚动到栏的上方。见 [../../../../adaptive-layout.md](../../../../adaptive-layout.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `LearnPage.new` | 构造函数 | B | 创建学习页面实例。 |
| `LearnPage.build` | 方法（`ConsumerWidget` build） | B | 构建首页标签：应用有什么、用户做了什么、从哪里开始。 |
| `LearnPage._card` | 方法（widget 辅助） | B | 渲染一张仪表盘卡片（图标、标题、正文）。 |
| `LearnPage._line` | 方法（widget 辅助） | B | 在卡片内渲染一行正文。 |
| `LearnPage._link` | 方法（widget 辅助） | B | 渲染一行用 `context.go` 跳转到标签的快速开始项。 |
