import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/progress_provider.dart';
import '../../progress/models/learner_profile.dart';
import '../../progress/models/study_record.dart';

/// How many weeks the calendar shows.
///
/// Twelve. Long enough that a habit is visible and a gap is obvious, short
/// enough to fit a phone's width at a legible square size.
const calendarWeeks = 12;

/// The days a learner answered something, as a grid.
///
/// Derived from the records and never stored, like the daily counts and the
/// unit progress bars: a day counts as studied when a record was created or
/// last reviewed on it. That is coarser than counting answers — a day's second
/// answer to the same word leaves no separate trace — and it is the honest
/// limit of what the progress file remembers.
class StudyCalendar extends ConsumerWidget {
  /// Purpose: Show the last twelve weeks of study.
  /// Inputs: None; reads the progress file.
  /// Returns: A new `StudyCalendar` instance.
  /// Side effects: None.
  /// Notes: None.
  const StudyCalendar({super.key});

  @override
  /// Purpose: Build the grid.
  /// Inputs: `context`, `ref`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: One column per week, oldest on the left, with today in the last
  /// column — so the shape a learner recognises is the right-hand edge. A day
  /// with nothing on it is drawn, not skipped: the gaps are the information.
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final progress = ref.watch(progressDataProvider).value;
    if (progress == null) return const SizedBox.shrink();

    final studied = studiedDays(progress);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Start on the Monday of the week that is `calendarWeeks - 1` weeks back,
    // so the columns are whole weeks and today lands in the last one.
    final start = today
        .subtract(Duration(days: today.weekday - 1))
        .subtract(const Duration(days: 7 * (calendarWeeks - 1)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(
            l10n.calendarTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 3.0;
            final cell =
                ((constraints.maxWidth - gap * (calendarWeeks - 1)) /
                        calendarWeeks)
                    .clamp(6.0, 18.0);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var week = 0; week < calendarWeeks; week++)
                  Padding(
                    padding: EdgeInsets.only(
                      right: week == calendarWeeks - 1 ? 0 : gap,
                    ),
                    child: Column(
                      children: [
                        for (var day = 0; day < 7; day++)
                          Padding(
                            padding: EdgeInsets.only(bottom: day == 6 ? 0 : gap),
                            child: _cell(
                              theme,
                              cell,
                              start.add(Duration(days: week * 7 + day)),
                              today,
                              studied,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          l10n.calendarSummary(studied.length),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Purpose: Draw one day.
  /// Inputs: The `theme`, the cell `size`, the `date`, `today`, and the days
  /// that were studied.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. A day in the future is
  /// drawn faintly rather than left blank, so the grid keeps its shape to the
  /// end of the week the learner is in.
  Widget _cell(
    ThemeData theme,
    double size,
    DateTime date,
    DateTime today,
    Set<String> studied,
  ) {
    final key = LearnerProfile.localDateKey(date);
    final done = studied.contains(key);
    final future = date.isAfter(today);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: done
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: future ? 0.3 : 1,
              ),
        border: date == today
            ? Border.all(color: theme.colorScheme.primary, width: 1.5)
            : null,
      ),
    );
  }
}

/// Purpose: Find the local days on which anything was answered.
/// Inputs: The learner's `progress`.
/// Returns: `Set<String>` of `YYYY-MM-DD` keys.
/// Side effects: None.
/// Notes: A record's `lastReviewedAt` is when it was last answered and its
/// `createdAt` is when it was first answered, because **a record is created by
/// its first answer**. Both count, so the day somebody started a word shows up
/// even after they have reviewed it since. The profile record is skipped: it
/// is written once a day by the streak and would mark days nothing was
/// studied on.
Set<String> studiedDays(ProgressData progress) => {
  for (final record in progress.records)
    if (studyKindOf(record.id) != StudyKind.profile) ...[
      LearnerProfile.localDateKey(record.createdAt.toLocal()),
      if (record.lastReviewedAt case final at?)
        LearnerProfile.localDateKey(at.toLocal()),
    ],
};
