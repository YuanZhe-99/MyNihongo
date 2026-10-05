# lib/features/profile/services/avatar_image.dart

P3：下文公共声明位于 `myapps_profile`；应用文件为重新导出或适配，
保留公开导入路径和构造器形式。
见 [../../../../shared-ui.md](../../../../shared-ui.md)。

头像编辑器背后的纯图像操作（0.6.1）。每个函数都是同步且只做内存分配，因此调用方在另一个 isolate 中运行它们；两个 `…InBackground` 包装函数正是这样做的。该模块只导入 `dart:isolate`、`dart:typed_data` 和 `package:image`。`ProfileStore` 不再解码图片——它只存储编辑器产出的 JPEG。见 [`../views/avatar_editor.md`](../views/avatar_editor.md)、[`profile_store.md`](profile_store.md) 和 [`../../../../features/profile.md`](../../../../features/profile.md)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `AvatarSource` | 类 | B | 所选图片转正并限制尺寸后的 PNG 副本，带宽高，供编辑器使用。 |
| `AvatarSource.new` | 构造函数 | B | 由字节、宽和高创建头像源。 |
| `_decode` | 顶层函数 | B | 解码任何图片；解码器异常或返回 null 都变成 `FormatException`。 |
| [`prepareAvatarSource`](#prepareavatarsource) | 顶层函数 | A | 为编辑器规整所选图片：按 EXIF 转正、额外的四分之一圈旋转、限制最长边、编码为 PNG。 |
| [`cropAvatarJpeg`](#cropavatarjpeg) | 顶层函数 | A | 裁出用户取景的正方形并编码为 512 像素的头像 JPEG。 |
| [`squareAvatarJpeg`](#squareavatarjpeg) | 顶层函数 | A | 把任何可解码的图片变成居中裁剪的正方形 JPEG（从 `profile_store.dart` 迁来）。 |
| [`prepareAvatarSourceInBackground`](#后台包装函数) | 顶层函数 | A | 在另一个 isolate 中运行 `prepareAvatarSource`。 |
| [`cropAvatarJpegInBackground`](#后台包装函数) | 顶层函数 | A | 在另一个 isolate 中运行 `cropAvatarJpeg`。 |

`avatarSourceMaxEdge`（`2048`）带有文档注释，但没有 `/// Purpose:` 行。

## prepareAvatarSource

- **输入：** `bytes`——所选文件；`quarterTurns`——额外的顺时针 90 度旋转次数（编辑器的旋转按钮）。
- **返回：** `AvatarSource`——已转正，最长边不超过 `avatarSourceMaxEdge`，编码为 PNG。
- **算法：** 解码、`bakeOrientation`、`copyRotate(90 * (turns % 4))`、仅在需要时按较长边缩小、`encodePng`。
- **备注：** 在这里烘焙方向，意味着编辑器显示的像素和 `cropAvatarJpeg` 裁剪的像素是同一份，不论平台自己如何处理 EXIF。对非图片抛出 `FormatException`。

## cropAvatarJpeg

- **输入：** `source`——来自 `prepareAvatarSource` 的字节；`x`、`y`、`side`——源像素中的正方形；`size`——输出边长。
- **返回：** `Uint8List`——JPEG（`quality: 88`），`size` x `size`。
- **备注：** 正方形会被钳制到图像内（`side` 不超过较短边，`x` 和 `y` 使正方形保持在图内），因此边缘处的舍入永远不会失败。对非图片抛出 `FormatException`。

## squareAvatarJpeg

- **返回：** `Uint8List`——居中正方形的 JPEG 字节。
- **备注：** 非交互路径（没有编辑器）：EXIF 方向、`copyResizeCropSquare`、`encodeJpg(quality: 88)`。

## 后台包装函数

`prepareAvatarSourceInBackground(bytes, {quarterTurns})` 和 `cropAvatarJpegInBackground(source, {x, y, side, size})` 各自把纯函数包在 `Isolate.run` 里。

- **副作用：** 创建一个短命的 isolate。
- **备注：** 它们刻意放在顶层。在编辑器的 `State` 方法里创建的闭包也会捕获该 `State` 及其 controller，而它们无法发送到另一个 isolate——调用会失败，编辑器报告“无法使用此图片”。在顶层，闭包只捕获自己的参数。
