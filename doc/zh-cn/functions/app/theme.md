# lib/app/theme.dart

`AppTheme` 用同一个种子色 `AppTheme.seedColor`（`0xFFCE5B78`，樱花粉，使本应用一眼就能与兄弟应用区分开）通过 `ColorScheme.fromSeed` 构建亮色和暗色主题；调用方传入平台动态方案时则使用动态方案（仅 Android，见 `MyNihongoApp.build`）。`AppUiStyle` 是用户在设置中选择的界面风格：`expressive`（默认）在原生 Material 3 之上叠加主题层面的 Material 3 Expressive 近似，`material3` 是原生 Material 3 加轮廓输入框。两种风格共用同一套颜色；Expressive 只改变形状、字重和组件细节，绝不改变布局或颜色。见 [../../architecture.md](../../architecture.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `AppUiStyle` | 枚举 | B | 两种界面风格：`material3` 与 `expressive`。 |
| `NavPlacement` | 枚举 | B | 外壳把导航放在哪里（0.6.1）：`bottom`（默认）、`sideOnWide` 或 `side`；两种界面风格都适用。 |
| `AppTheme._` | 私有构造函数 | B | 阻止直接实例化，只暴露静态成员。 |
| `AppTheme.seedColor` | 静态常量 | B | 应用的品牌色，也是视觉体系中唯一的每应用旋钮。 |
| `AppTheme.scheme` | 静态方法 | B | 解析某个亮度的配色方案：有动态方案则用之，否则用 `fromSeed`。 |
| `AppTheme.build` | 静态方法 | B | 构建某个亮度和风格的主题（原生 Material 3；Expressive 再叠加 `_expressive`）。 |
| `AppTheme._morphingButtonStyle` | 静态方法 | B | 静止为胶囊、按下变为 12 圆角方形（200 ms）的按钮样式。 |
| `AppTheme._emphasized` | 静态方法 | B | 仅通过字重让 display、headline 与 title 样式更粗。 |
| `AppTheme._expressive` | 静态方法 | B | 在主题上叠加 Expressive 近似：更大圆角、变形按钮、加粗标题、2024 版指示器、渐进淡入转场。 |
| `AppTheme.light` | 静态方法 | B | 返回亮色主题，参数为可选动态方案和风格（默认 Expressive）。 |
| `AppTheme.dark` | 静态方法 | B | 返回暗色主题，参数为可选动态方案和风格（默认 Expressive）。 |

## Expressive（仅主题层面）

圆角：卡片 20、对话框 32、底部面板顶部 32、菜单 16、Chip 12、输入框 12、FAB 20、浮动 SnackBar 16。按钮（Filled、Elevated、Outlined、Text、Icon）静止为胶囊，按下变形为 12 圆角方形。Display 样式为 w500，headline/title 样式为 w600；字号和行高保持原生。进度条与滑块使用 2024 版设计（`year2023: false`，该参数已标注弃用但仍是唯一开关，代码中以 `// ignore: deprecated_member_use` 注明）。页面转场在 Android、Windows、Linux 上为淡入前进，在 iOS、macOS 上为 Cupertino。弹簧动效、波浪进度条、按钮组、分裂按钮、FAB 菜单和浮动工具栏在 Flutter 3.44 中没有对应组件，因此不模仿。
