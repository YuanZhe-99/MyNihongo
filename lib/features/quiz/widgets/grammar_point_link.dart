import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../content/services/content_repository.dart';
import '../../../shared/widgets/content_sheets.dart';

/// Names the grammar point a question is about, above the question.
///
/// Only ever shown on a generated question. On an authored one the point is
/// frequently the answer — 「这句用了哪个语法点？」 with the four points as
/// options — so naming it above would be giving it away, while on a generated
/// question the point is the premise: the model was asked to test 〜ね, and a
/// learner who does not know that is being asked to guess what is being asked.
class GrammarPointLine extends ConsumerWidget {
  /// Purpose: Build the line for one catalog id.
  /// Inputs: The `itemId` the question is recorded against.
  /// Returns: A new `GrammarPointLine` instance.
  /// Side effects: None.
  /// Notes: Takes the id rather than the point, because the widget is where
  /// the locale is and the point's meaning has to be resolved against it.
  const GrammarPointLine(this.itemId, {super.key});

  /// The catalog id, expected to be a `grammar:` one.
  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(contentCatalogProvider).asData?.value;
    final point = catalog?.grammarById(itemId);
    if (point == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        AppLocalizations.of(context)!.quizGrammarPointLine(
          point.pattern,
          point.meaning.resolveJoined(locale),
        ),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// Opens the grammar point a question was about, after it is answered.
///
/// The quiz has never linked to the catalog it draws from: a wrong answer gave
/// the learner an explanation and no way to read the page it came from. The
/// chip is shown on every grammar question, authored or generated, because by
/// then the answer is on screen and the point is no longer a secret.
class GrammarPointChip extends ConsumerWidget {
  /// Purpose: Build the chip for one catalog id.
  /// Inputs: The `itemId` the question is recorded against.
  /// Returns: A new `GrammarPointChip` instance.
  /// Side effects: None.
  /// Notes: Renders nothing when the id is not a grammar point the catalog
  /// knows, which is the same silence the rest of the quiz keeps about ids it
  /// cannot resolve.
  const GrammarPointChip(this.itemId, {super.key});

  /// The catalog id, expected to be a `grammar:` one.
  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(contentCatalogProvider).asData?.value;
    final point = catalog?.grammarById(itemId);
    if (point == null || catalog == null) return const SizedBox.shrink();
    final locale = Localizations.localeOf(context);
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: ActionChip(
          avatar: const Icon(Icons.menu_book_outlined, size: 18),
          label: Text(point.pattern),
          tooltip: l10n.quizOpenGrammarPoint,
          onPressed: () =>
              showGrammarDetailSheet(context, catalog, point, locale),
        ),
      ),
    );
  }
}
