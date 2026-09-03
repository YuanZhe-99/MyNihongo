import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/app_settings.dart';
import '../../../shared/utils/adaptive_layout.dart';
import '../../../shared/widgets/content_sheets.dart';
import '../../content/services/content_repository.dart';
import '../../speech/services/tts_service.dart';
import '../models/kana.dart';

class KanaPage extends ConsumerStatefulWidget {
  /// Purpose: Create a kana page instance.
  /// Inputs: None.
  /// Returns: A new `KanaPage` instance.
  /// Side effects: None.
  /// Notes: None.
  const KanaPage({super.key});

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new state object.
  /// Side effects: None.
  /// Notes: Flutter lifecycle override.
  @override
  ConsumerState<KanaPage> createState() => _KanaPageState();
}

class _KanaPageState extends ConsumerState<KanaPage> {
  final _searchController = TextEditingController();
  String _query = '';

  /// Which script the chart shows, from the device preferences.
  ///
  /// A getter rather than page state, so the choice survives a tab switch and
  /// a restart. `build` watches the provider, so every read here is current.
  KanaScript get _script => ref.watch(appSettingsProvider).kanaScript;

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

  /// Purpose: Build the page in one or two columns, according to the window.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often. The
  /// two-column arrangement is gated twice: by the app-wide [canSplitLayout],
  /// and by whether two tables of [kanaTableMinWidth] actually fit. The second
  /// gate is what keeps the narrower unfolded foldables on one column without
  /// needing a breakpoint of their own.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    // Watched, not read: a cell tapped before the catalog finishes loading
    // should become live as soon as it does, without a second tap.
    ref.watch(contentCatalogProvider);
    final matches = matchingKanaEntries(_query);
    final searching = _query.trim().isNotEmpty;

    final screen = MediaQuery.sizeOf(context);
    final contentWidth = referenceContentWidth(screen.width);
    final twoColumn =
        canSplitLayout(screen.width, screen.height) &&
        columnCapacity(
              contentWidth,
              minItemWidth: kanaTableMinWidth,
              maxColumns: 2,
            ) >=
            2;

    final scriptPicker = SegmentedButton<KanaScript>(
      segments: [
        ButtonSegment(
          value: KanaScript.hiragana,
          icon: const Icon(Icons.text_fields, size: 18),
          label: Text(l10n.kanaScriptHiragana),
        ),
        ButtonSegment(
          value: KanaScript.katakana,
          icon: const Icon(Icons.title, size: 18),
          label: Text(l10n.kanaScriptKatakana),
        ),
      ],
      selected: {_script},
      onSelectionChanged: (selection) {
        ref.read(appSettingsProvider.notifier).setKanaScript(selection.first);
      },
    );

    final searchField = TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: l10n.kanaSearchHint,
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
    );

    final basicTable = _buildKanaTable(
      theme,
      l10n.kanaBasicSection,
      kanaVowelColumns,
      kanaBasicRows,
    );
    final voicedTable = _buildKanaTable(
      theme,
      l10n.kanaVoicedSection,
      kanaVowelColumns,
      kanaVoicedRows,
    );
    final yoonTable = _buildKanaTable(
      theme,
      l10n.kanaYoonSection,
      kanaYoonColumns,
      kanaYoonRows,
    );
    final rules = _buildRules(theme, l10n);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.kanaTitle)),
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
                  // Side by side when there is room: the picker sizes to its
                  // content and the field takes the rest, which buys back a
                  // row of vertical space on the axis a foldable is short on.
                  if (twoColumn)
                    Row(
                      children: [
                        scriptPicker,
                        const SizedBox(width: listTileGap),
                        Expanded(child: searchField),
                      ],
                    )
                  else ...[
                    scriptPicker,
                    const SizedBox(height: 12),
                    searchField,
                  ],
                  const SizedBox(height: 20),
                  if (searching) ...[
                    _buildSearchResults(theme, l10n, matches),
                    const SizedBox(height: 24),
                    rules,
                  ] else if (twoColumn)
                    // The tall basic and yoon tables balance against the short
                    // voiced table plus the rules, so neither column runs far
                    // past the other.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              basicTable,
                              const SizedBox(height: 20),
                              yoonTable,
                            ],
                          ),
                        ),
                        const SizedBox(width: listTileGap),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              voicedTable,
                              const SizedBox(height: 20),
                              rules,
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    basicTable,
                    const SizedBox(height: 20),
                    voicedTable,
                    const SizedBox(height: 20),
                    yoonTable,
                    const SizedBox(height: 24),
                    rules,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Purpose: Render one titled kana table.
  /// Inputs: `theme`, `title`, `columns`, `rows`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  Widget _buildKanaTable(
    ThemeData theme,
    String title,
    List<String> columns,
    List<KanaRow> rows,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(theme, Icons.grid_on_outlined, title),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildHeaderRow(theme, columns),
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
              for (var i = 0; i < rows.length; i++) ...[
                _buildKanaRow(theme, rows[i]),
                if (i != rows.length - 1)
                  Divider(
                    height: 1,
                    indent: 44,
                    color: theme.colorScheme.outlineVariant,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Purpose: Render a table's column-label header row.
  /// Inputs: `theme`, `columns`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  Widget _buildHeaderRow(ThemeData theme, List<String> columns) {
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          const SizedBox(width: 44),
          for (final column in columns)
            Expanded(
              child: Center(
                child: Text(
                  column,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Purpose: Render one consonant row of kana cells plus its label.
  /// Inputs: `theme`, `row`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  Widget _buildKanaRow(ThemeData theme, KanaRow row) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 44,
          child: Center(
            child: Text(
              row.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        for (final entry in row.entries) _buildKanaCell(theme, entry),
      ],
    );
  }

  /// Purpose: Open one kana's detail sheet.
  /// Inputs: `entry`.
  /// Returns: None.
  /// Side effects: Pushes a modal bottom sheet.
  /// Notes: Internal helper used within this file only. The catalog is read at
  /// tap time rather than threaded through every table builder; before it has
  /// loaded there is nothing to show, so the tap does nothing rather than
  /// opening an empty sheet.
  void _openKana(KanaEntry entry) {
    final catalog = ref.read(contentCatalogProvider).value;
    if (catalog == null) return;
    showKanaDetailSheet(
      context,
      catalog,
      entry,
      Localizations.localeOf(context),
    );
  }

  /// Purpose: Read one kana aloud without opening its detail sheet.
  /// Inputs: `entry`.
  /// Returns: None.
  /// Side effects: Speaks through the device engine.
  /// Notes: Internal helper used within this file only. Bound to long-press on
  /// a chart cell and on a search result, so running down a row and hearing it
  /// takes no navigation. The kana spoken is the script currently shown, since
  /// that is the one the user is looking at; both scripts read the same.
  void _speakKana(KanaEntry entry) {
    TtsService.instance.speak(entry.kana(_script));
  }

  /// Purpose: Render one kana/romaji cell, or a blank for a missing slot.
  /// Inputs: `theme`, `entry`.
  /// Returns: `Widget`.
  /// Side effects: Opens the kana detail sheet on tap.
  /// Notes: Internal helper used within this file only.
  Widget _buildKanaCell(ThemeData theme, KanaEntry? entry) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: entry == null
            ? const SizedBox(height: 58)
            : Tooltip(
                message: '${entry.kana(_script)} / ${entry.romaji}',
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _openKana(entry),
                  onLongPress: () => _speakKana(entry),
                  child: Container(
                    height: 58,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.52),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          entry.kana(_script),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entry.romaji,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  /// Purpose: Render the search results, or an empty-state message.
  /// Inputs: `theme`, `l10n`, `matches`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  Widget _buildSearchResults(
    ThemeData theme,
    AppLocalizations l10n,
    List<KanaEntry> matches,
  ) {
    if (matches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            l10n.kanaNoMatches,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          theme,
          Icons.manage_search_outlined,
          l10n.kanaSearchResults(matches.length),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: matches
              .map(
                (entry) =>
                    SizedBox(width: 92, child: _buildResultTile(theme, entry)),
              )
              .toList(),
        ),
      ],
    );
  }

  /// Purpose: Render one kana entry as a search-result tile.
  /// Inputs: `theme`, `entry`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  Widget _buildResultTile(ThemeData theme, KanaEntry entry) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _openKana(entry),
      onLongPress: () => _speakKana(entry),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              entry.kana(_script),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              entry.romaji,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Purpose: Lay out the pronunciation-rule cards in one or two columns.
  /// Inputs: `theme`, `l10n`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Measured against
  /// whatever this section is actually given — a whole page width in one
  /// column and half of one in two — so the cards reflow on their own rather
  /// than needing to know which mode they are in. Capped at two: these are
  /// paragraphs, and a third column would take them below a comfortable
  /// reading measure.
  Widget _buildRules(ThemeData theme, AppLocalizations l10n) {
    final rules = [
      _KanaRule(
        Icons.graphic_eq_outlined,
        l10n.kanaRuleMoraTitle,
        l10n.kanaRuleMoraBody,
        theme.colorScheme.primaryContainer,
        theme.colorScheme.onPrimaryContainer,
      ),
      _KanaRule(
        Icons.record_voice_over_outlined,
        l10n.kanaRuleVowelsTitle,
        l10n.kanaRuleVowelsBody,
        theme.colorScheme.secondaryContainer,
        theme.colorScheme.onSecondaryContainer,
      ),
      _KanaRule(
        Icons.blur_on_outlined,
        l10n.kanaRuleDakutenTitle,
        l10n.kanaRuleDakutenBody,
        theme.colorScheme.tertiaryContainer,
        theme.colorScheme.onTertiaryContainer,
      ),
      _KanaRule(
        Icons.join_inner_outlined,
        l10n.kanaRuleYoonTitle,
        l10n.kanaRuleYoonBody,
        theme.colorScheme.primaryContainer,
        theme.colorScheme.onPrimaryContainer,
      ),
      _KanaRule(
        Icons.compress_outlined,
        l10n.kanaRuleSokuonTitle,
        l10n.kanaRuleSokuonBody,
        theme.colorScheme.secondaryContainer,
        theme.colorScheme.onSecondaryContainer,
      ),
      _KanaRule(
        Icons.keyboard_double_arrow_right_outlined,
        l10n.kanaRuleLongVowelsTitle,
        l10n.kanaRuleLongVowelsBody,
        theme.colorScheme.tertiaryContainer,
        theme.colorScheme.onTertiaryContainer,
      ),
      _KanaRule(
        Icons.waves_outlined,
        l10n.kanaRuleNTitle,
        l10n.kanaRuleNBody,
        theme.colorScheme.primaryContainer,
        theme.colorScheme.onPrimaryContainer,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final ruleColumns = columnCapacity(
          constraints.maxWidth,
          minItemWidth: ruleCardMinWidth,
          maxColumns: 2,
        );
        final width = ruleColumns > 1
            ? (constraints.maxWidth - listTileGap * (ruleColumns - 1)) /
                  ruleColumns
            : constraints.maxWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(
              theme,
              Icons.tips_and_updates_outlined,
              l10n.kanaRulesSection,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: listTileGap,
              runSpacing: listTileGap,
              children: [
                for (final rule in rules)
                  SizedBox(width: width, child: _buildRuleCard(theme, rule)),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Purpose: Render one pronunciation-rule card.
  /// Inputs: `theme`, `rule`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  Widget _buildRuleCard(ThemeData theme, _KanaRule rule) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: rule.iconBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(rule.icon, size: 21, color: rule.iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rule.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rule.body,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Purpose: Render a section heading shared by the tables and rules.
  /// Inputs: `theme`, `icon`, `title`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  Widget _sectionTitle(ThemeData theme, IconData icon, String title) {
    return Row(
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
    );
  }
}

class _KanaRule {
  final IconData icon;
  final String title;
  final String body;
  final Color iconBackground;
  final Color iconColor;

  /// Purpose: Create a kana rule instance.
  /// Inputs: `icon`, `title`, `body`, `iconBackground`, `iconColor`.
  /// Returns: A new `_KanaRule` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _KanaRule(
    this.icon,
    this.title,
    this.body,
    this.iconBackground,
    this.iconColor,
  );
}
