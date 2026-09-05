/// Purpose: Show the learner what their recent papers say they are worst at.
/// Inputs: `weaknessReportProvider`, the catalog, the locale.
/// Returns: One route widget.
/// Side effects: None — everything on this page is derived, nothing is written.
/// Notes: Three tables, coarsest first: section, then 大問, then the individual
/// words and grammar points. That order is the order a learner can act on —
/// "listening is the weak one" changes what they practise tonight, and "this
/// word keeps catching me" changes nothing until they know which section to
/// open. The report is recomputed from the last few attempts every time this
/// page is built, so a weakness the learner has fixed disappears by itself.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/exam_provider.dart';
import '../../../shared/utils/adaptive_layout.dart';
import '../../content/models/content_catalog.dart';
import '../../content/services/content_repository.dart';
import '../../content/services/study_item_labels.dart';
import '../../learn/widgets/jlpt_practice_card.dart';
import '../models/drill_section.dart';
import '../services/weakness_report.dart';

/// What to work on next.
///
/// A full-screen route outside the tab shell, like the exam history it sits
/// beside: entered with a purpose and left when it has been read.
class WeaknessReportPage extends ConsumerWidget {
  /// Purpose: Create the page.
  /// Inputs: None.
  /// Returns: A new `WeaknessReportPage` instance.
  /// Side effects: None.
  /// Notes: None.
  const WeaknessReportPage({super.key});

  /// Purpose: Build the three tables, or say there is nothing yet.
  /// Inputs: `context`, `ref`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often. An empty
  /// report says what would fill it rather than only that it is empty: a
  /// screen reached from a button, showing nothing and explaining nothing,
  /// reads as broken.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final report = ref.watch(weaknessReportProvider);
    final catalog = ref.watch(contentCatalogProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.weaknessTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: pageMaxContentWidth),
          child: report.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      l10n.weaknessEmpty,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Text(
                      l10n.weaknessBasis(report.attempts),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _heading(theme, l10n.weaknessBySection),
                    for (final section in DrillSection.values)
                      if (report.bySection[section] case final tally?)
                        _row(
                          context,
                          l10n,
                          theme,
                          title: l10n.drillSectionName(section),
                          tally: tally,
                        ),
                    const SizedBox(height: 16),
                    _heading(theme, l10n.weaknessByType),
                    if (report.weakestTypes.isEmpty)
                      _nothingWeak(theme, l10n)
                    else
                      for (final entry in report.weakestTypes)
                        _row(
                          context,
                          l10n,
                          theme,
                          title: entry.key.jaName,
                          subtitle: l10n.drillSectionName(entry.key.section),
                          tally: entry.value,
                        ),
                    const SizedBox(height: 16),
                    _heading(theme, l10n.weaknessByItem),
                    if (report.weakestItems.isEmpty)
                      _nothingWeak(theme, l10n)
                    else
                      for (final entry in report.weakestItems)
                        _itemRow(context, l10n, theme, catalog, entry),
                  ],
                ),
        ),
      ),
    );
  }

  /// Purpose: Render one table heading.
  /// Inputs: `theme`, the `text`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  Widget _heading(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  /// Purpose: Say that nothing in this table qualifies yet.
  /// Inputs: `theme`, `l10n`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. A table that is empty
  /// because the learner is doing well and a table that is empty because too
  /// little has been asked look the same, and both are honestly described by
  /// "keep going" — the report names something only once it has been asked
  /// `weaknessMinAsked` times and got wrong at least once.
  Widget _nothingWeak(ThemeData theme, AppLocalizations l10n) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      l10n.weaknessNothingWeak,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    ),
  );

  /// Purpose: Render one tallied row with its accuracy bar.
  /// Inputs: `context`, `l10n`, `theme`; the `title`, an optional `subtitle`,
  /// and the `tally`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The bar is a
  /// determinate `LinearProgressIndicator` — it has a known value, so it
  /// settles, which the indeterminate one never does and which cost this
  /// project a hung test once already.
  Widget _row(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme, {
    required String title,
    String? subtitle,
    required WeaknessTally tally,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyMedium),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.weaknessScore(tally.right, tally.asked),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: tally.accuracy,
          minHeight: 4,
        ),
      ],
    ),
  );

  /// Purpose: Render one weak catalog item, named from the catalog.
  /// Inputs: `context`, `l10n`, `theme`, the `catalog`, and the `entry`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The id is resolved
  /// through the same function the sync conflict dialog and the study calendar
  /// use, so a word retired in favour of a JMdict-keyed id still names its
  /// entry here. An id the catalog no longer has falls back to itself rather
  /// than vanishing — the learner did get it wrong, and a row that disappears
  /// because of a content edit is a worse answer than an ugly one.
  Widget _itemRow(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    ContentCatalog? catalog,
    MapEntry<String, WeaknessTally> entry,
  ) {
    final label = resolveStudyItemLabel(
      entry.key,
      catalog: catalog,
      locale: Localizations.localeOf(context),
    );
    return _row(
      context,
      l10n,
      theme,
      title: label.title,
      subtitle: label.subtitle,
      tally: entry.value,
    );
  }
}
