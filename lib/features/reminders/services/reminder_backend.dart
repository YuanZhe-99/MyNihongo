/// What a reminder needs from the platform, and nothing more.
///
/// One interface over two very different plugins — the operating system's own
/// scheduler on a phone, a timer in this process on a desktop — so the planner
/// and the settings row can be tested without either of them. Every method is
/// allowed to do nothing: a platform with no notifications is a platform where
/// the switch simply never appears.
library;

import 'package:flutter/foundation.dart';

/// One reminder to show at one time.
@immutable
class ScheduledReminder {
  /// Purpose: Describe one reminder.
  /// Inputs: `id`, `fireAt` in local time, `title`, `body`.
  /// Returns: A new `ScheduledReminder` instance.
  /// Side effects: None.
  /// Notes: `id` is small and stable so re-scheduling replaces rather than
  /// duplicates: seven ids for seven days, reused every time the plan changes.
  const ScheduledReminder({
    required this.id,
    required this.fireAt,
    required this.title,
    required this.body,
  });

  /// The notification id, 100 upwards.
  final int id;

  /// When it should appear, in the device's own time zone.
  final DateTime fireAt;

  /// The title line.
  final String title;

  /// The body line.
  final String body;

  @override
  bool operator ==(Object other) =>
      other is ScheduledReminder &&
      other.id == id &&
      other.fireAt == fireAt &&
      other.title == title &&
      other.body == body;

  @override
  int get hashCode => Object.hash(id, fireAt, title, body);

  @override
  String toString() => '#$id at $fireAt: $title / $body';
}

/// The platform side of a reminder.
abstract class ReminderBackend {
  /// Purpose: Prepare the platform's notification machinery.
  /// Inputs: None.
  /// Returns: A future completing when it is ready.
  /// Side effects: Initializes the plugin and the time-zone database.
  /// Notes: **Never asks for permission.** Initialization runs at startup on
  /// every device, and a device that has never turned reminders on must not be
  /// asked for anything — the same rule the microphone follows.
  Future<void> init();

  /// Purpose: Ask the learner for permission to post notifications.
  /// Inputs: None.
  /// Returns: `Future<bool>` — whether it was granted.
  /// Side effects: Shows the system permission dialog.
  /// Notes: Called only from the switch in Settings, at the moment the learner
  /// turns reminders on.
  Future<bool> requestPermission();

  /// Purpose: Replace every scheduled reminder with these.
  /// Inputs: `reminders`.
  /// Returns: A future completing when they are scheduled.
  /// Side effects: Cancels the app's existing reminders and schedules these.
  /// Notes: Replace rather than add, because the plan is recomputed whenever
  /// the progress file changes and a learner who studies twice in a day would
  /// otherwise accumulate a week of stale reminders.
  Future<void> schedule(List<ScheduledReminder> reminders);

  /// Purpose: Remove every reminder this app scheduled.
  /// Inputs: None.
  /// Returns: A future completing when they are gone.
  /// Side effects: Cancels notifications.
  /// Notes: None.
  Future<void> cancelAll();

  /// Purpose: Show a reminder now.
  /// Inputs: `title`, `body`.
  /// Returns: A future completing when it is posted.
  /// Side effects: Posts a notification.
  /// Notes: For the desktop path, which has no scheduler of its own and posts
  /// from a timer inside the running app.
  Future<void> showNow(String title, String body);
}

/// A backend that does nothing, for a platform with no notifications.
class NoReminderBackend extends ReminderBackend {
  /// Purpose: Create the do-nothing backend.
  /// Inputs: None.
  /// Returns: A new `NoReminderBackend` instance.
  /// Side effects: None.
  /// Notes: Not a failure state. It is what the web and any future platform
  /// without notifications get, and the Settings switch is hidden rather than
  /// shown broken.
  NoReminderBackend();

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> schedule(List<ScheduledReminder> reminders) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> showNow(String title, String body) async {}
}
