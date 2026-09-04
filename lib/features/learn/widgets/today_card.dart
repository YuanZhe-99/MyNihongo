import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/app_settings.dart';
import '../../../shared/providers/learner_profile_provider.dart';
import '../../progress/services/review_queue.dart';
import '../../quiz/models/quiz_config.dart';

/// What there is to do today: the streak, what is due, and what is new.
///
/// The first card on the Learn tab, and the one thing a returning learner
/// should be able to read without scrolling. Each count is also the button that
/// acts on it, so starting a session is one tap from opening the app.
class TodayCard extends ConsumerWidget {
  /// Purpose: Create the today card.
  /// Inputs: None.
  /// Returns: A new `TodayCard` instance.
  /// Side effects: None.
  /// Notes: None.
  const TodayCard({super.key});

  /// Purpose: Build the card from the review queue.
  /// Inputs: `context`, `ref`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often. A null
  /// queue means the progress file or the catalog has not loaded; it shows a
  /// progress bar rather than "nothing due", because those are different
  /// claims and only one of them is true before the data arrives.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final queue = ref.watch(reviewQueueProvider);
    final profile = ref.watch(learnerProfileProvider);

    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_fire_department_outlined,
                  size: 20,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.learnToday,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                // Flexible, not a Spacer plus a fixed Text: "No streak yet —
                // one answer starts it" is far wider than "3-day streak", and
                // the German or English wording on a narrow phone has to wrap
                // rather than overflow the row.
                Expanded(
                  child: Text(
                    profile.streakDays > 0
                        ? l10n.learnStreak(profile.streakDays)
                        : l10n.learnStreakNone,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (queue == null)
              const LinearProgressIndicator()
            else ...[
              ..._lines(l10n, theme, queue),
              if (!queue.isEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (queue.due.isNotEmpty)
                      FilledButton.icon(
                        icon: const Icon(Icons.repeat, size: 18),
                        label: Text(l10n.quizStartReviews),
                        onPressed: () => _start(context, ref, const DueReviews()),
                      ),
                    if (queue.newIds.isNotEmpty)
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(l10n.quizStartNew),
                        onPressed: () => _start(context, ref, const NewItems()),
                      ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  /// Purpose: Open a quiz over the queue.
  /// Inputs: `context`, `ref`, and which part of the queue.
  /// Returns: None.
  /// Side effects: Pushes the quiz route.
  /// Notes: Internal helper used within this file only. Pushed rather than
  /// navigated to, so finishing or leaving the quiz comes back here.
  void _start(BuildContext context, WidgetRef ref, QuizSource source) {
    context.push(
      '/quiz',
      extra: QuizConfig(
        source: source,
        modes: ref.read(appSettingsProvider).quizModes,
      ),
    );
  }

  /// Purpose: Say what is due and what is new, or that there is nothing.
  /// Inputs: `l10n`, `theme`, the computed `queue`.
  /// Returns: `List<Widget>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. When the backlog is
  /// larger than today's allowance, both numbers are shown: a learner with 300
  /// items overdue is owed the truth about the backlog, not a comfortable
  /// number that never moves.
  List<Widget> _lines(
    AppLocalizations l10n,
    ThemeData theme,
    ReviewQueue queue,
  ) {
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSecondaryContainer,
    );
    if (queue.isEmpty) {
      return [
        Text(
          queue.reviewLimitReached
              ? l10n.learnReviewLimitReached
              : l10n.learnAllDone,
          style: style,
        ),
      ];
    }
    return [
      Text(
        switch (queue) {
          _ when queue.due.isEmpty => l10n.learnDueNone,
          _ when queue.overdueTotal > queue.due.length => l10n.learnDueCapped(
            queue.due.length,
            queue.overdueTotal,
          ),
          _ => l10n.learnDueCount(queue.due.length),
        },
        style: style,
      ),
      const SizedBox(height: 4),
      Text(
        queue.newIds.isEmpty
            ? l10n.learnNewNone
            : l10n.learnNewCount(queue.newIds.length),
        style: style,
      ),
    ];
  }
}
