/// Purpose: Show a word, a grammar point or a kana in a bottom sheet, with
/// chips linking to the entries around it.
/// Inputs: The content catalog and the entry to show.
/// Returns: Nothing; each function opens a modal sheet.
/// Side effects: Pushes a modal route.
/// Notes: Lifted out of the vocabulary and grammar pages so kana, vocabulary
/// and grammar can all open each other's sheets. Sheets rather than routes,
/// because a sheet keeps the list position underneath and works the same in
/// one column and in several. Opening a linked sheet stacks a second sheet, so
/// dismissing it returns to the first, which is what "back" should mean here.
library;

import 'package:flutter/material.dart';

import '../../features/content/models/content_catalog.dart';
import '../../features/content/models/grammar_point.dart';
import '../../features/content/models/vocab_entry.dart';
import '../../features/content/services/content_links.dart';
import '../../features/kana/models/kana.dart';
import '../../features/kana/models/kana_note.dart';
import '../../features/speech/widgets/speak_button.dart';
import '../../l10n/app_localizations.dart';
import 'reference_widgets.dart';

/// Purpose: Render a section heading inside a sheet.
/// Inputs: `theme`, `text`.
/// Returns: `Widget`.
/// Side effects: None.
/// Notes: Internal helper used within this file only.
Widget _sectionLabel(ThemeData theme, String text) => Text(
  text,
  style: theme.textTheme.titleSmall?.copyWith(
    color: theme.colorScheme.primary,
    fontWeight: FontWeight.w700,
  ),
);

/// Purpose: Wrap a sheet's contents in the padding and scrolling every sheet
/// uses.
/// Inputs: `children`.
/// Returns: `Widget`.
/// Side effects: None.
/// Notes: Internal helper used within this file only. `SafeArea` matters on a
/// phone with a gesture bar, where the last chip would otherwise sit under it.
Widget _sheetBody(List<Widget> children) => SafeArea(
  child: SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  ),
);

/// Purpose: Render a labelled row of tappable chips.
/// Inputs: `context`, `label`, `chips`.
/// Returns: `Widget`; an empty box when there are no chips.
/// Side effects: None.
/// Notes: Internal helper used within this file only. An empty box rather than
/// an empty section, so a word with no links shows no heading at all.
Widget _chipSection(BuildContext context, String label, List<Widget> chips) {
  if (chips.isEmpty) return const SizedBox.shrink();
  final theme = Theme.of(context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 16),
      _sectionLabel(theme, label),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: chips),
    ],
  );
}

/// Purpose: Show a word's full entry, with the grammar its examples use.
/// Inputs: `context`, `catalog`, `entry`, `locale`.
/// Returns: `Future<void>` completing when the sheet closes.
/// Side effects: Pushes a modal bottom sheet.
/// Notes: The grammar chips are matched by substring, not by parsing, so they
/// are labelled as what the example uses rather than presented as analysis;
/// see `content_links.dart`.
Future<void> showVocabDetailSheet(
  BuildContext context,
  ContentCatalog catalog,
  VocabEntry entry,
  Locale locale,
) {
  final l10n = AppLocalizations.of(context)!;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final theme = Theme.of(context);
      final grammar = <GrammarPoint>[];
      for (final example in entry.examples) {
        for (final point in grammarPointsInExample(catalog, example)) {
          if (!grammar.any((p) => p.id == point.id)) grammar.add(point);
        }
      }
      return _sheetBody([
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                entry.headword,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SpeakButton(text: entry.reading),
            levelChip(context, entry.level),
          ],
        ),
        Text(
          [entry.reading, if (entry.romaji != null) entry.romaji!].join(' · '),
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (entry.partsOfSpeech.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '${l10n.vocabPartOfSpeech}: ${entry.partsOfSpeech.join(', ')}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 16),
        for (final meaning in entry.meanings.resolve(locale))
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('• $meaning', style: theme.textTheme.bodyLarge),
          ),
        const SizedBox(height: 16),
        exampleList(context, entry.examples, locale),
        _chipSection(context, l10n.vocabGrammarUsed, [
          for (final point in grammar)
            ActionChip(
              label: Text(point.pattern),
              onPressed: () =>
                  showGrammarDetailSheet(context, catalog, point, locale),
            ),
        ]),
      ]);
    },
  );
}

/// Purpose: Show a grammar point's full entry, with the words its examples
/// use.
/// Inputs: `context`, `catalog`, `point`, `locale`.
/// Returns: `Future<void>` completing when the sheet closes.
/// Side effects: Pushes a modal bottom sheet.
/// Notes: The word chips are limited to the point's own level and below, so a
/// sentence teaching N5 grammar does not send the reader to an N1 word.
Future<void> showGrammarDetailSheet(
  BuildContext context,
  ContentCatalog catalog,
  GrammarPoint point,
  Locale locale,
) {
  final l10n = AppLocalizations.of(context)!;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final theme = Theme.of(context);
      final explanation = point.explanation.resolveJoined(
        locale,
        separator: '\n',
      );
      final words = vocabInExamples(catalog, point);
      return _sheetBody([
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
        _chipSection(context, l10n.grammarWordsUsed, [
          for (final word in words)
            ActionChip(
              label: Text(word.headword),
              onPressed: () =>
                  showVocabDetailSheet(context, catalog, word, locale),
            ),
        ]),
      ]);
    },
  );
}

/// Purpose: Show one kana in both scripts, with its note and example words.
/// Inputs: `context`, `catalog`, `entry`, `locale`.
/// Returns: `Future<void>` completing when the sheet closes.
/// Side effects: Pushes a modal bottom sheet.
/// Notes: The example words are the point of the sheet: a kana chart teaches
/// shapes, and a beginner needs to see the shape inside a word to read it.
/// They are the easiest and most common words that start with the kana.
Future<void> showKanaDetailSheet(
  BuildContext context,
  ContentCatalog catalog,
  KanaEntry entry,
  Locale locale,
) {
  final l10n = AppLocalizations.of(context)!;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final theme = Theme.of(context);
      final note = catalog.kanaNotes[entry.progressId];
      final words = vocabStartingWithKana(catalog, entry);
      return _sheetBody([
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              entry.hiragana,
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 20),
            Text(
              entry.katakana,
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(entry.romaji, style: theme.textTheme.headlineSmall),
            SpeakButton(text: entry.hiragana),
          ],
        ),
        if (note?.strokes != null) ...[
          const SizedBox(height: 12),
          Text(
            l10n.kanaStrokes(note!.strokes!),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (note != null && !note.hint.isEmpty) ...[
          const SizedBox(height: 16),
          Text(
            note.hint.resolveJoined(locale, separator: '\n'),
            style: theme.textTheme.bodyMedium,
          ),
        ],
        if (note != null && note.confusableWith.isNotEmpty)
          _chipSection(context, l10n.kanaConfusableWith, [
            for (final id in note.confusableWith)
              if (kanaEntryById(id) case final other?)
                ActionChip(
                  label: Text('${other.hiragana} · ${other.katakana}'),
                  onPressed: () =>
                      showKanaDetailSheet(context, catalog, other, locale),
                ),
          ]),
        _chipSection(context, l10n.kanaExampleWords, [
          for (final word in words)
            ActionChip(
              label: Text('${word.headword} (${word.reading})'),
              onPressed: () =>
                  showVocabDetailSheet(context, catalog, word, locale),
            ),
        ]),
        if (note == null && words.isEmpty) ...[
          const SizedBox(height: 16),
          Text(
            l10n.kanaNoExtras,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ]);
    },
  );
}

/// Re-exported so a caller that only needs the note type does not import the
/// kana model as well.
typedef KanaSheetNote = KanaNote;
