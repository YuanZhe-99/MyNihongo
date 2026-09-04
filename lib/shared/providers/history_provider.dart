/// Purpose: Derive the sentence-lab and writing-practice histories from the
/// progress file, so the pages read them synchronously instead of loading a
/// file in a build method.
/// Inputs: `progressDataProvider`.
/// Returns: Two `Provider`s.
/// Side effects: None of their own; they only read another provider.
/// Notes: Plain `Provider`s rather than notifiers, the same shape as
/// `learnerProfileProvider`: the progress file is the state and these are
/// functions of it, so an entry written here, restored from a backup, or synced
/// in from another device all reach the list the same way, with no second
/// source of truth to keep in step.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/progress/models/history_entry.dart';
import 'progress_provider.dart';

/// Every remembered sentence from the lab, newest first.
///
/// Empty while the progress file is still loading, which is also what a learner
/// who has never analysed anything sees — so nothing on screen has to tell
/// "not loaded" apart from "nothing yet".
///
/// Read through `asData` rather than `value`: in riverpod 1.x `value` **rethrows**
/// when the progress file could not be loaded, which would take down every page
/// that shows a history instead of showing an empty one. A device whose storage
/// is unreadable has bigger problems than an empty history, and the pages above
/// this still work.
final labHistoryProvider = Provider<List<HistoryEntry>>((ref) {
  final progress = ref.watch(progressDataProvider).asData?.value;
  if (progress == null) return const [];
  return historyEntries(progress.records, kind: HistoryKind.lab);
});

/// Every remembered piece of writing for one unit, newest first.
///
/// Keyed by unit id, because a writing prompt is about its own unit and the
/// history beside it should be what was written for *this* exercise. A null
/// family argument is the unfiltered list, which is what a writing prompt
/// opened outside a unit gets.
final writingHistoryProvider = Provider.family<List<HistoryEntry>, String?>((
  ref,
  unitId,
) {
  final progress = ref.watch(progressDataProvider).asData?.value;
  if (progress == null) return const [];
  return historyEntries(
    progress.records,
    kind: HistoryKind.writing,
    unitId: unitId,
  );
});
