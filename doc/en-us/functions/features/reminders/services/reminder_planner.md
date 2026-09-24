# lib/features/reminders/services/reminder_planner.dart

What to remind the learner of, and when. A pure function of the time, the progress file and the
path: it reads no preferences, touches no plugin and posts nothing, which is what lets the wording
and the timing be tested exactly on a host with no notifications.

Consumers: `reminder_service.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `reminderDays` | constant | B | How many days ahead a plan reaches (7). |
| `reminderFirstId` | constant | B | The first notification id (100). |
| [`planReminders`](#plan) | function | A | Work out the week's reminders. |

## Documentation

### `List<ScheduledReminder> planReminders({...})` <a id="plan"></a>

- **Kind:** function
- **Purpose:** Work out the week's reminders.
- **Inputs:** The `hour` and `minute`, `now`, the learner's `progress`, the `path`, and `l10n`.
- **Returns:** One reminder per day for a week.
- **Side effects:** None.
- **Algorithm:** Counts what is due today, finds the next open unit, then emits seven reminders at
  the chosen time — starting tomorrow when today's time has already passed.
- **Usage:** `ReminderService.reschedule`.
- **Notes:** **Only the first day carries a number.** Nothing can know what will be due on
  Thursday, and a count that is quietly wrong is worse than no count, so the later days name the
  next unit instead. Seven days at a time means a phone nobody opens still reminds for a week; the
  ids are small and stable so re-scheduling replaces rather than duplicates.

  The next unit's title is resolved in the UI language with
  `localeFromTag(l10n.localeName)` ([../../../app/locale_resolution.md](../../../app/locale_resolution.md)),
  so it follows the same lookup order the content uses everywhere else: `zh_TW`, `zh` and `ja` keep
  their own text. The planner has only `AppLocalizations` and no `BuildContext`; it used to map
  every Chinese UI to `zh` and everything else to English.
