import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../ai/services/ai_assist_service.dart';
import '../../ai/services/ai_practice_service.dart';
import '../../ai/services/genai_backend.dart';
import '../../ai/services/practice_response_parser.dart';
import '../../ai/widgets/ai_explanation_card.dart';
import '../../content/models/content_catalog.dart';
import '../../content/services/content_repository.dart';
import '../../progress/models/study_record.dart';
import '../../sentence/services/sentence_analyzer.dart';
import '../models/quiz_question.dart';

/// The explanation shown under a wrong answer.
///
/// Two layers, in this order. The catalog's own explanation of the grammar
/// point, or a hand-written question's own note, is shown first and always —
/// it is the app's answer and it is right. Only if on-device AI is switched on
/// does a button appear offering more words about **this** wrong choice, which
/// is the thing the catalog cannot say because it does not know what was
/// picked.
class WhyWrong extends ConsumerStatefulWidget {
  /// Purpose: Explain one wrong answer.
  /// Inputs: The `question` and the option index the learner `chose`.
  /// Returns: A new `WhyWrong` instance.
  /// Side effects: None until the button is tapped.
  /// Notes: None.
  const WhyWrong({super.key, required this.question, required this.chose});

  final QuizQuestion question;
  final int? chose;

  @override
  ConsumerState<WhyWrong> createState() => _WhyWrongState();
}

class _WhyWrongState extends ConsumerState<WhyWrong> {
  String? _generated;
  GenAiFailure? _failure;
  bool _loading = false;

  @override
  /// Purpose: Build the deterministic note and, when possible, the button.
  /// Inputs: `context`.
  /// Returns: `Widget`.
  /// Side effects: None until tapped.
  /// Notes: With the switch off there is no button and no hint — the quiz is
  /// exactly what it was before the AI existed, which is the rule the sentence
  /// lab already follows.
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final catalog = ref.watch(contentCatalogProvider).value;
    final service = ref.watch(aiAssistServiceProvider);
    final note = _note(catalog);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(note, style: theme.textTheme.bodyMedium),
          ),
        if (service.canExplain && _generated == null && _failure == null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _loading ? null : () => _ask(catalog),
              icon: const Icon(Icons.auto_awesome_outlined, size: 18),
              label: Text(l10n.quizWhyWrong),
            ),
          ),
        if (_loading || _generated != null || _failure != null)
          AiExplanationCard(
            title: l10n.quizWhyWrong,
            text: _generated,
            failure: _failure,
            loading: _loading,
            onDismiss: () => setState(() {
              _generated = null;
              _failure = null;
            }),
          ),
      ],
    );
  }

  /// Purpose: Find what the app itself can say about this question.
  /// Inputs: The `catalog`.
  /// Returns: `String?`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. A hand-written
  /// question carries its own note; anything else falls back to the catalog's
  /// explanation of the grammar point it is about. A vocabulary question has
  /// neither, and shows nothing rather than something vague.
  String? _note(ContentCatalog? catalog) {
    final explanation = widget.question.explanation;
    if (explanation != null && explanation.isNotEmpty) return explanation;
    if (catalog == null) return null;
    if (studyKindOf(widget.question.itemId) != StudyKind.grammar) return null;
    final point = catalog.grammarById(widget.question.itemId);
    if (point == null) return null;
    final locale = Localizations.localeOf(context);
    final text = point.explanation.resolveJoined(locale);
    return text.isEmpty ? null : text;
  }

  /// Purpose: Ask the model why this choice was wrong.
  /// Inputs: The `catalog`, for the grammar note to ground the answer in.
  /// Returns: None.
  /// Side effects: Runs a model on the device; rebuilds.
  /// Notes: Internal helper used within this file only. The question is handed
  /// over exactly as it was worded on screen, and the catalog's own note is
  /// handed over with an instruction not to contradict it.
  Future<void> _ask(ContentCatalog? catalog) async {
    final question = widget.question;
    final chose = widget.chose;
    if (chose == null) return;
    final builder = await practicePromptBuilder(ref);
    if (builder == null || !mounted) return;
    if (chose < 0 || chose >= question.options.length) return;
    final answer = question.answerText;
    if (answer == null) return;

    final prompt = builder.forWhyWrong(
      question: question.prompt,
      chosen: question.options[chose],
      correct: answer,
      grammarNote: _note(catalog),
      locale: Localizations.localeOf(context),
    );
    if (prompt == null) return;

    setState(() {
      _loading = true;
      _failure = null;
    });
    try {
      final raw = await AiPracticeService.instance.run(prompt);
      if (!mounted) return;
      setState(() {
        _generated = PracticeResponseParser.explanation(raw, prompt: prompt);
        _failure = _generated == null ? GenAiFailure.failed : null;
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
