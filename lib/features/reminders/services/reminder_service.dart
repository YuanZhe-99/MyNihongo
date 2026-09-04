import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/utils/platform_capabilities.dart';
import '../../content/models/jlpt_level.dart';
import '../../lessons/models/lesson_path.dart';
import '../../lessons/services/lesson_repository.dart';
import '../../progress/models/learner_profile.dart';
import '../../progress/services/nihongo_storage.dart';
import 'desktop_reminder_backend.dart';
import 'local_notifications_backend.dart';
import 'reminder_backend.dart';
import 'reminder_planner.dart';

/// Keeps one reminder a day pointed at what the learner actually has waiting.
///
/// A singleton like the speech and AI services, and for the same reason: there
/// is one notification schedule on the device, and two owners of it would
/// fight. Nothing here posts anything unless the learner turned the switch on.
class ReminderService {
  /// Purpose: Create the service.
  /// Inputs: A `backend`; the platform's own is chosen when none is given.
  /// Returns: A new `ReminderService` instance.
  /// Side effects: None until [init].
  /// Notes: None.
  ReminderService({ReminderBackend? backend})
    : _backend = backend ?? _backendForPlatform();

  /// The app-wide instance.
  static ReminderService instance = ReminderService();

  /// Purpose: Replace the instance in a test.
  /// Inputs: `service`.
  /// Returns: None.
  /// Side effects: Replaces the singleton.
  /// Notes: None.
  @visibleForTesting
  static void setInstanceForTest(ReminderService service) {
    instance = service;
  }

  /// Purpose: Choose the backend this platform needs.
  /// Inputs: None.
  /// Returns: `ReminderBackend`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The one place the
  /// platform is branched on, and it reads `platform_capabilities.dart`
  /// rather than `dart:io` so a test on a Windows host can still exercise the
  /// mobile path.
  static ReminderBackend _backendForPlatform() {
    if (platformSchedulesReminders) {
      return LocalNotificationsReminderBackend();
    }
    if (platformRemindsFromInsideTheApp) return DesktopReminderBackend();
    return NoReminderBackend();
  }

  final ReminderBackend _backend;
  Timer? _tick;
  bool _started = false;

  /// How often the desktop path checks whether the hour has arrived.
  static const desktopTick = Duration(minutes: 1);

  /// Purpose: Prepare the platform without asking for anything.
  /// Inputs: None.
  /// Returns: A future completing when the backend is ready.
  /// Side effects: Initializes the backend.
  /// Notes: Called from `main`. It **must not** request permission: a device
  /// whose owner has never turned reminders on is a device that is never
  /// asked. The request happens in the Settings switch, once, when they turn
  /// it on.
  Future<void> init() => _backend.init();

  /// Purpose: Ask for permission to post notifications.
  /// Inputs: None.
  /// Returns: `Future<bool>`.
  /// Side effects: Shows the system dialog.
  /// Notes: Only the Settings switch calls this.
  Future<bool> requestPermission() => _backend.requestPermission();

  /// Purpose: Recompute the plan and hand it to the platform.
  /// Inputs: `l10n`, for the wording; `now` for tests.
  /// Returns: A future completing when the schedule is replaced.
  /// Side effects: Reads the progress file and the path; schedules or cancels.
  /// Notes: Reads the preference itself rather than being told, so every
  /// caller — startup, a settings change, a finished session — is the same
  /// one line. With reminders off it cancels, which is what makes turning the
  /// switch off take effect immediately rather than in a week.
  Future<void> reschedule(AppLocalizations l10n, {DateTime? now}) async {
    final enabled = await NihongoStorage.getReminderEnabled();
    if (!enabled) {
      _tick?.cancel();
      _tick = null;
      await _backend.cancelAll();
      return;
    }
    final (hour, minute) = await NihongoStorage.getReminderTime();
    final progress = await NihongoStorage.load();
    final profile = LearnerProfile.fromRecord(
      progress.recordById(learnerProfileId),
    );
    final path = await _pathFor(profile.targetLevel);
    final plan = planReminders(
      hour: hour,
      minute: minute,
      now: now ?? DateTime.now(),
      progress: progress,
      path: path,
      l10n: l10n,
    );
    await _backend.schedule(plan);
    if (platformRemindsFromInsideTheApp) _startTicking(plan);
  }

  /// Purpose: Load the path for a level, tolerating a level with no file.
  /// Inputs: `level`.
  /// Returns: `Future<LessonPath>`.
  /// Side effects: Reads an asset.
  /// Notes: Internal helper used within this file only.
  Future<LessonPath> _pathFor(JlptLevel level) => LessonRepository.load(level);

  /// Purpose: Watch the clock on a platform with no scheduler.
  /// Inputs: The `plan`.
  /// Returns: None.
  /// Side effects: Starts a periodic timer; posts a toast when one is due.
  /// Notes: Internal helper used within this file only. The day's reminder is
  /// posted at most once, recorded by date in the config file, so a machine
  /// left running does not toast every minute for an hour.
  void _startTicking(List<ScheduledReminder> plan) {
    _tick?.cancel();
    _started = true;
    _tick = Timer.periodic(desktopTick, (_) async {
      final now = DateTime.now();
      final today = LearnerProfile.localDateKey(now);
      if (await NihongoStorage.getLastReminderDate() == today) return;
      for (final reminder in plan) {
        if (reminder.fireAt.isAfter(now)) continue;
        if (LearnerProfile.localDateKey(reminder.fireAt) != today) continue;
        await NihongoStorage.setLastReminderDate(today);
        await _backend.showNow(reminder.title, reminder.body);
        return;
      }
    });
  }

  /// Whether the desktop timer is running.
  @visibleForTesting
  bool get isTicking => _started && _tick != null;

  /// Purpose: Stop everything, for a test or a shutdown.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Cancels the timer.
  /// Notes: None.
  void dispose() {
    _tick?.cancel();
    _tick = null;
    _started = false;
  }
}
