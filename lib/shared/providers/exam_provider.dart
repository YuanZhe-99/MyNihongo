/// Purpose: Derive the JLPT attempt history from the progress file, so the
/// pages read it synchronously instead of loading a file in a build method.
/// Inputs: `progressDataProvider`.
/// Returns: Two `Provider`s.
/// Side effects: None of their own; they only read another provider.
/// Notes: Plain `Provider`s rather than notifiers, the same shape as
/// `labHistoryProvider`: the progress file is the state and these are functions
/// of it, so an attempt written here, restored from a backup, or synced in from
/// another device all reach the list the same way, with no second source of
/// truth to keep in step.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/content/models/content_catalog.dart';
import '../../features/content/models/jlpt_level.dart';
import '../../features/content/services/content_repository.dart';
import '../../features/drills/models/drill_file.dart';
import '../../features/drills/services/drill_repository.dart';
import '../../features/drills/services/exam_session.dart';
import '../../features/drills/services/readiness_rules.dart';
import '../../features/drills/services/weakness_report.dart';
import '../../features/speech/services/tts_service.dart';
import '../../features/progress/models/exam_attempt.dart';
import '../../features/progress/models/study_record.dart';
import '../../features/progress/services/nihongo_storage.dart';
import 'learner_profile_provider.dart';
import 'progress_provider.dart';

/// Every JLPT attempt, newest first.
///
/// Empty while the progress file is still loading, which is also what a learner
/// who has never sat one sees — so nothing on screen has to tell "not loaded"
/// apart from "nothing yet".
///
/// Read through `asData` rather than `value`: in riverpod 1.x `value`
/// **rethrows** when the progress file could not be loaded, which would take
/// down every page that shows the history instead of showing an empty one.
final examAttemptsProvider = Provider<List<ExamAttempt>>((ref) {
  final progress = ref.watch(progressDataProvider).asData?.value;
  if (progress == null) return const [];
  return examAttempts(progress.records);
});

/// The paper this device has half-sat, if there is one.
///
/// Read straight from the save file rather than from the progress file: a
/// paper in progress is device-local, and an unfinished exam on another device
/// is meaningless — the clock belongs to the sitting.
///
/// A `FutureProvider` so the Learn card can render before the file has been
/// read, and `invalidate`d rather than watched for changes: the file is written
/// by the exam page and deleted by this card, both of which know when they did
/// it.
final savedExamProvider = FutureProvider<SavedExam?>(
  (ref) async => SavedExam.fromJson(await NihongoStorage.loadExamInProgress()),
);

/// Every drill question the app ships, by id.
///
/// The join a weakness report and a results screen both need: an attempt keeps
/// only which questions were asked, and everything else — the section, the
/// 大問, the catalog ids — is read from the files now, so a content correction
/// reaches both.
final drillQuestionsProvider = FutureProvider<Map<String, DrillQuestion>>((
  ref,
) async {
  final byId = <String, DrillQuestion>{};
  for (final level in JlptLevel.values) {
    final files = await ref.watch(drillLevelProvider(level).future);
    for (final file in files.values) {
      for (final question in file.questions) {
        byId[question.id] = question;
      }
    }
  }
  return byId;
});

/// What the learner is worst at, over their recent papers at their own level.
///
/// Empty while anything it needs is still loading, which is also what a learner
/// who has sat nothing sees — so nothing on screen has to tell the two apart.
final weaknessReportProvider = Provider<WeaknessReport>((ref) {
  final questions = ref.watch(drillQuestionsProvider).asData?.value;
  if (questions == null) return WeaknessReport.empty;
  return WeaknessReport.build(
    attempts: ref.watch(examAttemptsProvider),
    questions: questions,
    level: ref.watch(learnerProfileProvider).targetLevel.label,
  );
});

/// How ready the learner looks for their target level.
///
/// A band, never a number, and never called a JLPT score — see
/// `readiness_rules.dart` for why no app can compute one.
final readinessProvider = Provider<ReadinessEstimate>((ref) {
  final level = ref.watch(learnerProfileProvider).targetLevel;
  final structure = ref.watch(jlptStructureProvider).asData?.value;
  final spec = structure?.forLevel(level);
  if (spec == null) return ReadinessEstimate.unknown;

  final catalog = ref.watch(contentCatalogProvider).asData?.value;
  final progress = ref.watch(progressDataProvider).asData?.value;
  return ReadinessEstimate.build(
    report: ref.watch(weaknessReportProvider),
    structure: spec,
    coverage: _coverage(catalog, progress, level),
    hasJapaneseVoice: TtsService.instance.hasJapaneseVoice,
  );
});

/// Purpose: Say what share of a level's catalog the learner has met.
/// Inputs: The `catalog`, the `progress`, the `level`.
/// Returns: `double` from 0 to 1; 1 when there is nothing to measure.
/// Side effects: None.
/// Notes: Internal helper used within this file only. "Met" means there is a
/// progress record — the item has been answered at least once — not that it has
/// been mastered. The estimate uses this only to hold back a "ready" band, so
/// the generous reading is the right one: it is a check against declaring
/// somebody ready for a level whose words they have never seen, not a second
/// score.
///
/// One when the catalog has not loaded, so a slow start shows the band the
/// papers earned rather than an unexplained cap.
double _coverage(
  ContentCatalog? catalog,
  ProgressData? progress,
  JlptLevel level,
) {
  if (catalog == null || progress == null) return 1;
  final ids = {
    for (final entry in catalog.vocab)
      if (entry.level == level) entry.id,
    for (final point in catalog.grammar)
      if (point.level == level) point.id,
  };
  if (ids.isEmpty) return 1;
  final met = progress.studyRecords.where((r) => ids.contains(r.id)).length;
  return met / ids.length;
}

/// What every drill question the learner has already been asked, and when.
///
/// The sampler's whole no-repeat rule reads this: `asked` is the set of ids and
/// `lastAsked` maps each to the most recent attempt that used it, in
/// milliseconds since the epoch.
///
/// Derived from the **synced** attempts, which is what makes two devices avoid
/// each other's questions rather than each grinding through the same first
/// twenty. The cap on how many attempts are kept is therefore also the point at
/// which a question becomes askable again, which is a reasonable definition of
/// forgetting it.
final askedQuestionsProvider =
    Provider<({Set<String> asked, Map<String, int> lastAsked})>((ref) {
      final attempts = ref.watch(examAttemptsProvider);
      final asked = <String>{};
      final lastAsked = <String, int>{};
      // Newest first, so the first time a question is seen is its most recent
      // sitting and later ones need not overwrite it.
      for (final attempt in attempts) {
        final at = attempt.startedAt.millisecondsSinceEpoch;
        for (final id in attempt.answers.keys) {
          asked.add(id);
          lastAsked.putIfAbsent(id, () => at);
        }
      }
      return (asked: asked, lastAsked: lastAsked);
    });
