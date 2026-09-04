/// What to remind the learner of, and when.
///
/// A pure function of the time, the progress file and the path. It reads no
/// preferences, touches no plugin and posts nothing — which is what lets the
/// wording and the timing be tested exactly, on a host with no notifications.
library;

import 'dart:ui';

import '../../../l10n/app_localizations.dart';
import '../../lessons/models/lesson_path.dart';
import '../../lessons/services/lesson_rules.dart';
import '../../progress/models/study_record.dart';
import '../../progress/services/review_queue.dart';
import 'reminder_backend.dart';

/// How many days ahead a plan reaches.
///
/// Seven. Long enough that a phone which is never opened still reminds for a
/// week, short enough that the counts in the text are not fiction — after a
/// week without study, "3 items due" would be badly wrong.
const reminderDays = 7;

/// The notification ids the plan uses, one per day.
const reminderFirstId = 100;

/// Purpose: Work out the week's reminders.
/// Inputs: `time` of day as hour and minute; `now`; the learner's `progress`;
/// the `path` for the unit to name; and `l10n` for the wording.
/// Returns: `List<ScheduledReminder>`.
/// Side effects: None.
/// Notes: **Today is included only if the time has not passed**, which is what
/// stops turning the switch on at nine in the evening from firing a reminder
/// for eight that morning. The body says what is actually waiting: the number
/// due if anything is, otherwise the next unit by name, otherwise a plain
/// nudge. Counts are computed for **today** and reused for the rest of the
/// week, because nothing can know what will be due on Thursday — and saying
/// so plainly in the later days is why only the first uses a number.
List<ScheduledReminder> planReminders({
  required int hour,
  required int minute,
  required DateTime now,
  required ProgressData progress,
  required LessonPath path,
  required AppLocalizations l10n,
}) {
  final due = progress.studyRecords
      .where((record) => ReviewQueue.isDue(record, now))
      .length;
  final next = nextUnit(path, unitStates(path, progress));

  final out = <ScheduledReminder>[];
  var day = DateTime(now.year, now.month, now.day, hour, minute);
  if (!day.isAfter(now)) day = day.add(const Duration(days: 1));

  for (var i = 0; i < reminderDays; i++) {
    final at = day.add(Duration(days: i));
    final body = i == 0 && due > 0
        ? l10n.reminderDueBody(due)
        : next != null
        ? l10n.reminderUnitBody(next.title.resolveJoined(l10n.localeName.startsWith('zh')
              ? const Locale('zh')
              : const Locale('en')))
        : l10n.reminderPlainBody;
    out.add(
      ScheduledReminder(
        id: reminderFirstId + i,
        fireAt: at,
        title: l10n.reminderTitle,
        body: body,
      ),
    );
  }
  return out;
}
