# lib/features/progress/services/nihongo_storage.dart

`NihongoStorage` is the app's storage hub: the one place that knows where data lives on disk. It
resolves the app directory (the platform documents directory plus `MyNihongo`, or the custom path
in `storage_config.json`), reads and writes `nihongo_progress.json` and `storage_config.json`
atomically through the package's `atomicWriteString`, notifies auto-sync after every data save, and
migrates the whole folder when the storage path changes. The `StorageAdapter` the shared engines
use delegates to it (see [../../../app/data_modules.md](../../../app/data_modules.md)). See
[../../../../data-formats.md](../../../../data-formats.md) and
[../../../../features/learning-progress.md](../../../../features/learning-progress.md).

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
| `NihongoStorage.readConfig` | static method | B | Read `storage_config.json`; empty when absent or blank. |
| `NihongoStorage.writeConfig` | static method | B | Write `storage_config.json` atomically. |
| `NihongoStorage.getThemeMode` | static method | B | Read the persisted theme mode (`light`, `dark`, or null for system). |
| `NihongoStorage.setThemeMode` | static method | B | Persist the theme mode; the default is removed rather than stored. |
| `NihongoStorage.getLocaleTag` | static method | B | Read the persisted locale tag. |
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
