import 'jlpt_level.dart';
import 'localized_strings.dart';

/// One grammar point from the bundled content.
class GrammarPoint {
  /// Stable id, `grammar:<slug>`; also the progress record id.
  final String id;

  /// JLPT level the point is taught at.
  final JlptLevel level;

  /// The pattern as shown in a heading, e.g. `〜です`.
  final String pattern;

  /// How the pattern attaches, e.g. `N + です`, when the content supplies it.
  final String? structure;

  /// Short meaning by language.
  final LocalizedStrings meaning;

  /// Longer explanation by language.
  final LocalizedStrings explanation;

  /// Example sentences.
  final List<ContentExample> examples;

  /// Literal strings that mark this point in a sentence, from the JSON key
  /// `match`.
  ///
  /// The cross-linking in `content_links.dart` derives forms from the pattern
  /// when this is empty. A single-character particle needs an explicit list,
  /// because deriving one from its pattern would match nearly every sentence.
  final List<String> matchForms;

  /// Purpose: Create a grammar point instance.
  /// Inputs: All fields.
  /// Returns: A new `GrammarPoint` instance.
  /// Side effects: None.
  /// Notes: None.
  const GrammarPoint({
    required this.id,
    required this.level,
    required this.pattern,
    this.structure,
    this.meaning = LocalizedStrings.empty,
    this.explanation = LocalizedStrings.empty,
    this.examples = const [],
    this.matchForms = const [],
  });

  /// Purpose: Parse from content JSON.
  /// Inputs: `json`.
  /// Returns: `GrammarPoint?` — null when the id, level, or pattern is
  /// missing.
  /// Side effects: None.
  /// Notes: None.
  static GrammarPoint? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final level = JlptLevel.parse(json['level']);
    final pattern = json['pattern'];
    if (id is! String || id.isEmpty || level == null) return null;
    if (pattern is! String || pattern.isEmpty) return null;
    return GrammarPoint(
      id: id,
      level: level,
      pattern: pattern,
      structure: json['structure'] is String
          ? json['structure'] as String
          : null,
      meaning: LocalizedStrings.fromJson(json['meaning']),
      explanation: LocalizedStrings.fromJson(json['explanation']),
      examples: ContentExample.listFromJson(json['examples']),
      matchForms: json['match'] is List
          ? (json['match'] as List).whereType<String>().toList()
          : const [],
    );
  }

  /// Purpose: Test whether a search query matches this point.
  /// Inputs: `query` — expected already trimmed and lowercased.
  /// Returns: `bool` — true when the query is a substring of the pattern, the
  /// structure, or any meaning in any language.
  /// Side effects: None.
  /// Notes: The explanation is deliberately not searched; it would match
  /// nearly everything on common words.
  bool matches(String query) {
    if (pattern.contains(query)) return true;
    if (structure != null && structure!.toLowerCase().contains(query)) {
      return true;
    }
    return meaning.matches(query);
  }
}
