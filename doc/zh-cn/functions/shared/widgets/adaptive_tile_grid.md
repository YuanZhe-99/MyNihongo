# lib/shared/widgets/adaptive_tile_grid.dart

两个辅助函数，把平铺的瓦片列表按 `columns` 列排成由 `Expanded` 子项组成的 `Row`——刻意不用 `GridView`，这样在 `listRowCount` 行上用 `ListView.builder` 喂给它们的调用方能保持虚拟化以及从左到右、从上到下的顺序。不满的最后一行用空单元格补齐，使剩余瓦片保持宽度。由单词和语法页面使用。见 [../../../adaptive-layout.md](../../../adaptive-layout.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `adaptiveTileRow` | 顶层函数 | B | 构建多列列表的一行，从左到右填充，末尾补齐。 |
| `adaptiveTileRows` | 顶层函数 | B | 把列表的子项构建为多行；单列时原样返回瓦片。 |

`listColumnsButton` 构建选择列表列数的弹出菜单。当窗口只能容纳一列时它被隐藏而不是禁用，因此手机上绝不会出现一个
什么都做不到的控件。菜单始终提供直到 `listMaxColumns` 的每个数值，这样在折叠状态下也能设置偏好并在展开后生效；
勾选标记跟随存储的偏好，而实际渲染的是该偏好被钳制到实际容量后的结果。
