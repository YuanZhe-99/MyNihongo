import 'dart:ui';

/// A set of strings keyed by language code, as content files store glosses,
/// explanations, and example translations.
class LocalizedStrings {
  /// Language code (`en`, `zh`) to the strings in that language.
  final Map<String, List<String>> values;

  /// Purpose: Create a localized strings instance.
  /// Inputs: `values`.
  /// Returns: A new `LocalizedStrings` instance.
  /// Side effects: None.
  /// Notes: None.
  const LocalizedStrings(this.values);

  /// An instance with no strings in any language.
  static const empty = LocalizedStrings({});

  /// Purpose: Parse from content JSON.
  /// Inputs: `json` — a map of language code to a string or a list of
  /// strings, or a bare string taken as English.
  /// Returns: `LocalizedStrings`; [empty] for anything else.
  /// Side effects: None.
  /// Notes: Non-string list members are dropped rather than failing the whole
  /// entry, because content is bundled and a bad member is a content bug, not
  /// user data.
  factory LocalizedStrings.fromJson(Object? json) {
    if (json is String) {
      return LocalizedStrings({
        'en': [json],
      });
    }
    if (json is! Map) return empty;
    final values = <String, List<String>>{};
    for (final entry in json.entries) {
      final raw = entry.value;
      final list = <String>[];
      if (raw is String) {
        list.add(raw);
      } else if (raw is List) {
        list.addAll(raw.whereType<String>());
      }
      if (list.isNotEmpty) values[entry.key.toString()] = list;
    }
    return LocalizedStrings(values);
  }

  /// Purpose: Report whether no language has any string.
  /// Inputs: None.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: None.
  bool get isEmpty => values.isEmpty;

  /// Purpose: List the content keys to try for a locale, best first.
  /// Inputs: `locale`.
  /// Returns: `List<String>` — e.g. `['zh_TW', 'zh', 'en']` for Traditional
  /// Chinese, `['zh', 'en']` for Simplified, `['en']` for English.
  /// Side effects: None.
  /// Notes: The full tag comes before the bare language, which is what lets
  /// Traditional Chinese fall back to the Simplified text of an entry the
  /// conversion has not reached — every `zh_TW` string is generated from the
  /// `zh` beside it, so a missing one means there was no Chinese at all.
  /// English is last because it is the one language every entry has.
  static List<String> lookupOrder(Locale locale) {
    final country = locale.countryCode;
    return [
      if (country != null && country.isNotEmpty)
        '${locale.languageCode}_$country',
      locale.languageCode,
      if (locale.languageCode != 'en') 'en',
    ];
  }

  /// Purpose: Pick the strings for a locale.
  /// Inputs: `locale`.
  /// Returns: `List<String>` — the first of [lookupOrder] that is present,
  /// then the first language there is; empty when there is nothing at all.
  /// Side effects: None.
  /// Notes: None.
  List<String> resolve(Locale locale) {
    for (final key in lookupOrder(locale)) {
      final match = values[key];
      if (match != null) return match;
    }
    return values.isEmpty ? const [] : values.values.first;
  }

  /// Purpose: Pick the strings for a locale and join them for display.
  /// Inputs: `locale`, `separator`.
  /// Returns: `String`; empty when there is nothing.
  /// Side effects: None.
  /// Notes: None.
  String resolveJoined(Locale locale, {String separator = '; '}) =>
      resolve(locale).join(separator);

  /// Purpose: Test whether any string in any language contains a query.
  /// Inputs: `query` — expected already lowercased.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Searches every language, so an English query finds a Chinese UI's
  /// entries too.
  bool matches(String query) {
    for (final list in values.values) {
      for (final text in list) {
        if (text.toLowerCase().contains(query)) return true;
      }
    }
    return false;
  }
}

/// One example sentence with its translations.
class ContentExample {
  /// The Japanese sentence.
  final String ja;

  /// The sentence's reading in kana, when the content supplies one.
  final String? reading;

  /// Translations by language.
  final LocalizedStrings translations;

  /// Purpose: Create a content example instance.
  /// Inputs: `ja`, `reading`, `translations`.
  /// Returns: A new `ContentExample` instance.
  /// Side effects: None.
  /// Notes: None.
  const ContentExample({
    required this.ja,
    this.reading,
    this.translations = LocalizedStrings.empty,
  });

  /// Purpose: Parse from content JSON.
  /// Inputs: `json` — `{"ja": ..., "reading": ..., "en": ..., "zh": ...}`.
  /// Returns: `ContentExample?` — null when there is no Japanese sentence.
  /// Side effects: None.
  /// Notes: Every key other than `ja` and `reading` is taken as a language.
  static ContentExample? fromJson(Object? json) {
    if (json is! Map) return null;
    final ja = json['ja'];
    if (ja is! String || ja.isEmpty) return null;
    final translations = <String, dynamic>{
      for (final entry in json.entries)
        if (entry.key != 'ja' && entry.key != 'reading')
          entry.key.toString(): entry.value,
    };
    return ContentExample(
      ja: ja,
      reading: json['reading'] is String ? json['reading'] as String : null,
      translations: LocalizedStrings.fromJson(translations),
    );
  }

  /// Purpose: Parse a list of examples, skipping malformed members.
  /// Inputs: `json`.
  /// Returns: `List<ContentExample>`.
  /// Side effects: None.
  /// Notes: None.
  static List<ContentExample> listFromJson(Object? json) {
    if (json is! List) return const [];
    return [for (final entry in json) ?fromJson(entry)];
  }
}
