# Profile (name and avatar)

P3 delegates model, merge, storage coordination and avatar components to
`myapps_profile`; app providers, picker, module registration and edit dialog retain
the behaviors below. See [../shared-ui.md](../shared-ui.md).

Since 0.6.0 the app has a small user profile: a **display name** and an **avatar**. Both are
optional, and both sync to every device through WebDAV and are included in backups. Per-file detail
is in [`../functions/features/profile/`](../functions/features/profile/services/profile_store.md);
the file format is in [`../data-formats.md`](../data-formats.md#profilejson) and the sync rules in
[`../sync.md`](../sync.md#the-profile-file).

## Where it appears

- **Home (Learn) app bar.** The avatar, in a small circle, sits at the left of the Learn tab title, the first tab of the shell; no other page shows it.
  Tapping it opens Settings (the app bar button's tooltip is *Profile and settings*). With nothing
  set it shows a person icon; with a name but no avatar it shows the first letter of the name.
- **Settings header.** A *Profile* row is the first item of the Settings list, before *General*, so it
  appears in both the one-pane and the two-pane layout. It shows a larger avatar, the name (or the
  placeholder *Set your name*), the hint *Name and avatar sync across your devices*, and an edit
  icon. Tapping it opens the edit dialog.

## Editing

The edit dialog (*Profile*) holds the large avatar, a *Choose avatar* button, an *Adjust avatar* button and a
*Remove* button that appear only while an avatar is set, and a *Name* field (at most 40 characters).
Tapping the large avatar adjusts it, or picks one when there is none.

- **Avatar changes save immediately.** *Choose avatar* opens the platform file picker for an image and then
  the **avatar editor** (0.6.1); *Adjust avatar* opens the editor on the current avatar; *Remove* clears the
  avatar. If the chosen file cannot be used as an image, a snack bar says *This
  image could not be used* and nothing changes.
- **The name saves on Save.** Cancel discards it. The name is trimmed; an empty name clears it, and
  saving an unchanged name writes nothing.

## Avatar editor and processing

The editor (0.6.1) is a full-screen page: the image sits under a circular mask, and the user drags to
move it, pinches or scrolls to zoom (1x to 8x, never leaving a gap inside the circle), rotates in
quarter turns, resets, and taps **Save**. Backing out saves nothing. The framed square is cropped from
the picked image (decoded, EXIF-upright, longest edge limited to 2048 pixels), scaled to **512 x 512**
pixels and stored as a **JPEG** (quality 88) at `images/avatar_<uuid>.jpg`. The work runs in a separate
isolate so the UI does not stall. A fresh file name is used for every avatar. Replacing or removing the
avatar deletes the previous avatar file on that device only. Adjusting an existing avatar re-frames the
stored 512-pixel image, so it can zoom in, rotate or re-centre but cannot recover detail that was already
cropped away.

## Sync

The profile is the second synced data module (`profile.json`). Each field has its own timestamp and
merges by last writer wins, so changing the name on one device and the avatar on another keeps both;
there is never a conflict dialog. The avatar image travels through the additive image
phase. Because image sync never overwrites or deletes, old avatar files stay on the WebDAV server and
on other devices — a known limitation. Builds older than 0.6.0 never request the file, and each sync
costs one extra `GET profile.json`. Backups include `profile.json` (restore label *Profile*) and the
avatar file, and ZIP export includes both. See [`../sync.md`](../sync.md#the-profile-file) and
[`../backup-restore.md`](../backup-restore.md).

## Behavior notes

- A profile edited on another device appears without restarting: the profile state reloads whenever
  sync or a restore rewrites local data.
- If the avatar file has not reached this device yet, the placeholder is shown until it does.
