/// Purpose: Let the user pick a winner when sync finds one progress record
/// edited on two devices.
/// Inputs: The conflicting record pair and a display label for the item.
/// Returns: The chosen `StudyRecord`, or null when the user backs out.
/// Side effects: Shows a modal dialog.
/// Notes: The dialog is not barrier-dismissible and has no cancel action:
/// resolution is all-or-nothing, and the caller treats a null (system back)
/// as "abort the whole sync", never as "keep local".
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../features/content/services/study_item_labels.dart';
import '../../features/progress/models/exam_attempt.dart';
import '../../features/progress/models/history_entry.dart';
import '../../features/progress/models/learner_profile.dart';
import '../../features/progress/models/study_record.dart';
import '../../l10n/app_localizations.dart';
import '../services/sync_merge.dart';

/// Shows both versions of one conflicting progress record side by side.
class StudyConflictDialog extends StatelessWidget {
  /// The conflicting pair, as the merge reported it.
  final RecordConflict<StudyRecord> conflict;

  /// What to call the item the record tracks.
  final StudyItemLabel label;

  /// Purpose: Create a study conflict dialog instance.
  /// Inputs: `conflict`, `label`.
  /// Returns: A new `StudyConflictDialog` instance.
  /// Side effects: None.
  /// Notes: None.
  const StudyConflictDialog({
    super.key,
    required this.conflict,
    required this.label,
  });

  /// Purpose: Format a UTC timestamp in the device's zone.
  /// Inputs: `time`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Records store UTC; the
  /// user compares them in local time.
  static String _formatTime(DateTime time) =>
      DateFormat.yMd().add_Hms().format(time.toLocal());

  /// Purpose: Render one version's facts as a labelled block.
  /// Inputs: `context`, `l10n`, `heading`, `record`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Both blocks show the
  /// same fields in the same order so the difference is easy to spot. The
  /// learner profile shares this file and this merge but has none of these
  /// fields, so it gets its own block: "correct 0 · wrong 0, stage fresh" is
  /// not a description of a target level, and a conflict the learner cannot
  /// read is a conflict they cannot resolve.
  Widget _version(
    BuildContext context,
    AppLocalizations l10n,
    String heading,
    StudyRecord record,
  ) {
    if (record.kind == StudyKind.profile) {
      return _profileVersion(l10n, heading, record);
    }
    if (record.kind == StudyKind.history) {
      return _historyVersion(l10n, heading, record);
    }
    if (record.kind == StudyKind.exam) {
      return _examVersion(l10n, heading, record);
    }
    final stage = switch (record.stage) {
      StudyStage.fresh => l10n.stageFresh,
      StudyStage.learning => l10n.stageLearning,
      StudyStage.mastered => l10n.stageMastered,
    };
    final reviewed = record.lastReviewedAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(heading, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(l10n.syncModifiedAt(_formatTime(record.modifiedAt))),
        Text(l10n.syncRecordAnswers(record.correct, record.wrong)),
        Text(l10n.syncStreak(record.streak)),
        Text('${l10n.syncStage}: $stage'),
        Text(
          reviewed == null
              ? l10n.syncNeverReviewed
              : l10n.syncLastReviewed(_formatTime(reviewed)),
        ),
      ],
    );
  }

  /// Purpose: Show one side of a remembered-sentence conflict.
  /// Inputs: `l10n`, `heading`, `record`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. A history record has
  /// none of the counter fields either, and the only thing that distinguishes
  /// two versions of one is the text and when it was written. The text is shown
  /// in full rather than truncated: it is the whole content of the record the
  /// learner is being asked to choose between.
  Widget _historyVersion(
    AppLocalizations l10n,
    String heading,
    StudyRecord record,
  ) {
    final entry = HistoryEntry.fromRecord(record);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(heading, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(l10n.syncModifiedAt(_formatTime(record.modifiedAt))),
        if (entry != null) Text(entry.text),
      ],
    );
  }

  /// Purpose: Show one side of an exam-attempt conflict.
  /// Inputs: `l10n`, `heading`, `record`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. An attempt has the
  /// counter fields — they are written so an older build's dialog says
  /// something true — but they are not what distinguishes two versions of one.
  /// What does is the paper: which level, practice or timed, when it was sat
  /// and what it scored. The counters are deliberately **not** repeated here,
  /// because "correct 48 · wrong 19" alongside "48 / 67" is the same fact
  /// twice in two shapes.
  Widget _examVersion(
    AppLocalizations l10n,
    String heading,
    StudyRecord record,
  ) {
    final attempt = ExamAttempt.fromRecord(record);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(heading, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(l10n.syncModifiedAt(_formatTime(record.modifiedAt))),
        if (attempt != null) ...[
          Text(
            '${attempt.level} · '
            '${attempt.mode == ExamMode.mock ? l10n.jlptMock : l10n.jlptModePractice}',
          ),
          Text(l10n.jlptScore(attempt.right, attempt.asked)),
          Text(l10n.syncModifiedAt(_formatTime(attempt.startedAt))),
        ],
      ],
    );
  }

  /// Purpose: Show one side of a learner-profile conflict.
  /// Inputs: `l10n`, `heading`, `record`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Reads the payload
  /// through `LearnerProfile.fromRecord`, so a profile written by a newer
  /// build with fields this one cannot show still renders the ones it can.
  Widget _profileVersion(
    AppLocalizations l10n,
    String heading,
    StudyRecord record,
  ) {
    final profile = LearnerProfile.fromRecord(record);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(heading, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(l10n.syncModifiedAt(_formatTime(record.modifiedAt))),
        Text(l10n.syncProfileLevel(profile.targetLevel.label)),
        Text(
          l10n.syncProfileDaily(
            profile.dailyNewLimit,
            profile.dailyReviewLimit,
          ),
        ),
        Text(l10n.syncProfileStreak(profile.streakDays)),
      ],
    );
  }

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final local = conflict.localRecord;
    final remote = conflict.remoteRecord;

    return AlertDialog(
      title: Text(l10n.syncConflictTitle(label.title)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label.subtitle != null)
                Text(
                  label.subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              if (!label.resolved)
                Text(
                  l10n.syncUnknownItem,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 12),
              Text(l10n.syncConflictDesc),
              const SizedBox(height: 16),
              _version(context, l10n, l10n.syncLocalVersion, local),
              const SizedBox(height: 12),
              _version(context, l10n, l10n.syncRemoteVersion, remote),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(local),
          child: Text(l10n.syncKeepLocal),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(remote),
          child: Text(l10n.syncKeepRemote),
        ),
      ],
    );
  }
}

/// Purpose: Present one conflict and wait for the user's choice.
/// Inputs: `context`, `conflict`, `label`.
/// Returns: `Future<StudyRecord?>` — the kept record, or null when the user
/// dismissed the dialog with system back.
/// Side effects: Opens a modal route.
/// Notes: `barrierDismissible` is false on purpose; see the library note.
Future<StudyRecord?> showStudyConflictDialog(
  BuildContext context,
  RecordConflict<StudyRecord> conflict,
  StudyItemLabel label,
) {
  return showDialog<StudyRecord>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StudyConflictDialog(conflict: conflict, label: label),
  );
}
