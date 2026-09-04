import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/history_provider.dart';
import '../../../shared/providers/progress_provider.dart';
import '../../../shared/utils/adaptive_layout.dart';
import '../../../shared/widgets/history_list.dart';
import '../../ai/services/ai_assist_service.dart';
import '../../ai/services/genai_backend.dart';
import '../../ai/widgets/ai_explanation_card.dart';
import '../../content/services/content_repository.dart';
import '../../progress/models/history_entry.dart';
import '../../progress/services/nihongo_storage.dart';
import '../../speech/widgets/speak_button.dart';
import '../models/sentence_analysis.dart';
import '../services/sentence_analyzer.dart';
import '../widgets/analysis_result_view.dart';

/// One pending or finished answer from the on-device model.
///
/// Three states in one object because a card shows exactly one of them, and
/// keeping them apart in the page's state would let a stale text survive a new
/// request.
class _AiResult {
  const _AiResult({this.loading = false, this.text, this.failure});

  /// The model is running.
  final bool loading;

  /// What it answered, cleaned up.
  final String? text;

  /// Why there is no answer.
  final GenAiFailure? failure;
}

/// The sentence lab: type a sentence, see what it is made of.
///
/// A full-screen route rather than a sixth tab. The five tabs are the
/// reference the app is built around, and this is something you do *to* a
/// sentence you already have — it is opened from the Learn dashboard, from the
/// vocabulary and grammar pages, and from any example sentence.
class SentenceLabPage extends ConsumerStatefulWidget {
  const SentenceLabPage({super.key, this.initialSentence});

  /// A sentence to analyse on open, when the page was entered from an example.
  final String? initialSentence;

  @override
  ConsumerState<SentenceLabPage> createState() => _SentenceLabPageState();
}

class _SentenceLabPageState extends ConsumerState<SentenceLabPage> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialSentence ?? '',
  );
  SentenceAnalysis? _analysis;

  /// Generated explanations, by issue index.
  final Map<int, _AiResult> _issueResults = {};

  /// The generated explanation of the whole sentence.
  _AiResult? _sentenceResult;

  /// The generated correction suggestion.
  _AiResult? _correctionResult;

  /// The optional on-device model, taken from the analyser that produced
  /// [_analysis]; null in every build where nothing may run.
  SentenceEnhancer? _enhancer;

  /// Purpose: Analyse the sentence the page was opened with, if any.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Schedules an analysis once the analyser is ready.
  /// Notes: The analyser needs the catalog, which is loaded asynchronously, so
  /// the first analysis waits for the provider rather than running here.
  @override
  void initState() {
    super.initState();
    AiAssistService.instance.addListener(_onAiChanged);
    if ((widget.initialSentence ?? '').isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _analyze());
    }
  }

  /// Purpose: Rebuild when the on-device AI's state changes.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Rebuilds.
  /// Notes: Internal helper used within this file only. This is what makes the
  /// AI actions appear and disappear with the switch in Settings while the
  /// page is open.
  void _onAiChanged() {
    if (mounted) setState(() {});
  }

  /// Purpose: Release the controller and stop any generation in flight.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Cancels the on-device model.
  /// Notes: A model left running for an answer nobody will read holds the
  /// device's one AICore inference slot; the next page to ask would be told
  /// the device is busy.
  @override
  void dispose() {
    AiAssistService.instance
      ..removeListener(_onAiChanged)
      ..cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Purpose: Analyse what is in the text field.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Rebuilds with the result, and remembers the sentence.
  /// Notes: Internal helper used within this file only. Analysis is
  /// synchronous once the lexicon exists, so this only awaits the provider.
  /// Blank input clears the result rather than analysing nothing. Every
  /// generated answer is dropped here: they describe the previous sentence,
  /// and leaving one on screen beside a new analysis would attach an
  /// explanation to something it was never about.
  Future<void> _analyze() async {
    final text = _controller.text.trim();
    _clearGenerated();
    if (text.isEmpty) {
      setState(() => _analysis = null);
      return;
    }
    final analyzer = await ref.read(sentenceAnalyzerProvider.future);
    if (!mounted) return;
    final analysis = analyzer.analyze(text);
    setState(() {
      _enhancer = analyzer.enhancer;
      _analysis = analysis;
    });
    await _remember(analysis.normalized);
  }

  /// Purpose: Add the analysed sentence to the history.
  /// Inputs: The `text` as it was analysed.
  /// Returns: None.
  /// Side effects: Writes the progress file; reloads the progress provider.
  /// Notes: Internal helper used within this file only. The **normalized**
  /// sentence is stored, which is what the analysis and every section above
  /// refer to; storing the raw input would replay something the page then
  /// analysed differently. Only the input is kept — never the analysis, which
  /// is recomputed, and never anything a model produced.
  Future<void> _remember(String text) async {
    final entry = HistoryEntry.forInput(HistoryKind.lab, text);
    if (entry == null) return;
    try {
      await NihongoStorage.recordHistory(entry);
      if (mounted) await ref.read(progressDataProvider.notifier).reload();
    } catch (_) {
      // Remembering is a convenience; the analysis on screen is the feature.
      // A storage failure loses one history row, and turning it into an error
      // over a correct analysis would be a worse answer than a shorter list.
    }
  }

  /// Purpose: Put a remembered sentence back in the field and analyse it.
  /// Inputs: The `entry`.
  /// Returns: None.
  /// Side effects: As [_analyze].
  /// Notes: Internal helper used within this file only.
  void _openHistory(HistoryEntry entry) {
    _controller.text = entry.text;
    _analyze();
  }

  /// Purpose: Forget one remembered sentence.
  /// Inputs: The `entry`.
  /// Returns: None.
  /// Side effects: Writes the progress file; reloads the progress provider.
  /// Notes: Internal helper used within this file only. A real deletion, which
  /// the sync merge propagates to the learner's other devices.
  Future<void> _deleteHistory(HistoryEntry entry) async {
    try {
      await NihongoStorage.deleteRecords([entry.id]);
      if (mounted) await ref.read(progressDataProvider.notifier).reload();
    } catch (_) {
      // As in [_remember]: nothing on screen depends on this succeeding.
    }
  }

  /// Purpose: Forget every generated answer.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Clears the three result holders.
  /// Notes: Internal helper used within this file only. Not wrapped in
  /// `setState` because every caller rebuilds straight afterwards.
  void _clearGenerated() {
    _issueResults.clear();
    _sentenceResult = null;
    _correctionResult = null;
  }

  /// Purpose: Run one generation and put its outcome where the UI reads it.
  /// Inputs: `request`, and `store` which files the result.
  /// Returns: None.
  /// Side effects: Runs a model on the device; rebuilds twice.
  /// Notes: Internal helper used within this file only. One place for the
  /// loading-then-outcome dance, so a new action cannot forget to clear its
  /// spinner. A null answer is stored as a `_AiResult` with neither text nor
  /// failure, which the card words as "nothing could be generated" — the
  /// honest description of a model that ran and said nothing useful.
  Future<void> _generate(
    Future<String?> Function() request,
    void Function(_AiResult) store,
  ) async {
    setState(() => store(const _AiResult(loading: true)));
    try {
      final text = await request();
      if (!mounted) return;
      setState(() => store(_AiResult(text: text)));
    } on GenAiException catch (e) {
      if (!mounted) return;
      setState(() => store(_AiResult(failure: e.failure)));
    } catch (_) {
      if (!mounted) return;
      setState(() => store(const _AiResult(failure: GenAiFailure.failed)));
    }
  }

  /// Purpose: Build the page in one or two panes.
  /// Inputs: The build `context`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: The four result sections stay one column at every size — they are a
  /// chain, each referring to the one above it. What the split adds is a second
  /// pane for the *input*: the field, the buttons and the history, which refer
  /// to nothing in the analysis and are what the learner reaches for next. On a
  /// narrow window the history moves behind an app-bar button, because there is
  /// no room for a second pane and a list between the field and the answer
  /// would push the answer off screen. Recorded in `adaptive-layout.md`.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final catalog = ref.watch(contentCatalogProvider);
    final history = ref.watch(labHistoryProvider);
    final analysis = _analysis;

    final screen = MediaQuery.sizeOf(context);
    final split = canSplitLayout(screen.width, screen.height);

    final result = <Widget>[
      if (analysis == null)
        Text(
          l10n.labEmpty,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        )
      else ...[
        AnalysisResultView(
          analysis: analysis,
          catalog: catalog.value,
          onExplain: _canExplain
              ? (index, message) => _explainIssue(analysis, index, message)
              : null,
          issueCardBuilder: (index) => _cardFor(
            l10n.aiExplain,
            _issueResults[index],
            () => setState(() => _issueResults.remove(index)),
          ),
        ),
        ..._buildAiActions(context, l10n, theme, analysis),
      ],
      const SizedBox(height: 24),
      Text(
        l10n.labLimitsNote,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ];

    final appBar = AppBar(
      title: Text(l10n.labTitle),
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
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: pageMaxContentWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                ..._buildInput(l10n, theme, analysis),
                const SizedBox(height: 20),
                ...result,
              ],
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
                ..._buildInput(l10n, theme, analysis),
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

  /// Purpose: Build the subtitle, the field and the analyse row.
  /// Inputs: `l10n`, `theme` and the current `analysis`.
  /// Returns: `List<Widget>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Shared by both layouts
  /// so the two cannot drift apart, which is the same rule the settings page
  /// follows for its detail pages.
  List<Widget> _buildInput(
    AppLocalizations l10n,
    ThemeData theme,
    SentenceAnalysis? analysis,
  ) {
    return [
      Text(
        l10n.labSubtitle,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _controller,
        maxLines: 3,
        minLines: 1,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          hintText: l10n.labInputHint,
          border: const OutlineInputBorder(),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n.labClear,
                  onPressed: () {
                    _controller.clear();
                    setState(() {
                      _clearGenerated();
                      _analysis = null;
                    });
                  },
                ),
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _analyze(),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          FilledButton.icon(
            onPressed: _analyze,
            icon: const Icon(Icons.account_tree_outlined),
            label: Text(l10n.labAnalyze),
          ),
          if (analysis != null) ...[
            const SizedBox(width: 8),
            SpeakButton(text: analysis.normalized),
          ],
        ],
      ),
    ];
  }

  /// Whether an explanation can be offered right now.
  ///
  /// Both halves have to hold: an enhancer was attached to the analyser, and
  /// the service still says the Prompt model is ready. The second is watched in
  /// `build`, so the buttons disappear the moment the switch goes off.
  bool get _canExplain =>
      _enhancer != null && ref.watch(aiAssistServiceProvider).canExplain;

  /// Whether a rewrite can be offered right now.
  ///
  /// Separate from [_canExplain] because the two features have separate device
  /// lists, and the Prompt API's is the narrower one. On most non-Pixel
  /// hardware this is true while [_canExplain] is false.
  bool get _canProofread =>
      _enhancer != null && ref.watch(aiAssistServiceProvider).canProofread;

  /// Purpose: Build the whole-sentence AI actions and their cards.
  /// Inputs: `context`, `l10n`, `theme` and the `analysis`.
  /// Returns: `List<Widget>` — empty when the feature is off.
  /// Side effects: None until a button is used.
  /// Notes: Internal helper used within this file only. These sit **below**
  /// every deterministic section on purpose: the analysis is the page, and the
  /// model comments on it.
  ///
  /// **Each button is gated on its own feature.** Explanations use the Prompt
  /// API and rewrites use Proofreading, which have separate device lists, so a
  /// Galaxy Z Fold 8 has the second and not the first. Gating both on
  /// explanations — which is what this did until v0.3.2 — hid a working feature
  /// on exactly the hardware Settings was correctly reporting as ready. The
  /// download hint appears only when neither button does, since a hint under a
  /// usable button reads as if the button will fail.
  List<Widget> _buildAiActions(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    SentenceAnalysis analysis,
  ) {
    final service = ref.watch(aiAssistServiceProvider);
    if (!service.enabled) return const [];

    final buttons = <Widget>[
      if (_canExplain)
        OutlinedButton.icon(
          icon: const Icon(Icons.auto_awesome_outlined, size: 16),
          label: Text(l10n.aiExplainSentence),
          onPressed: service.busy
              ? null
              : () => _generate(
                  () => _enhancer!.explain(
                    analysis,
                    null,
                    null,
                    Localizations.localeOf(context),
                  ),
                  (result) => _sentenceResult = result,
                ),
        ),
      if (_canProofread)
        OutlinedButton.icon(
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: Text(l10n.aiSuggestCorrection),
          onPressed: service.busy
              ? null
              : () => _generate(
                  () async =>
                      await _enhancer!.suggestCorrection(analysis) ??
                      l10n.aiCorrectionNone,
                  (result) => _correctionResult = result,
                ),
        ),
    ];

    if (buttons.isEmpty) {
      if (!service.needsDownload) return const [];
      return [
        const SizedBox(height: 16),
        Text(
          l10n.aiHintDownload,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ];
    }

    return [
      const SizedBox(height: 16),
      Wrap(spacing: 8, runSpacing: 4, children: buttons),
      ?_cardFor(
        l10n.aiExplainSentence,
        _sentenceResult,
        () => setState(() => _sentenceResult = null),
      ),
      ?_cardFor(
        l10n.aiCorrectionHeading,
        _correctionResult,
        () => setState(() => _correctionResult = null),
      ),
    ];
  }

  /// Purpose: Explain one flagged issue.
  /// Inputs: The `analysis`, the issue `index` and the `message` shown for it.
  /// Returns: None.
  /// Side effects: Runs a model on the device.
  /// Notes: Internal helper used within this file only.
  void _explainIssue(SentenceAnalysis analysis, int index, String message) {
    final issue = analysis.issues[index];
    _generate(
      () => _enhancer!.explain(
        analysis,
        issue,
        message,
        Localizations.localeOf(context),
      ),
      (result) => _issueResults[index] = result,
    );
  }

  /// Purpose: Build the card for one result, when there is one.
  /// Inputs: The card's `title`, the `result` and its `onDismiss`.
  /// Returns: `Widget?` — null when nothing has been asked for yet.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. A card that is still
  /// loading cannot be dismissed: the request is already running on the
  /// device, and hiding it would leave a spinner nobody can see.
  Widget? _cardFor(String title, _AiResult? result, VoidCallback onDismiss) {
    if (result == null) return null;
    return AiExplanationCard(
      title: title,
      text: result.text,
      failure: result.failure,
      loading: result.loading,
      onDismiss: result.loading ? null : onDismiss,
    );
  }
}
