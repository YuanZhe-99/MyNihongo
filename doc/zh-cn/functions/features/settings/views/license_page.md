# lib/features/settings/views/license_page.dart

`LicensePage` 在应用栏下以可选择文本显示 MyNihongo!!!!! 的 GPLv3 声明。它是两个二级设置页面之一，在窄窗口上全屏压栈，在宽窗口上承载在详情窗格（pane）中（见 [settings_page.md](settings_page.md)）。第三方内容的署名随其发布添加到这里（`PLAN.md` M1.2）。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `LicensePage.new` | 构造函数 | B | 创建许可证页面实例。 |
| `LicensePage.build` | 方法（widget build） | B | 构建 GPLv3 声明页面。 |
