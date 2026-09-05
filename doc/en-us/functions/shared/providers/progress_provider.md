# lib/shared/providers/progress_provider.dart

Declares `ProgressNotifier` and `progressDataProvider`, a
`StateNotifierProvider<ProgressNotifier, AsyncValue<ProgressData>>` over `NihongoStorage.load()`.
Pages that show progress watch it and call `reload()` after a save. A sync, a backup restore, or a
ZIP import reaches it through `AutoSyncService`'s local-data-changed callback, which the notifier —
not each page — registers. See
[../../../features/learning-progress.md](../../../features/learning-progress.md) and
[../../../features/sync-and-backup.md](../../../features/sync-and-backup.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | `library` | B | Expose the user's progress file to the widget tree and keep it current. |
| `ProgressNotifier` | constructor | B | Create the notifier and start the first read. |
| `ProgressNotifier.reload` | method | B | Re-read the progress file and publish the result. |
| `ProgressNotifier.recordExam` | method | B | Record one sitting of a JLPT paper, then reload. |
| `ProgressNotifier._onLocalDataChanged` | method | B | React to a sync, restore, or import writing the file. |
| `ProgressNotifier.dispose` | method | B | Release the service callback. |
| `progressDataProvider` | top-level `final` | — | The user's progress file, read from disk and kept current. |

Reload never returns the state to `loading` after the first read, so a background sync does not
blank a page that is already showing data.

`recordExam` is a thin wrapper over `NihongoStorage.recordExam`, like the other write methods here:
write, then reload. An attempt does not go through the scheduler — the questions it asked already
moved their own items' intervals, one at a time, as they were answered — and it is written once at
the end rather than per answer, because half an exam is not an attempt.
