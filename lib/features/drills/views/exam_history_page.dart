import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/exam_provider.dart';
import '../../../shared/providers/progress_provider.dart';
import '../../../shared/utils/adaptive_layout.dart';
import '../../../shared/widgets/furigana_text.dart';
import '../../content/models/jlpt_level.dart';
import '../../learn/widgets/jlpt_practice_card.dart';
import '../../progress/models/exam_attempt.dart';
import '../../progress/services/nihongo_storage.dart';
import '../models/drill_file.dart';
import '../models/drill_section.dart';
import '../services/drill_repository.dart';

/// Every JLPT paper the learner has sat, newest first, with what they got
/// wrong.
///
/// A full-screen route outside the tab shell, for the reason the quiz and the
/// sentence lab are: it is entered with a purpose from the Learn tab and left
/// when it is finished, not a place to browse.
class ExamHistoryPage extends ConsumerWidget {
  /// Purpose: Create the results page.
  /// Inputs: None.
  /// Returns: A new `ExamHistoryPage` instance.
  /// Side effects: None.
  /// Notes: None.
  const ExamHistoryPage({super.key});

  /// Purpose: Build the list of attempts, or say there are none.
  /// Inputs: `context`, `ref`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often. The
  /// note at the top is not decoration: a screen that shows "48 of 67" beside
  /// the letters JLPT will be read as a JLPT score unless it says otherwise.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final attempts = ref.watch(examAttemptsProvider);
    final screen = MediaQuery.sizeOf(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.jlptHistoryTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: pageMaxContentWidth),
          child: attempts.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      l10n.jlptHistoryEmpty,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    24 + screen.height * 0.02,
                  ),
                  itemCount: attempts.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          l10n.jlptHistoryNote,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }
                    return _AttemptTile(attempt: attempts[index - 1]);
                  },
                ),
        ),
      ),
    );
  }
}

/// One attempt, expandable into what was got wrong.
class _AttemptTile extends ConsumerWidget {
  const _AttemptTile({required this.attempt});

  final ExamAttempt attempt;

  /// Purpose: Build one attempt's summary and its detail.
  /// Inputs: `context`, `ref`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state; deletes the
  /// record when the delete action is used.
  /// Notes: Keep this method cheap because Flutter may call it often. The
  /// wrong questions are loaded only when the tile is expanded, because
  /// showing them means reading up to four content files and most attempts in
  /// a long list are never opened.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final mode = attempt.mode == ExamMode.mock
        ? l10n.jlptMock
        : l10n.jlptModePractice;
    final when = DateFormat.yMd().add_Hm().format(attempt.startedAt.toLocal());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          '${attempt.level} · $mode',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(when),
            Text(l10n.jlptScore(attempt.right, attempt.asked)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              children: [
                for (final entry in attempt.sections.entries)
                  if (DrillSection.parse(entry.key) case final section?)
                    Text(
                      l10n.jlptHistorySection(
                        l10n.drillSectionName(section),
                        entry.value.right,
                        entry.value.asked,
                      ),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
              ],
            ),
          ],
        ),
        children: [
          _WrongQuestions(attempt: attempt),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 8, 8),
              child: TextButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final text = l10n.jlptHistoryDeleted;
                  // A real deletion, not a tombstone: the three-way merge
                  // treats a record deleted on one side and untouched on the
                  // other as deleted, so an attempt removed here is removed
                  // everywhere on the next sync. A record that came back would
                  // be worse than no delete button at all.
                  await NihongoStorage.deleteRecords([attempt.id]);
                  await ref.read(progressDataProvider.notifier).reload();
                  messenger.showSnackBar(SnackBar(content: Text(text)));
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(l10n.jlptHistoryDelete),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The questions this attempt got wrong or never reached.
class _WrongQuestions extends ConsumerWidget {
  const _WrongQuestions({required this.attempt});

  final ExamAttempt attempt;

  /// Purpose: Show what went wrong, joined back from the shipped files.
  /// Inputs: `context`, `ref`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Reads the drill assets through a provider.
  /// Notes: Keep this method cheap because Flutter may call it often.
  ///
  /// Only the answers were stored, so the question text, its options and its
  /// explanation are all read from the content files now. That is the point of
  /// storing only the input: a content update that corrected an answer key
  /// corrects the history with it, rather than leaving a frozen copy the app no
  /// longer agrees with.
  ///
  /// A question the shipped files no longer have says so in one line. Content
  /// is rewritten between releases, and an attempt that quietly lost three of
  /// its rows would be a worse record than one that admits it.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final level = JlptLevel.parse(attempt.level);
    if (level == null) return const SizedBox.shrink();
    // Nothing at all while the files load, rather than a spinner. An
    // `ExpansionTile` builds its children before they are ever shown, so a
    // spinner here would run — invisibly — behind every collapsed row in the
    // list, and the wait is a few milliseconds of reading four small files.
    final files = ref.watch(drillLevelProvider(level)).value;
    if (files == null) return const SizedBox.shrink();

    final byId = <String, DrillQuestion>{
      for (final file in files.values)
        for (final question in file.questions) question.id: question,
    };
    final missed = [
      for (final entry in attempt.answers.entries)
        if (entry.value != 1) entry,
    ]..sort((a, b) => a.key.compareTo(b.key));

    if (missed.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in missed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Builder(
                builder: (context) {
                  final question = byId[entry.key];
                  final label = entry.value == examUnanswered
                      ? l10n.jlptHistoryUnanswered
                      : l10n.jlptHistoryWrong;
                  if (question == null) {
                    return Text(
                      '$label · ${l10n.jlptHistoryGone}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    );
                  }
                  final explanation = question.explanation?.resolveJoined(
                    locale,
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (question.ja != null)
                        FuriganaText(
                          question.renderJa(),
                          reading: question.type.hidesReading
                              ? null
                              : question.reading,
                          style: theme.textTheme.bodyMedium,
                        )
                      else
                        Text(
                          question.prompt.resolveJoined(locale),
                          style: theme.textTheme.bodyMedium,
                        ),
                      if (question.answer case final index?)
                        if (index >= 0 && index < question.options.length)
                          Text(
                            question.options[index],
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      if (explanation != null && explanation.isNotEmpty)
                        Text(
                          explanation,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
