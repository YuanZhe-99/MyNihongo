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
import '../../ai/services/ai_assist_service.dart';
import '../../ai/services/ai_practice_service.dart';
import '../../ai/services/genai_backend.dart';
import '../../ai/services/practice_response_parser.dart';
import '../../ai/widgets/ai_explanation_card.dart';
import '../../learn/widgets/jlpt_practice_card.dart';
import '../../sentence/services/sentence_analyzer.dart';
import '../../../shared/providers/learner_profile_provider.dart';
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
                    const SizedBox(height: 8),
                    _WeaknessNote(report: report, catalog: catalog),
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

/// The model's note on what to do about the weaknesses above.
///
/// A widget of its own so the page itself stays stateless: the tables are a
/// function of the report and nothing else, and only this one card has a
/// request in flight to remember.
class _WeaknessNote extends ConsumerStatefulWidget {
  /// Purpose: Offer a note on the report.
  /// Inputs: The `report` and the `catalog` for naming items.
  /// Returns: A new `_WeaknessNote` instance.
  /// Side effects: None until the button is tapped.
  /// Notes: Internal helper used within this file only.
  const _WeaknessNote({required this.report, required this.catalog});

  final WeaknessReport report;
  final ContentCatalog? catalog;

  @override
  ConsumerState<_WeaknessNote> createState() => _WeaknessNoteState();
}

class _WeaknessNoteState extends ConsumerState<_WeaknessNote> {
  String? _note;
  GenAiFailure? _failure;
  bool _loading = false;

  /// Purpose: Show the button, or whatever came back.
  /// Inputs: `context`.
  /// Returns: `Widget`.
  /// Side effects: None until tapped.
  /// Notes: With the switch off there is nothing here at all — not a disabled
  /// button and not an invitation to turn something on. The report is complete
  /// without it.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!ref.watch(aiAssistServiceProvider).canExplain) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_note == null && _failure == null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _loading ? null : _ask,
              icon: const Icon(Icons.auto_awesome_outlined, size: 18),
              label: Text(l10n.aiWeaknessNote),
            ),
          ),
        if (_loading || _note != null || _failure != null)
          AiExplanationCard(
            title: l10n.aiWeaknessNote,
            text: _note,
            failure: _failure,
            loading: _loading,
            onDismiss: () => setState(() {
              _note = null;
              _failure = null;
            }),
          ),
      ],
    );
  }

  /// Purpose: Ask what to do about what the report found.
  /// Inputs: None; reads the report and the catalog.
  /// Returns: None.
  /// Side effects: Runs a model on the device; rebuilds.
  /// Notes: Internal helper used within this file only. **Only what the app
  /// already computed goes into the prompt** — the same counts the tables
  /// show — and the task's rules forbid estimating whether the learner would
  /// pass. The readiness band is a thing the app derives under stated rules,
  /// and a model guessing at one beside it would be a second, unexplainable
  /// answer to the same question.
  Future<void> _ask() async {
    final builder = await practicePromptBuilder(ref);
    if (builder == null || !mounted) return;
    final level = ref.read(learnerProfileProvider).targetLevel;
    final prompt = builder.forWeakness(
      weakest: _lines(),
      level: level.label,
      locale: Localizations.localeOf(context),
    );
    if (prompt == null) return;

    setState(() {
      _loading = true;
      _failure = null;
    });
    try {
      final raw = await AiPracticeService.instance.run(
        prompt,
        maxOutputTokens: builder.maxOutputTokens,
      );
      if (!mounted) return;
      setState(() {
        _note = PracticeResponseParser.explanation(raw, prompt: prompt);
        _failure = _note == null ? GenAiFailure.failed : null;
        _loading = false;
      });
    } on GenAiException catch (error) {
      if (!mounted) return;
      setState(() {
        _failure = error.failure;
        _loading = false;
      });
    }
  }

  /// Purpose: Say what the report found, in lines a prompt can carry.
  /// Inputs: None; reads the report and the catalog.
  /// Returns: `List<String>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The 大問 go in under
  /// their Japanese names, which is what they are called on the paper and what
  /// a learner would search for. A word goes in under its headword rather than
  /// its catalog id: `vocab:jm1578850` means nothing to a model, and the point
  /// of the note is that it says something about the Japanese.
  List<String> _lines() {
    final report = widget.report;
    return [
      for (final entry in report.bySection.entries)
        '${entry.key.name}: ${entry.value.right} of ${entry.value.asked} '
            'right.',
      for (final entry in report.weakestTypes)
        '${entry.key.jaName}: ${entry.value.right} of ${entry.value.asked} '
            'right.',
      for (final entry in report.weakestItems)
        '${widget.catalog?.vocabById(entry.key)?.headword ?? widget.catalog?.grammarById(entry.key)?.pattern ?? entry.key}: '
            '${entry.value.right} of ${entry.value.asked} right.',
    ];
  }
}
