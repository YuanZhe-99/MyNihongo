import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/content/models/jlpt_level.dart';
import '../../features/content/models/localized_strings.dart';
import '../../l10n/app_localizations.dart';
import '../../features/content/services/furigana_aligner.dart';
import '../providers/app_settings.dart';
import 'example_actions.dart';
import 'furigana_text.dart';

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
/// Notes: Shared by the vocabulary and grammar detail sheets. The reading
/// appears once: over the kanji when it aligns and the preference is on, on
/// its own line otherwise.
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
        _ExampleTile(example: example, locale: locale),
    ],
  );
}

/// One example sentence with its reading and translation.
class _ExampleTile extends ConsumerWidget {
  /// Purpose: Show one example sentence.
  /// Inputs: `example`, `locale`.
  /// Returns: A new `_ExampleTile` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. A widget rather than a
  /// piece of [exampleList] because whether the reading gets its own line
  /// depends on a preference, and reading a provider needs a build context of
  /// its own.
  const _ExampleTile({required this.example, required this.locale});

  final ContentExample example;
  final Locale locale;

  @override
  /// Purpose: Build the sentence, its reading and its translation.
  /// Inputs: `context`, `ref`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. **The reading appears
  /// once or not at all.** With the kana printed over the kanji, a second copy
  /// of the same kana underneath is noise; when the sentence cannot be aligned
  /// the separate line is the only place the reading appears, so it stays.
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ruby =
        ref.watch(appSettingsProvider).showFurigana &&
        (alignFurigana(example.ja, example.reading)?.any((s) => s.isRuby) ??
            false);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FuriganaText(
                  example.ja,
                  reading: example.reading,
                  style: theme.textTheme.bodyLarge,
                ),
                if (example.reading != null && !ruby)
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
          ExampleActions(example: example),
        ],
      ),
    );
  }
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
