# lib/features/profile/services/avatar_image.dart

The pure image operations behind the avatar editor (0.6.1). Every function is synchronous and
allocation-only, so callers run them in another isolate; the two `…InBackground` wrappers do exactly
that. The module imports only `dart:isolate`, `dart:typed_data` and `package:image`. `ProfileStore` no
longer decodes images — it stores the JPEG the editor produces. See
[`../views/avatar_editor.md`](../views/avatar_editor.md), [`profile_store.md`](profile_store.md) and
[`../../../../features/profile.md`](../../../../features/profile.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `AvatarSource` | class | B | An upright, size-limited PNG copy of a picked image, with its width and height, ready for the editor. |
| `AvatarSource.new` | constructor | B | Create an avatar source from bytes, width and height. |
| `_decode` | top-level function | B | Decode any image; a decoder exception or a null result becomes a `FormatException`. |
| [`prepareAvatarSource`](#prepareavatarsource) | top-level function | A | Normalise a picked image for the editor: EXIF upright, extra quarter turns, longest edge limited, encoded as PNG. |
| [`cropAvatarJpeg`](#cropavatarjpeg) | top-level function | A | Cut the square the user framed and encode it as a 512-pixel avatar JPEG. |
| [`squareAvatarJpeg`](#squareavatarjpeg) | top-level function | A | Turn any decodable image into a centred square JPEG (moved here from `profile_store.dart`). |
| [`prepareAvatarSourceInBackground`](#background-wrappers) | top-level function | A | Run `prepareAvatarSource` in another isolate. |
| [`cropAvatarJpegInBackground`](#background-wrappers) | top-level function | A | Run `cropAvatarJpeg` in another isolate. |

`avatarSourceMaxEdge` (`2048`) carries a doc comment without a `/// Purpose:` line.

## prepareAvatarSource

- **Inputs:** `bytes` — the picked file; `quarterTurns` — extra clockwise 90-degree turns (the editor's rotate button).
- **Returns:** `AvatarSource` — upright, longest edge at most `avatarSourceMaxEdge`, encoded as PNG.
- **Algorithm:** decode, `bakeOrientation`, `copyRotate(90 * (turns % 4))`, scale down by the longer edge only when needed, `encodePng`.
- **Notes:** Baking the orientation here means the pixels the editor shows and the pixels `cropAvatarJpeg` cuts are the same, whatever the platform's own EXIF handling. Throws `FormatException` for non-images.

## cropAvatarJpeg

- **Inputs:** `source` — bytes from `prepareAvatarSource`; `x`, `y`, `side` — the square in source pixels; `size` — output edge.
- **Returns:** `Uint8List` — JPEG (`quality: 88`), `size` x `size`.
- **Notes:** The square is clamped into the image (`side` to the shorter edge, `x` and `y` so the square stays inside), so rounding at the edges never fails. Throws `FormatException` for non-images.

## squareAvatarJpeg

- **Returns:** `Uint8List` — JPEG bytes of the centred square.
- **Notes:** The non-interactive path (no editor): EXIF orientation, `copyResizeCropSquare`, `encodeJpg(quality: 88)`.

## Background wrappers

`prepareAvatarSourceInBackground(bytes, {quarterTurns})` and `cropAvatarJpegInBackground(source, {x, y, side, size})` each wrap the pure function in `Isolate.run`.

- **Side effects:** Spawn a short-lived isolate.
- **Notes:** They are top-level on purpose. A closure created inside the editor's `State` method also captures that `State` and its controllers, which cannot be sent to another isolate — the call fails and the editor reports "This image could not be used". At top level the closure captures only its arguments.
