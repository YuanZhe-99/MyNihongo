# lib/features/reminders/services/reminder_service.dart

Keeps one reminder a day pointed at what the learner actually has waiting. A singleton like the
speech and AI services, and for the same reason: there is one notification schedule on the device,
and two owners of it would fight.

Consumers: `main.dart`, `app_settings.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `ReminderService` | class | B | Owns the device's reminder schedule. |
| `ReminderService.instance` | field | B | The app-wide instance. |
| `ReminderService.setInstanceForTest` | method | B | Replace it in a test. |
| `ReminderService._backendForPlatform` | method | B | Choose the backend this platform needs. |
| `desktopTick` | constant | B | How often the desktop path checks the clock. |
| [`ReminderService.init`](#init) | method | A | Prepare the platform, asking for nothing. |
| `ReminderService.requestPermission` | method | B | Ask for notification permission. |
| [`ReminderService.reschedule`](#reschedule) | method | A | Recompute the plan and hand it over. |
| [`ReminderService._startTicking`](#tick) | method | A | Watch the clock where nothing else will. |
| `ReminderService.isTicking` | getter | B | Whether the desktop timer is running. |
| `ReminderService.dispose` | method | B | Stop the timer. |

## Documentation

### `Future<void> init()` <a id="init"></a>

- **Kind:** method
- **Purpose:** Prepare the platform without asking the learner for anything.
- **Inputs:** None.
- **Returns:** A future completing when the backend is ready.
- **Side effects:** Initializes the plugin and the time-zone database.
- **Algorithm:** Delegates to the backend, which loads the zone database and initializes the plugin
  with every permission request turned off.
- **Usage:** `main.dart`, unawaited, at startup.
- **Notes:** **It must not request permission**, and a test asserts that it makes zero requests. A
  device whose owner has never turned reminders on is never asked for anything; the request lives
  in the Settings switch. M2.4 shipped a build that asked for the microphone the moment Settings
  opened, and this is the same mistake one line away.

### `Future<void> reschedule(AppLocalizations l10n, {DateTime? now})` <a id="reschedule"></a>

- **Kind:** method
- **Purpose:** Recompute the plan and hand it to the platform.
- **Inputs:** `l10n` for the wording; `now` for tests.
- **Returns:** A future completing when the schedule is replaced.
- **Side effects:** Reads the preference, the progress file and the path; schedules or cancels.
- **Algorithm:** Cancels and returns when reminders are off; otherwise reads the time, the profile
  and the level's path, plans a week, and replaces the schedule.
- **Usage:** Called from every setter that could change what a reminder should say.
- **Notes:** It reads the preference itself rather than being told, so every caller is the same one
  line. With reminders off it cancels rather than doing nothing, which is what makes turning the
  switch off take effect immediately rather than in a week.

### `void _startTicking(List<ScheduledReminder> plan)` <a id="tick"></a>

- **Kind:** method
- **Purpose:** Watch the clock on a platform with no scheduler.
- **Inputs:** The plan.
- **Returns:** None.
- **Side effects:** Starts a periodic timer; posts a toast when one is due.
- **Algorithm:** Every minute, if today's reminder has not been posted and one of the plan's times
  has passed, records the date and posts it.
- **Usage:** Desktop only, from `reschedule`.
- **Notes:** Internal helper used within this file only. The date is recorded in the config file
  before posting, so a machine left running does not toast every minute for an hour. This is a
  weaker promise than the phone's — the app has to be open — and the Settings subtitle says so.
