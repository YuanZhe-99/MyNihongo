/// Purpose: Derive the learner profile and the review queue from the progress
/// file and the catalog, so pages read them synchronously instead of computing
/// them in a build method.
/// Inputs: `progressDataProvider`, `contentCatalogProvider`.
/// Returns: Two `Provider`s.
/// Side effects: None of their own; they only combine other providers.
/// Notes: Both are plain `Provider`s rather than notifiers because neither owns
/// state: the progress file is the state, and these are functions of it. When
/// it changes — an answer, a sync, a restore — they recompute and every
/// watching page rebuilds, with no second source of truth to keep in step.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/content/services/content_repository.dart';
import '../../features/progress/models/learner_profile.dart';
import '../../features/progress/services/review_queue.dart';
import 'exam_provider.dart';
import 'progress_provider.dart';

/// The learner's target level, daily goals and streak.
///
/// Defaults while the progress file is still loading, which is the same value
/// a learner who has never opened Settings has — so nothing on screen has to
/// distinguish "not loaded" from "not set".
final learnerProfileProvider = Provider<LearnerProfile>((ref) {
  final progress = ref.watch(progressDataProvider);
  return LearnerProfile.fromRecord(
    progress.value?.recordById(learnerProfileId),
  );
});

/// What to study now, or null until the progress file and catalog have loaded.
///
/// Null rather than an empty queue on purpose: an empty queue means "nothing
/// due, well done", and showing that before the data has loaded would be a
/// lie the learner acts on.
///
/// The weakness report only **reorders** this queue — it never adds anything
/// and never removes anything — so a report still empty because the drill
/// files have not been read costs the learner the old ordering and nothing
/// else, and the queue does not wait for it.
final reviewQueueProvider = Provider<ReviewQueue?>((ref) {
  final progress = ref.watch(progressDataProvider).value;
  final catalog = ref.watch(contentCatalogProvider).value;
  if (progress == null || catalog == null) return null;
  return ReviewQueue.build(
    progress: progress,
    catalog: catalog,
    profile: ref.watch(learnerProfileProvider),
    now: DateTime.now(),
    prioritized: ref.watch(weaknessReportProvider).prioritizedIds(catalog),
  );
});
