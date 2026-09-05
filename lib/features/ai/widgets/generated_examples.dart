import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/furigana_text.dart';
import '../../content/models/localized_strings.dart';
import '../../content/models/vocab_entry.dart';
import '../../sentence/services/sentence_analyzer.dart';
import '../../speech/widgets/speak_button.dart';
import '../services/ai_assist_service.dart';
import '../services/ai_practice_service.dart';
import '../services/genai_backend.dart';
import '../services/practice_response_parser.dart';
import 'ai_explanation_card.dart';

/// More example sentences for one word, written on the device, on request.
///
/// Most of the catalog has no example sentence, and the ones it has were
/// written for the word rather than for the learner's level. This asks for
/// three more. They are drawn **below** the catalog's own, labelled, and never
/// saved: they are gone when the sheet closes, and nothing about them reaches
/// the progress file or the catalog.
class GeneratedExamples extends ConsumerStatefulWidget {
  /// Purpose: Offer generated examples for a word.
  /// Inputs: The `entry`.
  /// Returns: A new `GeneratedExamples` instance.
  /// Side effects: None until the button is tapped.
  /// Notes: None.
  const GeneratedExamples({super.key, required this.entry});

  final VocabEntry entry;

  @override
  ConsumerState<GeneratedExamples> createState() => _GeneratedExamplesState();
}

class _GeneratedExamplesState extends ConsumerState<GeneratedExamples> {
  List<ContentExample> _examples = const [];
  GenAiFailure? _failure;
  bool _loading = false;

  @override
  /// Purpose: Build the button and whatever came back.
  /// Inputs: `context`.
  /// Returns: `Widget`.
  /// Side effects: None until tapped.
  /// Notes: Nothing at all with the switch off. The generated block carries
  /// the same label every generated thing in this app carries, above the text
  /// rather than below it, so it is read before the Japanese is.
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    if (!ref.watch(aiAssistServiceProvider).canExplain) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_examples.isEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _loading ? null : _ask,
              icon: const Icon(Icons.auto_awesome_outlined, size: 18),
              label: Text(l10n.aiMoreExamples),
            ),
          ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          ),
        if (_failure != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              AiExplanationCard.messageFor(l10n, _failure),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (_examples.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.aiGeneratedLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final example in _examples)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FuriganaText(
                          example.ja,
                          reading: example.reading,
                          style: theme.textTheme.bodyLarge,
                        ),
                        Text(
                          example.translations.resolveJoined(locale),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SpeakButton(
                    text: example.reading ?? example.ja,
                    iconSize: 20,
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  /// Purpose: Ask the model for three sentences.
  /// Inputs: None; reads the templates and the entry.
  /// Returns: None.
  /// Side effects: Runs a model on the device; rebuilds.
  /// Notes: Internal helper used within this file only. A reply that does not
  /// parse into whole lines is dropped rather than partly shown: a generated
  /// sentence sits beside the catalog's own and would otherwise look exactly
  /// as authoritative as one somebody wrote.
  Future<void> _ask() async {
    final builder = await practicePromptBuilder(ref);
    if (builder == null || !mounted) return;
    final locale = Localizations.localeOf(context);
    final prompt = builder.forExamples(widget.entry, locale: locale);
    if (prompt == null) return;

    setState(() {
      _loading = true;
      _failure = null;
    });
    try {
      final raw = await AiPracticeService.instance.run(
        prompt,
        maxOutputTokens: builder.maxOutputTokens,
      );
      if (!mounted) return;
      final parsed = PracticeResponseParser.examples(
        raw,
        language: locale.languageCode == 'en' ? 'en' : 'zh',
        limit: builder.templates.limit('maxExamples', 3),
      );
      setState(() {
        _examples = parsed;
        _failure = parsed.isEmpty ? GenAiFailure.failed : null;
        _loading = false;
      });
    } on GenAiException catch (error) {
      if (!mounted) return;
      setState(() {
        _failure = error.failure;
        _loading = false;
      });
    }
  }
}
