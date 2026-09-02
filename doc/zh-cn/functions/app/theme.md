# lib/app/theme.dart

`AppTheme` 通过 `flex_color_scheme` 构建亮色和暗色 Material 3 主题，以 `FlexScheme.sakura` 为种子，使本应用一眼就能与兄弟应用区分开。两者都使用层级表面混合、轮廓输入边框，以及只为选中目标显示标签的导航栏。见 [../../architecture.md](../../architecture.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `AppTheme._` | 私有构造函数 | B | 阻止直接实例化，只暴露静态成员。 |
| `AppTheme.light` | 静态 getter | B | 返回应用使用的亮色 Material 主题。 |
| `AppTheme.dark` | 静态 getter | B | 返回应用使用的暗色 Material 主题。 |
