import 'package:flutter/material.dart';

import '../../features/content/models/jlpt_level.dart';
import '../../features/content/models/localized_strings.dart';
import '../../l10n/app_localizations.dart';

/// Purpose: Render a small JLPT level badge.
/// Inputs: `level`.
/// Returns: `Widget`.
/// Side effects: None.
/// Notes: Shared by the vocabulary and grammar tiles and their detail sheets
/// so the level always looks the same.
Widget levelChip(BuildContext context, JlptLevel level) {
  final theme = Theme.of(context);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: theme.colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      level.label,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSecondaryContainer,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

/// Purpose: Render the row of level filter chips: all levels, then N5 to N1.
/// Inputs: `selected` — the active level, null for all; `onChanged`.
/// Returns: `Widget` — a `Wrap` of `ChoiceChip`s.
/// Side effects: Invokes `onChanged` when a chip is chosen.
/// Notes: A `Wrap`, so on a phone the six chips flow onto a second line rather
/// than overflowing. Selecting the active level again is a no-op rather than a
/// toggle, so the row always has exactly one selection.
Widget levelFilterRow(
  BuildContext context, {
  required JlptLevel? selected,
  required ValueChanged<JlptLevel?> onChanged,
}) {
  final l10n = AppLocalizations.of(context)!;
  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      ChoiceChip(
        label: Text(l10n.referenceLevelAll),
        selected: selected == null,
        onSelected: (_) => onChanged(null),
      ),
      for (final level in JlptLevel.values)
        ChoiceChip(
          label: Text(level.label),
          selected: selected == level,
          onSelected: (_) => onChanged(level),
        ),
    ],
  );
}

/// Purpose: Render a titled block of example sentences with translations.
/// Inputs: `examples`, `locale`.
/// Returns: `Widget`; an empty box when there are no examples.
/// Side effects: None.
/// Notes: Shared by the vocabulary and grammar detail sheets. The reading line
/// appears only when the content supplies one.
Widget exampleList(
  BuildContext context,
  List<ContentExample> examples,
  Locale locale,
) {
  if (examples.isEmpty) return const SizedBox.shrink();
  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        l10n.referenceExamples,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      for (final example in examples)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(example.ja, style: theme.textTheme.bodyLarge),
              if (example.reading != null)
                Text(
                  example.reading!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              Text(
                example.translations.resolveJoined(locale),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

/// Purpose: Render the empty-state line shown when a filter matches nothing.
/// Inputs: `message`.
/// Returns: `Widget`.
/// Side effects: None.
/// Notes: None.
Widget emptyResults(BuildContext context, String message) {
  final theme = Theme.of(context);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Center(
      child: Text(
        message,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  );
}
