import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../services/genai_backend.dart';

/// One answer from the on-device model, or the reason there is not one.
///
/// Everything generated in this app is shown inside one of these, and every
/// one carries the same label. That is the whole point of the widget: a
/// learner reading the page has to be able to tell, without effort, which
/// lines came from the deterministic analysis and which came from a model that
/// can be wrong. Nothing here is ever mixed into a deterministic section.
class AiExplanationCard extends StatelessWidget {
  const AiExplanationCard({
    super.key,
    required this.title,
    this.text,
    this.failure,
    this.loading = false,
    this.onDismiss,
  });

  /// What was asked, so a card can be told from its neighbour.
  final String title;

  /// The generated text, when there is one.
  final String? text;

  /// Why there is no text, when there is not.
  final GenAiFailure? failure;

  /// Whether the model is still running.
  final bool loading;

  /// Called when the learner closes the card; hidden when null.
  final VoidCallback? onDismiss;

  /// Purpose: Build the card.
  /// Inputs: The build `context`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: The label sits **above** the answer rather than below it, because
  /// a reader who has already read the text cannot un-read it: the warning has
  /// to arrive first to do its job. The card is drawn in the tertiary
  /// container rather than the surface so it is visibly a different kind of
  /// thing from the sections around it, and the label repeats in words what
  /// the colour says.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(top: 12),
      color: theme.colorScheme.tertiaryContainer,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  size: 16,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.aiGeneratedLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: l10n.aiDismiss,
                    visualDensity: VisualDensity.compact,
                    onPressed: onDismiss,
                  ),
              ],
            ),
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
            const SizedBox(height: 6),
            if (loading)
              Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n.aiGenerating,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                ],
              )
            else
              Text(
                text ?? messageFor(l10n, failure),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Purpose: Word one failure for the learner.
  /// Inputs: `l10n` and the `failure`, which may be null.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: A null failure with no text means the model answered with nothing
  /// usable, which reads as the generic line — it is not an error, and saying
  /// "something went wrong" would send the learner looking for a fault that is
  /// not there. `cancelled` shares that line because a cancelled request the
  /// learner started by leaving the page needs no explanation.
  static String messageFor(AppLocalizations l10n, GenAiFailure? failure) =>
      switch (failure) {
        GenAiFailure.unavailable => l10n.aiFailedUnavailable,
        GenAiFailure.busy => l10n.aiFailedBusy,
        GenAiFailure.timeout => l10n.aiFailedTimeout,
        GenAiFailure.tooLong => l10n.aiFailedTooLong,
        GenAiFailure.failed => l10n.aiFailedGeneric,
        GenAiFailure.cancelled => l10n.aiFailedGeneric,
        null => l10n.aiFailedGeneric,
      };
}
