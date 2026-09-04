import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/learner_profile_provider.dart';
import '../../../shared/providers/progress_provider.dart';
import '../../../shared/utils/adaptive_layout.dart';
import '../../content/services/content_repository.dart';
import '../../kana/models/kana.dart';
import '../../progress/models/study_record.dart';
import '../widgets/today_card.dart';

class LearnPage extends ConsumerWidget {
  /// Purpose: Create a learn page instance.
  /// Inputs: None.
  /// Returns: A new `LearnPage` instance.
  /// Side effects: None.
  /// Notes: None.
  const LearnPage({super.key});

  /// Purpose: Build the home tab: what the app holds, what the user has done,
  /// where to start.
  /// Inputs: `context`, `ref`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often. The
  /// today card spans the full width above the dashboard, because what to do
  /// now is the one thing a returning learner should read without scrolling or
  /// scanning; the cards below it flow one or two across by [ruleCardMinWidth],
  /// gated on [canSplitLayout] like every other split in the app.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final catalog = ref.watch(contentCatalogProvider);
    final progress = ref.watch(progressDataProvider);
    final profile = ref.watch(learnerProfileProvider);

    final screen = MediaQuery.sizeOf(context);
    final contentWidth = referenceContentWidth(screen.width);
    final cardColumns = canSplitLayout(screen.width, screen.height)
        ? columnCapacity(
            contentWidth,
            minItemWidth: ruleCardMinWidth,
            maxColumns: 2,
          )
        : 1;
    final cardWidth = cardColumns > 1
        ? (contentWidth - listTileGap * (cardColumns - 1)) / cardColumns
        : double.infinity;

    final cards = <Widget>[
      _card(
        theme,
        Icons.library_books_outlined,
        l10n.learnContentSummary,
        catalog.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => Text(l10n.contentLoadFailed),
          data: (catalog) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _line(theme, l10n.learnKanaCount(allKanaEntries().length)),
              _line(theme, l10n.learnVocabCount(catalog.vocab.length)),
              _line(theme, l10n.learnGrammarCount(catalog.grammar.length)),
            ],
          ),
        ),
      ),
      _card(
        theme,
        Icons.trending_up_outlined,
        l10n.learnLevelProgress(profile.targetLevel.label),
        catalog.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => Text(l10n.contentLoadFailed),
          data: (catalog) {
            final ids = {
              for (final entry in catalog.vocab)
                if (entry.level == profile.targetLevel) entry.id,
              for (final point in catalog.grammar)
                if (point.level == profile.targetLevel) point.id,
            };
            final started = progress.value?.studyRecords
                    .where((r) => ids.contains(r.id))
                    .length ??
                0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _line(theme, l10n.learnLevelStarted(started, ids.length)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ids.isEmpty ? 0 : started / ids.length,
                    minHeight: 6,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      _card(
        theme,
        Icons.insights_outlined,
        l10n.learnProgressSummary,
        progress.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => Text(l10n.learnNoProgress),
          data: (data) => data.studyRecords.isEmpty
              ? Text(
                  l10n.learnNoProgress,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _line(
                      theme,
                      l10n.learnTrackedItems(data.studyRecords.length),
                    ),
                    _line(
                      theme,
                      l10n.learnMasteredItems(
                        data.studyRecords
                            .where((r) => r.stage == StudyStage.mastered)
                            .length,
                      ),
                    ),
                  ],
                ),
        ),
      ),
      _card(
        theme,
        Icons.rocket_launch_outlined,
        l10n.learnQuickStart,
        Column(
          children: [
            _link(
              context,
              Icons.translate_outlined,
              l10n.learnOpenKana,
              '/kana',
            ),
            _link(
              context,
              Icons.menu_book_outlined,
              l10n.learnOpenVocab,
              '/vocab',
            ),
            _link(
              context,
              Icons.account_tree_outlined,
              l10n.learnOpenGrammar,
              '/grammar',
            ),
            _link(
              context,
              Icons.biotech_outlined,
              l10n.labTitle,
              '/lab',
              push: true,
            ),
          ],
        ),
      ),
      _card(
        theme,
        Icons.upcoming_outlined,
        l10n.learnRoadmap,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _line(theme, l10n.learnRoadmapSrs),
            _line(theme, l10n.learnRoadmapJlpt),
          ],
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.learnTitle)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          shellListBottomInset(screen.width),
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: pageMaxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.learnWelcome,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.learnWelcomeBody,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const TodayCard(),
                  const SizedBox(height: listTileGap),
                  Wrap(
                    spacing: listTileGap,
                    runSpacing: listTileGap,
                    children: [
                      for (final card in cards)
                        SizedBox(width: cardWidth, child: card),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Purpose: Render one dashboard card.
  /// Inputs: `theme`, `icon`, `title`, `body`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  Widget _card(ThemeData theme, IconData icon, String title, Widget body) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            body,
          ],
        ),
      ),
    );
  }

  /// Purpose: Render one line of body text inside a card.
  /// Inputs: `theme`, `text`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  Widget _line(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: theme.textTheme.bodyMedium),
    );
  }

  /// Purpose: Render one quick-start row that navigates to a tab.
  /// Inputs: `context`, `icon`, `label`, `route`.
  /// Returns: `Widget`.
  /// Side effects: Navigates on tap.
  /// Notes: Internal helper used within this file only.
  Widget _link(
    BuildContext context,
    IconData icon,
    String label,
    String route, {
    bool push = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      // A tab is switched to; a page outside the shell is pushed, so the back
      // button returns here rather than leaving the app.
      onTap: () => push ? context.push(route) : context.go(route),
    );
  }
}
