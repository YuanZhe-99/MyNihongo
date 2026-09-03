import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../models/sentence_analysis.dart';

/// The sentence's structure, as an indented list.
///
/// Japanese dependency is right-headed: every chunk attaches to something
/// later, and the last one is the main predicate. Drawing that as an indented
/// list rather than as lines and boxes keeps it readable at any width and in
/// either language, and it degrades to a flat list when the guess is poor
/// rather than to a tangle.
class BunsetsuTree extends StatelessWidget {
  const BunsetsuTree({super.key, required this.analysis});

  /// The analysed sentence.
  final SentenceAnalysis analysis;

  /// Purpose: Build the structure list.
  /// Inputs: The build `context`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: One row per chunk, in sentence order, each naming what it attaches
  /// to. Sentence order rather than tree order on purpose: the learner is
  /// reading a sentence they wrote, and reordering it would make the rows
  /// harder to find than the relationship is worth.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    if (analysis.chunks.isEmpty) return const SizedBox.shrink();

    String surfaceOf(Bunsetsu chunk) => analysis.tokens
        .sublist(chunk.first, chunk.last + 1)
        .map((t) => t.surface)
        .join();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final chunk in analysis.chunks)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  chunk.dependsOn == null
                      ? Icons.flag_outlined
                      : Icons.subdirectory_arrow_right,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text: surfaceOf(chunk),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: chunk.dependsOn == null
                              ? '  ${l10n.labRoot}'
                              : '  ${l10n.labDependsOn} '
                                    '${surfaceOf(analysis.chunks[chunk.dependsOn!])}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
