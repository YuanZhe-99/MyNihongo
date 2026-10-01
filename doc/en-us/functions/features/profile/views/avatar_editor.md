# lib/features/profile/views/avatar_editor.dart

The full-screen avatar editor (0.6.1). After an image is picked — or the current avatar is opened again — the user frames it inside a circle: drag to move, pinch or scroll to zoom 1x to 8x, rotate in quarter turns, reset, then **Save**. What the circle shows is exactly what is stored. See
[`../services/avatar_image.md`](../services/avatar_image.md), [`profile_header.md`](profile_header.md)
and [`../../../../features/profile.md`](../../../../features/profile.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`showAvatarEditor`](#showavatareditor) | top-level function | A | Push the full-screen editor and return the 512-pixel square JPEG, or null when the user backed out. |
| `AvatarEditorPage` | class | B | A full-screen editor that frames an image inside a circle. |
| `AvatarEditorPage.new` | constructor | B | Create the editor from the source bytes. |
| `AvatarEditorPage.createState` | method (widget lifecycle) | B | Create the editor state. |
| `_AvatarEditorPageState.initState` | method (widget lifecycle) | B | Start preparing the image. |
| `_AvatarEditorPageState.dispose` | method (widget lifecycle) | B | Release the transformation controller. |
| `_AvatarEditorPageState._prepare` | method | B | Decode, orient and size the source for the current rotation, in the background. |
| `_AvatarEditorPageState._rotate` | method | B | Rotate a quarter turn clockwise and re-prepare. |
| `_AvatarEditorPageState._reset` | method | B | Return to the initial framing (centred, filling the circle). |
| [`_AvatarEditorPageState._save`](#_save) | method | A | Map the viewport back to source pixels, crop in the background and pop with the JPEG. |
| [`_AvatarEditorPageState.build`](#build) | method (widget build) | A | Build the app bar, the circular viewport and the hint. |
| `_CircleMaskPainter` | private class | B | Darkens everything outside the avatar circle and outlines the circle. |
| `_CircleMaskPainter.new` | constructor | B | Create the mask painter from the scrim and ring colours. |
| `_CircleMaskPainter.paint` | method | B | Paint the scrim with a circular hole and the outline. |
| `_CircleMaskPainter.shouldRepaint` | method | B | Repaint only when the colours change. |

## showAvatarEditor

- **Inputs:** `context`; `source` — the picked image or the current avatar bytes.
- **Returns:** `Future<Uint8List?>` — a `ProfileStore.avatarSize` square JPEG, or null.
- **Side effects:** Pushes a `fullscreenDialog` `MaterialPageRoute`.
- **Notes:** Never throws for bad input: an undecodable image shows `profileAvatarError` in the editor with *Save* disabled.

## build

- **Layout:** An app bar titled `profileAdjustAvatar` with a rotate button (`profileAvatarRotate`), a reset button (`profileAvatarReset`) and **Save**; below it the viewport and the hint `profileAvatarEditorHint`.
- **Algorithm:** The viewport side is `min(width, height - 96) - 32`, clamped to 160–480. The image is laid out to *cover* that square at zoom 1 (`cover = side / min(w, h)`) inside an `InteractiveViewer(constrained: false, minScale: 1, maxScale: 8, boundaryMargin: zero)`, so it can never be dragged or zoomed to leave a gap inside the circle. A `CustomPaint` scrim with a circular hole sits over it, ignoring pointers.
- **Notes:** The viewport size and the image's base size are recorded for `_save`. The transformation is reset in a `postFrameCallback`, never in `build`, because the controller notifies its listeners.

## _save

- **Side effects:** Reads the transformation matrix, maps the viewport's top-left and size back to source pixels (`x = -tx / scale * toPixels`, `side = viewport / scale * toPixels`), runs `cropAvatarJpegInBackground` and pops the route with the JPEG. On failure shows the error state.
