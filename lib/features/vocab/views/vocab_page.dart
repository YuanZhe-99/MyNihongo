import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/utils/adaptive_layout.dart';
import '../../../shared/widgets/adaptive_tile_grid.dart';
import '../../../shared/widgets/reference_widgets.dart';
import '../../content/models/content_catalog.dart';
import '../../content/models/jlpt_level.dart';
import '../../content/models/vocab_entry.dart';
import '../../content/services/content_repository.dart';
import '../../../shared/providers/app_settings.dart';
import '../../../shared/widgets/content_sheets.dart';

class VocabPage extends ConsumerStatefulWidget {
  /// Purpose: Create a vocabulary page instance.
  /// Inputs: None.
  /// Returns: A new `VocabPage` instance.
  /// Side effects: None.
  /// Notes: None.
  const VocabPage({super.key});

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new state object.
  /// Side effects: None.
  /// Notes: Flutter lifecycle override.
  @override
  ConsumerState<VocabPage> createState() => _VocabPageState();
}

class _VocabPageState extends ConsumerState<VocabPage> {
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

  /// Purpose: Build the vocabulary browser.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often. The
  /// catalog is a `FutureProvider`, so the page shows a spinner on first load
  /// and an error line if a content file is unreadable.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final catalog = ref.watch(contentCatalogProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.vocabTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.biotech_outlined),
            tooltip: l10n.labTitle,
            onPressed: () => context.push('/lab'),
          ),
        ],
      ),
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
  /// Notes: Internal helper used within this file only. Rows rather than tiles
  /// are the list items, so `ListView.builder` still virtualizes at two or
  /// more columns. The column count comes from [referenceColumnCount]: the
  /// screen gates the split, the content width sets the capacity.
  Widget _buildList(
    BuildContext context,
    AppLocalizations l10n,
    ContentCatalog catalog,
  ) {
    final locale = Localizations.localeOf(context);
    final settings = ref.watch(appSettingsProvider);
    final level = settings.vocabLevel;
    final query = _query.trim().toLowerCase();
    final filtered = [
      for (final entry in catalog.vocab)
        if ((level == null || entry.level == level) &&
            (query.isEmpty || entry.matches(query)))
          entry,
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
          return constrain(emptyResults(context, l10n.vocabEmpty));
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
  /// `contentWidth` — the width the list gets, which decides whether the
  /// column control can do anything.
  /// Returns: `Widget`.
  /// Side effects: None beyond building widgets; the controls persist through
  /// the settings notifier.
  /// Notes: Internal helper used within this file only. The level filter and
  /// the column count are device preferences, not page state, so they survive
  /// a tab switch and a restart.
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
            hintText: l10n.vocabSearchHint,
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
          onChanged: notifier.setVocabLevel,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.vocabCount(count),
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

  /// Purpose: Build one vocabulary tile.
  /// Inputs: `context`, `entry`, `locale`.
  /// Returns: `Widget`.
  /// Side effects: Opens the detail sheet on tap.
  /// Notes: Internal helper used within this file only. The reading line is
  /// dropped for kana-only words so the tile does not repeat itself.
  Widget _buildTile(
    BuildContext context,
    ContentCatalog catalog,
    VocabEntry entry,
    Locale locale,
  ) {
    final theme = Theme.of(context);
    final reading = [
      if (entry.hasKanji) entry.reading,
      if (entry.romaji != null) entry.romaji!,
    ].join(' · ');
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showVocabDetailSheet(context, catalog, entry, locale),
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
                      entry.headword,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (reading.isNotEmpty)
                      Text(
                        reading,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      entry.meanings.resolveJoined(locale),
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              levelChip(context, entry.level),
            ],
          ),
        ),
      ),
    );
  }
}
