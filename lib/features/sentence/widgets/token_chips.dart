import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/content_sheets.dart';
import '../../content/models/content_catalog.dart';
import '../../content/models/localized_strings.dart';
import '../models/sentence_analysis.dart';
import '../models/token.dart';

/// The sentence as a row of tappable word chips.
///
/// Colour groups the words by what they do, and the label under each chip
/// names the group in words — colour is never the only carrier of meaning.
/// Tapping a chip opens the catalog entry where there is one, and a small
/// sheet with the function word's meaning where there is not.
class TokenChips extends StatelessWidget {
  const TokenChips({super.key, required this.analysis, this.catalog});

  /// The analysed sentence.
  final SentenceAnalysis analysis;

  /// The catalog, for opening a word's entry; null before it has loaded.
  final ContentCatalog? catalog;

  /// Purpose: Build the chip row.
  /// Inputs: The build `context`.
  /// Returns: `Widget`.
  /// Side effects: None until a chip is tapped.
  /// Notes: A `Wrap`, so a long sentence flows onto more lines instead of
  /// scrolling sideways — the whole point is seeing the sentence at once.
  /// Punctuation is skipped: it is not a word and a chip for it would only
  /// break the line up.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final token in analysis.tokens)
          if (token.category != TokenCategory.punctuation)
            _chip(context, theme, l10n, token),
      ],
    );
  }

  /// Purpose: Build one word's chip.
  /// Inputs: `context`, `theme`, `l10n`, `token`.
  /// Returns: `Widget`.
  /// Side effects: None until tapped.
  /// Notes: Internal helper used within this file only. The chip shows the
  /// surface as written, the form chain underneath when the word was
  /// inflected, and the category name below that. A word not in the dictionary
  /// is drawn in the error colour and says so, rather than being left to look
  /// like an ordinary noun.
  Widget _chip(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    Token token,
  ) {
    final colors = _colorsFor(theme, token.category);
    final forms = token.forms.isEmpty
        ? null
        : token.forms.map((f) => f.name).join(' + ');
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _open(context, token),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colors.$1,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              token.surface,
              style: theme.textTheme.titleMedium?.copyWith(color: colors.$2),
            ),
            if (forms != null)
              Text(
                forms,
                style: theme.textTheme.labelSmall?.copyWith(color: colors.$2),
              ),
            Text(
              _label(l10n, token.category),
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.$2.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Purpose: Open whatever a word has to show.
  /// Inputs: `context`, `token`.
  /// Returns: None.
  /// Side effects: Presents a sheet or a dialog.
  /// Notes: Internal helper used within this file only. A catalog word opens
  /// the same detail sheet the vocabulary page uses, so a word looked up here
  /// is the same page as a word looked up there. A function word has no
  /// catalog entry — it is grammar, not vocabulary — so its own gloss is shown
  /// instead.
  void _open(BuildContext context, Token token) {
    final id = token.refId;
    final entry = id == null ? null : catalog?.vocabById(id);
    if (entry != null && catalog != null) {
      showVocabDetailSheet(
        context,
        catalog!,
        entry,
        Localizations.localeOf(context),
      );
      return;
    }
    final gloss = token.gloss;
    if (gloss == null || gloss.isEmpty) return;
    final keys = LocalizedStrings.lookupOrder(Localizations.localeOf(context));
    final text = keys.map((key) => gloss[key]).nonNulls.firstOrNull ?? '';
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(token.surface),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }

  /// Purpose: Name a category in the user's language.
  /// Inputs: `l10n`, `category`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Six names for twenty
  /// categories on purpose: a learner reading a sentence wants to know that a
  /// word is a particle, not that it is a binding particle as opposed to a
  /// conjunctive one.
  static String _label(AppLocalizations l10n, TokenCategory category) =>
      switch (category) {
        TokenCategory.noun ||
        TokenCategory.pronoun ||
        TokenCategory.properNoun ||
        TokenCategory.number ||
        TokenCategory.counter ||
        TokenCategory.formalNoun ||
        TokenCategory.katakanaUnknown => l10n.labCategoryNoun,
        TokenCategory.verb || TokenCategory.auxVerb => l10n.labCategoryVerb,
        TokenCategory.iAdjective ||
        TokenCategory.naAdjective => l10n.labCategoryAdjective,
        TokenCategory.particleCase ||
        TokenCategory.particleBinding ||
        TokenCategory.particleConjunctive ||
        TokenCategory.particleFinal => l10n.labCategoryParticle,
        TokenCategory.copula ||
        TokenCategory.auxiliary => l10n.labCategoryAuxiliary,
        TokenCategory.unknown => l10n.labCategoryUnknown,
        _ => l10n.labCategoryOther,
      };

  /// Purpose: Pick the colours for a category.
  /// Inputs: `theme`, `category`.
  /// Returns: A record of background and foreground.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Every colour comes
  /// from the scheme, so the chips follow the theme in both modes, and the
  /// groups are the same six the labels name.
  static (Color, Color) _colorsFor(ThemeData theme, TokenCategory category) {
    final scheme = theme.colorScheme;
    return switch (category) {
      TokenCategory.verb || TokenCategory.auxVerb => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      TokenCategory.iAdjective || TokenCategory.naAdjective => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      TokenCategory.particleCase ||
      TokenCategory.particleBinding ||
      TokenCategory.particleConjunctive ||
      TokenCategory.particleFinal => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      TokenCategory.copula || TokenCategory.auxiliary => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
      TokenCategory.unknown => (scheme.errorContainer, scheme.onErrorContainer),
      _ => (scheme.surfaceContainerHigh, scheme.onSurface),
    };
  }
}
