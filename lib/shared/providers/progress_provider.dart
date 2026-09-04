/// Purpose: Expose the user's progress file to the widget tree and keep it
/// current when something other than the UI writes it.
/// Inputs: `NihongoStorage` for the read, `AutoSyncService` for the "local
/// data changed" callback.
/// Returns: A `StateNotifierProvider` holding an `AsyncValue<ProgressData>`.
/// Side effects: Reads the progress file; registers a service callback for the
/// notifier's lifetime.
/// Notes: A sync, a restore, or a ZIP import replaces the file behind the
/// app's back. `AutoSyncService` already reports that, so the provider
/// subscribes once here instead of every page doing it — the `PLAN.md` M1.1
/// wording says "pages register", and this is the deliberate deviation from it.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/progress/models/learner_profile.dart';
import '../../features/progress/models/study_record.dart';
import '../../features/progress/services/nihongo_storage.dart';
import '../services/auto_sync_service.dart';

/// Holds the parsed progress file and reloads it on demand.
class ProgressNotifier extends StateNotifier<AsyncValue<ProgressData>> {
  /// Purpose: Create the notifier and start the first read.
  /// Inputs: None.
  /// Returns: A new `ProgressNotifier`.
  /// Side effects: Registers the local-data-changed callback and calls
  /// [reload].
  /// Notes: The callback is registered before the first read so a sync that
  /// lands mid-read is not missed.
  ProgressNotifier() : super(const AsyncValue.loading()) {
    AutoSyncService.instance.addOnLocalDataChanged(_onLocalDataChanged);
    reload();
  }

  /// Purpose: Re-read the progress file and publish the result.
  /// Inputs: None.
  /// Returns: A future completing once the state has been replaced.
  /// Side effects: Reads local storage.
  /// Notes: Never returns the state to `loading` after the first load, so a
  /// background sync does not blank the pages that are showing data.
  Future<void> reload() async {
    try {
      final data = await NihongoStorage.load();
      if (mounted) state = AsyncValue.data(data);
    } catch (error, stack) {
      if (mounted) state = AsyncValue.error(error, stackTrace: stack);
    }
  }

  /// Purpose: Record one answer and refresh every page showing progress.
  /// Inputs: `id`, `correct`; `now` for tests.
  /// Returns: A future completing once the file is written and re-read.
  /// Side effects: Writes the progress file, notifies auto-sync, reloads.
  /// Notes: Write then reload, rather than patching the state in place. The
  /// file is authoritative — a sync may have rewritten it under this notifier
  /// between two answers — and re-reading it is cheap next to the write.
  Future<void> recordAnswer(String id, bool correct, {DateTime? now}) async {
    await NihongoStorage.recordAnswer(id, correct, now: now);
    await reload();
  }

  /// Purpose: Record whether a unit's checkpoint was passed.
  /// Inputs: The `recordId`, `passed`; `now` for tests.
  /// Returns: A future completing once the file is written and re-read.
  /// Side effects: Writes the progress file and reloads it.
  /// Notes: A checkpoint is a gate rather than an item, so this does not go
  /// through the scheduler; see `NihongoStorage.recordLessonResult`.
  Future<void> recordLessonResult(
    String recordId,
    bool passed, {
    DateTime? now,
  }) async {
    await NihongoStorage.recordLessonResult(recordId, passed, now: now);
    await reload();
  }

  /// Purpose: Record a batch of answers in one write.
  /// Inputs: `answers`; `now` for tests.
  /// Returns: A future completing once the file is written and re-read.
  /// Side effects: As [recordAnswer], but one save for the whole batch.
  /// Notes: For a caller that already has every answer, such as a finished
  /// lesson. A quiz records each answer as it happens instead, so an
  /// interrupted session is not lost.
  Future<void> recordAnswers(Map<String, bool> answers, {DateTime? now}) async {
    await NihongoStorage.recordAnswers(answers, now: now);
    await reload();
  }

  /// Purpose: Save the learner profile and refresh.
  /// Inputs: `profile`; `now` for tests.
  /// Returns: A future completing once the file is written and re-read.
  /// Side effects: Writes the progress file, notifies auto-sync, reloads.
  /// Notes: The profile is a record inside the same file, so this is an
  /// ordinary progress write and syncs like any other.
  Future<void> updateProfile(LearnerProfile profile, {DateTime? now}) async {
    await NihongoStorage.saveProfile(profile, now: now);
    await reload();
  }

  /// Purpose: React to a sync, restore, or import writing the progress file.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Starts a [reload].
  /// Notes: Internal helper used within this file only. Fire-and-forget: the
  /// service's callback is synchronous.
  void _onLocalDataChanged() {
    reload();
  }

  /// Purpose: Release the service callback.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Unregisters the callback.
  /// Notes: Riverpod lifecycle override.
  @override
  void dispose() {
    AutoSyncService.instance.removeOnLocalDataChanged(_onLocalDataChanged);
    super.dispose();
  }
}

/// The user's progress file, read from disk and kept current.
///
/// Pages watch this and call `notifier.reload()` after saving. Sync, restore
/// and ZIP import reach it through `AutoSyncService`.
final progressDataProvider =
    StateNotifierProvider<ProgressNotifier, AsyncValue<ProgressData>>(
      (ref) => ProgressNotifier(),
    );
