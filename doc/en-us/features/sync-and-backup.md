# Sync and backup, as the user meets them

The engines are described in [`../sync.md`](../sync.md) and
[`../backup-restore.md`](../backup-restore.md). This page describes the screens.

Everything lives under **Settings › Data**, so the whole data story is in one place. On a window
wide enough to split, each row opens in the detail pane beside the list; on a narrow one it is
pushed full screen. Both use the same widgets — see [`../adaptive-layout.md`](../adaptive-layout.md).

## WebDAV sync

`lib/shared/views/webdav_config_page.dart`. The row's subtitle is the live status: a pending
conflict outranks a plain failure, a failure outranks the last success, and an unconfigured server
reads "Not connected". The page itself:

1. A Nextcloud preset button fills the URL shape and the default remote path `/MyNihongo`.
2. Server URL, username, password and remote path, then **Save** and **Test connection**.
3. Once a configuration with a server and credentials is saved, the rest appears: the status card,
   a progress bar with the current phase while a sync runs, **Sync now**, **Force upload**,
   **Force download**, the auto-sync switch, and **Disconnect**.

A sync that finds conflicts opens one dialog per record, showing both versions with their
modification times, correct and wrong counts, streak, stage and last review. Dismissing any of them
aborts the whole resolution: nothing is uploaded and the conflict stays pending. Force upload and
force download each ask for confirmation first, in the error colour, because each discards one
side's changes.

## Backup

`lib/features/settings/views/backup_page.dart`. An information card states that bundles stay on the
device. Below it: the automatic-backup switch, a retention dropdown (forever, 3, 7, 14, 30, 60, 90
days), **Create backup**, and the history newest first. Each row shows its timestamp and size;
a damaged bundle is labelled as such, cannot be restored, and can still be deleted.

Restoring asks which modules to take out of the bundle, then confirms. Afterwards auto-sync is off,
and the page says so and offers a force upload — a restored older file merged automatically would
look like mass deletion on the other devices.

## ZIP export and import

Two rows that act in place. Export asks for a folder and writes
`mynihongo_export_<stamp>.zip`. Import asks for a `.zip`, confirms, and replaces the local
progress. The archive is refused whole if it holds anything but the app's data files, so a
tampered archive is never half-applied.

## What the pages never do

No screen sends anything anywhere except the user's own WebDAV server. Backups and exports go where
the user points them. The WebDAV password is stored in plain text in the app directory, as in the
sibling apps; the privacy policy says so.
