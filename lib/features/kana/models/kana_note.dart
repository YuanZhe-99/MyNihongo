/// Purpose: Carry the extra teaching notes a kana needs beyond its romaji.
/// Inputs: `assets/content/kana_notes.json`.
/// Returns: A parsed note per kana progress id.
/// Side effects: None.
/// Notes: Only kana that need a note have one. The chart itself is compiled
/// into `kana.dart`; the notes are an asset because they are prose and get
/// translated, and because more of them will be written without touching code.
library;

import '../../content/models/localized_strings.dart';

/// What to tell the learner about one kana beyond how it is read.
class KanaNote {
  /// Stroke count, when the note records one.
  final int? strokes;

  /// The point to make about this kana, by language.
  final LocalizedStrings hint;

  /// Progress ids of kana this one is easily confused with.
  final List<String> confusableWith;

  /// Purpose: Create a kana note instance.
  /// Inputs: `strokes`, `hint`, `confusableWith`.
  /// Returns: A new `KanaNote` instance.
  /// Side effects: None.
  /// Notes: None.
  const KanaNote({
    this.strokes,
    this.hint = LocalizedStrings.empty,
    this.confusableWith = const [],
  });

  /// Purpose: Parse one note from content JSON.
  /// Inputs: `json` — `{"strokes": 3, "hint": {...}, "confusableWith": [...]}`.
  /// Returns: `KanaNote?` — null when the entry is not a map.
  /// Side effects: None.
  /// Notes: Every field is optional; a note with only a confusable list is
  /// still useful, and one with only a hint is the common case.
  static KanaNote? fromJson(Object? json) {
    if (json is! Map) return null;
    final strokes = json['strokes'];
    final confusable = json['confusableWith'];
    return KanaNote(
      strokes: strokes is int ? strokes : null,
      hint: LocalizedStrings.fromJson(json['hint']),
      confusableWith: confusable is List
          ? confusable.whereType<String>().toList()
          : const [],
    );
  }

  /// Purpose: Parse the whole notes file.
  /// Inputs: `json` — `{"notes": {"kana:し": {...}, ...}}`.
  /// Returns: `Map<String, KanaNote>` keyed by kana progress id.
  /// Side effects: None.
  /// Notes: A malformed note is skipped rather than failing the file, as
  /// everywhere else in the content parsers — bundled content is a build
  /// input, not user data, and a test catches a bad entry before release.
  static Map<String, KanaNote> mapFromJson(Object? json) {
    if (json is! Map || json['notes'] is! Map) return const {};
    final notes = <String, KanaNote>{};
    for (final entry in (json['notes'] as Map).entries) {
      final parsed = fromJson(entry.value);
      if (parsed != null) notes[entry.key.toString()] = parsed;
    }
    return notes;
  }
}
