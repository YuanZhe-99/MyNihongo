import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../models/sentence_analysis.dart';

/// The possible issues the checks raised.
///
/// Every row is worded as a possibility, and the section is titled that way
/// too. The analyser has no model of what the writer meant: it can see that a
/// pattern is unusual, not that it is wrong. Saying so plainly is what makes
/// the findings usable — a learner told they are wrong when they are not stops
/// reading the section at all.
class IssueList extends StatelessWidget {
  const IssueList({super.key, required this.analysis});

  /// The analysed sentence.
  final SentenceAnalysis analysis;

  /// Purpose: Build the issue list.
  /// Inputs: The build `context`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: An empty list says "nothing looked unusual" rather than rendering
  /// nothing, so a clean sentence gets an answer instead of an absence.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    if (analysis.issues.isEmpty) {
      return Text(
        l10n.labIssuesNone,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final issue in analysis.issues)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.help_outline,
                  size: 18,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _span(issue),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _message(l10n, issue),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Purpose: Quote the part of the sentence an issue is about.
  /// Inputs: `issue`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Quoting the span
  /// rather than naming token indices is what makes a finding findable in a
  /// sentence the learner just typed.
  String _span(Issue issue) => analysis.tokens
      .sublist(issue.first, issue.last + 1)
      .map((t) => t.surface)
      .join();

  /// Purpose: Word one issue.
  /// Inputs: `l10n`, `issue`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The particle-frame
  /// message has two forms: one that can name the verb to use instead, when
  /// the word is half of a transitivity pair, and one that only reports the
  /// mismatch. Suggesting a word the analyser is not sure of would be worse
  /// than suggesting none.
  String _message(AppLocalizations l10n, Issue issue) {
    final word = issue.detail ?? _span(issue);
    return switch (issue.kind) {
      IssueKind.particleFrame =>
        issue.suggestion == null
            ? l10n.labIssueParticleFrame(word)
            : l10n.labIssueParticleFrameSuggest(word, issue.suggestion!),
      IssueKind.naNoConfusion => l10n.labIssueNaNo(
        word,
        issue.suggestion ?? '',
      ),
      IssueKind.tenseTimeWord => l10n.labIssueTense(word),
      IssueKind.missingCopula => l10n.labIssueCopula(word),
      IssueKind.adjectiveAsVerb => l10n.labIssueAdjectiveAsVerb(word),
    };
  }
}
