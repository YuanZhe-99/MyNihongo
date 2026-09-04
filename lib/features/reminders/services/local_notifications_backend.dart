import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_backend.dart';
import 'reminder_planner.dart';

/// The Android and iOS backend: the operating system holds the schedule.
///
/// The whole reason to use the system scheduler rather than a timer is that a
/// reminder has to arrive on a phone that has not been opened for a week,
/// which is exactly the phone that needs reminding.
class LocalNotificationsReminderBackend extends ReminderBackend {
  /// Purpose: Create the mobile backend.
  /// Inputs: A `plugin`, for tests.
  /// Returns: A new `LocalNotificationsReminderBackend` instance.
  /// Side effects: None until [init].
  /// Notes: None.
  LocalNotificationsReminderBackend([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  /// The Android channel reminders are posted on.
  static const channelId = 'my_nihongo_reminder';

  @override
  /// Purpose: Initialize the plugin and the time-zone database.
  /// Inputs: None.
  /// Returns: A future completing when it is ready.
  /// Side effects: Loads the time-zone database and sets the local zone.
  /// Notes: **Every permission request is disabled here.** The iOS settings
  /// ask for alert, badge and sound by default at initialization, which would
  /// make a device that has never turned reminders on show a permission
  /// dialog at startup. That is the same mistake the microphone permission
  /// made in M2.4, and it is turned off explicitly rather than by omission.
  Future<void> init() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name.identifier));
    } catch (_) {
      // A device whose zone name the database does not know keeps UTC, which
      // is wrong by an offset rather than silent. Better than not scheduling.
    }
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        macOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  @override
  /// Purpose: Ask for permission to post notifications.
  /// Inputs: None.
  /// Returns: `Future<bool>`.
  /// Side effects: Shows the system dialog, once.
  /// Notes: Android 13 and later need this; earlier versions grant it at
  /// install and the implementation returns true without asking.
  Future<bool> requestPermission() async {
    await init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final darwin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (darwin != null) {
      return await darwin.requestPermissions(alert: true, sound: true) ?? false;
    }
    return false;
  }

  @override
  /// Purpose: Replace the schedule with these reminders.
  /// Inputs: `reminders`.
  /// Returns: A future completing when they are scheduled.
  /// Side effects: Cancels this app's notifications and schedules the new set.
  /// Notes: `inexactAllowWhileIdle` rather than an exact alarm. An exact alarm
  /// needs `SCHEDULE_EXACT_ALARM`, which Android treats as a high-privilege
  /// permission and which a study reminder does not deserve — a nudge that
  /// arrives within a few minutes of eight o'clock is a nudge.
  Future<void> schedule(List<ScheduledReminder> reminders) async {
    await init();
    await cancelAll();
    for (final reminder in reminders) {
      await _plugin.zonedSchedule(
        reminder.id,
        reminder.title,
        reminder.body,
        tz.TZDateTime.from(reminder.fireAt, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            'Study reminders',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  /// Purpose: Cancel every reminder this app scheduled.
  /// Inputs: None.
  /// Returns: A future completing when they are gone.
  /// Side effects: Cancels notifications.
  /// Notes: None.
  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  @override
  /// Purpose: Post a reminder now.
  /// Inputs: `title`, `body`.
  /// Returns: A future completing when it is posted.
  /// Side effects: Posts a notification.
  /// Notes: Unused on this platform, which schedules instead; implemented so
  /// the interface has no platform-shaped hole in it.
  Future<void> showNow(String title, String body) async {
    await init();
    await _plugin.show(
      reminderFirstId - 1,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Study reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
    );
  }
}
