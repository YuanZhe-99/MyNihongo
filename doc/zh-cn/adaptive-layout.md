# 自适应布局

这是全应用的规则，决定**布局何时可以分栏**——五十音页面和学习仪表盘分成两列，单词和语法列表分成多列，设置页面分成两个窗格（pane），在折叠屏设备的内屏、平板或桌面窗口上——以及一旦可以，**得到几列**。第二条更窄的规则决定**导航放在哪里**。全部位于 [`lib/shared/utils/adaptive_layout.dart`](functions/shared/utils/adaptive_layout.md)，该模块刻意除 `dart:core` 外不导入任何东西，使每个决策都可以在没有组件（widget）树的情况下直接单元测试。

这些约定是 MyAnime!!!!! 在其 1.5.2 – 1.5.7 版本中总结、并写成本系列自适应布局指南的那一套，从第一次提交起就在这里采用，使同一设备在本系列每个应用中得到相同的答案。数字离开推理就毫无价值，因此推理被写了下来。**如果组件文件里出现数值宽度比较，那就是 bug**——数字属于策略模块，页面调用具名断言。

## 何时分栏

当以下**三条全部**成立时分栏：

| 常量 | 值 | 含义 |
|---|---|---|
| `splitMinWidth` | `600.0` | Material 的 *medium* 宽度类别；Android 的 `sw600dp`。 |
| `splitMinHeight` | `480.0` | compact/medium 高度边界。 |
| `splitMinAspect` | `0.82` | 宽除以高。 |

```dart
bool canSplitLayout(double width, double height) {
  if (width < splitMinWidth) return false;
  if (height < splitMinHeight) return false;
  if (height <= 0) return false;
  return width / height >= splitMinAspect;
}
```

每个条件都有其存在的理由，且没有任何一条单独足够。

### 宽高比检验是承重的那一条

**它是这不是单纯宽度断点的原因，而 Galaxy Z Fold 8 是它必须存在的原因。** Fold 8 展开后是 4:3 的*横向*面板（2448 × 1848 px），因此竖持时是 3:4——相对高度而言比它取代的近方形 Fold 7 更窄——而 Fold 8 Ultra 则走向另一边。一代产品展开后跨越约 672 到 954 逻辑像素，而同一设备在同一宽度下需要两个不同的答案。没有任何宽度阈值能做到这一点；宽高比检验可以。

像素数是权威；逻辑像素取决于密度桶和三星用户可调的**显示大小**设置，因此给出可能的范围。

| 设备 | 内屏，px | 竖持 W:H | 竖持宽度，dp | 竖持 | 横持 |
|---|---|---|---|---|---|
| Galaxy Z Fold 5 | 1812 × 2176 | 0.83 | 659–690 | 分栏 | 分栏 |
| Galaxy Z Fold 6 | 1856 × 2160 | 0.86 | 675–707 | 分栏 | 分栏 |
| Galaxy Z Fold 7 | 1968 × 2184 | 0.90 | 716–750 | 分栏 | 分栏 |
| **Galaxy Z Fold 8** | **2448 × 1848（4:3 横向）** | **0.755** | **672–704** | **单列** | **分栏** |
| Galaxy Z Fold 8 Ultra | 2256 × 2504 | 0.90 | 820–859 | 分栏 | 分栏 |
| Pixel 9 / 10 Pro Fold | 2076 × 2152 | 0.96 | 755–791 | 分栏 | 分栏 |

`0.82` 大致位于 Fold 8 竖持 `0.755` 与 Fold 7 / Fold 8 Ultra 竖持 `0.90` 之间空隙的中点，两侧各有约 9% 的余量。除非有设备落入该空隙，否则保持这个常量不变；改动它是全应用的行为变更。

### 宽度下限

每块展开面板即使在密度较大的一端也至少高出 600 dp 59 dp，而每块折叠外屏都远低于它：Z Fold 7 / 8 Ultra 约 360 dp，Z Fold 8 约 356–416 dp，Pixel 10 Pro Fold 约 411 dp。

### 高度下限

宽高比检验单独会放进*宽而矮*的视口。没有这条下限，转成横向的折叠态 Z Fold 8 外屏（约 657 × 416 dp）和横持的普通手机（约 915 × 412 dp）都会分成两个局促的窗格。Google 也独立给出同样的建议：横持的手机或打开的翻盖机，窗口宽度通常是 medium 但高度是 compact，双栏布局在那里并不实用。

### 值得知道的后果

这条规则关乎**形状而非设备类别**，因此 4:3 平板竖持（768 × 1024 → 0.75）和 16:10 平板竖持（0.625）同样保持单列，与竖持的 Fold 8 完全一样。两者横持都分栏。「我的平板竖持不分栏」正是规则在起作用。

## 导航放在哪里

```dart
const navRailMinWidth = 600.0;
const navRailWidth = 81.0; // 80 dp NavigationRail + 1 dp VerticalDivider

bool useNavigationRail(double screenWidth) => screenWidth >= navRailMinWidth;
```

**刻意只看宽度。它不经过 `canSplitLayout`。** 导航栏（NavigationRail）不是分栏；它用宽度——只要检验通过宽度就充裕——换高度，而高度并不充裕。它帮助最大的情形恰恰是分栏规则拒绝的那一个：915 × 412 横持的手机，底部导航栏花掉 19% 的高度做导航，而 915 dp 的宽度闲置着。

两个后果贯穿整个应用：

```dart
double shellContentWidth(double screenWidth) =>
    useNavigationRail(screenWidth) ? screenWidth - navRailWidth : screenWidth;

double shellListBottomInset(double screenWidth) =>
    useNavigationRail(screenWidth) ? 16.0 : 80.0;
```

侧边导航栏和底部导航栏在 `shell_scaffold.dart` 中由**同一份目标列表**构建，导航栏设置 `groupAlignment: 0`，使五个目标居中而不是钉在高导航栏的顶部。

## 能放几列

绝不按断点写死数量。问一问给定最小宽度的列能放几列：

```dart
int columnCapacity(double contentWidth, {required double minItemWidth,
    double gap = listTileGap, int maxColumns = listMaxColumns});
```

分子里加上一个间隙，使算式只为列*之间*的间隙付费，而不是每列之后都付一次。每个调用方带来自己内容所需的最小值，并在文档注释里说明数字的来源：

| 调用方 | 常量 | 最小值 | 上限 | 数字的理由 |
|---|---|---|---|---|
| 假名表 | `kanaTableMinWidth` | 330 | 2 | 五列表在行标签上花 44，剩下每格约 57——与手机单列时给它的一致。再窄，展开的屏幕就会比手机显示更多、更小的假名。 |
| 规则卡、学习卡 | `ruleCardMinWidth` | 320 | 2 | 是段落；第三列会低于舒适的阅读宽度，低于 320 时两行标题会折成三行。 |
| 单词 / 语法条目卡片 | `referenceTileMinWidth` | 320 | 4 | 词条、读音行、一行释义和尾部的级别徽章；再窄，最长的种子英文释义就会在徽章前被截断。 |

参考页面把内容居中在 `pageMaxContentWidth`（1080）之内，使桌面窗口不会把五列表拉伸到 1600 像素宽。`referenceContentWidth(screenWidth)` 是唯一计算「内容减去导航栏、减去页面边距、再加上限」的地方——五十音、单词和语法页面都据此确定列宽，因此它们对第二列出现的位置意见一致。

## 门控量屏幕，容量量内容框

- **门控**（`canSplitLayout`、`useNavigationRail`）读取 `MediaQuery.sizeOf(context)`——整个屏幕。若对 `Scaffold` 主体度量分栏决策，就会减掉应用栏，把竖持的 Fold 8 读成 0.80 而不是 0.755，几乎不给阈值留余量。
- **容量和窗格宽度**读取内容实际得到的宽度：`referenceContentWidth`，或 `LayoutBuilder` 的 `constraints.maxWidth`。

## 每个页面使用哪条规则

每个决策都连同其代价记录在这里。

| 页面 | 规则 | 决策 |
|---|---|---|
| 外壳 | 仅宽度 | 从 600 dp 起使用导航栏。 |
| 五十音 | **双重门控** | 当 `canSplitLayout` **且** 两张 `kanaTableMinWidth` 表能放进 `referenceContentWidth` 时两列。第二道门控让 Z Fold 5/6 和竖持的 Fold 7（546–637 dp 内容；两张表需要 672）保持单列，而无需它们自己的断点。两列模式下书写体系切换与搜索框共用一行。规则卡按 `ruleCardMinWidth` 对该节实际得到的宽度自行排成 1–2 列。 |
| 单词、语法 | 形状门控 + 容量 | `referenceColumnCount`：除非 `canSplitLayout`，否则 1 列，然后是 `referenceTileMinWidth` 下的 `columnCapacity`，上限 `listMaxColumns`（4）。横持的 Fold 8 得到两列，横持平板两列，桌面三列。尚无存储的偏好；到来时钳制而不拒绝，容量为 1 时隐藏。 |
| 学习 | 形状门控 + 容量 | 仪表盘卡片按 `ruleCardMinWidth` 排成 1–2 列，以 `canSplitLayout` 为门控。 |
| 设置 | 形状门控 | `canSplitLayout` 时两个窗格；左窗格 `settingsLeftPaneWidth(shellContentWidth)`——比例式（0.44），钳制在 300–440，并加上限使详情窗格永不低于 `settingsRightPaneMinWidth`（280）。二级页面在窄窗口上全屏压栈，在宽窗口上承载于详情窗格内嵌套的 `Navigator`，因此同一组件服务两种模式。 |
| 详情面板 | 无 | 底部面板，在每种模式下相同。 |

**明知而接受的代价：** 横持的手机（915 × 412）保留每个单列布局，尽管它是所有视口中高度最少的——本来受益最大的情形。本系列为其分栏表面的一致性接受了这个取舍；本应用沿用。

## 运行时折叠与展开

`android/app/src/main/AndroidManifest.xml` 在 activity 的 `configChanges` 中声明了 `screenLayout|screenSize|smallestScreenSize|density`，因此窗口**无需重建 activity** 即可调整大小，所有读取 `MediaQuery.sizeOf` 的地方在下一帧重新求值。「设备展开时自动切换」需要的仅此而已。没有它，activity 会重建，而未持久化的页面状态——输了一半的搜索词——会在折叠途中丢失。

## 测试

1. **纯函数测试**（`test/adaptive_layout_test.dart`）：每个阈值在 `n − 1` 和 `n` 处，每个钳制在两端，每个视口以其代表的设备命名。
2. **组件测试**在同样的几何尺寸上（`test/kana_layout_ui_test.dart`、`test/shell_nav_ui_test.dart`、`test/widget_test.dart`）：断言相对位置（相同 `y`、不同 `x`），并用 `expect(tester.takeException(), isNull)` 捕获溢出条纹。
3. `flutter_test` 把默认字体的每个字形渲染成一个完整的 em 方块，把拉丁文本放大到实际宽度的约 2.5 倍。关心文本宽度的布局测试用简体中文驱动，因为中文字形确实是方的，这样测试度量的是生产布局而不是字体的人为产物。布局测试溢出时，先检查未改动的路径是否以同样方式失败，再相信布局真的坏了。
4. 不要按位置索引可滚动组件；每个 `TextField` 都会贡献自己的 `Scrollable`。
5. 注意默认的 800 × 600 测试视口会通过 `canSplitLayout`；在任何在意这一点的测试中固定显式视口。
6. 在声称没有内联断点残留之前，grep 整棵树：

```bash
grep -rnE "maxWidth *[<>]=? *[0-9]|size\.width *[<>]=? *[0-9]" lib/
```

## 刻意与 Google 指南的分歧

Google 的自适应布局指南说窗口尺寸类别不用于设备类型逻辑，并指导应用按可用宽度决策。本约定**刻意只在一点上分歧：宽高比检验。** 仅凭宽度无法在 Fold 8 的两个方向上给出两个不同答案，而这个行为正是规则存在要满足的需求。其余一切都遵循 Google：宽度与高度下限就是它的断点，列容量是它的信息流指南，medium 宽度及以上使用导航栏是它的原话建议。
