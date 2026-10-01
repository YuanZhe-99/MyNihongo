# lib/features/profile/views/avatar_editor.dart

全屏头像编辑器（0.6.1）。选好图片——或再次打开当前头像——之后，用户在圆形遮罩内取景：拖动移动，双指缩放或滚轮缩放 1 倍到 8 倍，按四分之一圈旋转，重置，然后点**保存**。圆形里显示的就是实际存储的内容。见 [`../services/avatar_image.md`](../services/avatar_image.md)、[`profile_header.md`](profile_header.md) 和 [`../../../../features/profile.md`](../../../../features/profile.md)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`showAvatarEditor`](#showavatareditor) | 顶层函数 | A | 压入全屏编辑器，返回 512 像素的正方形 JPEG；用户退出时返回 null。 |
| `AvatarEditorPage` | 类 | B | 在圆形内给图片取景的全屏编辑器。 |
| `AvatarEditorPage.new` | 构造函数 | B | 由源字节创建编辑器。 |
| `AvatarEditorPage.createState` | 方法（widget 生命周期） | B | 创建编辑器状态。 |
| `_AvatarEditorPageState.initState` | 方法（widget 生命周期） | B | 开始准备图片。 |
| `_AvatarEditorPageState.dispose` | 方法（widget 生命周期） | B | 释放变换 controller。 |
| `_AvatarEditorPageState._prepare` | 方法 | B | 在后台为当前旋转解码、转正并调整源图尺寸。 |
| `_AvatarEditorPageState._rotate` | 方法 | B | 顺时针旋转四分之一圈并重新准备。 |
| `_AvatarEditorPageState._reset` | 方法 | B | 回到初始取景（居中、铺满圆形）。 |
| [`_AvatarEditorPageState._save`](#_save) | 方法 | A | 把视口映射回源像素，在后台裁剪，并带着 JPEG 退出。 |
| [`_AvatarEditorPageState.build`](#build) | 方法（widget build） | A | 构建应用栏、圆形视口和提示。 |
| `_CircleMaskPainter` | 私有类 | B | 压暗头像圆形以外的一切并给圆形描边。 |
| `_CircleMaskPainter.new` | 构造函数 | B | 由遮罩色和圆环色创建遮罩绘制器。 |
| `_CircleMaskPainter.paint` | 方法 | B | 绘制带圆形镂空的遮罩和描边。 |
| `_CircleMaskPainter.shouldRepaint` | 方法 | B | 仅在颜色变化时重绘。 |

## showAvatarEditor

- **输入：** `context`；`source`——所选图片或当前头像的字节。
- **返回：** `Future<Uint8List?>`——`ProfileStore.avatarSize` 的正方形 JPEG，或 null。
- **副作用：** 压入一个 `fullscreenDialog` 的 `MaterialPageRoute`。
- **备注：** 对错误输入不会抛出：无法解码的图片在编辑器里显示 `profileAvatarError`，且*保存*被禁用。

## build

- **布局：** 标题为 `profileAdjustAvatar` 的应用栏，带旋转按钮（`profileAvatarRotate`）、重置按钮（`profileAvatarReset`）和**保存**；其下是视口和提示 `profileAvatarEditorHint`。
- **算法：** 视口边长为 `min(宽, 高 - 96) - 32`，钳制在 160–480。图片在缩放 1 时按*铺满*该正方形排布（`cover = side / min(w, h)`），放在 `InteractiveViewer(constrained: false, minScale: 1, maxScale: 8, boundaryMargin: zero)` 内，因此无论怎样拖动或缩放，圆形内都不会出现空隙。其上覆盖一个带圆形镂空的 `CustomPaint` 遮罩，忽略指针事件。
- **备注：** 视口尺寸和图片基础尺寸被记录下来供 `_save` 使用。变换在 `postFrameCallback` 中重置，绝不在 `build` 中，因为 controller 会通知其监听者。

## _save

- **副作用：** 读取变换矩阵，把视口的左上角和尺寸映射回源像素（`x = -tx / scale * toPixels`，`side = viewport / scale * toPixels`），运行 `cropAvatarJpegInBackground`，并带着 JPEG 弹出路由。失败时显示错误状态。
