import 'dart:convert';

import 'package:myapps_data/myapps_data.dart';

import '../../features/progress/models/study_record.dart';

// ─── Generic record merge ───────────────────────────────────────────
//
// `mergeRecords<T>`, `RecordConflict<T>`, and `RecordMergeResult<T>` live in
// the shared package. They are re-exported here so the conflict dialog and the
// tests import one file for everything merge-related.
export 'package:myapps_data/myapps_data.dart'
    show RecordConflict, RecordMergeResult, mergeRecords;

// ─── Progress-specific merge ────────────────────────────────────────

/// Result of merging progress data with possible per-record conflicts.
class ProgressMergeResult {
  final List<StudyRecord> merged;
  final List<RecordConflict<StudyRecord>> conflicts;
  final Map<String, dynamic> extraJson;

  /// Purpose: Create a progress merge result instance.
  /// Inputs: `merged`, `conflicts`, `extraJson`.
  /// Returns: A new `ProgressMergeResult` instance.
  /// Side effects: None.
  /// Notes: None.
  const ProgressMergeResult({
    required this.merged,
    this.conflicts = const [],
    this.extraJson = const {},
  });

  /// Purpose: Report whether any record needs a manual decision.
  /// Inputs: None.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: None.
  bool get hasConflicts => conflicts.isNotEmpty;

  /// Purpose: Build the final merged dataset from conflict resolutions.
  /// Inputs: `resolutions` — each conflicting record ID mapped to the chosen
  /// record.
  /// Returns: `ProgressData`.
  /// Side effects: None.
  /// Notes: A conflict without a resolution keeps the local record, the
  /// same fallback the sibling apps use.
  ProgressData buildResolved(Map<String, StudyRecord> resolutions) {
    final all = <StudyRecord>[...merged];
    for (final c in conflicts) {
      final chosen = resolutions[c.id] ?? c.localRecord;
      all.add(chosen.withPreservedUnknownJson([c.localRecord, c.remoteRecord]));
    }
    return ProgressData(records: all, extraJson: extraJson);
  }
}

/// Purpose: Merge local, remote, and base progress JSON into one
/// conflict-aware result.
/// Inputs: `localJson`, `remoteJson`, `baseJson`, `autoResolve`.
/// Returns: `ProgressMergeResult`.
/// Side effects: None.
/// Notes: Preserves unknown JSON fields on both the records and the top-level
/// container while delegating per-record decisions to `mergeRecords`. Records
/// are keyed by `StudyRecord.id`, compared by `modifiedAt`, and named by their
/// id in the conflict dialog because the id is the stable, nonlocalized label.
ProgressMergeResult mergeProgressData(
  String localJson,
  String remoteJson,
  String? baseJson, {
  bool autoResolve = false,
}) {
  final localData = ProgressData.fromJson(
    jsonDecode(localJson) as Map<String, dynamic>,
  );
  final remoteData = ProgressData.fromJson(
    jsonDecode(remoteJson) as Map<String, dynamic>,
  );
  final baseData = baseJson != null
      ? ProgressData.fromJson(jsonDecode(baseJson) as Map<String, dynamic>)
      : null;
  final localMap = {for (final r in localData.records) r.id: r};
  final remoteMap = {for (final r in remoteData.records) r.id: r};

  final result = mergeRecords<StudyRecord>(
    local: localData.records,
    remote: remoteData.records,
    base: baseData?.records,
    getId: (r) => r.id,
    getModifiedAt: (r) => r.modifiedAt,
    getDisplayName: (r) => r.id,
    autoResolve: autoResolve,
    serialize: (r) => jsonEncode(r.toJson()),
  );
  final merged = result.merged
      .map(
        (record) => record.withPreservedUnknownJson([
          localMap[record.id],
          remoteMap[record.id],
        ]),
      )
      .toList();
  final extraJson = localData.withPreservedUnknownJson([remoteData]).extraJson;

  return ProgressMergeResult(
    merged: merged,
    conflicts: result.conflicts,
    extraJson: extraJson,
  );
}
