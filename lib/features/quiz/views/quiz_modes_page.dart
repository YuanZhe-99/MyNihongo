import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/app_settings.dart';
import '../../../shared/utils/adaptive_layout.dart';
import '../models/quiz_question.dart';
import '../widgets/quiz_runner.dart';

/// The Settings page that switches ways of asking on and off.
///
/// A second-level page like the WebDAV and backup pages: pushed full-screen on
/// a narrow window, hosted in the detail pane on a wide one, by the same
/// `_SettingsDetail` mechanism.
class QuizModesPage extends ConsumerWidget {
  /// Purpose: Create the quiz modes page.
  /// Inputs: None.
  /// Returns: A new `QuizModesPage` instance.
  /// Side effects: None.
  /// Notes: None.
  const QuizModesPage({super.key});

  /// Purpose: Build the three groups of mode switches.
  /// Inputs: `context`, `ref`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often. An empty
  /// stored set means every mode, so the switches are drawn against the full
  /// set rather than against what was stored.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final enabled = settings.quizModes.isEmpty
        ? QuizMode.values.toSet()
        : settings.quizModes;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.quizModesTitle)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              l10n.quizModesBody,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final group in [
            (l10n.quizModesVocab, vocabQuizModes),
            (l10n.quizModesKana, kanaQuizModes),
            (l10n.quizModesGrammar, grammarQuizModes),
          ]) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                group.$1,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (final mode in group.$2)
              SwitchListTile(
                title: Text(l10n.quizModeLabel(mode)),
                value: enabled.contains(mode),
                onChanged: (on) => _toggle(context, notifier, enabled, mode, on),
              ),
          ],
          SizedBox(height: shellListBottomInset(MediaQuery.sizeOf(context).width)),
        ],
      ),
    );
  }

  /// Purpose: Switch one mode on or off, refusing to switch off the last one.
  /// Inputs: `context`, the `notifier`, the currently `enabled` set, the
  /// `mode` and whether it should be on.
  /// Returns: None.
  /// Side effects: Persists the set, or shows a message.
  /// Notes: Internal helper used within this file only. With every mode off
  /// there is nothing to ask, and a quiz that opens empty looks broken rather
  /// than configured — so the last one is refused with a reason rather than
  /// silently ignored.
  void _toggle(
    BuildContext context,
    AppSettingsNotifier notifier,
    Set<QuizMode> enabled,
    QuizMode mode,
    bool on,
  ) {
    final next = {...enabled};
    if (on) {
      next.add(mode);
    } else {
      next.remove(mode);
    }
    if (next.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.quizModesNoneWarning),
        ),
      );
      return;
    }
    notifier.setQuizModes(next);
  }
}
