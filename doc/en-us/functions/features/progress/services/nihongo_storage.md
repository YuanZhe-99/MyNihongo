# lib/features/progress/services/nihongo_storage.dart

`NihongoStorage` is the app's storage hub: the one place that knows where data lives on disk. It
resolves the app directory (the platform documents directory plus `MyNihongo`, or the custom path
in `storage_config.json`), reads and writes `nihongo_progress.json` and `storage_config.json`
atomically through the package's `atomicWriteString`, notifies auto-sync after every data save, and
migrates the whole folder when the storage path changes. The `StorageAdapter` the shared engines
use delegates to it (see [../../../app/data_modules.md](../../../app/data_modules.md)). See
[../../../../data-formats.md](../../../../data-formats.md) and
[../../../../features/learning-progress.md](../../../../features/learning-progress.md).

M3.0 added the `ttsEngine` preference beside `ttsVoice`; both are device-local and never synced,
because neither a voice name nor an engine package means anything on another device.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `NihongoStorage._getDefaultAppDir` | static method | B | Resolve `<documents>/MyNihongo`, creating it if absent. |
| `NihongoStorage._getConfigFile` | static method | B | Locate `storage_config.json`, always in the default directory. |
| `NihongoStorage._loadConfig` | static method | B | Load the custom storage path from the config file, once. |
| `NihongoStorage.getAppDir` | static method | B | Resolve the active app data directory — custom path when set, else default. |
| `NihongoStorage._getFile` | static method | B | Locate a file inside the app directory. |
| `NihongoStorage.getDataFile` | static method | B | Return the progress data file for direct low-level access. |
| `NihongoStorage.getStoragePath` | static method | B | Return the active storage directory path for UI display. |
| [`NihongoStorage.setStoragePath`](#setstoragepath) | static method | A | Change the storage directory and migrate the data to it. |
| [`NihongoStorage.load`](#load) | static method | A | Load the progress data file; empty when absent or blank, throws when corrupt. |
| [`NihongoStorage.save`](#save) | static method | A | Write the progress data file atomically and notify auto-sync. |
| `NihongoStorage.upsertRecords` | static method | B | Insert or replace study records by id, carrying the container's `extraJson` through. |
| [`NihongoStorage.recordHistory`](#recordhistory) | static method | A | Remember one analysed sentence, and prune the oldest past the cap. |
| [`NihongoStorage.recordExam`](#recordexam) | static method | A | Remember one sitting of a JLPT paper, and prune the oldest past the cap for that mode. |
| [`NihongoStorage.deleteRecords`](#deleterecords) | static method | A | Forget records the learner deleted. |
| `NihongoStorage.readConfig` | static method | B | Read `storage_config.json`; empty when absent or blank. |
| `NihongoStorage.writeConfig` | static method | B | Write `storage_config.json` atomically. |
| `NihongoStorage.getThemeMode` | static method | B | Read the persisted theme mode (`light`, `dark`, or null for system). |
| `NihongoStorage.setThemeMode` | static method | B | Persist the theme mode; the default is removed rather than stored. |
| `NihongoStorage.getLocaleTag` | static method | B | Read the persisted locale tag (`en`, `zh`, `zh_TW`). |
| `NihongoStorage.setLocaleTag` | static method | B | Persist the locale tag; null removes it. |

## Documentation

### `static Future<bool> setStoragePath(String? newPath)` <a id="setstoragepath"></a>

- **Kind:** static method
- **Purpose:** Change the storage directory and move the data to it.
- **Inputs:** `newPath`; `null` resets to the default location.
- **Returns:** `false` only when the path could not be recorded.
- **Side effects:** Rewrites `storage_config.json`; moves the old folder's contents.
- **Algorithm:** Remember the old directory; record (or remove) `storagePath`; resolve the new
  directory; if it differs, `migrateStorageContents(from: old, to: new)` from `myapps_data`.
- **Usage:** A desktop settings control (arrives with the desktop targets); the Android settings page
  only displays the path today.
- **Notes:** Migrates **everything** in the folder — the data file, `.sync_base/`, `backups/`,
  `webdav_config.json` — not an enumerated list. `storage_config.json` stays put because it holds
  the path itself. Leaving `.sync_base/` behind would make the next sync resurrect records other
  devices deleted. Existing destination files win and their source copies are left in place.

### `static Future<ProgressData> load()` <a id="load"></a>

- **Kind:** static method
- **Purpose:** Read the progress file.
- **Inputs:** None.
- **Returns:** An empty `ProgressData` for a missing or blank file, else the parsed data.
- **Side effects:** Reads the data file.
- **Algorithm:** Exists? blank? else `ProgressData.fromJson(jsonDecode(raw))`.
- **Usage:** `progressDataProvider`, `upsertRecords`.
- **Notes:** A corrupt file **throws** rather than being treated as empty, so a later save cannot
  silently overwrite data that was merely unreadable — the lesson MyDay recorded in its `v1.1.0`
  and `v1.2.5`.

### `static Future<void> save(ProgressData data)` <a id="save"></a>

- **Kind:** static method
- **Purpose:** Write the progress file.
- **Inputs:** `data`.
- **Returns:** None.
- **Side effects:** Atomic write (temp file, then rename); `AutoSyncService.instance.notifySaved()`.
- **Algorithm:** `JsonEncoder.withIndent('  ')`, `atomicWriteString`, notify.
- **Usage:** `upsertRecords`; every future write path.
- **Notes:** The two-space format is the one the shared sync engine writes, which is what lets an
  unchanged file hit the raw-equality fast path instead of re-uploading.

## Reference preferences (`PLAN.md` M1.3)

Five typed accessors over two private helpers, `_getString`/`_setString` and `_getInt`/`_setInt`:
`getLastTab`/`setLastTab`, `getVocabLevel`/`setVocabLevel`, `getGrammarLevel`/`setGrammarLevel`,
`getKanaScript`/`setKanaScript`, `getReferenceListColumns`/`setReferenceListColumns`.

Two properties the helpers enforce for all of them. A default is **removed** rather than written,
so the file stays small and a future change of default reaches devices that never touched the
setting. And a value of the wrong type reads as unset rather than throwing: the file is plain JSON
in a folder the user can point anywhere, so it can be hand-edited. See
[`../../../../features/reference-preferences.md`](../../../../features/reference-preferences.md).

## Speech and AI preferences (`PLAN.md` M2.1, M2.2, M2.4)

Four more pairs over `_getDouble`/`_setDouble` and `_getBool`/`_setBool`, following the same two
rules: `getTtsRate`/`setTtsRate`, `getTtsVoice`/`setTtsVoice`,
`getSpeechNetworkFallback`/`setSpeechNetworkFallback`, and
`getAiAssistEnabled`/`setAiAssistEnabled`.

The last two are the ones worth naming here, because both gate something that would otherwise leave
the device or run a model: each is **false unless the user turned it on**, and each stores "off" as
an absent key rather than as `false`. A hand-edited `"true"` string reads as unset, like every other
wrong-typed value in this file — the string is not a boolean, and a setting this consequential should
not be switchable by a typo. See [`../../../../features/pronunciation.md`](../../../../features/pronunciation.md)
and [`../../../../features/ai-assist.md`](../../../../features/ai-assist.md).

## Developer options (v0.4.6)

One more pair over `_getBool`/`_setBool`, following the same two rules: `getDebugMode` returns false
unless somebody unlocked developer options, and `setDebugMode` stores "off" as an absent key rather
than as `false`.

It sits in `storage_config.json` and is **not synced**, unlike almost every other preference. What
it controls is the diagnosis of *this* device — which model variant it served, which AICore build it
has — so carrying it to another device would turn diagnostics on where nobody asked for them and
where the numbers would be about a different phone. It is written from exactly one place,
`AppSettingsNotifier.setDebugMode`; see
[`../../../shared/providers/app_settings.md`](../../../shared/providers/app_settings.md).

### `static Future<void> recordHistory(HistoryEntry entry, {DateTime? now})` <a id="recordhistory"></a>

- **Kind:** static method
- **Purpose:** Remember one analysed sentence or piece of writing.
- **Inputs:** The `entry`; `now` for tests.
- **Returns:** None.
- **Side effects:** Reads then rewrites the data file; notifies auto-sync once.
- **Algorithm:** Upsert by the entry's id, then collect that kind's entries and remove everything
  past `historyMaxEntries`, oldest first. One load and one save.
- **Usage:** The sentence lab after an analysis; writing practice after a check.
- **Notes:** The id is content-addressed, so re-analysing the same sentence updates the record
  already there and moves it to the top rather than adding a second. The prune happens in the same
  write — the progress file is uploaded whole on every sync, so an unbounded log would eventually
  cost more than the progress it travels with. Pruning **by kind** keeps a busy sentence lab from
  emptying the writing history, and only history records are ever removed. Both callers swallow a
  failure here: remembering is a convenience, and the analysis on screen is the feature.

### `static Future<void> recordExam(ExamAttempt attempt, {DateTime? now})` <a id="recordexam"></a>

- **Kind:** static method
- **Purpose:** Remember one sitting of a JLPT paper.
- **Inputs:** The `attempt`; `now` for tests.
- **Returns:** None.
- **Side effects:** Reads then rewrites the data file; notifies auto-sync once.
- **Algorithm:** Upsert by the attempt's id, then collect that **mode's** attempts and remove
  everything past its cap — `examMaxMockEntries` for a mock, `examMaxPracticeEntries` for practice —
  oldest first. One load and one save.
- **Usage:** `ProgressNotifier.recordExam`, from the quiz page when a paper is submitted.
- **Notes:** Shaped on `recordHistory`, with one difference that matters: **pruning is per mode**. A
  learner who practises daily and sits a mock once a month would otherwise lose every mock to the
  practice runs, and the mocks are the ones worth looking back at. The id is timestamped and salted
  rather than content-addressed, because two sittings of the same paper are genuinely two attempts
  and must not collapse into one the way two analyses of the same sentence should.

### `static Future<void> deleteRecords(Iterable<String> ids)` <a id="deleterecords"></a>

- **Kind:** static method
- **Purpose:** Remove records the learner deleted.
- **Inputs:** The `ids`.
- **Returns:** None.
- **Side effects:** Reads then rewrites the data file; notifies auto-sync.
- **Algorithm:** Drop every record whose id is named. Returns without writing when the set is empty
  or nothing matched.
- **Usage:** The delete button on a history row, and the one on an exam-history tile.
- **Notes:** A real deletion rather than a tombstone: the three-way merge treats a record deleted on
  one side and untouched on the other as deleted, so forgetting a sentence forgets it on the
  learner's other devices too. That is the behaviour a delete button has to have — an entry that came
  back on the next sync would be worse than no button. Not writing when nothing changed keeps an
  idle delete from touching the file and waking a sync.

