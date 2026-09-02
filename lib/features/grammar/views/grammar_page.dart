import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/utils/adaptive_layout.dart';
import '../../../shared/widgets/adaptive_tile_grid.dart';
import '../../../shared/widgets/reference_widgets.dart';
import '../../content/models/content_catalog.dart';
import '../../content/models/grammar_point.dart';
import '../../content/models/jlpt_level.dart';
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
  JlptLevel? _level;

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
    final query = _query.trim().toLowerCase();
    final filtered = [
      for (final point in catalog.grammar)
        if ((_level == null || point.level == _level) &&
            (query.isEmpty || point.matches(query)))
          point,
    ];

    final screen = MediaQuery.sizeOf(context);
    final contentWidth = referenceContentWidth(screen.width);
    final columns = referenceColumnCount(
      screenWidth: screen.width,
      screenHeight: screen.height,
      contentWidth: contentWidth,
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
          return constrain(_buildHeader(context, l10n, filtered.length));
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
              itemBuilder: (i) => _buildTile(context, filtered[i], locale),
            ),
          ),
        );
      },
    );
  }

  /// Purpose: Build the search field, level chips, and result count.
  /// Inputs: `context`, `l10n`, `count`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  Widget _buildHeader(BuildContext context, AppLocalizations l10n, int count) {
    final theme = Theme.of(context);
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
          selected: _level,
          onChanged: (level) => setState(() => _level = level),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.grammarCount(count),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
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
  Widget _buildTile(BuildContext context, GrammarPoint point, Locale locale) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(context, point, locale),
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

  /// Purpose: Show a grammar point's full entry in a bottom sheet.
  /// Inputs: `context`, `point`, `locale`.
  /// Returns: None.
  /// Side effects: Pushes a modal bottom sheet.
  /// Notes: Internal helper used within this file only.
  void _showDetail(BuildContext context, GrammarPoint point, Locale locale) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        final explanation = point.explanation.resolveJoined(
          locale,
          separator: '\n',
        );
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        point.pattern,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    levelChip(context, point.level),
                  ],
                ),
                Text(
                  point.meaning.resolveJoined(locale),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (point.structure != null) ...[
                  const SizedBox(height: 16),
                  _sectionLabel(theme, l10n.grammarStructure),
                  const SizedBox(height: 4),
                  Text(point.structure!, style: theme.textTheme.bodyLarge),
                ],
                if (explanation.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _sectionLabel(theme, l10n.grammarExplanation),
                  const SizedBox(height: 4),
                  Text(explanation, style: theme.textTheme.bodyMedium),
                ],
                const SizedBox(height: 16),
                exampleList(context, point.examples, locale),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Purpose: Render a small section label inside the detail sheet.
  /// Inputs: `theme`, `text`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  Widget _sectionLabel(ThemeData theme, String text) {
    return Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
