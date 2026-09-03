import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/utils/adaptive_layout.dart';
import '../../../shared/widgets/adaptive_tile_grid.dart';
import '../../../shared/widgets/reference_widgets.dart';
import '../../content/models/content_catalog.dart';
import '../../content/models/grammar_point.dart';
import '../../content/models/jlpt_level.dart';
import '../../../shared/providers/app_settings.dart';
import '../../../shared/widgets/content_sheets.dart';
import '../../content/services/content_repository.dart';

class GrammarPage extends ConsumerStatefulWidget {
  /// Purpose: Create a grammar page instance.
  /// Inputs: None.
  /// Returns: A new `GrammarPage` instance.
  /// Side effects: None.
  /// Notes: None.
  const GrammarPage({super.key});

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new state object.
  /// Side effects: None.
  /// Notes: Flutter lifecycle override.
  @override
  ConsumerState<GrammarPage> createState() => _GrammarPageState();
}

class _GrammarPageState extends ConsumerState<GrammarPage> {
  final _searchController = TextEditingController();
  String _query = '';

  /// Purpose: Release the search controller.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Disposes the controller.
  /// Notes: Flutter lifecycle override.
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Purpose: Build the grammar browser.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often. Same
  /// shape as the vocabulary page; the two share their chips, badges, and
  /// example rendering through `reference_widgets.dart`.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final catalog = ref.watch(contentCatalogProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.grammarTitle)),
      body: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => emptyResults(context, l10n.contentLoadFailed),
        data: (catalog) => _buildList(context, l10n, catalog),
      ),
    );
  }

  /// Purpose: Build the filtered, adaptive-column list with its header.
  /// Inputs: `context`, `l10n`, `catalog`.
  /// Returns: `Widget` — a `ListView.builder` whose first item is the header.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. See the vocabulary
  /// page for why rows, not tiles, are the list items.
  Widget _buildList(
    BuildContext context,
    AppLocalizations l10n,
    ContentCatalog catalog,
  ) {
    final locale = Localizations.localeOf(context);
    final settings = ref.watch(appSettingsProvider);
    final level = settings.grammarLevel;
    final query = _query.trim().toLowerCase();
    final filtered = [
      for (final point in catalog.grammar)
        if ((level == null || point.level == level) &&
            (query.isEmpty || point.matches(query)))
          point,
    ];

    final screen = MediaQuery.sizeOf(context);
    final contentWidth = referenceContentWidth(screen.width);
    final columns = referenceColumnCount(
      screenWidth: screen.width,
      screenHeight: screen.height,
      contentWidth: contentWidth,
      preference: settings.referenceListColumns,
    );
    final rowCount = listRowCount(filtered.length, columns);

    Widget constrain(Widget child) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: pageMaxContentWidth),
        child: child,
      ),
    );

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        shellListBottomInset(screen.width),
      ),
      itemCount: 1 + (filtered.isEmpty ? 1 : rowCount),
      itemBuilder: (context, index) {
        if (index == 0) {
          return constrain(
            _buildHeader(context, l10n, filtered.length, level, contentWidth),
          );
        }
        if (filtered.isEmpty) {
          return constrain(emptyResults(context, l10n.grammarEmpty));
        }
        return constrain(
          Padding(
            padding: const EdgeInsets.only(bottom: listTileGap),
            child: adaptiveTileRow(
              rowIndex: index - 1,
              columns: columns,
              itemCount: filtered.length,
              itemBuilder: (i) =>
                  _buildTile(context, catalog, filtered[i], locale),
            ),
          ),
        );
      },
    );
  }

  /// Purpose: Build the search field, level chips, result count and the
  /// column-count control.
  /// Inputs: `context`, `l10n`, `count`, `level` — the active filter,
  /// `contentWidth` — the width the list gets.
  /// Returns: `Widget`.
  /// Side effects: None beyond building widgets; the controls persist through
  /// the settings notifier.
  /// Notes: Internal helper used within this file only. The grammar level
  /// filter is separate from the vocabulary one: a learner reading N3 grammar
  /// is often still looking up N5 words. The column count is shared, because
  /// both lists use the same tile width and the same rule.
  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l10n,
    int count,
    JlptLevel? level,
    double contentWidth,
  ) {
    final theme = Theme.of(context);
    final screen = MediaQuery.sizeOf(context);
    final notifier = ref.read(appSettingsProvider.notifier);
    final preference = ref.watch(appSettingsProvider).referenceListColumns;
    final capacity = referenceColumnCount(
      screenWidth: screen.width,
      screenHeight: screen.height,
      contentWidth: contentWidth,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: l10n.grammarSearchHint,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 12),
        levelFilterRow(
          context,
          selected: level,
          onChanged: notifier.setGrammarLevel,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.grammarCount(count),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            listColumnsButton(
              context,
              preference: preference,
              capacity: capacity,
              onChanged: notifier.setReferenceListColumns,
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Purpose: Build one grammar tile.
  /// Inputs: `context`, `point`, `locale`.
  /// Returns: `Widget`.
  /// Side effects: Opens the detail sheet on tap.
  /// Notes: Internal helper used within this file only.
  Widget _buildTile(
    BuildContext context,
    ContentCatalog catalog,
    GrammarPoint point,
    Locale locale,
  ) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showGrammarDetailSheet(context, catalog, point, locale),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      point.pattern,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (point.structure != null)
                      Text(
                        point.structure!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      point.meaning.resolveJoined(locale),
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              levelChip(context, point.level),
            ],
          ),
        ),
      ),
    );
  }
}
