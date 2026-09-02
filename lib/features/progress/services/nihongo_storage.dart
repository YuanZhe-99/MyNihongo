import 'dart:convert';
import 'dart:io';

import 'package:myapps_data/myapps_data.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../shared/services/auto_sync_service.dart';
import '../models/study_record.dart';

/// The app's storage hub: the one place that knows where data lives on disk.
///
/// Every file read or write in the app goes through [getAppDir] so a custom
/// storage path keeps working, and every data write goes through [save] so
/// auto-sync learns about it.
class NihongoStorage {
  static const _dataFileName = 'nihongo_progress.json';
  static const _configFileName = 'storage_config.json';

  /// Custom storage directory path override.
  static String? _customPath;

  /// Whether config has been loaded from disk.
  static bool _configLoaded = false;

  /// Purpose: Resolve the platform default data directory.
  /// Inputs: None.
  /// Returns: `Future<Directory>` — `<documents>/MyNihongo`, created if absent.
  /// Side effects: May create the directory.
  /// Notes: Internal helper used within this file only.
  static Future<Directory> _getDefaultAppDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final appDir = Directory(p.join(dir.path, 'MyNihongo'));
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return appDir;
  }

  /// Purpose: Locate `storage_config.json`.
  /// Inputs: None.
  /// Returns: `Future<File>`.
  /// Side effects: May create the default directory.
  /// Notes: Internal helper used within this file only. The config file
  /// always lives in the default location because it holds the custom path.
  static Future<File> _getConfigFile() async {
    final dir = await _getDefaultAppDir();
    return File(p.join(dir.path, _configFileName));
  }

  /// Purpose: Load the storage path from the config file, once.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Reads `storage_config.json`; caches the custom path.
  /// Notes: Internal helper used within this file only. A malformed config
  /// is treated as absent.
  static Future<void> _loadConfig() async {
    if (_configLoaded) return;
    try {
      final file = await _getConfigFile();
      if (await file.exists()) {
        final json =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        _customPath = json['storagePath'] as String?;
      }
    } catch (_) {}
    _configLoaded = true;
  }

  /// Purpose: Resolve the active app data directory.
  /// Inputs: None.
  /// Returns: `Future<Directory>` — the custom path when set, else the default.
  /// Side effects: May create the directory.
  /// Notes: Every file access in the app resolves through here.
  static Future<Directory> getAppDir() async {
    await _loadConfig();
    if (_customPath != null && _customPath!.isNotEmpty) {
      final dir = Directory(_customPath!);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }
    return _getDefaultAppDir();
  }

  /// Purpose: Locate a file inside the app directory.
  /// Inputs: `name`.
  /// Returns: `Future<File>`.
  /// Side effects: None beyond [getAppDir].
  /// Notes: Internal helper used within this file only.
  static Future<File> _getFile(String name) async {
    final appDir = await getAppDir();
    return File(p.join(appDir.path, name));
  }

  /// Purpose: Return the progress data file for direct low-level access.
  /// Inputs: None.
  /// Returns: `Future<File>`.
  /// Side effects: None.
  /// Notes: For flows that need the path rather than the parsed model.
  static Future<File> getDataFile() => _getFile(_dataFileName);

  /// Purpose: Return the active storage directory path for UI display.
  /// Inputs: None.
  /// Returns: `Future<String>`.
  /// Side effects: None.
  /// Notes: Respects the configured custom storage path when one is set.
  static Future<String> getStoragePath() async {
    final appDir = await getAppDir();
    return appDir.path;
  }

  /// Purpose: Change the storage directory and migrate the data to it.
  /// Inputs: `newPath`; pass `null` to reset to the default location.
  /// Returns: `Future<bool>` — false only when the path could not be recorded.
  /// Side effects: Rewrites `storage_config.json` and moves the old folder's
  /// contents to the new location.
  /// Notes: Migrates everything in the folder — the data file, `.sync_base/`,
  /// `backups/`, and `webdav_config.json` — not an enumerated list, so a data
  /// file added later moves automatically. `storage_config.json` stays put.
  /// Leaving `.sync_base/` behind would make the next sync treat records other
  /// devices deleted as new local records and resurrect them everywhere.
  /// Existing destination files win and their source copies are left in place.
  static Future<bool> setStoragePath(String? newPath) async {
    try {
      final oldDir = await getAppDir();

      _customPath = newPath;
      final config = await readConfig();
      if (newPath != null) {
        config['storagePath'] = newPath;
      } else {
        config.remove('storagePath');
      }
      await writeConfig(config);

      final newDir = await getAppDir();
      if (oldDir.path == newDir.path) return true;

      // Per-entry failures are reported rather than thrown; the path change
      // itself has already been persisted, so the move is best-effort and any
      // unmoved file remains readable at the old location.
      await migrateStorageContents(from: oldDir, to: newDir);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Data persistence ──

  /// Purpose: Load the progress data file.
  /// Inputs: None.
  /// Returns: `Future<ProgressData>` — empty when the file is absent or blank.
  /// Side effects: Reads the data file.
  /// Notes: A corrupt file throws rather than being treated as empty, so a
  /// later save cannot silently overwrite data that was merely unreadable.
  static Future<ProgressData> load() async {
    final file = await _getFile(_dataFileName);
    if (!await file.exists()) return const ProgressData();
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return const ProgressData();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return ProgressData.fromJson(json);
  }

  /// Purpose: Write the progress data file.
  /// Inputs: `data`.
  /// Returns: None.
  /// Side effects: Atomically writes the data file, then notifies auto-sync.
  /// Notes: Pretty-printed with two-space indentation — the shared sync
  /// engine writes the same format, which is what lets an unchanged file hit
  /// the raw-equality fast path instead of re-uploading.
  static Future<void> save(ProgressData data) async {
    final file = await _getFile(_dataFileName);
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data.toJson());
    await atomicWriteString(file, jsonStr);
    AutoSyncService.instance.notifySaved();
  }

  /// Purpose: Insert or replace study records by id.
  /// Inputs: `records`.
  /// Returns: None.
  /// Side effects: Reads then rewrites the data file.
  /// Notes: Carries the container's `extraJson` through, so unknown top-level
  /// fields written by a newer build survive an edit made by this one.
  static Future<void> upsertRecords(Iterable<StudyRecord> records) async {
    final data = await load();
    final list = List<StudyRecord>.of(data.records);
    for (final record in records) {
      final idx = list.indexWhere((r) => r.id == record.id);
      if (idx >= 0) {
        list[idx] = record;
      } else {
        list.add(record);
      }
    }
    await save(ProgressData(records: list, extraJson: data.extraJson));
  }

  // ── Config persistence ──

  /// Purpose: Read `storage_config.json`.
  /// Inputs: None.
  /// Returns: `Future<Map<String, dynamic>>` — empty when absent or blank.
  /// Side effects: Reads the config file.
  /// Notes: None.
  static Future<Map<String, dynamic>> readConfig() async {
    final file = await _getConfigFile();
    if (!await file.exists()) return {};
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// Purpose: Write `storage_config.json`.
  /// Inputs: `config`.
  /// Returns: None.
  /// Side effects: Atomically writes the config file.
  /// Notes: Callers read-modify-write so keys they do not own survive.
  static Future<void> writeConfig(Map<String, dynamic> config) async {
    final file = await _getConfigFile();
    await atomicWriteString(
      file,
      const JsonEncoder.withIndent('  ').convert(config),
    );
  }

  /// Purpose: Read the persisted theme mode.
  /// Inputs: None.
  /// Returns: `Future<String?>` — `light`, `dark`, or null for system.
  /// Side effects: Reads the config file.
  /// Notes: None.
  static Future<String?> getThemeMode() async {
    final config = await readConfig();
    return config['themeMode'] as String?;
  }

  /// Purpose: Persist the theme mode.
  /// Inputs: `mode` — `light`, `dark`, or null for system.
  /// Returns: None.
  /// Side effects: Writes the config file.
  /// Notes: The default is removed from config rather than stored.
  static Future<void> setThemeMode(String? mode) async {
    final config = await readConfig();
    if (mode == null) {
      config.remove('themeMode');
    } else {
      config['themeMode'] = mode;
    }
    await writeConfig(config);
  }

  /// Purpose: Read the persisted locale tag.
  /// Inputs: None.
  /// Returns: `Future<String?>` — `en`, `zh`, or null for system.
  /// Side effects: Reads the config file.
  /// Notes: None.
  static Future<String?> getLocaleTag() async {
    final config = await readConfig();
    return config['locale'] as String?;
  }

  /// Purpose: Persist the locale tag.
  /// Inputs: `tag` — null follows the system.
  /// Returns: None.
  /// Side effects: Writes the config file.
  /// Notes: The default is removed from config rather than stored.
  static Future<void> setLocaleTag(String? tag) async {
    final config = await readConfig();
    if (tag == null) {
      config.remove('locale');
    } else {
      config['locale'] = tag;
    }
    await writeConfig(config);
  }
}
