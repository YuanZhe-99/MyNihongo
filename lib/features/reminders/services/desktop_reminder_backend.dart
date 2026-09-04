import 'package:local_notifier/local_notifier.dart';

import 'reminder_backend.dart';

/// The desktop backend: a toast, posted by the app itself.
///
/// There is no system scheduler here, so [ReminderService] keeps a timer and
/// calls [showNow] when the hour arrives. That is a weaker promise than the
/// phone's — a machine with the app closed is not reminded — and the Settings
/// subtitle says so rather than implying otherwise.
class DesktopReminderBackend extends ReminderBackend {
  /// Purpose: Create the desktop backend.
  /// Inputs: None.
  /// Returns: A new `DesktopReminderBackend` instance.
  /// Side effects: None until [init].
  /// Notes: None.
  DesktopReminderBackend();

  bool _ready = false;

  @override
  /// Purpose: Register the app with the desktop notification service.
  /// Inputs: None.
  /// Returns: A future completing when it is ready.
  /// Side effects: Sets up `local_notifier`.
  /// Notes: The app name and its GUID are what Windows keys a toast to; the
  /// GUID is arbitrary but must not change, or an existing toast's identity
  /// is lost.
  Future<void> init() async {
    if (_ready) return;
    await localNotifier.setup(
      appName: 'MyNihongo!!!!!',
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );
    _ready = true;
  }

  @override
  /// Purpose: Ask for permission.
  /// Inputs: None.
  /// Returns: `Future<bool>` — always true.
  /// Side effects: Initializes the backend.
  /// Notes: A desktop toast needs no runtime permission; the operating
  /// system's own notification settings are where a user turns it off, and
  /// nothing the app can ask would add to that.
  Future<bool> requestPermission() async {
    await init();
    return true;
  }

  @override
  /// Purpose: Accept a schedule this backend cannot keep.
  /// Inputs: `reminders`.
  /// Returns: A completed future.
  /// Side effects: None.
  /// Notes: Deliberately empty. The service holds the plan and drives the
  /// timer; putting a no-op here rather than a platform branch in the service
  /// is what keeps `Platform.isX` out of the service entirely.
  Future<void> schedule(List<ScheduledReminder> reminders) async {}

  @override
  /// Purpose: Cancel what was scheduled.
  /// Inputs: None.
  /// Returns: A completed future.
  /// Side effects: None.
  /// Notes: Nothing is scheduled here to cancel; the service stops its timer.
  Future<void> cancelAll() async {}

  @override
  /// Purpose: Post a toast now.
  /// Inputs: `title`, `body`.
  /// Returns: A future completing when it is shown.
  /// Side effects: Shows a desktop notification.
  /// Notes: None.
  Future<void> showNow(String title, String body) async {
    await init();
    final notification = LocalNotification(title: title, body: body);
    await notification.show();
  }
}
