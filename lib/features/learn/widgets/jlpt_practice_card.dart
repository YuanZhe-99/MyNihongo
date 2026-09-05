import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/learner_profile_provider.dart';
import '../../content/models/jlpt_level.dart';
import '../../drills/models/drill_file.dart';
import '../../drills/models/drill_section.dart';
import '../../drills/services/drill_repository.dart';
import '../../quiz/models/quiz_config.dart';
import '../../speech/services/tts_service.dart';

/// The Learn tab's way into JLPT practice.
///
/// Replaces the roadmap card that promised this. A card that says a feature is
/// coming should be deleted by the release that ships it, or the app is
/// advertising to a learner who is already using the thing.
class JlptPracticeCard extends ConsumerWidget {
  /// Purpose: Create the card.
  /// Inputs: None.
  /// Returns: A new `JlptPracticeCard` instance.
  /// Side effects: None.
  /// Notes: The level comes from the learner's own target rather than from a
  /// picker on this card: it is already a setting, and two places to change
  /// one thing is how they come to disagree.
  const JlptPracticeCard({super.key});

  /// Purpose: Build the four practise buttons and the two that are not ready.
  /// Inputs: `context`, `ref`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  ///
  /// A section with no shipped file is **disabled with the reason next to
  /// it**, not hidden: a learner who cannot find 読解 practice has no way to
  /// tell whether it does not exist or they have not found it. The same rule
  /// covers listening on a device with no Japanese voice, and the two buttons
  /// this release has not built yet.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final level = ref.watch(learnerProfileProvider).targetLevel;
    final files = ref.watch(drillLevelProvider(level)).value;
    final hasVoice = TtsService.instance.hasJapaneseVoice;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.jlptPracticeTitle(level.label),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.jlptPracticeBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            for (final section in DrillSection.values)
              _sectionRow(
                context,
                l10n,
                theme,
                level: level,
                section: section,
                file: files?[section],
                loading: files == null,
                hasVoice: hasVoice,
              ),
            const Divider(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.timer_outlined, size: 18),
                  label: Text(l10n.jlptMock),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.push('/exam-history'),
                  icon: const Icon(Icons.history_outlined, size: 18),
                  label: Text(l10n.jlptHistory),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.jlptComingNext,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Purpose: Render one section's practise row.
  /// Inputs: `context`, `l10n`, `theme`; the `level`, the `section`, its
  /// `file` if loaded, whether the card is still `loading`, and `hasVoice`.
  /// Returns: `Widget`.
  /// Side effects: Pushes the quiz route on tap.
  /// Notes: Internal helper used within this file only. The count is shown
  /// because it is the honest measure of what a section can offer: "20
  /// questions" is a different offer from "120 questions", and a learner
  /// choosing what to practise is entitled to know which they are getting.
  Widget _sectionRow(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme, {
    required JlptLevel level,
    required DrillSection section,
    required DrillFile? file,
    required bool loading,
    required bool hasVoice,
  }) {
    final count = file?.questions.length ?? 0;
    final silent = section == DrillSection.listening && !hasVoice;
    final ready = count > 0 && !silent;
    final reason = loading
        ? null
        : silent
        ? l10n.jlptNoVoice
        : count == 0
        ? l10n.jlptNoContent
        : null;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      enabled: ready,
      leading: Icon(_icon(section)),
      title: Text(l10n.drillSectionName(section)),
      subtitle: reason == null
          ? (loading ? null : Text(l10n.jlptQuestionCount(count)))
          : Text(
              reason,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
      trailing: const Icon(Icons.chevron_right),
      onTap: ready
          ? () => context.push(
              '/quiz',
              extra: QuizConfig(
                source: DrillSource(level, sections: {section}),
              ),
            )
          : null,
    );
  }

  /// Purpose: Pick an icon for a section.
  /// Inputs: `section`.
  /// Returns: `IconData`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  IconData _icon(DrillSection section) => switch (section) {
    DrillSection.vocab => Icons.abc_outlined,
    DrillSection.grammar => Icons.account_tree_outlined,
    DrillSection.reading => Icons.article_outlined,
    DrillSection.listening => Icons.headphones_outlined,
  };
}

/// Purpose: Name a section in the learner's language.
/// Inputs: The `section`.
/// Returns: `String`.
/// Side effects: None.
/// Notes: An extension rather than a free function so the card, the exam page
/// and the results view all reach it the same way — the shape `quizModeLabel`
/// already set. Exhaustive on purpose: a new section with no name is a compile
/// error rather than a blank row.
extension DrillSectionLabel on AppLocalizations {
  /// Purpose: Name one section.
  /// Inputs: `section`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: None.
  String drillSectionName(DrillSection section) => switch (section) {
    DrillSection.vocab => drillSectionVocab,
    DrillSection.grammar => drillSectionGrammar,
    DrillSection.reading => drillSectionReading,
    DrillSection.listening => drillSectionListening,
  };
}
