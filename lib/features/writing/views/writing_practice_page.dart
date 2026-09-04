import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/utils/adaptive_layout.dart';
import '../../ai/services/ai_assist_service.dart';
import '../../ai/services/ai_practice_service.dart';
import '../../ai/services/genai_backend.dart';
import '../../ai/services/practice_response_parser.dart';
import '../../ai/widgets/ai_explanation_card.dart';
import '../../content/models/content_catalog.dart';
import '../../content/models/vocab_entry.dart';
import '../../content/services/content_repository.dart';
import '../../lessons/models/lesson_path.dart';
import '../../sentence/models/sentence_analysis.dart';
import '../../sentence/services/sentence_analyzer.dart';
import '../../sentence/widgets/issue_list.dart';
import '../../sentence/widgets/token_chips.dart';

/// What a writing exercise is about, passed as the route's `extra`.
class WritingPrompt {
  /// Purpose: Describe one writing exercise.
  /// Inputs: The `unit` it belongs to and the `prompt` text to show.
  /// Returns: A new `WritingPrompt` instance.
  /// Side effects: None.
  /// Notes: The unit is carried so the deterministic check can ask whether the
  /// learner used what the unit teaches, which is the part that works without
  /// a model.
  const WritingPrompt({required this.prompt, this.unit});

  /// What the learner is asked to write, in their own language.
  final String prompt;

  /// The unit whose words the exercise is built on, when it came from one.
  final LessonUnit? unit;
}

/// How many of the unit's words a piece of writing should use.
const writingWordTarget = 3;

/// Write a few sentences, and get them checked.
///
/// The deterministic pipeline runs first and always: the sentences are parsed,
/// unknown words and flagged issues are shown, and the unit's own words are
/// counted. **That is the whole exercise on a device with no model.** With
/// on-device AI switched on it also offers a natural rewrite and a few notes,
/// which is the part a dictionary and a rule set cannot do.
///
/// Nothing here writes a progress record. A piece of writing is not an item
/// with a recall interval, and the learner grading their own paragraph is not
/// something the scheduler should act on.
class WritingPracticePage extends ConsumerStatefulWidget {
  /// Purpose: Show a writing exercise.
  /// Inputs: The `prompt`.
  /// Returns: A new `WritingPracticePage` instance.
  /// Side effects: None.
  /// Notes: None.
  const WritingPracticePage({super.key, required this.prompt});

  final WritingPrompt prompt;

  @override
  ConsumerState<WritingPracticePage> createState() =>
      _WritingPracticePageState();
}

class _WritingPracticePageState extends ConsumerState<WritingPracticePage> {
  final _controller = TextEditingController();
  List<SentenceAnalysis> _analyses = const [];
  WritingFeedback? _feedback;
  GenAiFailure? _failure;
  bool _checking = false;
  bool _asking = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  /// Purpose: Build the page.
  /// Inputs: `context`.
  /// Returns: `Widget`.
  /// Side effects: None until a button is tapped.
  /// Notes: One column, because writing and reading feedback about it are the
  /// same activity and splitting them would put the learner's own words off
  /// screen while they read what was said about them.
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final service = ref.watch(aiAssistServiceProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.writingTitle)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: pageMaxContentWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Text(
                widget.prompt.prompt,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                minLines: 4,
                maxLines: 8,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: l10n.writingHint,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton(
                    onPressed: _checking ? null : _check,
                    child: Text(l10n.writingCheck),
                  ),
                  const SizedBox(width: 8),
                  if (service.canExplain)
                    TextButton.icon(
                      onPressed: _asking ? null : _ask,
                      icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                      label: Text(l10n.writingRewrite),
                    ),
                ],
              ),
              if (_analyses.isNotEmpty) ..._deterministic(context, l10n),
              if (_asking || _feedback != null || _failure != null)
                AiExplanationCard(
                  title: l10n.writingRewrite,
                  text: _feedback == null
                      ? null
                      : [_feedback!.rewrite, ..._feedback!.notes].join('\n\n'),
                  failure: _failure,
                  loading: _asking,
                  onDismiss: () => setState(() {
                    _feedback = null;
                    _failure = null;
                  }),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Purpose: Show what the app itself can say about the writing.
  /// Inputs: `context`, `l10n`.
  /// Returns: The widgets for the deterministic part.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Three things, in the
  /// order they matter: which of the unit's words were used, how each sentence
  /// was understood, and anything that looked unusual. All of it comes from
  /// the same pipeline the sentence lab uses, so a learner who has met the lab
  /// is reading a familiar answer.
  List<Widget> _deterministic(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final used = _unitWordsUsed();
    return [
      const SizedBox(height: 16),
      if (widget.prompt.unit != null)
        Text(
          l10n.writingWordsUsed(used.length, writingWordTarget),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: used.length >= writingWordTarget
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      for (final analysis in _analyses) ...[
        const SizedBox(height: 12),
        TokenChips(analysis: analysis, catalog: _catalog),
        if (analysis.issues.isNotEmpty) IssueList(analysis: analysis),
      ],
    ];
  }

  ContentCatalog? get _catalog => ref.read(contentCatalogProvider).value;

  /// Purpose: Count the unit's words the learner actually used.
  /// Inputs: None; reads the analyses and the unit.
  /// Returns: `Set<String>` of catalog ids.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Counted from the
  /// **parse** rather than by searching the text, so an inflected form counts:
  /// somebody who wrote 食べました used 食べる.
  Set<String> _unitWordsUsed() {
    final unit = widget.prompt.unit;
    if (unit == null) return const {};
    final wanted = unit.vocab.toSet();
    return {
      for (final analysis in _analyses)
        for (final token in analysis.tokens)
          if (token.refId case final id? when wanted.contains(id)) id,
    };
  }

  /// Purpose: Run the deterministic pipeline over what was written.
  /// Inputs: None; reads the text field.
  /// Returns: None.
  /// Side effects: Builds the analyser if it is not built; rebuilds.
  /// Notes: Internal helper used within this file only. Split on the Japanese
  /// full stop, because that is what the learner typed and each sentence is
  /// analysed on its own — the analyser is built for one sentence at a time.
  Future<void> _check() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _checking = true);
    final analyzer = await ref.read(sentenceAnalyzerProvider.future);
    if (!mounted) return;
    final sentences = [
      for (final part in text.split('。'))
        if (part.trim().isNotEmpty) '${part.trim()}。',
    ];
    setState(() {
      _analyses = [for (final one in sentences) analyzer.analyze(one)];
      _checking = false;
    });
  }

  /// Purpose: Ask the model for a rewrite and a few notes.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Runs a model on the device; rebuilds.
  /// Notes: Internal helper used within this file only. The unit's words and
  /// the deterministic findings go into the prompt, so the rewrite is about
  /// this exercise rather than about Japanese in general.
  Future<void> _ask() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final builder = await practicePromptBuilder(ref);
    if (builder == null || !mounted) return;
    final catalog = _catalog;
    final unit = widget.prompt.unit;
    final words = <VocabEntry>[
      if (catalog != null && unit != null)
        for (final id in unit.vocab) ?catalog.vocabById(id),
    ];

    final prompt = builder.forWriting(
      text,
      unitWords: words,
      locale: Localizations.localeOf(context),
    );
    if (prompt == null) return;

    setState(() {
      _asking = true;
      _failure = null;
    });
    try {
      final raw = await AiPracticeService.instance.run(prompt);
      if (!mounted) return;
      final parsed = PracticeResponseParser.writing(raw);
      setState(() {
        _feedback = parsed;
        _failure = parsed == null ? GenAiFailure.failed : null;
        _asking = false;
      });
    } on GenAiException catch (error) {
      if (!mounted) return;
      setState(() {
        _failure = error.failure;
        _asking = false;
      });
    }
  }
}
