# Reminders

One local notification a day, off until the learner turns it on, saying what is
actually waiting for them. Nothing about it touches a network.

## The rule that shapes everything else

**Permission is requested by the switch, and nowhere else.**

`ReminderService.init()` runs from `main` on every device and prepares the
plugin and the time-zone database. It never asks for anything. The request
happens once, inside `setReminderEnabled(true)`, at the moment the learner turns
reminders on — and if it is refused the switch stays off, with a line saying the
system has notifications disabled for the app.

This is written down because it has already gone wrong once here. M2.4 shipped a
build that asked for the microphone the moment Settings opened, and a test now
asserts that `init` makes zero permission requests.

The iOS and macOS initialization settings turn off alert, badge and sound
requests explicitly rather than by omission, because the plugin's defaults ask
for all three at initialization.

## What it says

The plan is a pure function — `planReminders` — of the time, the progress file
and the path. It reads no preferences and posts nothing, which is what lets the
wording and the timing be tested exactly on a machine with no notifications.

| When | Body |
|---|---|
| Something is due today | how many |
| Nothing due, a unit open | the unit's name |
| Neither | a plain nudge |

Seven days are scheduled at a time, so a phone that is never opened still
reminds for a week. Only the first day carries a number: nothing can know what
will be due on Thursday, and a count that is quietly wrong is worse than no
count.

**A time that has already passed today starts tomorrow.** Turning the switch on
at nine in the evening must not fire a reminder for eight that morning.

The plan is rebuilt whenever the switch, the time, or the progress file changes,
and it replaces the previous one rather than adding to it — a learner who
studies twice in a day would otherwise accumulate a week of stale reminders.

## Two platforms, two promises

| | Android and iOS | Windows, macOS, Linux |
|---|---|---|
| Who fires it | the operating system | a timer inside the running app |
| App closed | still reminds | does not remind |
| Permission | asked once, by the switch | none needed |

The desktop path posts at most once a day, recorded by local date in
`storage_config.json`, so a machine left running does not toast every minute for
an hour. The weaker promise is stated in the Settings subtitle rather than
implied away.

A platform with neither shows no switch at all. A switch that cannot do
anything is worse than no switch.

## Android specifics

`POST_NOTIFICATIONS` is requested at the switch. `RECEIVE_BOOT_COMPLETED` is
what makes a schedule survive a restart; without it a phone that reboots stops
reminding and nothing says why.

**`SCHEDULE_EXACT_ALARM` is deliberately not requested.** Android treats it as a
high-privilege permission, a study nudge does not deserve one, and
`inexactAllowWhileIdle` puts the reminder within a few minutes of the hour —
which is what a nudge is.

## Preferences

All three are device-local; nothing here is synced. A phone and a laptop want
different reminder times, and a habit lives on a device.

| Key | Default | Stored |
|---|---|---|
| `reminderEnabled` | off | `true` only when on |
| `reminderTime` | 20:00 | `"HH:mm"` only when it differs |
| `lastReminderDate` | — | desktop only, a local `YYYY-MM-DD` |

## Privacy

The notification is composed on the device from the progress file and shown by
the device. No text, count or time leaves it. The privacy policy says so.
