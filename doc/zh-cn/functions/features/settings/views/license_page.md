# lib/features/settings/views/license_page.dart

`LicensePage` 在应用栏下以可选择文本显示 MyNihongo!!!!! 的 GPLv3 声明。它是两个二级设置页面之一，在窄窗口上全屏压栈，在宽窗口上承载在详情窗格（pane）中（见 [settings_page.md](settings_page.md)）。第三方内容的署名随其发布添加到这里（`PLAN.md` M1.2）。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `LicensePage.new` | 构造函数 | B | 创建许可证页面实例。 |
| `LicensePage.build` | 方法（widget build） | B | 构建 GPLv3 声明页面。 |

自 `PLAN.md` M1.2 起，本页还包含**内容许可**一节。JMdict 与 JLPT 词表采用 CC BY-SA，要求署名随应用一同分发，
而不能只放在仓库文件里。署名文本本身是 `const` 字符串，且有意不作翻译：EDRDG 的许可证要求按其原文标注项目名
称与链接。
