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

import '../../features/drills/services/exam_session.dart';
import '../../features/progress/models/exam_attempt.dart';
import '../../features/progress/services/nihongo_storage.dart';
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
