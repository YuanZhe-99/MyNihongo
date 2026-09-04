/// Purpose: The synced learning-progress model — one `StudyRecord` per item
/// the user has studied, and the `ProgressData` container written to
/// `nihongo_progress.json`.
/// Inputs: JSON maps from disk, sync, backup, or import.
/// Returns: Immutable model values with unknown JSON fields preserved.
/// Side effects: None.
/// Notes: Records carry no content — only an item id, counters, and SRS state.
/// The kana, vocabulary and grammar catalogs resolve the id to something the
/// user can read. Everything compared across devices is UTC.
library;

/// JSON keys this build understands on a `StudyRecord`.
const _studyRecordJsonKeys = {
  'id',
  'correct',
  'wrong',
  'streak',
  'intervalDays',
  'ease',
  'dueAt',
  'lastReviewedAt',
  'createdAt',
  'modifiedAt',
};

/// JSON keys this build understands on the `ProgressData` container.
const _progressDataJsonKeys = {'records'};

/// The Unix epoch, used as the modification time of a record that arrived
/// without one so it loses every merge rather than winning by accident.
final _epochUtc = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

/// Default SM-2 ease factor for a record that has never been reviewed.
const defaultStudyEase = 2.5;

/// Interval, in days, from which a record counts as mastered.
///
/// Three weeks is the point at which SM-2 schedules stop being daily work; it
/// is a display threshold only and changes no scheduling.
const masteredIntervalDays = 21;

/// Which catalog a study record belongs to, derived from its id prefix.
///
/// `profile`, `lesson` and `history` are not catalog items. They share the
/// file, and the merge, because a second data module would mean a second remote
/// file, a second backup entry and a second set of golden transcripts for state
/// that is a handful of fields — see the decisions log in `PLAN.md`. The kinds
/// that are studied are what [studiedKinds] names.

enum StudyKind { kana, vocab, grammar, profile, lesson, history, other }

/// The kinds the review queue schedules. The others live in the same file but
/// are not items anybody studies.
const studiedKinds = {StudyKind.kana, StudyKind.vocab, StudyKind.grammar};

/// Where a record sits in its learning life, derived rather than stored.
enum StudyStage { fresh, learning, mastered }

/// Purpose: Derive the catalog a record id belongs to.
/// Inputs: `id` — `kana:あ`, `vocab:watashi`, `grammar:desu`, `lab:<hash>`,
/// and so on.
/// Returns: `StudyKind`; [StudyKind.other] for a prefix this build does not
/// know, so a record written by a newer build still loads and merges.
/// Side effects: None.
/// Notes: The kind is not a stored field on purpose: deriving it from the id
/// leaves nothing to fall out of step with it.
StudyKind studyKindOf(String id) {
  final sep = id.indexOf(':');
  final prefix = sep < 0 ? id : id.substring(0, sep);
  return switch (prefix) {
    'kana' => StudyKind.kana,
    'vocab' => StudyKind.vocab,
    'grammar' => StudyKind.grammar,
    'profile' => StudyKind.profile,
    'lesson' => StudyKind.lesson,
    'lab' || 'writing' => StudyKind.history,
    _ => StudyKind.other,
  };
}

/// Purpose: Collect the JSON keys this build does not model.
/// Inputs: `json`, `knownKeys`.
/// Returns: `Map<String, dynamic>`.
/// Side effects: None.
/// Notes: Internal helper used within this file only.
Map<String, dynamic> _unknownJson(
  Map<String, dynamic> json,
  Set<String> knownKeys,
) {
  final extra = Map<String, dynamic>.from(json);
  extra.removeWhere((key, _) => knownKeys.contains(key));
  return extra;
}

/// Purpose: Coerce a dynamically keyed map to string keys.
/// Inputs: `map`.
/// Returns: `Map<String, dynamic>`.
/// Side effects: None.
/// Notes: Internal helper used within this file only.
Map<String, dynamic> _stringKeyedMap(Map<dynamic, dynamic> map) => {
  for (final entry in map.entries) entry.key.toString(): entry.value,
};

/// Purpose: Deep-merge several unknown-field maps, later sources winning.
/// Inputs: `maps`.
/// Returns: `Map<String, dynamic>`.
/// Side effects: None.
/// Notes: Internal helper used within this file only. Nested maps merge key
/// by key; every other value is replaced.
Map<String, dynamic> _mergeJsonMaps(Iterable<Map<String, dynamic>> maps) {
  final merged = <String, dynamic>{};
  for (final map in maps) {
    for (final entry in map.entries) {
      final existing = merged[entry.key];
      final value = entry.value;
      if (existing is Map && value is Map) {
        merged[entry.key] = _mergeJsonMaps([
          _stringKeyedMap(existing),
          _stringKeyedMap(value),
        ]);
      } else {
        merged[entry.key] = value;
      }
    }
  }
  return merged;
}

/// Purpose: Parse an ISO-8601 timestamp into a UTC `DateTime`.
/// Inputs: `value`.
/// Returns: `DateTime?` — null when the value is not a parseable string.
/// Side effects: None.
/// Notes: Internal helper used within this file only. Normalizes to UTC so a
/// timestamp written with an offset compares correctly against one written
/// with `Z`.
DateTime? _parseUtc(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value)?.toUtc();
}

/// Purpose: Parse an integer counter, accepting a whole `double` from JSON.
/// Inputs: `value`.
/// Returns: `int?` — null when the value is not a whole number.
/// Side effects: None.
/// Notes: Internal helper used within this file only.
int? _parseInt(Object? value) {
  if (value is int) return value;
  if (value is double && value == value.roundToDouble()) return value.round();
  return null;
}

/// Purpose: Parse a floating-point field.
/// Inputs: `value`.
/// Returns: `double?` — null when the value is not a number.
/// Side effects: None.
/// Notes: Internal helper used within this file only.
double? _parseDouble(Object? value) {
  if (value is num) return value.toDouble();
  return null;
}

/// One studied item's counters and spaced-repetition state.
class StudyRecord {
  /// Stable item id, `<kind>:<slug>`; also the sync merge key.
  final String id;

  /// Lifetime correct answers.
  final int correct;

  /// Lifetime wrong answers.
  final int wrong;

  /// Consecutive correct answers, reset by a wrong one.
  final int streak;

  /// Current SM-2 interval in days; 0 until the first review.
  final int intervalDays;

  /// Current SM-2 ease factor.
  final double ease;

  /// When the next review is due, UTC; null until the first review.
  final DateTime? dueAt;

  /// When the item was last reviewed, UTC; null until the first review.
  final DateTime? lastReviewedAt;

  /// When the record was created, UTC.
  final DateTime createdAt;

  /// When the record was last changed, UTC. The sync merge compares this.
  final DateTime modifiedAt;

  /// JSON keys this build does not model, carried through unchanged.
  final Map<String, dynamic> extraJson;

  /// Purpose: Create a study record instance.
  /// Inputs: `id`, counters, SRS fields, timestamps, `extraJson`.
  /// Returns: A new `StudyRecord` instance.
  /// Side effects: None.
  /// Notes: Pass UTC timestamps; nothing here converts them.
  const StudyRecord({
    required this.id,
    this.correct = 0,
    this.wrong = 0,
    this.streak = 0,
    this.intervalDays = 0,
    this.ease = defaultStudyEase,
    this.dueAt,
    this.lastReviewedAt,
    required this.createdAt,
    required this.modifiedAt,
    this.extraJson = const {},
  });

  /// Purpose: Create a fresh record for an item that has never been studied.
  /// Inputs: `id`; optional `now` for tests.
  /// Returns: `StudyRecord` with zeroed counters and both timestamps set.
  /// Side effects: None.
  /// Notes: `now` defaults to the current UTC time.
  factory StudyRecord.create(String id, {DateTime? now}) {
    final stamp = (now ?? DateTime.now()).toUtc();
    return StudyRecord(id: id, createdAt: stamp, modifiedAt: stamp);
  }

  /// Purpose: Report which catalog this record belongs to.
  /// Inputs: None.
  /// Returns: `StudyKind`.
  /// Side effects: None.
  /// Notes: Derived from the id prefix; see [studyKindOf].
  StudyKind get kind => studyKindOf(id);

  /// Purpose: Report how many times the item has been answered.
  /// Inputs: None.
  /// Returns: `int`.
  /// Side effects: None.
  /// Notes: None.
  int get reviews => correct + wrong;

  /// Purpose: Report the share of answers that were correct.
  /// Inputs: None.
  /// Returns: `double` between 0 and 1; 0 before the first review.
  /// Side effects: None.
  /// Notes: None.
  double get accuracy => reviews == 0 ? 0 : correct / reviews;

  /// Purpose: Report where the item sits in its learning life.
  /// Inputs: None.
  /// Returns: `StudyStage`.
  /// Side effects: None.
  /// Notes: Derived, not stored: fresh until the first review, mastered once
  /// the interval reaches [masteredIntervalDays], learning in between.
  StudyStage get stage {
    if (lastReviewedAt == null) return StudyStage.fresh;
    if (intervalDays >= masteredIntervalDays) return StudyStage.mastered;
    return StudyStage.learning;
  }

  /// Purpose: Parse a record from JSON, preserving what this build cannot read.
  /// Inputs: `json`.
  /// Returns: `StudyRecord`.
  /// Side effects: None.
  /// Notes: A nullable field (`dueAt`, `lastReviewedAt`) whose value fails to
  /// parse is routed into `extraJson` instead of being dropped, so a newer
  /// build's representation survives a round trip through this one; [toJson]
  /// leaves such a key alone. A counter or SRS field that fails to parse takes
  /// its default and is written back as that default — the two cannot share a
  /// key. A record without `modifiedAt` gets the epoch, so it loses every
  /// merge rather than winning by accident.
  factory StudyRecord.fromJson(Map<String, dynamic> json) {
    final extra = _unknownJson(json, _studyRecordJsonKeys);

    T? read<T>(
      String key,
      T? Function(Object?) parse, {
      bool preserveOnFailure = false,
    }) {
      final raw = json[key];
      if (raw == null) return null;
      final parsed = parse(raw);
      if (parsed == null && preserveOnFailure) extra[key] = raw;
      return parsed;
    }

    final createdAt = read('createdAt', _parseUtc);
    final modifiedAt = read('modifiedAt', _parseUtc);

    return StudyRecord(
      id: json['id'] as String,
      correct: read('correct', _parseInt) ?? 0,
      wrong: read('wrong', _parseInt) ?? 0,
      streak: read('streak', _parseInt) ?? 0,
      intervalDays: read('intervalDays', _parseInt) ?? 0,
      ease: read('ease', _parseDouble) ?? defaultStudyEase,
      dueAt: read('dueAt', _parseUtc, preserveOnFailure: true),
      lastReviewedAt: read(
        'lastReviewedAt',
        _parseUtc,
        preserveOnFailure: true,
      ),
      createdAt: createdAt ?? modifiedAt ?? _epochUtc,
      modifiedAt: modifiedAt ?? createdAt ?? _epochUtc,
      extraJson: extra,
    );
  }

  /// Purpose: Serialize the record, unknown fields included.
  /// Inputs: None.
  /// Returns: `Map<String, dynamic>` ready for `jsonEncode`.
  /// Side effects: None.
  /// Notes: Starts from `extraJson` and overlays the known fields, so a
  /// preserved unknown key can never shadow a real one. A nullable field is
  /// written only when set; when it is null the key is left as `extraJson`
  /// has it — absent normally, or holding the raw value [fromJson] could not
  /// parse — rather than written as `null`.
  Map<String, dynamic> toJson() {
    final json = Map<String, dynamic>.from(extraJson);
    json['id'] = id;
    json['correct'] = correct;
    json['wrong'] = wrong;
    json['streak'] = streak;
    json['intervalDays'] = intervalDays;
    json['ease'] = ease;
    if (dueAt != null) {
      json['dueAt'] = dueAt!.toUtc().toIso8601String();
    }
    if (lastReviewedAt != null) {
      json['lastReviewedAt'] = lastReviewedAt!.toUtc().toIso8601String();
    }
    json['createdAt'] = createdAt.toUtc().toIso8601String();
    json['modifiedAt'] = modifiedAt.toUtc().toIso8601String();
    return json;
  }

  /// Purpose: Create a copy with selected fields replaced.
  /// Inputs: Any field; `modifiedAt` defaults to now when omitted.
  /// Returns: `StudyRecord`.
  /// Side effects: None.
  /// Notes: The `modifiedAt` default is what makes every edit visible to the
  /// sync merge. Pass the existing value explicitly for a change that must
  /// not count as an edit.
  StudyRecord copyWith({
    int? correct,
    int? wrong,
    int? streak,
    int? intervalDays,
    double? ease,
    DateTime? dueAt,
    DateTime? lastReviewedAt,
    DateTime? modifiedAt,
    Map<String, dynamic>? extraJson,
  }) {
    return StudyRecord(
      id: id,
      correct: correct ?? this.correct,
      wrong: wrong ?? this.wrong,
      streak: streak ?? this.streak,
      intervalDays: intervalDays ?? this.intervalDays,
      ease: ease ?? this.ease,
      dueAt: dueAt ?? this.dueAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      createdAt: createdAt,
      modifiedAt: (modifiedAt ?? DateTime.now()).toUtc(),
      extraJson: extraJson ?? this.extraJson,
    );
  }

  /// Purpose: Merge unknown JSON fields from other copies of this record.
  /// Inputs: `sources` — usually the local and remote copies during a sync.
  /// Returns: `StudyRecord` with the union of every source's `extraJson`,
  /// this record's own values winning on a clash.
  /// Side effects: None.
  /// Notes: How a field unknown to this build, present on either side of a
  /// merge, survives the merge.
  StudyRecord withPreservedUnknownJson(Iterable<StudyRecord?> sources) {
    final merged = _mergeJsonMaps([
      for (final source in sources)
        if (source != null) source.extraJson,
      extraJson,
    ]);
    return StudyRecord(
      id: id,
      correct: correct,
      wrong: wrong,
      streak: streak,
      intervalDays: intervalDays,
      ease: ease,
      dueAt: dueAt,
      lastReviewedAt: lastReviewedAt,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
      extraJson: merged,
    );
  }
}

/// The top-level container written to `nihongo_progress.json`.
class ProgressData {
  /// Every studied item, in no particular order.
  final List<StudyRecord> records;

  /// Top-level JSON keys this build does not model.
  final Map<String, dynamic> extraJson;

  /// Purpose: Create a progress data instance.
  /// Inputs: `records`, `extraJson`.
  /// Returns: A new `ProgressData` instance.
  /// Side effects: None.
  /// Notes: None.
  const ProgressData({this.records = const [], this.extraJson = const {}});

  /// Purpose: Parse the container from JSON.
  /// Inputs: `json`.
  /// Returns: `ProgressData`.
  /// Side effects: None.
  /// Notes: Entries of `records` that are not objects are skipped; a
  /// `records` value that is not a list is treated as empty.
  factory ProgressData.fromJson(Map<String, dynamic> json) {
    final raw = json['records'];
    final records = <StudyRecord>[];
    if (raw is List) {
      for (final entry in raw) {
        if (entry is Map) {
          records.add(StudyRecord.fromJson(_stringKeyedMap(entry)));
        }
      }
    }
    return ProgressData(
      records: records,
      extraJson: _unknownJson(json, _progressDataJsonKeys),
    );
  }

  /// Purpose: Serialize the container, unknown fields included.
  /// Inputs: None.
  /// Returns: `Map<String, dynamic>` ready for `jsonEncode`.
  /// Side effects: None.
  /// Notes: Same overlay rule as [StudyRecord.toJson].
  Map<String, dynamic> toJson() {
    final json = Map<String, dynamic>.from(extraJson);
    json['records'] = [for (final record in records) record.toJson()];
    return json;
  }

  /// Every record that tracks a studied catalog item.
  ///
  /// The learner profile, the lesson results and the sentence history share
  /// the file; none of them is an item, so none belongs in a count of what has
  /// been studied or in the review queue.
  Iterable<StudyRecord> get studyRecords =>
      records.where((record) => studiedKinds.contains(record.kind));

  /// Purpose: Look a record up by id.
  /// Inputs: `id`.
  /// Returns: `StudyRecord?`.
  /// Side effects: None.
  /// Notes: Linear; the file is small.
  StudyRecord? recordById(String id) {
    for (final record in records) {
      if (record.id == id) return record;
    }
    return null;
  }

  /// Purpose: Merge top-level unknown fields from other copies of the file.
  /// Inputs: `sources`.
  /// Returns: `ProgressData` with the same records and the union of
  /// `extraJson`.
  /// Side effects: None.
  /// Notes: The record-level counterpart is [StudyRecord.withPreservedUnknownJson].
  ProgressData withPreservedUnknownJson(Iterable<ProgressData?> sources) {
    return ProgressData(
      records: records,
      extraJson: _mergeJsonMaps([
        for (final source in sources)
          if (source != null) source.extraJson,
        extraJson,
      ]),
    );
  }
}
