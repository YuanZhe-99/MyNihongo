/// JLPT levels, easiest first.
enum JlptLevel {
  n5,
  n4,
  n3,
  n2,
  n1;

  /// Purpose: Return the label users know the level by.
  /// Inputs: None.
  /// Returns: `String` — `N5` through `N1`.
  /// Side effects: None.
  /// Notes: Not localized; the JLPT uses these names in every language.
  String get label => name.toUpperCase();

  /// Purpose: Parse a level from content JSON.
  /// Inputs: `value` — `N5`, `n5`, or any other case.
  /// Returns: `JlptLevel?` — null for anything unrecognized.
  /// Side effects: None.
  /// Notes: Content files write the uppercase label.
  static JlptLevel? parse(Object? value) {
    if (value is! String) return null;
    final folded = value.toLowerCase();
    for (final level in values) {
      if (level.name == folded) return level;
    }
    return null;
  }
}
