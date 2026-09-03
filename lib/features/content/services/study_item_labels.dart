/// Purpose: Turn a progress record id into something a person recognizes.
/// Inputs: The content catalog and the kana tables.
/// Returns: A [StudyItemLabel] for any id, resolved or not.
/// Side effects: None; pure lookups.
/// Notes: Progress ids outlive the catalog — a record may name an item this
/// build no longer ships, or the catalog may not have loaded yet. Both cases
/// return a label carrying the raw id with `resolved == false` rather than
/// nothing, so the conflict dialog can still be shown.
library;

import 'dart:ui';

import '../../kana/models/kana.dart';
import '../../progress/models/study_record.dart';
import '../models/content_catalog.dart';

/// A display name for one progress record.
class StudyItemLabel {
  /// The headword, pattern, or kana pair; the raw id when unresolved.
  final String title;

  /// The reading and first meaning, when the catalog has them.
  final String? subtitle;

  /// Which kind of item the id names.
  final StudyKind kind;

  /// Whether the id was found in the catalog or the kana tables.
  final bool resolved;

  /// Purpose: Create a study item label instance.
  /// Inputs: `title`, `subtitle`, `kind`, `resolved`.
  /// Returns: A new `StudyItemLabel` instance.
  /// Side effects: None.
  /// Notes: None.
  const StudyItemLabel({
    required this.title,
    required this.kind,
    this.subtitle,
    this.resolved = true,
  });
}

/// Purpose: Look up the display name for a progress record id.
/// Inputs: `id` — a `kana:`, `vocab:` or `grammar:` id; `catalog` — the parsed
/// content, or null when it has not loaded; `locale` — the UI locale, which
/// picks the language of the meaning shown.
/// Returns: `StudyItemLabel`; never null.
/// Side effects: None.
/// Notes: Vocabulary lookups go through `ContentCatalog.vocabById`, which is
/// alias-aware, so an id retired in favour of a JMdict-keyed one still names
/// its entry.
StudyItemLabel resolveStudyItemLabel(
  String id, {
  ContentCatalog? catalog,
  required Locale locale,
}) {
  final kind = studyKindOf(id);
  switch (kind) {
    case StudyKind.kana:
      final entry = kanaEntryById(id);
      if (entry != null) {
        return StudyItemLabel(
          title: '${entry.hiragana} · ${entry.katakana}',
          subtitle: entry.romaji,
          kind: kind,
        );
      }
    case StudyKind.vocab:
      final entry = catalog?.vocabById(id);
      if (entry != null) {
        final meaning = entry.meanings.resolve(locale);
        final subtitle = [
          if (entry.reading != entry.headword) entry.reading,
          if (meaning.isNotEmpty) meaning.first,
        ].join(' · ');
        return StudyItemLabel(
          title: entry.headword,
          subtitle: subtitle.isEmpty ? null : subtitle,
          kind: kind,
        );
      }
    case StudyKind.grammar:
      final point = catalog?.grammarById(id);
      if (point != null) {
        final meaning = point.meaning.resolveJoined(locale);
        return StudyItemLabel(
          title: point.pattern,
          subtitle: meaning.isEmpty ? null : meaning,
          kind: kind,
        );
      }
    case StudyKind.other:
      break;
  }
  return StudyItemLabel(title: id, kind: kind, resolved: false);
}
