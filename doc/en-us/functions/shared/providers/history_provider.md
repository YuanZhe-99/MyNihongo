# lib/shared/providers/history_provider.dart

The sentence lab's and writing practice's histories, derived from the progress file so the pages read
them synchronously instead of loading a file in a build method.

Consumers: `sentence_lab_page.dart`, `writing_practice_page.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | Two derived views of the progress file's history records. |
| [`labHistoryProvider`](#labhistoryprovider) | provider | A | Every remembered sentence from the lab, newest first. |
| [`writingHistoryProvider`](#writinghistoryprovider) | provider family | A | Every remembered piece of writing for one unit. |

## Documentation

### `labHistoryProvider` <a id="labhistoryprovider"></a>

- **Kind:** `Provider<List<HistoryEntry>>`
- **Purpose:** Give the sentence lab its history.
- **Inputs:** `progressDataProvider`.
- **Returns:** The `lab:` entries, newest first; empty while the file is loading or unreadable.
- **Side effects:** None of its own.
- **Algorithm:** Read the progress data through `asData`, then `historyEntries` for
  `HistoryKind.lab`.
- **Usage:** The lab page watches it; an entry written, restored from a backup, or synced in from
  another device all reach the list the same way.
- **Notes:** A plain `Provider` rather than a notifier, the same shape as `learnerProfileProvider`:
  the progress file is the state and this is a function of it, so there is no second source of truth
  to keep in step. It reads through **`asData`, not `value`** — in riverpod 1.x `value` *rethrows*
  when the file could not be loaded, which would take down every page showing a history rather than
  showing an empty one. A device whose storage is unreadable has bigger problems than an empty
  history, and the pages above this still work.

### `writingHistoryProvider` <a id="writinghistoryprovider"></a>

- **Kind:** `Provider.family<List<HistoryEntry>, String?>`
- **Purpose:** Give a writing exercise its own history.
- **Inputs:** `progressDataProvider`; the unit id as the family argument.
- **Returns:** The `writing:` entries for that unit, newest first.
- **Side effects:** None of its own.
- **Algorithm:** As above, narrowed by `unitId`.
- **Usage:** The writing page watches it with `widget.prompt.unit?.id`.
- **Notes:** Keyed by unit because a writing prompt is about its own unit, and the history beside it
  should be what was written for *this* exercise rather than everything ever written. A null family
  argument is the unfiltered list, which is what a prompt opened outside a unit gets.
