import '../../content/models/content_catalog.dart';
import '../../content/models/vocab_entry.dart';
import '../../kana/models/kana_text.dart';

/// A surface-to-entry index over the bundled catalog.
///
/// `ContentCatalog` can look an entry up by id, which is all the reference
/// pages need. Reading Japanese text needs the opposite direction: given a run
/// of characters, which catalog entries could it be. The index is built once
/// per app run and answers that in constant time.
///
/// Today it serves pronunciation scoring, where a recognizer that answered in
/// kanji has to be rewritten to kana before it can be compared with a reading.
/// The sentence analyser in `PLAN.md` M2.3 extends this same class rather than
/// building a second index.
class Lexicon {
  Lexicon._(this._byHeadword, this._byReading, this._maxHeadwordLength);

  final Map<String, List<VocabEntry>> _byHeadword;
  final Map<String, List<VocabEntry>> _byReading;
  final int _maxHeadwordLength;

  /// Purpose: Build the index from the bundled catalog.
  /// Inputs: `catalog`.
  /// Returns: `Lexicon`.
  /// Side effects: None.
  /// Notes: Two maps over 7,700 entries; tens of milliseconds and a few
  /// megabytes of references, built once and shared. Headwords that are
  /// already kana appear in both maps, which costs nothing and means a caller
  /// never has to ask which kind it has.
  static Lexicon build(ContentCatalog catalog) {
    final byHeadword = <String, List<VocabEntry>>{};
    final byReading = <String, List<VocabEntry>>{};
    var longest = 1;
    for (final entry in catalog.vocab) {
      (byHeadword[entry.headword] ??= []).add(entry);
      (byReading[toHiragana(entry.reading)] ??= []).add(entry);
      if (entry.headword.length > longest) longest = entry.headword.length;
    }
    return Lexicon._(byHeadword, byReading, longest);
  }

  /// How many entries the index covers, for diagnostics and tests.
  int get entryCount => _byReading.values.fold(0, (sum, l) => sum + l.length);

  /// Purpose: Find the catalog entries written exactly this way.
  /// Inputs: `surface` — a headword as it is written.
  /// Returns: `List<VocabEntry>`; empty when nothing matches.
  /// Side effects: None.
  /// Notes: Several entries can share a headword (一日 is two words), so this
  /// answers a list and lets the caller decide.
  List<VocabEntry> byHeadword(String surface) =>
      _byHeadword[surface] ?? const [];

  /// Purpose: Find the catalog entries read this way.
  /// Inputs: `reading` — kana; normalized before lookup.
  /// Returns: `List<VocabEntry>`; empty when nothing matches.
  /// Side effects: None.
  /// Notes: None.
  List<VocabEntry> byReading(String reading) =>
      _byReading[toHiragana(reading)] ?? const [];

  /// Purpose: Rewrite text into kana, resolving kanji through the catalog.
  /// Inputs: `text` — typically what a speech recognizer returned.
  /// Returns: `String` — the same text with every recognized headword replaced
  /// by its reading. Still needs normalizing; see the note.
  /// Side effects: None.
  /// Notes: Greedy longest match from the left, capped at the longest headword
  /// in the catalog. A recognizer answers 東京 where the item says とうきょう,
  /// and comparing those character by character would score zero for a
  /// perfect reading; resolving the headword first is what makes the score
  /// mean what it claims. A span the catalog does not know is copied through
  /// **unchanged**, so an unresolved kanji still costs edits rather than
  /// disappearing — the score stays honest about what could not be read.
  ///
  /// Normalization is deliberately left to the caller and applied to the whole
  /// result at once: `ー` takes its vowel from the mora before it, so
  /// normalizing character by character inside this loop would drop it.
  String toKana(String text) {
    final out = StringBuffer();
    var i = 0;
    while (i < text.length) {
      var matched = false;
      final maxLength = _maxHeadwordLength < text.length - i
          ? _maxHeadwordLength
          : text.length - i;
      for (var length = maxLength; length >= 1; length--) {
        final candidate = text.substring(i, i + length);
        final entries = _byHeadword[candidate];
        if (entries != null && entries.isNotEmpty) {
          out.write(entries.first.reading);
          i += length;
          matched = true;
          break;
        }
      }
      if (!matched) {
        out.write(text[i]);
        i++;
      }
    }
    return out.toString();
  }
}
