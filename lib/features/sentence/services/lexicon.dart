import '../../content/models/content_catalog.dart';
import '../../content/models/vocab_entry.dart';
import '../../kana/models/kana_text.dart';
import '../models/function_word.dart';
import '../models/token.dart';

/// How a word conjugates.
///
/// Assigned from the catalog's part-of-speech tags plus, for godan verbs, the
/// last kana of the reading — which is the only place the row is written down.
enum ConjClass {
  /// Does not conjugate: nouns, particles, adverbs.
  none,
  godanU,
  godanKu,
  godanGu,
  godanSu,
  godanTsu,
  godanNu,
  godanBu,
  godanMu,
  godanRu,
  ichidan,

  /// する and every noun+する compound.
  suru,

  /// 来る, whose stems are irregular in both reading and surface.
  kuru,
  iAdjective,

  /// いい and 良い, which conjugate from よ- rather than from their own stem.
  iiAdjective,
  naAdjective,
}

/// One conjugable catalog entry, prepared for de-inflection.
class LexEntry {
  const LexEntry({
    required this.vocabId,
    required this.lemma,
    required this.reading,
    required this.conj,
    required this.stem,
    required this.category,
    required this.pos,
    this.viaReading = false,
  });

  /// The `vocab:` id, so a token can open its catalog entry.
  final String vocabId;

  /// The dictionary form as written.
  final String lemma;

  /// The dictionary form in kana.
  final String reading;

  /// How it conjugates.
  final ConjClass conj;

  /// The lemma minus its final kana, which every inflected form is built on.
  final String stem;

  /// What kind of word it is.
  final TokenCategory category;

  /// The catalog's own tags, carried through for the checks.
  final List<String> pos;

  /// Whether this candidate was reached through the entry's kana reading
  /// rather than the way it is normally written. A word usually written in
  /// kanji, found spelled in kana, is a weaker match than one found as it is
  /// written — see the cost table in `tokenizer.dart`.
  final bool viaReading;

  /// Purpose: Copy this entry, marked as reached through its reading.
  /// Inputs: None.
  /// Returns: `LexEntry`.
  /// Side effects: None.
  /// Notes: The two indexes hold different objects rather than one flagged at
  /// lookup time, so a caller can never forget to ask which index it came
  /// from.
  LexEntry asReadingMatch() => LexEntry(
    vocabId: vocabId,
    lemma: lemma,
    reading: reading,
    conj: conj,
    stem: stem,
    category: category,
    pos: pos,
    viaReading: true,
  );
}

/// A surface-to-entry index over the bundled catalog and the function words.
///
/// `ContentCatalog` looks entries up by id, which is what the reference pages
/// need. Reading Japanese text needs the opposite direction — given a run of
/// characters, which entries could it be — and that is what this provides, in
/// constant time, built once per app run.
///
/// It serves two callers: pronunciation scoring, which uses [toKana] to
/// rewrite a recognizer's kanji answer into a comparable reading, and the
/// sentence analyser, which uses the rest.
class Lexicon {
  Lexicon._({
    required Map<String, List<VocabEntry>> byHeadword,
    required Map<String, List<VocabEntry>> byReading,
    required Map<String, List<LexEntry>> entriesBySurface,
    required Map<String, List<LexEntry>> conjugablesByStem,
    required Map<String, List<FunctionWord>> functionWords,
    required this.functionWordTable,
    required this.maxKeyLength,
    required int maxHeadwordLength,
  }) : _byHeadword = byHeadword,
       _byReading = byReading,
       _entriesBySurface = entriesBySurface,
       _conjugablesByStem = conjugablesByStem,
       _functionWords = functionWords,
       _maxHeadwordLength = maxHeadwordLength;

  final Map<String, List<VocabEntry>> _byHeadword;
  final Map<String, List<VocabEntry>> _byReading;
  final Map<String, List<LexEntry>> _entriesBySurface;
  final Map<String, List<LexEntry>> _conjugablesByStem;
  final Map<String, List<FunctionWord>> _functionWords;
  final int _maxHeadwordLength;

  /// The longest key in the index, so a longest-match loop knows where to stop.
  final int maxKeyLength;

  /// The function-word table, including the named sets the checks use.
  final FunctionWordTable functionWordTable;

  /// Purpose: Build the index from the catalog and the function-word table.
  /// Inputs: `catalog`, and optionally `functionWords`.
  /// Returns: `Lexicon`.
  /// Side effects: None.
  /// Notes: A few maps over 7,700 entries: tens of milliseconds, built once
  /// and shared through `lexiconProvider`. Surfaces that are already kana are
  /// indexed under both maps, which costs nothing and means a caller never has
  /// to ask which kind it holds. The key length is capped at 12 characters —
  /// longer than any catalog headword, and short enough that a longest-match
  /// loop over a long sentence stays cheap.
  static Lexicon build(
    ContentCatalog catalog, {
    FunctionWordTable functionWords = FunctionWordTable.empty,
  }) {
    final byHeadword = <String, List<VocabEntry>>{};
    final byReading = <String, List<VocabEntry>>{};
    final entriesBySurface = <String, List<LexEntry>>{};
    final conjugablesByStem = <String, List<LexEntry>>{};
    var longestHeadword = 1;
    var longestKey = 1;

    void index(Map<String, List<LexEntry>> map, String key, LexEntry entry) {
      if (key.isEmpty) return;
      (map[key] ??= []).add(entry);
      if (key.length > longestKey) longestKey = key.length;
    }

    for (final vocab in catalog.vocab) {
      (byHeadword[vocab.headword] ??= []).add(vocab);
      (byReading[toHiragana(vocab.reading)] ??= []).add(vocab);
      if (vocab.headword.length > longestHeadword) {
        longestHeadword = vocab.headword.length;
      }

      final conj = _classOf(vocab);
      final entry = LexEntry(
        vocabId: vocab.id,
        lemma: vocab.headword,
        reading: toHiragana(vocab.reading),
        conj: conj,
        stem: conj == ConjClass.none
            ? vocab.headword
            : vocab.headword.substring(0, vocab.headword.length - 1),
        category: _categoryOf(vocab),
        pos: vocab.partsOfSpeech,
      );
      index(entriesBySurface, vocab.headword, entry);
      if (vocab.headword != toHiragana(vocab.reading)) {
        index(
          entriesBySurface,
          toHiragana(vocab.reading),
          entry.asReadingMatch(),
        );
      }
      if (conj != ConjClass.none) {
        index(conjugablesByStem, entry.stem, entry);
        final readingStem = entry.reading.substring(
          0,
          entry.reading.length - 1,
        );
        if (readingStem != entry.stem) {
          index(conjugablesByStem, readingStem, entry);
        }
      }
    }

    final functionWordMap = <String, List<FunctionWord>>{};
    for (final word in functionWords.words) {
      (functionWordMap[word.surface] ??= []).add(word);
      if (word.surface.length > longestKey) longestKey = word.surface.length;
    }

    return Lexicon._(
      byHeadword: byHeadword,
      byReading: byReading,
      entriesBySurface: entriesBySurface,
      conjugablesByStem: conjugablesByStem,
      functionWords: functionWordMap,
      functionWordTable: functionWords,
      maxHeadwordLength: longestHeadword,
      maxKeyLength: longestKey > 12 ? 12 : longestKey,
    );
  }

  /// How many entries the index covers, for diagnostics and tests.
  int get entryCount => _byReading.values.fold(0, (sum, l) => sum + l.length);

  /// Purpose: Find the catalog entries written exactly this way.
  /// Inputs: `surface`.
  /// Returns: `List<VocabEntry>`; empty when nothing matches.
  /// Side effects: None.
  /// Notes: Several entries can share a headword — 一日 is two words — so this
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

  /// Purpose: Find the prepared entries for a surface, conjugable or not.
  /// Inputs: `surface`.
  /// Returns: `List<LexEntry>`.
  /// Side effects: None.
  /// Notes: This is the lattice's dictionary lookup: it matches a written form
  /// and a kana form alike, so a sentence typed entirely in kana still finds
  /// its words.
  List<LexEntry> entriesAt(String surface) =>
      _entriesBySurface[surface] ?? const [];

  /// Purpose: Find conjugable entries whose stem is exactly this.
  /// Inputs: `stem` — a lemma minus its final kana.
  /// Returns: `List<LexEntry>`.
  /// Side effects: None.
  /// Notes: The de-inflector's second stage: having stripped an auxiliary and
  /// worked out which stem shape must precede it, it asks here which words
  /// could have produced that stem.
  List<LexEntry> conjugablesForStem(String stem) =>
      _conjugablesByStem[stem] ?? const [];

  /// Purpose: Find the function words written exactly this way.
  /// Inputs: `surface`.
  /// Returns: `List<FunctionWord>`; several when one surface does several jobs
  /// (から is both a case particle and a reason conjunction).
  /// Side effects: None.
  /// Notes: The table is authoritative over the vocabulary catalog for the
  /// same surface. は is the topic marker far more often than it is 歯, and an
  /// analyser that weighed those equally would be wrong in most sentences.
  List<FunctionWord> functionWordsAt(String surface) =>
      _functionWords[surface] ?? const [];

  /// Purpose: Rewrite text into kana, resolving kanji through the catalog.
  /// Inputs: `text` — typically what a speech recognizer returned.
  /// Returns: `String` — the same text with every recognized headword replaced
  /// by its reading. Still needs normalizing; see the notes.
  /// Side effects: None.
  /// Notes: Greedy longest match from the left, capped at the longest headword
  /// in the catalog. A recognizer answers 東京 where the item says とうきょう,
  /// and comparing those character by character would score a perfect reading
  /// at zero. A span the catalog does not know is copied through **unchanged**,
  /// so an unresolved kanji still costs edits rather than disappearing — the
  /// score stays honest about what could not be read.
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

  /// Purpose: Decide how a catalog entry conjugates.
  /// Inputs: `entry`.
  /// Returns: `ConjClass`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The godan row comes
  /// from the last kana of the **reading**, not the headword, because a verb
  /// written in kanji ends in okurigana that the reading spells out anyway and
  /// a kana-only entry has no other source. `する`-verbs in the catalog are
  /// nouns tagged `suru-verb` and are deliberately **not** given a verb class:
  /// 勉強します is the noun followed by する, which the chunker rejoins, and
  /// inventing 勉強する as a lemma would put a word in the lexicon that the
  /// catalog has no entry for.
  static ConjClass _classOf(VocabEntry entry) {
    final reading = toHiragana(entry.reading);
    if (reading.isEmpty) return ConjClass.none;
    final pos = entry.partsOfSpeech;
    if (pos.contains('verb-irregular')) {
      if (reading == 'くる') return ConjClass.kuru;
      if (reading.endsWith('する') || reading.endsWith('ずる')) {
        return ConjClass.suru;
      }
      return ConjClass.none;
    }
    if (pos.contains('verb-ichidan')) return ConjClass.ichidan;
    if (pos.contains('verb-godan')) {
      return switch (reading[reading.length - 1]) {
        'う' => ConjClass.godanU,
        'く' => ConjClass.godanKu,
        'ぐ' => ConjClass.godanGu,
        'す' => ConjClass.godanSu,
        'つ' => ConjClass.godanTsu,
        'ぬ' => ConjClass.godanNu,
        'ぶ' => ConjClass.godanBu,
        'む' => ConjClass.godanMu,
        'る' => ConjClass.godanRu,
        _ => ConjClass.none,
      };
    }
    if (pos.contains('i-adjective')) {
      return (reading == 'いい' || entry.headword == '良い')
          ? ConjClass.iiAdjective
          : ConjClass.iAdjective;
    }
    if (pos.contains('na-adjective')) return ConjClass.naAdjective;
    return ConjClass.none;
  }

  /// Purpose: Decide which token category a catalog entry produces.
  /// Inputs: `entry`.
  /// Returns: `TokenCategory`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Order matters: an
  /// entry tagged both `noun` and `suru-verb` is a noun, and one tagged both
  /// `noun` and `na-adjective` is treated as a na-adjective so the な/の check
  /// can exempt it.
  ///
  /// The catalog's `auxiliary` tag is deliberately **not** read here. JMdict
  /// gives it to いる, みる, おく, しまう and a dozen more that are ordinary verbs
  /// on their own and auxiliaries only behind a て-form — 見る would otherwise
  /// stop being a verb in 映画を見ました. Whether a verb is acting as an auxiliary
  /// is positional, and the chunker decides it from the token before.
  static TokenCategory _categoryOf(VocabEntry entry) {
    final pos = entry.partsOfSpeech;
    if (pos.contains('particle')) return TokenCategory.particleCase;
    if (pos.contains('verb-godan') ||
        pos.contains('verb-ichidan') ||
        pos.contains('verb-irregular')) {
      return TokenCategory.verb;
    }
    if (pos.contains('i-adjective')) return TokenCategory.iAdjective;
    if (pos.contains('na-adjective')) return TokenCategory.naAdjective;
    if (pos.contains('adverb')) return TokenCategory.adverb;
    if (pos.contains('adnominal')) return TokenCategory.adnominal;
    if (pos.contains('conjunction')) return TokenCategory.conjunction;
    if (pos.contains('interjection')) return TokenCategory.interjection;
    if (pos.contains('pronoun')) return TokenCategory.pronoun;
    if (pos.contains('proper-noun')) return TokenCategory.properNoun;
    // Counter, number, prefix and suffix come **after** noun, and only apply
    // to an entry that is not also a noun. 本 is tagged noun, counter and
    // prefix; it is a book far more often than it is the counter for long thin
    // things, and the counter reading needs a number in front of it, which the
    // chunker sees and this does not.
    if (pos.contains('noun')) return TokenCategory.noun;
    if (pos.contains('counter')) return TokenCategory.counter;
    if (pos.contains('numeric')) return TokenCategory.number;
    if (pos.contains('prefix')) return TokenCategory.prefix;
    if (pos.contains('suffix')) return TokenCategory.suffix;
    if (pos.contains('expression')) return TokenCategory.expression;
    return TokenCategory.noun;
  }
}
