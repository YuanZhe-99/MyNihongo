/// Purpose: Model one sitting of a JLPT paper as a record inside the progress
/// file, so an attempt on one device is in the history on another.
/// Inputs: `exam:` records inside `nihongo_progress.json`.
/// Returns: The [ExamAttempt] model and the helpers that read and write it.
/// Side effects: None; persistence is `NihongoStorage`'s job.
/// Notes: A record rather than a second data module, for the reason the
/// learner profile and the sentence history are records: a record gets the
/// per-record three-way merge, the conflict dialog, sync and backup for free,
/// while a second module means a second remote file, a second backup entry and
/// eleven golden transcripts re-recorded.
///
/// **Only the input is stored.** Which questions were asked and what was
/// answered — never the score of each, never the question text. Everything a
/// results screen shows is joined back from the shipped files at read time, so
/// a content update that corrected an answer key corrects the history too
/// rather than leaving a score the files no longer agree with.
///
/// The section keys are plain strings so `progress/` does not import `drills/`.
/// A section this build has no enum for still round-trips.
library;

import 'study_record.dart';

/// How many mock attempts are kept.
///
/// Lower than the practice cap because a mock is the heavier record — it holds
/// per-section times as well as every answer — and because the thing a learner
/// looks back at is the trend, which forty sittings is plenty for.
const examMaxMockEntries = 40;

/// How many practice attempts are kept.
const examMaxPracticeEntries = 80;

/// The `extraJson` key the payload lives under.
const _examPayloadKey = 'exam';

/// What was answered, for a question that was not.
///
/// Neither right nor wrong: the clock ran out. Stored as its own value so the
/// accuracy is over what was attempted, rather than counting a question nobody
/// saw as one they got wrong.
const examUnanswered = -1;

/// Whether an attempt was practice or a timed mock.
///
/// The name is written into the payload, so these names are a compatibility
/// contract: renaming one hides every attempt recorded under the old name.
enum ExamMode {
  /// Untimed, with the answer explained after each question.
  practice,

  /// Timed per block, marked at the end.
  mock,
}

/// One section's result within an attempt.
class ExamSectionResult {
  /// Purpose: Hold one section's tally and its clock.
  /// Inputs: `asked`, `right`; `seconds` and `limitSeconds` where the section
  /// was timed.
  /// Returns: A new `ExamSectionResult` instance.
  /// Side effects: None.
  /// Notes: The clock is on the **first** section of a shared block, because
  /// the clock is a property of the block: N2 examines three sections in one
  /// 105-minute block, and reporting 105 minutes three times would say the
  /// paper took five and a quarter hours.
  const ExamSectionResult({
    required this.asked,
    required this.right,
    this.seconds,
    this.limitSeconds,
  });

  /// How many questions of this section were on the paper.
  final int asked;

  /// How many were answered correctly.
  final int right;

  /// How long the block this section opened actually took.
  final int? seconds;

  /// How long that block was allowed.
  final int? limitSeconds;

  /// Accuracy from 0 to 1; 0 for a section with nothing in it.
  double get accuracy => asked == 0 ? 0 : right / asked;

  /// Purpose: Read one section out of the payload.
  /// Inputs: `json`.
  /// Returns: `ExamSectionResult?` — null for anything unreadable.
  /// Side effects: None.
  /// Notes: None.
  static ExamSectionResult? fromJson(Object? json) {
    if (json is! Map) return null;
    final asked = _int(json['asked']);
    final right = _int(json['right']);
    if (asked == null || right == null) return null;
    return ExamSectionResult(
      asked: asked,
      right: right,
      seconds: _int(json['secs']),
      limitSeconds: _int(json['limitSecs']),
    );
  }

  /// Purpose: Write one section into the payload.
  /// Inputs: None.
  /// Returns: `Map<String, dynamic>`.
  /// Side effects: None.
  /// Notes: The clock keys are omitted where the section was untimed, so a
  /// practice attempt does not carry two null fields per section.
  Map<String, dynamic> toJson() => {
    'asked': asked,
    'right': right,
    if (seconds != null) 'secs': seconds,
    if (limitSeconds != null) 'limitSecs': limitSeconds,
  };
}

/// One sitting of a paper.
class ExamAttempt {
  /// Purpose: Describe one attempt.
  /// Inputs: All fields; see each one.
  /// Returns: A new `ExamAttempt` instance.
  /// Side effects: None.
  /// Notes: `finishedAt` is null for an attempt that is still open, which only
  /// a saved mock can be — and a saved mock is not a record yet, so in practice
  /// every attempt in the file has one. It is nullable so a file written by a
  /// build that records them earlier still loads.
  const ExamAttempt({
    required this.id,
    required this.level,
    required this.mode,
    required this.scale,
    required this.startedAt,
    this.finishedAt,
    this.sections = const {},
    this.answers = const {},
  });

  /// `exam:20260904T101500Z-3f2a`.
  final String id;

  /// The level's label, `N5` through `N1`.
  final String level;

  /// Practice or mock.
  final ExamMode mode;

  /// `short` or `full`.
  final String scale;

  /// When the attempt began, UTC.
  final DateTime startedAt;

  /// When it was submitted, UTC.
  final DateTime? finishedAt;

  /// One entry per section examined, keyed by the section's name.
  final Map<String, ExamSectionResult> sections;

  /// What was answered, by question id: 1 right, 0 wrong, -1 unanswered.
  ///
  /// Only the input. Which option was chosen is deliberately **not** kept: it
  /// would be a second thing to keep in step with a content file that can
  /// change under it, and nothing on the results screen needs it once the
  /// attempt is closed.
  final Map<String, int> answers;

  /// How many questions the paper asked.
  int get asked => sections.values.fold(0, (sum, s) => sum + s.asked);

  /// How many were right.
  int get right => sections.values.fold(0, (sum, s) => sum + s.right);

  /// Accuracy over the whole paper, 0 to 1.
  double get accuracy => asked == 0 ? 0 : right / asked;

  /// Purpose: Build the id for a new attempt.
  /// Inputs: `startedAt`, and `suffix` — four hex digits.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: The timestamp sorts the ids the way the attempts happened, which
  /// makes a file diff readable and means an id is self-describing in a bug
  /// report. The suffix is what keeps two attempts started in the same second
  /// on two devices from merging into one — unlike the sentence history, two
  /// sittings of the same paper are genuinely two things and must not collapse.
  static String buildId(DateTime startedAt, String suffix) {
    final utc = startedAt.toUtc();
    String two(int value) => value.toString().padLeft(2, '0');
    return 'exam:${utc.year}${two(utc.month)}${two(utc.day)}'
        'T${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z-$suffix';
  }

  /// Purpose: Read an attempt out of a progress record.
  /// Inputs: `record`.
  /// Returns: `ExamAttempt?` — null when the record is not an exam record or
  /// its payload cannot be read.
  /// Side effects: None.
  /// Notes: Never throws, and every field is read independently, so a payload
  /// written by a newer build still loads with the fields this one knows.
  static ExamAttempt? fromRecord(StudyRecord? record) {
    if (record == null) return null;
    if (studyKindOf(record.id) != StudyKind.exam) return null;
    final raw = record.extraJson[_examPayloadKey];
    if (raw is! Map) return null;
    final level = '${raw['level'] ?? ''}';
    if (level.isEmpty) return null;
    final startedAt = _time(raw['startedAt']) ?? record.createdAt;
    return ExamAttempt(
      id: record.id,
      level: level,
      mode: '${raw['mode']}' == 'mock' ? ExamMode.mock : ExamMode.practice,
      scale: '${raw['scale'] ?? 'short'}',
      startedAt: startedAt,
      finishedAt: _time(raw['finishedAt']),
      sections: {
        if (raw['sections'] is Map)
          for (final entry in (raw['sections'] as Map).entries)
            '${entry.key}': ?ExamSectionResult.fromJson(entry.value),
      },
      answers: {
        if (raw['q'] is Map)
          for (final entry in (raw['q'] as Map).entries)
            '${entry.key}': ?_int(entry.value),
      },
    );
  }

  /// Purpose: Write the attempt back into its record.
  /// Inputs: `existing` — the record already in the file, if any; `now`.
  /// Returns: `StudyRecord` ready for `upsertRecords`.
  /// Side effects: None.
  /// Notes: Unknown payload keys are preserved, the rule every record in this
  /// file follows: an older build must not drop a newer one's fields the first
  /// time it touches a record.
  ///
  /// `correct` and `wrong` carry the totals even though the payload holds them
  /// too. They are what an older build's conflict dialog reads, and an attempt
  /// that showed "0 / 0" there would be telling that build something false
  /// about a record it cannot otherwise interpret.
  StudyRecord toRecord(StudyRecord? existing, DateTime now) {
    final previous = existing?.extraJson[_examPayloadKey];
    final payload = <String, dynamic>{
      if (previous is Map)
        for (final entry in previous.entries) entry.key.toString(): entry.value,
      'v': 1,
      'level': level,
      'mode': mode.name,
      'scale': scale,
      'startedAt': startedAt.toUtc().toIso8601String(),
      if (finishedAt != null)
        'finishedAt': finishedAt!.toUtc().toIso8601String(),
      'sections': {
        for (final entry in sections.entries) entry.key: entry.value.toJson(),
      },
      'q': answers,
    };
    final extra = <String, dynamic>{
      ...?existing?.extraJson,
      _examPayloadKey: payload,
    };
    final base = existing ?? StudyRecord.create(id, now: now);
    return base.copyWith(
      correct: right,
      wrong: asked - right,
      extraJson: extra,
      modifiedAt: now.toUtc(),
    );
  }
}

/// Purpose: Collect the exam attempts out of the progress file, newest first.
/// Inputs: `records`; `level` and `mode` to narrow the list.
/// Returns: `List<ExamAttempt>`.
/// Side effects: None.
/// Notes: Sorted by `startedAt` descending with the id as a tie-break, so the
/// order is total and two attempts started in the same second cannot swap
/// places between builds.
List<ExamAttempt> examAttempts(
  Iterable<StudyRecord> records, {
  String? level,
  ExamMode? mode,
}) {
  final attempts = <ExamAttempt>[];
  for (final record in records) {
    final attempt = ExamAttempt.fromRecord(record);
    if (attempt == null) continue;
    if (level != null && attempt.level != level) continue;
    if (mode != null && attempt.mode != mode) continue;
    attempts.add(attempt);
  }
  attempts.sort((a, b) {
    final byTime = b.startedAt.compareTo(a.startedAt);
    return byTime != 0 ? byTime : a.id.compareTo(b.id);
  });
  return attempts;
}

/// Purpose: Read a JSON value as an integer.
/// Inputs: `value`.
/// Returns: `int?`.
/// Side effects: None.
/// Notes: Internal helper used within this file only. A number written as a
/// string is accepted, because a payload can have been through a JSON encoder
/// that was not this one's.
int? _int(Object? value) => switch (value) {
  final int number => number,
  final String text => int.tryParse(text),
  _ => null,
};

/// Purpose: Read a JSON value as a UTC timestamp.
/// Inputs: `value`.
/// Returns: `DateTime?`.
/// Side effects: None.
/// Notes: Internal helper used within this file only.
DateTime? _time(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toUtc();
}
