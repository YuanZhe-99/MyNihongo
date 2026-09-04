import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../content/models/content_catalog.dart';
import '../models/sentence_analysis.dart';
import 'bunsetsu_tree.dart';
import 'grammar_used_list.dart';
import 'issue_list.dart';
import 'token_chips.dart';

/// One analysed sentence, drawn as the four sections the sentence lab defines.
///
/// The sections are a chain — the structure refers to the words, the grammar to
/// the structure, the issues to both — so they are always one column, whatever
/// the page around them does with its own width.
///
/// This exists because the sentence lab and writing practice were rendering the
/// same analysis two different ways: the lab with headings and all four
/// sections, writing practice with unlabelled chips and a bare issue list. A
/// learner who has met one should be reading the same answer in the other, so
/// there is one widget rather than two layouts of one pipeline's output.
class AnalysisResultView extends StatelessWidget {
  const AnalysisResultView({
    super.key,
    required this.analysis,
    required this.catalog,
    this.onExplain,
    this.issueCardBuilder,
  });

  /// The analysed sentence.
  final SentenceAnalysis analysis;

  /// The content catalog, or null while it is still loading.
  final ContentCatalog? catalog;

  /// Called when the learner asks for one issue to be explained, with the
  /// issue's index and the message the row showed for it.
  ///
  /// Null hides the button, which is what a device with no model does.
  final void Function(int index, String message)? onExplain;

  /// Builds the generated card under one issue, when there is one.
  final Widget? Function(int index)? issueCardBuilder;

  /// Purpose: Build the unknown-token banner and the four sections.
  /// Inputs: The build `context`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: The unknown-token warning comes first when it applies: everything
  /// below it is derived from the tokens, so a reader who knows the split is
  /// partly wrong reads the rest with the right amount of trust.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (analysis.hasUnknown) _unknownBanner(l10n, theme),
        _heading(theme, l10n.labWords),
        TokenChips(analysis: analysis, catalog: catalog),
        _heading(theme, l10n.labStructure),
        BunsetsuTree(analysis: analysis),
        _heading(theme, l10n.labGrammarUsed),
        GrammarUsedList(analysis: analysis, catalog: catalog),
        _heading(theme, l10n.labIssues),
        IssueList(
          analysis: analysis,
          onExplain: onExplain,
          cardBuilder: issueCardBuilder,
        ),
      ],
    );
  }

  /// Purpose: Render one section heading.
  /// Inputs: `theme`, the heading `text`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  Widget _heading(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  /// Purpose: Warn that some words are not in the bundled dictionary.
  /// Inputs: `l10n`, `theme`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Being told which part
  /// of an answer is unreliable is worth more than a clean-looking answer.
  Widget _unknownBanner(AppLocalizations l10n, ThemeData theme) => Container(
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
  );
}
