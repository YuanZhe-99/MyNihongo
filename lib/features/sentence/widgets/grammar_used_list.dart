import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/content_sheets.dart';
import '../../content/models/content_catalog.dart';
import '../models/sentence_analysis.dart';

/// The taught grammar points the sentence uses.
///
/// Each one opens the same detail sheet the grammar page uses, so a pattern
/// noticed here is explained in the same words as everywhere else in the app.
class GrammarUsedList extends StatelessWidget {
  const GrammarUsedList({super.key, required this.analysis, this.catalog});

  /// The analysed sentence.
  final SentenceAnalysis analysis;

  /// The catalog, for opening a point; null before it has loaded.
  final ContentCatalog? catalog;

  /// Purpose: Build the list of matched grammar points.
  /// Inputs: The build `context`.
  /// Returns: `Widget`.
  /// Side effects: None until a row is tapped.
  /// Notes: An empty match list says so rather than rendering nothing: a
  /// learner who used no taught pattern should see that answer, not an absence
  /// they have to interpret.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final points = [
      for (final match in analysis.grammar)
        if (catalog?.grammarById(match.pointId) case final point?)
          (match, point),
    ];
    if (points.isEmpty) {
      return Text(
        l10n.labGrammarNone,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (match, point) in points)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(point.pattern),
            subtitle: Text(
              point.meaning.resolveJoined(locale),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Text(
              analysis.tokens
                  .sublist(match.first, match.last + 1)
                  .map((t) => t.surface)
                  .join(),
              style: theme.textTheme.bodyMedium,
            ),
            onTap: () =>
                showGrammarDetailSheet(context, catalog!, point, locale),
          ),
      ],
    );
  }
}
