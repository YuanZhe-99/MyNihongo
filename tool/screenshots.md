# Capturing the reference screenshots

No emulator runs on the development host (Windows on ARM64, no AVD and no
attached device), so the screenshots in `doc/screenshots/` are captured from a
real device and reviewed afterwards. This is the procedure.

## What to capture

One shot per page at each pinned geometry, matching the table in
`doc/en-us/adaptive-layout.md`:

| Geometry | Logical size | Stands for |
|---|---|---|
| Phone portrait | 412 x 915 | Pixel 9 |
| Phone landscape | 915 x 412 | the shortest viewport the app supports |
| Fold 8 unfolded, landscape | 933 x 704 | the split layouts at their widest common size |
| Fold 8 unfolded, portrait | 704 x 933 | folded-shape check: one pane, not two |
| Fold 5 unfolded | 659 x 791 | the narrow foldable the kana page keeps on one column |
| Pixel 10 Pro Fold | 791 x 820 | the widest one-column kana case |
| Tablet landscape | 1024 x 768 | three reference columns |
| Tablet portrait | 768 x 1024 | two reference columns |

Pages: Learn, Kana (both scripts, and one search), Vocabulary (list and detail
sheet), Grammar (list and detail sheet), Settings (one pane and two), WebDAV
sync, Backup.

## On a real device

```bash
flutter run --release -d <device-id>
adb exec-out screencap -p > doc/screenshots/<page>_<width>x<height>.png
```

Fold and unfold the device rather than restarting it: the activity's
`configChanges` keeps it alive across the resize, and the point of the
foldable shots is what happens on that resize.

## Without the hardware

Debug builds run inside `DevicePreview`, which can emulate the geometries
above from the device frame picker. It is enough to check layout and overflow;
it is not enough to check what a physical hinge or a cover screen does, so a
`DevicePreview` capture is labelled as one in the review notes.

## Reviewing

The checklist lives in `doc/en-us/adaptive-layout.md` under Testing. Each shot
is looked at for: no overflow stripes, no text clipped mid-glyph, the
navigation on the expected side, and the column count the rules predict.
