import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/furigana_text.dart';
import '../../ai/services/ai_assist_service.dart';
import '../../ai/services/ai_practice_service.dart';
import '../../ai/services/genai_backend.dart';
import '../../ai/services/practice_response_parser.dart';
import '../../ai/widgets/ai_explanation_card.dart';
import '../../content/models/jlpt_level.dart';
import '../../sentence/services/sentence_analyzer.dart';
import '../models/drill_file.dart';

/// The text a reading question is about.
///
/// One line per `DialogueLine`, with furigana where the content supplies a
/// reading, and the translation behind a toggle. The translation is a toggle
/// rather than a column because 読解 is the skill of reading Japanese: a
/// translation beside the text turns the exercise into reading English.
class DrillPassageView extends ConsumerStatefulWidget {
  /// Purpose: Show one passage.
  /// Inputs: The `passage`; `allowTranslation` — whether the toggle is offered
  /// at all; `level` — what "simpler" is measured against.
  /// Returns: A new `DrillPassageView` instance.
  /// Side effects: None.
  /// Notes: `allowTranslation` is false in a timed block. A mock is meant to
  /// measure what the learner can read unaided, and a translation is the one
  /// aid that answers most questions outright. The per-line paraphrase is
  /// gated on the same flag, and for the same reason: an easier Japanese
  /// version of the sentence the question turns on is very nearly the answer.
  const DrillPassageView({
    super.key,
    required this.passage,
    this.allowTranslation = true,
    this.level = JlptLevel.n5,
  });

  /// The passage to show.
  final DrillPassage passage;

  /// Whether the learner may reveal the translation, and ask for a simpler
  /// version of a line.
  final bool allowTranslation;

  /// The level a paraphrase should stay within.
  final JlptLevel level;

  @override
  ConsumerState<DrillPassageView> createState() => _DrillPassageViewState();
}

class _DrillPassageViewState extends ConsumerState<DrillPassageView> {
  bool _translated = false;
  final _simpler = <int, Paraphrase>{};
  final _failed = <int, GenAiFailure>{};
  final _asking = <int>{};

  /// Purpose: Build the passage, its speakers and its translation toggle.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often. A line
  /// with a speaker is laid out as a dialogue turn; a line without one is a
  /// paragraph. That is the difference between a 会話 and a 説明文, and the
  /// content files say which by whether they wrote a `speaker`.
  ///
  /// The paraphrase sits **under its own line** rather than in a card at the
  /// bottom, because the whole point of it is that the learner can see the two
  /// versions of one sentence together.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final canAsk =
        widget.allowTranslation &&
        ref.watch(aiAssistServiceProvider).canExplain;
    final translation = widget.passage.translations.resolveTranslationJoined(
      locale,
      separator: '\n',
    );
    final hasTranslation =
        translation.isNotEmpty ||
        widget.passage.lines.any(
          (line) => line.translations.resolveTranslation(locale).isNotEmpty,
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
            for (final (index, line) in widget.passage.lines.indexed)
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
                          line.translations.resolveTranslationJoined(locale),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    if (canAsk &&
                        !_simpler.containsKey(index) &&
                        !_failed.containsKey(index))
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _asking.contains(index)
                              ? null
                              : () => _paraphrase(index, line.ja),
                          icon: const Icon(
                            Icons.auto_awesome_outlined,
                            size: 16,
                          ),
                          label: Text(l10n.aiParaphrase),
                        ),
                      ),
                    ..._paraphraseOf(index, theme, l10n),
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
            // A toggle that reveals nothing is not offered: a Japanese
            // reader has no translation of a Japanese passage.
            if (widget.allowTranslation && hasTranslation)
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

  /// Purpose: Render whatever came back for one line.
  /// Inputs: The line's `index`, the `theme`, `l10n`.
  /// Returns: The widgets under that line; empty when nothing was asked.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The generated label is
  /// carried by the text itself here rather than by a card, because a card
  /// per line in a nine-line passage would bury the passage. The label is not
  /// optional: this is model-written Japanese sitting directly under content
  /// the app wrote, and the two must not be indistinguishable.
  List<Widget> _paraphraseOf(
    int index,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    if (_asking.contains(index)) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 2),
          child: Text(
            l10n.aiGenerating,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ];
    }
    if (_failed[index] case final failure?) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            AiExplanationCard.messageFor(l10n, failure),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
      ];
    }
    final simpler = _simpler[index];
    if (simpler == null) return const [];
    return [
      Padding(
        padding: const EdgeInsets.only(top: 4, left: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.aiGeneratedLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            FuriganaText(
              simpler.japanese,
              reading: simpler.reading,
              style: theme.textTheme.bodyMedium,
            ),
            if (simpler.meaning case final meaning?)
              Text(
                meaning,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    ];
  }

  /// Purpose: Ask for one line in easier Japanese.
  /// Inputs: The line's `index` and its `japanese`.
  /// Returns: None.
  /// Side effects: Runs a model on the device; rebuilds.
  /// Notes: Internal helper used within this file only. A reply the parser
  /// cannot read is a failure rather than a shrug, and the line keeps the
  /// original only — nothing half-parsed is put in front of a learner as
  /// Japanese to imitate.
  Future<void> _paraphrase(int index, String japanese) async {
    final builder = await practicePromptBuilder(ref);
    if (builder == null || !mounted) return;
    final prompt = builder.forParaphrase(
      sentence: japanese,
      level: widget.level.label,
      locale: Localizations.localeOf(context),
    );
    if (prompt == null) return;

    setState(() {
      _asking.add(index);
      _failed.remove(index);
    });
    try {
      final raw = await AiPracticeService.instance.run(
        prompt,
        maxOutputTokens: builder.maxOutputTokens,
      );
      if (!mounted) return;
      final parsed = PracticeResponseParser.paraphrase(raw);
      setState(() {
        _asking.remove(index);
        if (parsed == null) {
          _failed[index] = GenAiFailure.failed;
        } else {
          _simpler[index] = parsed;
        }
      });
    } on GenAiException catch (error) {
      if (!mounted) return;
      setState(() {
        _asking.remove(index);
        _failed[index] = error.failure;
      });
    }
  }
}
