/// Purpose: Single source of truth describing MyNihongo's syncable data files
/// to the shared `myapps_data` engines.
/// Inputs: `NihongoStorage` for storage paths/settings, `mergeProgressData`
/// for the app's record merge, and the `ProgressData`/`StudyRecord` models
/// for parsing.
/// Returns: A `StorageAdapter` implementation and the app's `ModuleRegistry`.
/// Side effects: None at import time; callbacks perform parsing and storage I/O.
/// Notes: File names and module IDs are persisted compatibility contracts
/// (myapps_data invariants I1/I2) and must never change once a build ships.
library;

import 'dart:convert';
import 'dart:io';

import 'package:myapps_data/myapps_data.dart';

import '../features/progress/models/study_record.dart';
import '../features/progress/services/nihongo_storage.dart';
import '../shared/services/sync_merge.dart';

/// Pretty-printer matching `NihongoStorage`'s local save format.
///
/// Sync writes must use the same indentation the storage hub uses, otherwise an
/// otherwise-unchanged file misses the raw-equality fast path on the next sync
/// and re-uploads forever (I6).
const _prettyJson = JsonEncoder.withIndent('  ');

/// Purpose: Bridge the shared engines to MyNihongo's storage hub.
/// Inputs: Optional [appDir] resolver overriding the hub lookup.
/// Returns: Storage root and `storage_config.json` access.
/// Side effects: Delegates to `NihongoStorage`, which performs file I/O.
/// Notes: [appDir] exists so `BackupService` can expose a
/// `@visibleForTesting appDirProvider` seam; it is read on every call, so tests
/// that swap the provider between cases still work.
class NihongoStorageAdapter implements StorageAdapter {
  /// Purpose: Create an adapter over `NihongoStorage`.
  /// Inputs: Optional [appDir] resolver.
  /// Returns: A new adapter.
  /// Side effects: None.
  /// Notes: Pass [appDir] only to preserve a test seam.
  const NihongoStorageAdapter({Future<Directory> Function()? appDir})
    : _appDir = appDir;

  final Future<Directory> Function()? _appDir;

  /// Purpose: Resolve the active app data directory.
  /// Inputs: None.
  /// Returns: The custom storage path when configured, else the platform dir.
  /// Side effects: May create the directory via the hub.
  /// Notes: Honors the injected resolver first so `appDirProvider` still wins.
  @override
  Future<Directory> getAppDir() => (_appDir ?? NihongoStorage.getAppDir)();

  /// Purpose: Read `storage_config.json`.
  /// Inputs: None.
  /// Returns: The parsed settings map.
  /// Side effects: Reads local storage.
  /// Notes: Delegates so app-owned keys stay owned by the hub.
  @override
  Future<Map<String, dynamic>> readConfig() => NihongoStorage.readConfig();

  /// Purpose: Persist `storage_config.json`.
  /// Inputs: [config] complete settings map.
  /// Returns: A future completing after the write.
  /// Side effects: Writes local storage.
  /// Notes: The engines read-modify-write, so unknown keys survive.
  @override
  Future<void> writeConfig(Map<String, dynamic> config) =>
      NihongoStorage.writeConfig(config);
}

/// Local and remote name of MyNihongo's learning-progress data file (I1/I2).
const progressDataFileName = 'nihongo_progress.json';

/// Backup bundle module key for that file (I2).
const progressModuleId = 'progress';

/// Default remote WebDAV directory for MyNihongo.
const nihongoDefaultRemotePath = '/MyNihongo';

/// Archive name prefix for ZIP exports.
const nihongoArchiveNamePrefix = 'mynihongo_export_';

/// Purpose: Validate a `nihongo_progress.json` payload before it is written.
/// Inputs: [json] raw module content.
/// Returns: None; throws when the payload is not parseable progress data.
/// Side effects: None.
/// Notes: A bare `ProgressData.fromJson(jsonDecode(...))`, so the backup and
/// import engines surface the parser's own exception when a payload is bad.
void validateProgressJson(String json) {
  ProgressData.fromJson(jsonDecode(json) as Map<String, dynamic>);
}

/// Purpose: Encode a merged progress dataset the way the storage hub writes it.
/// Inputs: [data] merged dataset.
/// Returns: Pretty-printed JSON.
/// Side effects: None.
/// Notes: Shared by the merge and conflict-resolution paths.
String encodeProgressData(ProgressData data) =>
    _prettyJson.convert(data.toJson());

/// Purpose: Merge local/remote/base progress JSON for the shared sync engine.
/// Inputs: [localJson], [remoteJson], optional [baseJson], [autoResolve].
/// Returns: A complete outcome, or a pending one carrying the conflicts.
/// Side effects: None.
/// Notes: Wraps `mergeProgressData`. The typed `ProgressMergeResult` is
/// carried through as opaque `state` so `WebDAVService` can hand a real
/// `PendingSync` to the conflict dialog.
ModuleMergeOutcome mergeProgressModule({
  required String localJson,
  required String remoteJson,
  required String? baseJson,
  required bool autoResolve,
}) {
  final result = mergeProgressData(
    localJson,
    remoteJson,
    baseJson,
    autoResolve: autoResolve,
  );
  if (!result.hasConflicts) {
    return ModuleMergeOutcome(
      mergedJson: encodeProgressData(
        ProgressData(records: result.merged, extraJson: result.extraJson),
      ),
      state: result,
    );
  }
  return ModuleMergeOutcome(
    state: result,
    conflicts: [
      for (final conflict in result.conflicts)
        ModuleConflict(
          id: conflict.id,
          localRecord: conflict.localRecord,
          remoteRecord: conflict.remoteRecord,
          displayName: conflict.displayName,
        ),
    ],
    buildResolvedJson: (resolutions) => encodeProgressData(
      result.buildResolved({
        for (final entry in resolutions.entries)
          if (entry.value is StudyRecord) entry.key: entry.value as StudyRecord,
      }),
    ),
  );
}

/// Purpose: Describe `nihongo_progress.json` to the shared engines.
/// Inputs: None.
/// Returns: The app's single [DataModule].
/// Side effects: None.
/// Notes: No `postMergeTransform` (no migration yet), no
/// `preUploadTransform` (unknown-field preservation is baked into the models
/// via `withPreservedUnknownJson`), and no `referencedImages` — study records
/// carry no images.
DataModule buildProgressModule() => DataModule(
  fileName: progressDataFileName,
  moduleId: progressModuleId,
  validate: validateProgressJson,
  merge:
      ({
        required String localJson,
        required String remoteJson,
        required String? baseJson,
        required bool autoResolve,
      }) => mergeProgressModule(
        localJson: localJson,
        remoteJson: remoteJson,
        baseJson: baseJson,
        autoResolve: autoResolve,
      ),
);

/// Purpose: Provide MyNihongo's ordered module registry.
/// Inputs: None.
/// Returns: A registry holding the single progress module.
/// Side effects: None.
/// Notes: Built once; the shared engines treat registry order as significant,
/// so a second module must be appended, never inserted before this one.
final ModuleRegistry nihongoModuleRegistry = ModuleRegistry([
  buildProgressModule(),
]);
