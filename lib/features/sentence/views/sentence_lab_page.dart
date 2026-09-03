import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/utils/adaptive_layout.dart';
import '../../content/models/content_catalog.dart';
import '../../content/services/content_repository.dart';
import '../../speech/widgets/speak_button.dart';
import '../models/sentence_analysis.dart';
import '../services/sentence_analyzer.dart';
import '../widgets/bunsetsu_tree.dart';
import '../widgets/grammar_used_list.dart';
import '../widgets/issue_list.dart';
import '../widgets/token_chips.dart';

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

  /// Purpose: Analyse the sentence the page was opened with, if any.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Schedules an analysis once the analyser is ready.
  /// Notes: The analyser needs the catalog, which is loaded asynchronously, so
  /// the first analysis waits for the provider rather than running here.
  @override
  void initState() {
    super.initState();
    if ((widget.initialSentence ?? '').isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _analyze());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Purpose: Analyse what is in the text field.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Rebuilds with the result.
  /// Notes: Internal helper used within this file only. Analysis is
  /// synchronous once the lexicon exists, so this only awaits the provider.
  /// Blank input clears the result rather than analysing nothing.
  Future<void> _analyze() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _analysis = null);
      return;
    }
    final analyzer = await ref.read(sentenceAnalyzerProvider.future);
    if (!mounted) return;
    setState(() => _analysis = analyzer.analyze(text));
  }

  /// Purpose: Build the page.
  /// Inputs: The build `context`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: One column at every size, capped at `pageMaxContentWidth`. The
  /// content is a chain — input, then words, then structure, then grammar,
  /// then issues — and each section refers to the one before it, so splitting
  /// them into panes would put the reference and the referent side by side and
  /// make the reading order ambiguous. Recorded in `adaptive-layout.md`.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final catalog = ref.watch(contentCatalogProvider);
    final analysis = _analysis;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.labTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: pageMaxContentWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
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
                            setState(() => _analysis = null);
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
              const SizedBox(height: 20),
              if (analysis == null)
                Text(
                  l10n.labEmpty,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                ..._buildResult(context, l10n, theme, analysis, catalog.value),
              const SizedBox(height: 24),
              Text(
                l10n.labLimitsNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Purpose: Build the four result sections.
  /// Inputs: `context`, `l10n`, `theme`, the `analysis` and the `catalog`.
  /// Returns: `List<Widget>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The unknown-token
  /// warning comes first when it applies: everything below it is derived from
  /// the tokens, so a reader who knows the split is partly wrong reads the
  /// rest with the right amount of trust.
  List<Widget> _buildResult(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    SentenceAnalysis analysis,
    ContentCatalog? catalog,
  ) {
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    return [
      if (analysis.hasUnknown)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.labUnknownWarning,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      heading(l10n.labWords),
      TokenChips(analysis: analysis, catalog: catalog),
      heading(l10n.labStructure),
      BunsetsuTree(analysis: analysis),
      heading(l10n.labGrammarUsed),
      GrammarUsedList(analysis: analysis, catalog: catalog),
      heading(l10n.labIssues),
      IssueList(analysis: analysis),
    ];
  }
}
