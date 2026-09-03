import 'jlpt_level.dart';
import 'localized_strings.dart';

/// One vocabulary item from the bundled content.
class VocabEntry {
  /// Stable id, `vocab:<slug>`; also the progress record id.
  final String id;

  /// JLPT level the item is taught at.
  final JlptLevel level;

  /// Headword as written — kanji when the word has one, else kana.
  final String headword;

  /// Reading in kana.
  final String reading;

  /// Romanization, when the content supplies one.
  final String? romaji;

  /// Parts of speech, as content tags (`noun`, `verb-godan`, `i-adjective`).
  final List<String> partsOfSpeech;

  /// Glosses by language.
  final LocalizedStrings meanings;

  /// Example sentences.
  final List<ContentExample> examples;

  /// Ids this entry used to ship under, still resolvable.
  ///
  /// A shipped content id is never renamed, because progress records are keyed
  /// by it. When the JMdict import replaced the hand-written seed ids with
  /// JMdict-numbered ones, the old id moved here instead of disappearing.
  final List<String> aliases;

  /// Whether JMdict marks the chosen written form as common.
  ///
  /// Used to order suggestions, never to hide an entry.
  final bool common;

  /// Purpose: Create a vocab entry instance.
  /// Inputs: All fields.
  /// Returns: A new `VocabEntry` instance.
  /// Side effects: None.
  /// Notes: None.
  const VocabEntry({
    required this.id,
    required this.level,
    required this.headword,
    required this.reading,
    this.romaji,
    this.partsOfSpeech = const [],
    this.meanings = LocalizedStrings.empty,
    this.examples = const [],
    this.aliases = const [],
    this.common = false,
  });

  /// Purpose: Report whether the headword differs from the reading.
  /// Inputs: None.
  /// Returns: `bool` — false for words written in kana alone.
  /// Side effects: None.
  /// Notes: Drives whether the tile shows a reading line.
  bool get hasKanji => headword != reading;

  /// Purpose: Parse from content JSON.
  /// Inputs: `json`.
  /// Returns: `VocabEntry?` — null when the id, level, headword, or reading
  /// is missing, because content without those cannot be shown or tracked.
  /// Side effects: None.
  /// Notes: `kanji` may be absent; the reading is then the headword.
  static VocabEntry? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final level = JlptLevel.parse(json['level']);
    final reading = json['reading'];
    if (id is! String || id.isEmpty || level == null) return null;
    if (reading is! String || reading.isEmpty) return null;
    final kanji = json['kanji'];
    final pos = json['pos'];
    return VocabEntry(
      id: id,
      level: level,
      headword: kanji is String && kanji.isNotEmpty ? kanji : reading,
      reading: reading,
      romaji: json['romaji'] is String ? json['romaji'] as String : null,
      partsOfSpeech: pos is List ? pos.whereType<String>().toList() : const [],
      meanings: LocalizedStrings.fromJson(json['meanings']),
      examples: ContentExample.listFromJson(json['examples']),
      aliases: json['aliases'] is List
          ? (json['aliases'] as List).whereType<String>().toList()
          : const [],
      common: json['common'] == true,
    );
  }

  /// Purpose: Test whether a search query matches this entry.
  /// Inputs: `query` — expected already trimmed and lowercased.
  /// Returns: `bool` — true when the query is a substring of the headword,
  /// the reading, the romaji, or any gloss in any language.
  /// Side effects: None.
  /// Notes: None.
  bool matches(String query) {
    if (headword.contains(query) || reading.contains(query)) return true;
    if (romaji != null && romaji!.toLowerCase().contains(query)) return true;
    return meanings.matches(query);
  }
}
