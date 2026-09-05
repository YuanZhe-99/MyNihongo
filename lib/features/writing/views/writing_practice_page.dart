import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/history_provider.dart';
import '../../../shared/providers/progress_provider.dart';
import '../../../shared/utils/adaptive_layout.dart';
import '../../../shared/widgets/history_list.dart';
import '../../ai/services/ai_assist_service.dart';
import '../../ai/services/ai_practice_service.dart';
import '../../ai/services/genai_backend.dart';
import '../../ai/services/practice_response_parser.dart';
import '../../ai/services/writing_rewrite.dart';
import '../../ai/widgets/ai_explanation_card.dart';
import '../../content/models/content_catalog.dart';
import '../../content/models/vocab_entry.dart';
import '../../content/services/content_repository.dart';
import '../../lessons/models/lesson_path.dart';
import '../../progress/models/history_entry.dart';
import '../../progress/services/nihongo_storage.dart';
import '../../sentence/models/sentence_analysis.dart';
import '../../sentence/services/sentence_analyzer.dart';
import '../../sentence/widgets/analysis_result_view.dart';

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
/// The deterministic pipeline runs first and always: each sentence is analysed
/// exactly as the sentence lab analyses one — the words, the structure, the
/// grammar it uses and anything unusual — and the unit's own words are counted.
/// **That is the whole exercise on a device with no model.** With on-device AI
/// switched on it also offers a rewrite, which is the part a dictionary and a
/// rule set cannot do.
///
/// Nothing here writes a progress record about how well the writing did. A
/// piece of writing is not an item with a recall interval, and the learner
/// grading their own paragraph is not something the scheduler should act on.
/// What is written is the text itself, to the history, so it can be reopened.
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

  /// A rewrite from the proofreader, on a device with no Prompt model.
  String? _rewriteOnly;
  GenAiFailure? _failure;
  bool _checking = false;
  bool _asking = false;

  /// The optional on-device model, taken from the analyser that produced
  /// [_analyses]; null in every build where nothing may run.
  SentenceEnhancer? _enhancer;

  @override
  void initState() {
    super.initState();
    AiAssistService.instance.addListener(_onAiChanged);
  }

  /// Purpose: Rebuild when the on-device AI's state changes.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Rebuilds.
  /// Notes: Internal helper used within this file only. What makes the rewrite
  /// button appear and disappear with the switch while the page is open.
  void _onAiChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AiAssistService.instance.removeListener(_onAiChanged);
    _controller.dispose();
    super.dispose();
  }

  /// Purpose: Build the page in one or two panes.
  /// Inputs: `context`.
  /// Returns: `Widget`.
  /// Side effects: None until a button is tapped.
  /// Notes: The same rule the sentence lab follows, for the same reason: the
  /// feedback about one sentence is a chain and stays one column, while the
  /// prompt, the field and the history go in a pane of their own when there is
  /// room. On a narrow window the history moves behind an app-bar button.
  /// Recorded in `adaptive-layout.md`.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final history = ref.watch(writingHistoryProvider(widget.prompt.unit?.id));

    final screen = MediaQuery.sizeOf(context);
    final split = canSplitLayout(screen.width, screen.height);

    final result = <Widget>[
      if (_analyses.isNotEmpty) ..._deterministic(context, l10n),
      if (_asking ||
          _feedback != null ||
          _rewriteOnly != null ||
          _failure != null)
        AiExplanationCard(
          title: _feedback != null || _canExplain
              ? l10n.writingRewrite
              : l10n.aiCorrectionHeading,
          text: _aiText(),
          failure: _failure,
          loading: _asking,
          onDismiss: () => setState(() {
            _feedback = null;
            _rewriteOnly = null;
            _failure = null;
          }),
        ),
    ];

    final appBar = AppBar(
      title: Text(l10n.writingTitle),
      actions: [
        if (!split)
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: l10n.historyShow,
            onPressed: () => showHistorySheet(
              context,
              entries: history,
              onOpen: _openHistory,
              onDelete: _deleteHistory,
            ),
          ),
      ],
    );

    if (!split) {
      return Scaffold(
        appBar: appBar,
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: pageMaxContentWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [..._buildInput(l10n, theme), ...result],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labInputPaneWidth(shellContentWidth(screen.width)),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                ..._buildInput(l10n, theme),
                const SizedBox(height: 20),
                Text(l10n.historyTitle, style: theme.textTheme.titleSmall),
                HistoryList(
                  entries: history,
                  onOpen: _openHistory,
                  onDelete: _deleteHistory,
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: result,
            ),
          ),
        ],
      ),
    );
  }

  /// Purpose: Build the prompt, the field and the button row.
  /// Inputs: `l10n`, `theme`.
  /// Returns: `List<Widget>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Shared by both layouts
  /// so the two cannot drift apart.
  List<Widget> _buildInput(AppLocalizations l10n, ThemeData theme) {
    return [
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
          if (_canExplain || _canProofread)
            TextButton.icon(
              onPressed: _asking ? null : _ask,
              icon: const Icon(Icons.auto_awesome_outlined, size: 18),
              label: Text(
                _canExplain ? l10n.writingRewrite : l10n.aiSuggestCorrection,
              ),
            ),
        ],
      ),
    ];
  }

  /// Whether a rewrite with notes can be generated: the Prompt API.
  bool get _canExplain => ref.watch(aiAssistServiceProvider).canExplain;

  /// Whether a bare rewrite can be generated: the Proofreading API.
  ///
  /// A device can have this and not [_canExplain] — the two features have
  /// separate device lists and the Prompt API's is the narrower one. Offering
  /// the rewrite alone is better than offering nothing, which is what this page
  /// did until v0.3.2.
  bool get _canProofread =>
      _enhancer != null && ref.watch(aiAssistServiceProvider).canProofread;

  /// Purpose: Word whatever the model produced.
  /// Inputs: None; reads the two result holders.
  /// Returns: `String?` — null while nothing has come back.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The Prompt API answers
  /// with a rewrite and notes; the proofreader answers with a sentence and
  /// nothing else, and padding that out with an explanation the app invented
  /// would be putting words in the model's mouth.
  String? _aiText() {
    final feedback = _feedback;
    if (feedback != null) {
      return [feedback.rewrite, ...feedback.notes].join('\n\n');
    }
    return _rewriteOnly;
  }

  /// Purpose: Show what the app itself can say about the writing.
  /// Inputs: `context`, `l10n`.
  /// Returns: The widgets for the deterministic part.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Which of the unit's
  /// words were used, then each sentence analysed in full — the same four
  /// headed sections the sentence lab shows, through the same widget, so a
  /// learner who has met the lab is reading a familiar answer rather than a
  /// second, thinner one.
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
      for (var index = 0; index < _analyses.length; index++) ...[
        const SizedBox(height: 16),
        if (_analyses.length > 1)
          Text(
            l10n.writingSentenceN(index + 1),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        AnalysisResultView(analysis: _analyses[index], catalog: _catalog),
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
  /// Side effects: Builds the analyser if it is not built; writes the history;
  /// rebuilds.
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
      _enhancer = analyzer.enhancer;
      _analyses = [for (final one in sentences) analyzer.analyze(one)];
      _checking = false;
    });
    await _remember(text);
  }

  /// Purpose: Add what was written to the history.
  /// Inputs: The `text`.
  /// Returns: None.
  /// Side effects: Writes the progress file; reloads the progress provider.
  /// Notes: Internal helper used within this file only. Keyed by the unit as
  /// well as the text, so the same sentence written for two exercises is two
  /// entries — the prompt is what makes it a different piece of work.
  Future<void> _remember(String text) async {
    final entry = HistoryEntry.forInput(
      HistoryKind.writing,
      text,
      unitId: widget.prompt.unit?.id,
    );
    if (entry == null) return;
    try {
      await NihongoStorage.recordHistory(entry);
      if (mounted) await ref.read(progressDataProvider.notifier).reload();
    } catch (_) {
      // Remembering is a convenience; the feedback on screen is the feature.
    }
  }

  /// Purpose: Put a remembered piece of writing back and check it again.
  /// Inputs: The `entry`.
  /// Returns: None.
  /// Side effects: As [_check].
  /// Notes: Internal helper used within this file only.
  void _openHistory(HistoryEntry entry) {
    _controller.text = entry.text;
    setState(() {
      _feedback = null;
      _rewriteOnly = null;
      _failure = null;
    });
    _check();
  }

  /// Purpose: Forget one remembered piece of writing.
  /// Inputs: The `entry`.
  /// Returns: None.
  /// Side effects: Writes the progress file; reloads the progress provider.
  /// Notes: Internal helper used within this file only.
  Future<void> _deleteHistory(HistoryEntry entry) async {
    try {
      await NihongoStorage.deleteRecords([entry.id]);
      if (mounted) await ref.read(progressDataProvider.notifier).reload();
    } catch (_) {
      // As in [_remember]: nothing on screen depends on this succeeding.
    }
  }

  /// Purpose: Ask the model to improve what was written.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Runs a model on the device; rebuilds.
  /// Notes: Internal helper used within this file only. Two paths, because the
  /// two on-device features answer different questions and a device may have
  /// either. With the Prompt API the unit's words and the learner's text go
  /// into a prompt and the answer is a rewrite plus notes about it. With only
  /// the proofreader, each analysed sentence is corrected in turn and the
  /// result is the rewrite alone — less, but the honest most this device can
  /// say, and far better than the button not being there.
  Future<void> _ask() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (_canExplain) {
      await _askPrompt(text);
      return;
    }
    await _askProofreader();
  }

  /// Purpose: Ask the Prompt API for a rewrite and a few notes.
  /// Inputs: The `text`.
  /// Returns: None.
  /// Side effects: Runs a model on the device; rebuilds.
  /// Notes: Internal helper used within this file only. The unit's words and
  /// the learner's text go into the prompt, so the rewrite is about this
  /// exercise rather than about Japanese in general.
  Future<void> _askPrompt(String text) async {
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
      _rewriteOnly = null;
    });
    try {
      final raw = await AiPracticeService.instance.run(
        prompt,
        maxOutputTokens: builder.maxOutputTokens,
      );
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

  /// Purpose: Ask the proofreader to correct each sentence.
  /// Inputs: None; reads the analyses.
  /// Returns: None.
  /// Side effects: One inference per sentence, in sequence; rebuilds.
  /// Notes: Internal helper used within this file only. The sentences have to
  /// have been analysed first, because the proofreader is handed the normalized
  /// sentence the analysis refers to; so a learner who has not pressed Check
  /// gets the deterministic pass run for them rather than an error.
  Future<void> _askProofreader() async {
    if (_analyses.isEmpty) await _check();
    final enhancer = _enhancer;
    if (!mounted || enhancer == null || _analyses.isEmpty) return;

    setState(() {
      _asking = true;
      _failure = null;
      _feedback = null;
    });
    try {
      final rewrite = await proofreadSentences(enhancer, _analyses);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _rewriteOnly = rewrite ?? l10n.aiCorrectionNone;
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
