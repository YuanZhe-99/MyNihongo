import 'dart:convert';
import 'dart:io';

import 'package:myapps_data/myapps_data.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../shared/services/auto_sync_service.dart';
import '../models/exam_attempt.dart';
import '../models/history_entry.dart';
import '../models/learner_profile.dart';
import '../models/study_record.dart';
import 'sm2_scheduler.dart';

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

  /// Purpose: Record the answers to a batch of items and reschedule them.
  /// Inputs: `answers` — item id to whether it was answered correctly; `now`
  /// for tests.
  /// Returns: None.
  /// Side effects: Reads then rewrites the data file, and notifies auto-sync
  /// exactly once.
  /// Notes: The whole batch is one load and one save, so a quiz session costs
  /// one write and one sync debounce rather than one per question. An item with
  /// no record yet gets one — a record is created by the first answer, which is
  /// what makes "new items started today" countable without storing a counter.
  /// The learner's streak is touched here too, and only when the day changes,
  /// so the profile record is written once a day rather than once an answer.
  static Future<void> recordAnswers(
    Map<String, bool> answers, {
    DateTime? now,
  }) async {
    if (answers.isEmpty) return;
    final stamp = (now ?? DateTime.now()).toUtc();
    const scheduler = Sm2Scheduler();
    final data = await load();
    final list = List<StudyRecord>.of(data.records);

    for (final entry in answers.entries) {
      final idx = list.indexWhere((r) => r.id == entry.key);
      final before = idx >= 0
          ? list[idx]
          : StudyRecord.create(entry.key, now: stamp);
      final after = scheduler.apply(
        before,
        correct: entry.value,
        now: stamp,
      );
      if (idx >= 0) {
        list[idx] = after;
      } else {
        list.add(after);
      }
    }

    final today = LearnerProfile.localDateKey(stamp.toLocal());
    final profileIdx = list.indexWhere((r) => r.id == learnerProfileId);
    final existing = profileIdx >= 0 ? list[profileIdx] : null;
    final profile = LearnerProfile.fromRecord(existing);
    final touched = profile.withStreakTouched(today);
    if (!identical(touched, profile)) {
      final record = touched.toRecord(existing, stamp);
      if (profileIdx >= 0) {
        list[profileIdx] = record;
      } else {
        list.add(record);
      }
    }

    await save(ProgressData(records: list, extraJson: data.extraJson));
  }

  /// Purpose: Record one answer.
  /// Inputs: `id`, `correct`; `now` for tests.
  /// Returns: None.
  /// Side effects: As [recordAnswers].
  /// Notes: Quizzes call this per answer rather than batching a whole session,
  /// so an app killed mid-session keeps what was already answered. The sync
  /// scheduler debounces, so the extra saves do not become extra uploads.
  static Future<void> recordAnswer(
    String id,
    bool correct, {
    DateTime? now,
  }) => recordAnswers({id: correct}, now: now);

  /// Purpose: Record whether a unit's checkpoint was passed.
  /// Inputs: The `recordId` — a `lesson:` id; `passed`; `now` for tests.
  /// Returns: None.
  /// Side effects: Loads, updates and saves the progress file.
  /// Notes: **Not through the scheduler.** A unit is not an item to be
  /// reviewed on a schedule; it is a gate that is open or shut. So the record
  /// is a plain counter — how many times the checkpoint was passed, how many
  /// times it was not — and `correct > 0` is what the path reads as "open the
  /// next unit". The item answers inside the session were already recorded
  /// one at a time, by the ordinary path, while the learner was answering
  /// them.
  static Future<void> recordLessonResult(
    String recordId,
    bool passed, {
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now().toUtc();
    final data = await load();
    final list = List<StudyRecord>.of(data.records);
    final index = list.indexWhere((record) => record.id == recordId);
    final existing = index >= 0
        ? list[index]
        : StudyRecord.create(recordId, now: at);
    final updated = existing.copyWith(
      correct: existing.correct + (passed ? 1 : 0),
      wrong: existing.wrong + (passed ? 0 : 1),
      streak: passed ? existing.streak + 1 : 0,
      lastReviewedAt: at,
      modifiedAt: at,
    );
    if (index >= 0) {
      list[index] = updated;
    } else {
      list.add(updated);
    }
    await save(ProgressData(records: list, extraJson: data.extraJson));
  }

  /// Purpose: Read the learner profile out of the progress file.
  /// Inputs: None.
  /// Returns: `Future<LearnerProfile>` — defaults when there is none yet.
  /// Side effects: Reads the data file.
  /// Notes: Most callers read it from `learnerProfileProvider` instead, which
  /// derives it from the already-loaded progress data.
  static Future<LearnerProfile> loadProfile() async =>
      LearnerProfile.fromRecord((await load()).recordById(learnerProfileId));

  /// Purpose: Save the learner's settings.
  /// Inputs: `profile` — the settings to write; `now` for tests.
  /// Returns: None.
  /// Side effects: Reads then rewrites the data file; notifies auto-sync.
  /// Notes: **The streak is carried over from the stored profile, not taken
  /// from the argument.** A streak is earned by answering, and the only thing
  /// that writes it is [recordAnswers]; a settings screen that built a fresh
  /// profile would otherwise reset it to zero, destroying real progress
  /// through a control that says nothing about streaks. Unknown payload keys
  /// survive too, so a field written by a newer build is not dropped by an
  /// edit made by this one.
  static Future<void> saveProfile(
    LearnerProfile profile, {
    DateTime? now,
  }) async {
    final stamp = (now ?? DateTime.now()).toUtc();
    final existing = (await load()).recordById(learnerProfileId);
    final stored = LearnerProfile.fromRecord(existing);
    final merged = profile.copyWith(
      streakDays: stored.streakDays,
      streakLastDate: stored.streakLastDate,
    );
    await upsertRecords([merged.toRecord(existing, stamp)]);
  }

  /// Purpose: Remember one analysed sentence or piece of writing.
  /// Inputs: `entry`; `now` for tests.
  /// Returns: None.
  /// Side effects: Reads then rewrites the data file; notifies auto-sync.
  /// Notes: The id is content-addressed, so re-analysing the same sentence
  /// updates the record already there and moves it to the top rather than
  /// adding a second one. Everything past [historyMaxEntries] of that kind is
  /// dropped in the same write, oldest first: the progress file is uploaded
  /// whole on every sync, so an unbounded log would eventually cost more than
  /// the progress it travels with. Pruning by kind rather than overall keeps a
  /// busy sentence lab from emptying the writing history.
  static Future<void> recordHistory(HistoryEntry entry, {DateTime? now}) async {
    final stamp = (now ?? DateTime.now()).toUtc();
    final data = await load();
    final list = List<StudyRecord>.of(data.records);
    final index = list.indexWhere((record) => record.id == entry.id);
    final written = entry.toRecord(index >= 0 ? list[index] : null, stamp);
    if (index >= 0) {
      list[index] = written;
    } else {
      list.add(written);
    }

    final ofKind = historyEntries(list, kind: entry.kind);
    if (ofKind.length > historyMaxEntries) {
      final doomed = {
        for (final old in ofKind.skip(historyMaxEntries)) old.id,
      };
      list.removeWhere((record) => doomed.contains(record.id));
    }

    await save(ProgressData(records: list, extraJson: data.extraJson));
  }

  /// Purpose: Remember one sitting of a JLPT paper.
  /// Inputs: `attempt`; `now` for tests.
  /// Returns: None.
  /// Side effects: Reads then rewrites the data file; notifies auto-sync.
  /// Notes: Shaped on [recordHistory], with one difference that matters:
  /// **pruning is per mode**. A learner who practises daily and sits a mock
  /// once a month would otherwise lose every mock to the practice runs, and
  /// the mocks are the ones worth looking back at.
  ///
  /// The id is timestamped and salted rather than content-addressed, because
  /// two sittings of the same paper are genuinely two attempts and must not
  /// collapse into one the way two analyses of the same sentence should.
  static Future<void> recordExam(ExamAttempt attempt, {DateTime? now}) async {
    final stamp = (now ?? DateTime.now()).toUtc();
    final data = await load();
    final list = List<StudyRecord>.of(data.records);
    final index = list.indexWhere((record) => record.id == attempt.id);
    final written = attempt.toRecord(index >= 0 ? list[index] : null, stamp);
    if (index >= 0) {
      list[index] = written;
    } else {
      list.add(written);
    }

    final cap = attempt.mode == ExamMode.mock
        ? examMaxMockEntries
        : examMaxPracticeEntries;
    final ofMode = examAttempts(list, mode: attempt.mode);
    if (ofMode.length > cap) {
      final doomed = {for (final old in ofMode.skip(cap)) old.id};
      list.removeWhere((record) => doomed.contains(record.id));
    }

    await save(ProgressData(records: list, extraJson: data.extraJson));
  }

  /// Purpose: Forget records the learner deleted.
  /// Inputs: `ids`.
  /// Returns: None.
  /// Side effects: Reads then rewrites the data file; notifies auto-sync.
  /// Notes: A real deletion, not a tombstone: the three-way merge treats a
  /// record deleted on one side and untouched on the other as deleted, so a
  /// history entry removed here is removed everywhere on the next sync. That is
  /// the behaviour a delete button has to have; a record that came back would
  /// be worse than no button at all.
  static Future<void> deleteRecords(Iterable<String> ids) async {
    final doomed = ids.toSet();
    if (doomed.isEmpty) return;
    final data = await load();
    final list = List<StudyRecord>.of(data.records)
      ..removeWhere((record) => doomed.contains(record.id));
    if (list.length == data.records.length) return;
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

  /// Purpose: Read one string preference from `storage_config.json`.
  /// Inputs: `key`.
  /// Returns: `Future<String?>` — null when absent or not a string.
  /// Side effects: Reads the config file.
  /// Notes: Internal helper used within this file only. Every typed getter
  /// below funnels through here so a hand-edited config with a wrong type
  /// reads as "unset" rather than crashing the app on launch.
  static Future<String?> _getString(String key) async {
    final config = await readConfig();
    final value = config[key];
    return value is String ? value : null;
  }

  /// Purpose: Write or remove one string preference.
  /// Inputs: `key`, `value` — null removes the key.
  /// Returns: None.
  /// Side effects: Writes the config file.
  /// Notes: Internal helper used within this file only. A default is removed
  /// rather than written, so the file stays small and a future change of
  /// default reaches devices that never touched the setting.
  static Future<void> _setString(String key, String? value) async {
    final config = await readConfig();
    if (value == null) {
      config.remove(key);
    } else {
      config[key] = value;
    }
    await writeConfig(config);
  }

  /// Purpose: Read one integer preference.
  /// Inputs: `key`.
  /// Returns: `Future<int?>`.
  /// Side effects: Reads the config file.
  /// Notes: Internal helper used within this file only.
  static Future<int?> _getInt(String key) async {
    final config = await readConfig();
    final value = config[key];
    return value is int ? value : null;
  }

  /// Purpose: Write or remove one integer preference.
  /// Inputs: `key`, `value` — null removes the key.
  /// Returns: None.
  /// Side effects: Writes the config file.
  /// Notes: Internal helper used within this file only.
  static Future<void> _setInt(String key, int? value) async {
    final config = await readConfig();
    if (value == null) {
      config.remove(key);
    } else {
      config[key] = value;
    }
    await writeConfig(config);
  }

  /// Purpose: Read the tab the app was last on.
  /// Inputs: None.
  /// Returns: `Future<String?>` — `learn`, `kana`, `vocab`, `grammar` or
  /// `settings`; null before the first switch.
  /// Side effects: Reads the config file.
  /// Notes: The router validates it; an unknown value falls back to Learn.
  static Future<String?> getLastTab() => _getString('lastTab');

  /// Purpose: Remember the tab the user is on.
  /// Inputs: `tab`.
  /// Returns: None.
  /// Side effects: Writes the config file.
  /// Notes: Written on every tab switch, so it stays cheap: one small file.
  static Future<void> setLastTab(String? tab) => _setString('lastTab', tab);

  /// Purpose: Read the level filter the vocabulary page was left on.
  /// Inputs: None.
  /// Returns: `Future<String?>` — a JLPT label, or null for all levels.
  /// Side effects: Reads the config file.
  /// Notes: None.
  static Future<String?> getVocabLevel() => _getString('vocabLevel');

  /// Purpose: Remember the vocabulary page's level filter.
  /// Inputs: `level` — a JLPT label, or null for all levels.
  /// Returns: None.
  /// Side effects: Writes the config file.
  /// Notes: None.
  static Future<void> setVocabLevel(String? level) =>
      _setString('vocabLevel', level);

  /// Purpose: Read the level filter the grammar page was left on.
  /// Inputs: None.
  /// Returns: `Future<String?>` — a JLPT label, or null for all levels.
  /// Side effects: Reads the config file.
  /// Notes: Separate from the vocabulary filter: a learner reading N3 grammar
  /// is often still looking up N5 words.
  static Future<String?> getGrammarLevel() => _getString('grammarLevel');

  /// Purpose: Remember the grammar page's level filter.
  /// Inputs: `level` — a JLPT label, or null for all levels.
  /// Returns: None.
  /// Side effects: Writes the config file.
  /// Notes: None.
  static Future<void> setGrammarLevel(String? level) =>
      _setString('grammarLevel', level);

  /// Purpose: Read the kana script the chart was left on.
  /// Inputs: None.
  /// Returns: `Future<String?>` — `katakana`, or null for hiragana.
  /// Side effects: Reads the config file.
  /// Notes: Hiragana is the default and is stored as an absent key.
  static Future<String?> getKanaScript() => _getString('kanaScript');

  /// Purpose: Remember the kana chart's script.
  /// Inputs: `script` — `katakana`, or null for hiragana.
  /// Returns: None.
  /// Side effects: Writes the config file.
  /// Notes: None.
  static Future<void> setKanaScript(String? script) =>
      _setString('kanaScript', script);

  /// Purpose: Read the chosen column count for the reference lists.
  /// Inputs: None.
  /// Returns: `Future<int?>` — 1 to 4, or null to let the layout decide.
  /// Side effects: Reads the config file.
  /// Notes: One preference for both reference lists: they use the same tile
  /// width and the same rule, so two settings would only ever disagree by
  /// accident.
  static Future<int?> getReferenceListColumns() =>
      _getInt('referenceListColumns');

  /// Purpose: Remember the chosen column count.
  /// Inputs: `columns` — 1 to 4, or null for automatic.
  /// Returns: None.
  /// Side effects: Writes the config file.
  /// Notes: The layout clamps whatever is stored to what actually fits, so a
  /// value saved on a tablet does nothing harmful on a phone.
  static Future<void> setReferenceListColumns(int? columns) =>
      _setInt('referenceListColumns', columns);

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
  /// Returns: `Future<String?>` — `en`, `zh`, `zh_TW`, or null for system.
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

  /// Purpose: Read one fractional preference.
  /// Inputs: `key`.
  /// Returns: `Future<double?>`.
  /// Side effects: Reads the config file.
  /// Notes: Internal helper used within this file only. A whole number written
  /// by an earlier build (or by hand) arrives as an `int`, so both numeric
  /// shapes are accepted; anything else reads as unset.
  static Future<double?> _getDouble(String key) async {
    final config = await readConfig();
    final value = config[key];
    return value is num ? value.toDouble() : null;
  }

  /// Purpose: Write or remove one fractional preference.
  /// Inputs: `key`, `value` — null removes the key.
  /// Returns: None.
  /// Side effects: Writes the config file.
  /// Notes: Internal helper used within this file only.
  static Future<void> _setDouble(String key, double? value) async {
    final config = await readConfig();
    if (value == null) {
      config.remove(key);
    } else {
      config[key] = value;
    }
    await writeConfig(config);
  }

  /// Purpose: Read the chosen text-to-speech speaking rate.
  /// Inputs: None.
  /// Returns: `Future<double?>` — a multiple of normal speed, or null for 1.0.
  /// Side effects: Reads the config file.
  /// Notes: Device-local: a phone speaker and a desktop speaker want different
  /// speeds, and the value means nothing on another device's engine.
  static Future<double?> getTtsRate() => _getDouble('ttsRate');

  /// Purpose: Remember the speaking rate.
  /// Inputs: `rate` — null restores the default.
  /// Returns: None.
  /// Side effects: Writes the config file.
  /// Notes: `TtsService` clamps whatever is stored to the range it offers, so
  /// a hand-edited extreme does nothing harmful.
  static Future<void> setTtsRate(double? rate) => _setDouble('ttsRate', rate);

  /// Purpose: Read the chosen Japanese voice.
  /// Inputs: None.
  /// Returns: `Future<String?>` — an engine voice name, or null for the
  /// engine's own default.
  /// Side effects: Reads the config file.
  /// Notes: Voice names are engine-specific, which is another reason this is
  /// device-local and never synced. A name that no longer exists resolves back
  /// to the default rather than failing.
  static Future<String?> getTtsVoice() => _getString('ttsVoice');

  /// Purpose: Remember the chosen Japanese voice.
  /// Inputs: `name` — null restores the engine default.
  /// Returns: None.
  /// Side effects: Writes the config file.
  /// Notes: None.
  static Future<void> setTtsVoice(String? name) => _setString('ttsVoice', name);

  /// Purpose: Read the chosen speech engine.
  /// Inputs: None.
  /// Returns: `Future<String?>` — an engine package name, or null for the
  /// system default engine.
  /// Side effects: Reads the config file.
  /// Notes: Android devices commonly ship two engines, and they do not have
  /// the same voices — so this is device-local for the same reason the voice
  /// name is. An engine that has since been uninstalled resolves back to the
  /// system default rather than failing.
  static Future<String?> getTtsEngine() => _getString('ttsEngine');

  /// Purpose: Remember the chosen speech engine.
  /// Inputs: `engine` — null restores the system default engine.
  /// Returns: None.
  /// Side effects: Writes the config file.
  /// Notes: None.
  static Future<void> setTtsEngine(String? engine) =>
      _setString('ttsEngine', engine);

  /// Purpose: Read which quiz modes the learner has left switched on.
  /// Inputs: None.
  /// Returns: `Future<String?>` — a comma-joined list of mode names, or null
  /// when every mode is on.
  /// Side effects: Reads the config file.
  /// Notes: Absent means all of them, so a build that adds a mode switches it
  /// on for everybody who never touched the setting — which is what a learner
  /// who has not opted out expects. Device-local: which ways of asking suit
  /// somebody depends on the keyboard and the speaker in front of them.
  static Future<String?> getQuizModes() => _getString('quizModes');

  /// Purpose: Remember which quiz modes are switched on.
  /// Inputs: `modes` — a comma-joined list, or null for all of them.
  /// Returns: None.
  /// Side effects: Writes the config file.
  /// Notes: None.
  static Future<void> setQuizModes(String? modes) =>
      _setString('quizModes', modes);
  /// Purpose: Read whether kana are printed over kanji.
  /// Inputs: None.
  /// Returns: `Future<bool>` — true unless the learner turned it off.
  /// Side effects: Reads the config file.
  /// Notes: **The default is on and `false` is what gets written**, which is
  /// the opposite of every other boolean here. A learner who has never opened
  /// Settings is a learner who most needs the readings, so an absent key has
  /// to mean on. Device-local: whether furigana help depends on the reader,
  /// not on the account.
  static Future<bool> getShowFurigana() async =>
      await _getBool('furigana') ?? true;

  /// Purpose: Remember whether kana are printed over kanji.
  /// Inputs: `show`.
  /// Returns: None.
  /// Side effects: Writes the config file.
  /// Notes: On is stored as an absent key, so the stored value is only ever
  /// `false` — see [getShowFurigana] for why this one is inverted.
  static Future<void> setShowFurigana(bool show) =>
      _setBool('furigana', show ? null : false);

  /// Purpose: Read one boolean preference.
  /// Inputs: `key`.
  /// Returns: `Future<bool?>`.
  /// Side effects: Reads the config file.
  /// Notes: Internal helper used within this file only. Only a real JSON
  /// boolean counts; the string `"true"` reads as unset, like every other
  /// wrong-typed value in this file.
  static Future<bool?> _getBool(String key) async {
    final config = await readConfig();
    final value = config[key];
    return value is bool ? value : null;
  }

  /// Purpose: Write or remove one boolean preference.
  /// Inputs: `key`, `value` — null removes the key.
  /// Returns: None.
  /// Side effects: Writes the config file.
  /// Notes: Internal helper used within this file only.
  static Future<void> _setBool(String key, bool? value) async {
    final config = await readConfig();
    if (value == null) {
      config.remove(key);
    } else {
      config[key] = value;
    }
    await writeConfig(config);
  }

  /// Purpose: Read whether network speech recognition is allowed.
  /// Inputs: None.
  /// Returns: `Future<bool>` — false unless the user turned it on.
  /// Side effects: Reads the config file.
  /// Notes: The default is off, and an absent key means off, so a device that
  /// never touched the setting never sends audio to a server. See
  /// `doc/en-us/features/pronunciation.md`.
  static Future<bool> getSpeechNetworkFallback() async =>
      await _getBool('speechNetworkFallback') ?? false;

  /// Purpose: Remember whether network speech recognition is allowed.
  /// Inputs: `allowed`.
  /// Returns: None.
  /// Side effects: Writes the config file.
  /// Notes: Off is stored as an absent key, like every other default here.
  static Future<void> setSpeechNetworkFallback(bool allowed) =>
      _setBool('speechNetworkFallback', allowed ? true : null);

  /// Purpose: Read whether a question speaks itself when it appears.
  /// Inputs: None.
  /// Returns: `Future<bool>` — true unless the learner turned it off.
  /// Side effects: Reads the config file.
  /// Notes: On by default, so `false` is what gets written — the same
  /// inversion `furigana` uses and for the same reason: hearing the word is
  /// most of the point of a listening question, and a learner who has never
  /// opened Settings should not have to find a button to get it.
  static Future<bool> getAutoSpeak() async =>
      await _getBool('autoSpeak') ?? true;

  /// Purpose: Remember whether a question speaks itself.
  /// Inputs: `speak`.
  /// Returns: None.
  /// Side effects: Writes the config file.
  /// Notes: On is stored as an absent key; see [getAutoSpeak].
  static Future<void> setAutoSpeak(bool speak) =>
      _setBool('autoSpeak', speak ? null : false);

  /// Purpose: Read whether the smaller, faster on-device model is preferred.
  /// Inputs: None.
  /// Returns: `Future<bool>` — false unless the learner asked for it.
  /// Side effects: Reads the config file.
  /// Notes: Off by default, because the larger model gives the better
  /// explanation and that is what these features are for. On a device that
  /// serves only one size this changes nothing, which is why Settings hides
  /// the control there rather than showing one that cannot switch anything.
  static Future<bool> getPreferFastModel() async =>
      await _getBool('preferFastModel') ?? false;

  /// Purpose: Remember which on-device model size is preferred.
  /// Inputs: `fast`.
  /// Returns: None.
  /// Side effects: Writes the config file.
  /// Notes: Off is stored as an absent key; see [getPreferFastModel].
  static Future<void> setPreferFastModel(bool fast) =>
      _setBool('preferFastModel', fast ? true : null);

  /// Purpose: Read whether the daily reminder is on.
  /// Inputs: None.
  /// Returns: `Future<bool>` — false unless the learner turned it on.
  /// Side effects: Reads the config file.
  /// Notes: Off by default and stored as an absent key, so a device that never
  /// touched this setting is never asked for notification permission and never
  /// posts anything.
  static Future<bool> getReminderEnabled() async =>
      await _getBool('reminderEnabled') ?? false;

  /// Purpose: Remember whether the daily reminder is on.
  /// Inputs: `enabled`.
  /// Returns: None.
  /// Side effects: Writes the config file.
  /// Notes: Off is stored as an absent key, like every other default here.
  static Future<void> setReminderEnabled(bool enabled) =>
      _setBool('reminderEnabled', enabled ? true : null);

  /// Purpose: Read what time the reminder is set for.
  /// Inputs: None.
  /// Returns: `Future<(int, int)>` — hour and minute, 20:00 by default.
  /// Side effects: Reads the config file.
  /// Notes: Stored as `"HH:mm"` rather than as two numbers, because that is
  /// what a person reading the config file understands. Anything that does not
  /// parse reads as the default rather than as midnight.
  static Future<(int, int)> getReminderTime() async {
    final raw = await _getString('reminderTime');
    final parts = raw?.split(':') ?? const [];
    if (parts.length != 2) return (20, 0);
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return (20, 0);
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return (20, 0);
    return (hour, minute);
  }

  /// Purpose: Remember what time the reminder is set for.
  /// Inputs: `hour`, `minute`.
  /// Returns: None.
  /// Side effects: Writes the config file.
  /// Notes: The default, 20:00, is stored as an absent key like every other.
  static Future<void> setReminderTime(int hour, int minute) => _setString(
    'reminderTime',
    hour == 20 && minute == 0
        ? null
        : '${hour.toString().padLeft(2, '0')}:'
              '${minute.toString().padLeft(2, '0')}',
  );

  /// Purpose: Read the last day a desktop reminder was posted.
  /// Inputs: None.
  /// Returns: `Future<String?>` — a `YYYY-MM-DD` local date, or null.
  /// Side effects: Reads the config file.
  /// Notes: Desktop only. There is no system scheduler there, so the app posts
  /// from a timer and this is what stops a machine left running from posting
  /// every minute for an hour.
  static Future<String?> getLastReminderDate() =>
      _getString('lastReminderDate');

  /// Purpose: Remember the last day a desktop reminder was posted.
  /// Inputs: `date`.
  /// Returns: None.
  /// Side effects: Writes the config file.
  /// Notes: None.
  static Future<void> setLastReminderDate(String? date) =>
      _setString('lastReminderDate', date);

  /// Purpose: Read whether on-device AI assistance is turned on.
  /// Inputs: None.
  /// Returns: `Future<bool>` — false unless the user turned it on.
  /// Side effects: Reads the config file.
  /// Notes: Device-local and never synced: whether a phone has AICore and a
  /// downloaded model is a fact about that phone. Off is stored as an absent
  /// key, so a device that never touched the setting never runs a model. See
  /// `doc/en-us/features/ai-assist.md`.
  static Future<bool> getAiAssistEnabled() async =>
      await _getBool('aiAssistEnabled') ?? false;

  /// Purpose: Remember whether on-device AI assistance is turned on.
  /// Inputs: `enabled`.
  /// Returns: None.
  /// Side effects: Writes the config file.
  /// Notes: Off is stored as an absent key, like every other default here.
  static Future<void> setAiAssistEnabled(bool enabled) =>
      _setBool('aiAssistEnabled', enabled ? true : null);
}
