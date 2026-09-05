import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/furigana_text.dart';
import '../models/drill_file.dart';

/// The text a reading question is about.
///
/// One line per `DialogueLine`, with furigana where the content supplies a
/// reading, and the translation behind a toggle. The translation is a toggle
/// rather than a column because 読解 is the skill of reading Japanese: a
/// translation beside the text turns the exercise into reading English.
class DrillPassageView extends StatefulWidget {
  /// Purpose: Show one passage.
  /// Inputs: The `passage`; `allowTranslation` — whether the toggle is offered
  /// at all.
  /// Returns: A new `DrillPassageView` instance.
  /// Side effects: None.
  /// Notes: `allowTranslation` is false in a timed block. A mock is meant to
  /// measure what the learner can read unaided, and a translation is the one
  /// aid that answers most questions outright.
  const DrillPassageView({
    super.key,
    required this.passage,
    this.allowTranslation = true,
  });

  /// The passage to show.
  final DrillPassage passage;

  /// Whether the learner may reveal the translation.
  final bool allowTranslation;

  @override
  State<DrillPassageView> createState() => _DrillPassageViewState();
}

class _DrillPassageViewState extends State<DrillPassageView> {
  bool _translated = false;

  /// Purpose: Build the passage, its speakers and its translation toggle.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often. A line
  /// with a speaker is laid out as a dialogue turn; a line without one is a
  /// paragraph. That is the difference between a 会話 and a 説明文, and the
  /// content files say which by whether they wrote a `speaker`.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final translation = widget.passage.translations.resolveJoined(
      locale,
      separator: '\n',
    );

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in widget.passage.lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (line.speaker.isNotEmpty)
                      Text(
                        line.speaker,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    FuriganaText(
                      line.ja,
                      reading: line.reading,
                      style: theme.textTheme.bodyLarge,
                    ),
                    if (_translated)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          line.translations.resolveJoined(locale),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            if (_translated && translation.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  translation,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (widget.allowTranslation)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _translated = !_translated),
                  icon: Icon(
                    _translated
                        ? Icons.visibility_off_outlined
                        : Icons.translate_outlined,
                    size: 18,
                  ),
                  label: Text(
                    _translated
                        ? l10n.drillHideTranslation
                        : l10n.drillShowTranslation,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
