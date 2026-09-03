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
  const IssueList({
    super.key,
    required this.analysis,
    this.onExplain,
    this.cardBuilder,
  });

  /// The analysed sentence.
  final SentenceAnalysis analysis;

  /// Called when the learner asks for an issue to be explained, with the
  /// issue's index and **the message this widget showed for it**.
  ///
  /// The message is handed up rather than re-derived by the caller so the
  /// model is asked about the sentence the learner is actually reading. Null
  /// when on-device AI is off or unavailable, which is what hides the button.
  final void Function(int index, String message)? onExplain;

  /// Builds the generated card under one issue, when there is one.
  final Widget? Function(int index)? cardBuilder;

  /// Purpose: Build the issue list.
  /// Inputs: The build `context`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: An empty list says "nothing looked unusual" rather than rendering
  /// nothing, so a clean sentence gets an answer instead of an absence. Any
  /// generated card is rendered **under** the deterministic row it belongs to,
  /// never in place of it.
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
        for (var index = 0; index < analysis.issues.length; index++)
          Builder(
            builder: (context) {
              final issue = analysis.issues[index];
              final message = _message(l10n, issue);
              final card = cardBuilder?.call(index);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                                message,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (onExplain != null)
                          TextButton.icon(
                            icon: const Icon(
                              Icons.auto_awesome_outlined,
                              size: 16,
                            ),
                            label: Text(l10n.aiExplain),
                            onPressed: () => onExplain!(index, message),
                          ),
                      ],
                    ),
                    ?card,
                  ],
                ),
              );
            },
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
