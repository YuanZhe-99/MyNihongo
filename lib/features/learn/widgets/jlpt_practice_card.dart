import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/learner_profile_provider.dart';
import '../../content/models/jlpt_level.dart';
import '../../drills/models/drill_file.dart';
import '../../drills/models/drill_section.dart';
import '../../drills/services/drill_repository.dart';
import '../../drills/views/exam_page.dart';
import '../../progress/services/nihongo_storage.dart';
import '../../../shared/providers/exam_provider.dart';
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

    return ValueListenableBuilder<bool>(
      // Rebuilt when the speech engine has actually been asked. Reading
      // `hasJapaneseVoice` at first build says "no" on every device, because
      // the probe has not run — and this card would then tell a Pixel it
      // cannot practise listening and never take it back.
      valueListenable: TtsService.instance.ready,
      builder: (context, ready, _) =>
          _card(context, ref, l10n, theme, level, files, ready),
    );
  }

  /// Purpose: Build the card itself, once the speech probe has answered.
  /// Inputs: `context`, `ref`, `l10n`, `theme`, the `level`, its `files`, and
  /// whether the engine has been `ready` asked.
  /// Returns: `Widget`.
  /// Side effects: None until a control is used.
  /// Notes: Internal helper used within this file only. Split out only so the
  /// listenable wraps it; the reasoning is all in `build`.
  Widget _card(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ThemeData theme,
    JlptLevel level,
    Map<DrillSection, DrillFile>? files,
    bool ready,
  ) {
    final hasVoice = !ready || TtsService.instance.hasJapaneseVoice;

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
                // Listening is 'still loading' until the speech engine has
                // answered, so the row makes no claim it has not checked.
                loading:
                    files == null ||
                    (!ready && section == DrillSection.listening),
                hasVoice: hasVoice,
              ),
            const Divider(height: 24),
            // A saved paper is offered before a new one. Starting a fresh mock
            // is one tap away either way, but a learner who put one down half
            // an hour ago should not have to remember it exists.
            if (ref.watch(savedExamProvider).value case final saved?) ...[
              Text(
                l10n.examContinueBody(
                  saved.level,
                  saved.blockIndex + 1,
                  saved.remaining.inMinutes,
                ),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        context.push('/exam', extra: const ExamConfig.resume()),
                    icon: const Icon(Icons.play_arrow_outlined, size: 18),
                    label: Text(l10n.examContinue),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _discard(context, ref, l10n),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(l10n.examDiscard),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: files == null
                      ? null
                      : () => _startMock(context, ref, l10n, level),
                  icon: const Icon(Icons.timer_outlined, size: 18),
                  label: Text(l10n.examStartNew),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.push('/exam-history'),
                  icon: const Icon(Icons.history_outlined, size: 18),
                  label: Text(l10n.jlptHistory),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Purpose: Start a new mock, asking first if one is already saved.
  /// Inputs: `context`, `ref`, `l10n`, the `level`.
  /// Returns: None.
  /// Side effects: May clear the saved paper; navigates.
  /// Notes: Internal helper used within this file only. One saved paper per
  /// device, so starting a second has to replace the first. That is worth
  /// asking about: the learner may have forgotten a paper is half-sat, and it
  /// is the only thing here that cannot be recovered.
  Future<void> _startMock(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    JlptLevel level,
  ) async {
    final router = GoRouter.of(context);
    if (ref.read(savedExamProvider).value != null) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.examReplaceTitle),
          content: Text(l10n.examReplaceBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.examStartNew),
            ),
          ],
        ),
      );
      if (replace != true) return;
      await NihongoStorage.clearExamInProgress();
      ref.refresh(savedExamProvider);
    }
    // Through the router, not the local navigator: `/exam` is registered
    // outside the tab shell, and pushing a `MaterialPageRoute` here would put
    // a running clock above a navigation bar inviting the learner to leave.
    router.push('/exam', extra: ExamConfig(level));
  }

  /// Purpose: Throw away the saved paper.
  /// Inputs: `context`, `ref`, `l10n`.
  /// Returns: None.
  /// Side effects: Deletes the save file; refreshes the card.
  /// Notes: Internal helper used within this file only. The dialog says what
  /// survives: every answer already given went through the scheduler as it
  /// happened, so discarding the paper loses the paper, not the study.
  Future<void> _discard(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.examDiscardTitle),
        content: Text(l10n.examDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.examDiscard),
          ),
        ],
      ),
    );
    if (discard != true) return;
    await NihongoStorage.clearExamInProgress();
    ref.refresh(savedExamProvider);
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
