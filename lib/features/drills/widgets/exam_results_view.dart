import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../learn/widgets/jlpt_practice_card.dart';
import '../../quiz/services/quiz_session.dart';
import '../../quiz/widgets/why_wrong.dart';
import '../models/drill_section.dart';
import '../services/exam_session.dart';

/// What a finished mock scored, section by section, and what went wrong in it.
///
/// The one screen in the app that shows a whole paper's result, and the one
/// most at risk of being read as a JLPT score. It says it is not, in words, at
/// the top — not in a footnote under the number.
class ExamResultsView extends StatelessWidget {
  /// Purpose: Show the finished paper.
  /// Inputs: The `exam`; `sectionOf` mapping a question id to its section;
  /// `onDone`.
  /// Returns: A new `ExamResultsView` instance.
  /// Side effects: None.
  /// Notes: The section map is passed in rather than looked up, because the
  /// page that drew the paper already has it and re-deriving it here would
  /// mean reading four content files to answer a question already answered.
  const ExamResultsView({
    super.key,
    required this.exam,
    required this.sectionOf,
    required this.onDone,
  });

  /// The finished paper.
  final ExamSession exam;

  /// Which section each question belongs to.
  final Map<String, DrillSection> sectionOf;

  /// Called when the learner is done reading.
  final VoidCallback onDone;

  /// Purpose: Build the per-section scores and the list of what went wrong.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  ///
  /// **Unanswered is shown apart from wrong.** They are different things —
  /// one is a question the learner got wrong, the other is a question the
  /// clock took away — and a results screen that merged them would teach the
  /// learner to review material they never saw.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final screen = MediaQuery.sizeOf(context);

    final tallies = <DrillSection, (int asked, int right, int missed)>{};
    final wrong = <(String key, bool answered)>[];
    for (final block in exam.blocks) {
      for (final outcome in block.session.outcomes) {
        final section = sectionOf[outcome.key];
        if (section == null) continue;
        final current = tallies[section] ?? (0, 0, 0);
        tallies[section] = (
          current.$1 + 1,
          current.$2 + (outcome.correct ? 1 : 0),
          current.$3 + (outcome.answered ? 0 : 1),
        );
        if (!outcome.correct) wrong.add((outcome.key, outcome.answered));
      }
    }
    final asked = tallies.values.fold(0, (sum, t) => sum + t.$1);
    final right = tallies.values.fold(0, (sum, t) => sum + t.$2);

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 32 + screen.height * 0.02),
      children: [
        Text(
          l10n.examResultsTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(l10n.jlptScore(right, asked), style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          l10n.jlptHistoryNote,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        for (final section in DrillSection.values)
          if (tallies[section] case final tally?)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.drillSectionName(section)),
                  Text(
                    tally.$3 == 0
                        ? '${tally.$2}/${tally.$1}'
                        : '${tally.$2}/${tally.$1} · '
                              '${l10n.examUnansweredCount(tally.$3)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        const SizedBox(height: 8),
        for (final block in exam.blocks)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              l10n.examBlockTime(
                block.sections
                    .map((section) => l10n.drillSectionName(section))
                    .join(' · '),
                block.usedBefore.inMinutes,
                block.limit.inMinutes,
              ),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        const SizedBox(height: 16),
        if (wrong.isEmpty)
          Text(l10n.quizSummaryPerfect)
        else ...[
          Text(
            l10n.quizSummaryReview,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final block in exam.blocks)
            for (final question in block.session.allQuestions)
              if (wrong.any((w) => w.$1 == QuizSession.scoreKey(question)))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wrong
                                .firstWhere(
                                  (w) => w.$1 == QuizSession.scoreKey(question),
                                )
                                .$2
                            ? l10n.jlptHistoryWrong
                            : l10n.jlptHistoryUnanswered,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(question.prompt, style: theme.textTheme.bodyMedium),
                      if (question.answerText case final answer?)
                        Text(
                          answer,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      WhyWrong(question: question, chose: null),
                    ],
                  ),
                ),
        ],
        const SizedBox(height: 24),
        FilledButton(onPressed: onDone, child: Text(l10n.quizSummaryDone)),
      ],
    );
  }
}
