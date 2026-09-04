import '../models/function_word.dart';
import 'godan_rows.dart';
import 'lexicon.dart';

/// One conjugable word recovered from an inflected stem.
class DeinflectedStem {
  const DeinflectedStem({required this.entry, required this.surface});

  /// The catalog entry the stem came from.
  final LexEntry entry;

  /// The inflected stem as it was written, so the token keeps the text the
  /// learner typed rather than the dictionary form.
  final String surface;
}

/// Turns an inflected stem back into the word it came from.
///
/// This is the second stage of de-inflection. The lattice has already found an
/// auxiliary — ます, ない, た, て, ば — and each auxiliary declares the
/// [StemShape] it attaches to. Given that shape and the characters before it,
/// this answers which catalog entries could have produced them.
///
/// Running backwards is what makes the tables small. Forwards, every class has
/// a dozen forms; backwards, each shape is one row transformation per class,
/// and the lexicon rejects everything that is not a real word.
class Deinflector {
  const Deinflector(this._lexicon);

  final Lexicon _lexicon;

  /// Purpose: Find the words an inflected stem could have come from.
  /// Inputs: `stem` — the characters before an auxiliary; `shape` — what that
  /// auxiliary attaches to.
  /// Returns: `List<DeinflectedStem>`; empty when nothing fits.
  /// Side effects: None.
  /// Notes: Every candidate is confirmed against the lexicon, so a shape that
  /// could in principle have produced a word only survives when that word
  /// actually exists. 飲ん under `teStemVoiced` proposes 飲ぬ, 飲ぶ and 飲む;
  /// only 飲む is in the catalog.
  List<DeinflectedStem> stemsFor(String stem, StemShape shape) {
    if (stem.isEmpty) return const [];
    final out = <DeinflectedStem>[];
    void accept(String lemmaGuess, Set<ConjClass> classes) {
      for (final entry in _lexicon.conjugablesForStem(
        lemmaGuess.substring(0, lemmaGuess.length - 1),
      )) {
        if (!classes.contains(entry.conj)) continue;
        if (out.any((s) => s.entry.vocabId == entry.vocabId)) continue;
        out.add(DeinflectedStem(entry: entry, surface: stem));
      }
    }

    switch (shape) {
      case StemShape.masuStem:
        // 食べ → 食べる (ichidan); 行き → 行く (godan, i-row → u-row).
        accept('$stemる', _ichidanOnly);
        _godanFromRow(stem, godanIRow, accept);
        _acceptIrregular(stem, out, masu: true);
      case StemShape.naiStem:
        // 食べ → 食べる; 行か → 行く (a-row → u-row), with わ → う.
        accept('$stemる', _ichidanOnly);
        _godanFromRow(stem, godanARow, accept);
        _acceptIrregular(stem, out, nai: true);
      case StemShape.teStem:
        // 食べ → 食べる; 行っ → 行く/言う/待つ/取る; 話し → 話す.
        accept('$stemる', _ichidanOnly);
        _teStemGodan(stem, voiced: false, accept: accept);
        _acceptIrregular(stem, out, te: true);
      case StemShape.teStemVoiced:
        _teStemGodan(stem, voiced: true, accept: accept);
      case StemShape.adjectiveStem:
        return adjectiveStemsFor(stem);
      case StemShape.eStem:
        // 食べれ → 食べる; 行け → 行く (e-row → u-row).
        if (stem.endsWith('れ')) {
          accept('${stem.substring(0, stem.length - 1)}るる', _ichidanOnly);
        }
        _godanFromRow(stem, godanERow, accept);
      case StemShape.any:
      case StemShape.plain:
      case StemShape.dictionary:
      case StemShape.nominal:
        break;
    }
    return out;
  }

  /// Purpose: Recover an i-adjective from an inflected stem.
  /// Inputs: `stem` — the characters before く, かった, ければ and friends.
  /// Returns: `List<DeinflectedStem>`.
  /// Side effects: None.
  /// Notes: Adjectives are separate because their stem is the lemma minus い
  /// rather than minus a conjugating kana, and because いい conjugates from
  /// よ- — 良かった, not 良いかった.
  List<DeinflectedStem> adjectiveStemsFor(String stem) {
    final out = <DeinflectedStem>[];
    for (final entry in _lexicon.conjugablesForStem(stem)) {
      if (entry.conj == ConjClass.iAdjective ||
          entry.conj == ConjClass.iiAdjective) {
        out.add(DeinflectedStem(entry: entry, surface: stem));
      }
    }
    // よ- is いい's inflecting stem, and the lexicon indexes it under い-.
    if (stem.endsWith('よ')) {
      for (final entry in _lexicon.conjugablesForStem('い')) {
        if (entry.conj == ConjClass.iiAdjective) {
          out.add(DeinflectedStem(entry: entry, surface: stem));
        }
      }
    }
    return out;
  }

  /// The classes an ichidan guess may resolve to.
  static const _ichidanOnly = {ConjClass.ichidan};

  /// Purpose: Propose godan lemmas for a stem ending in a known row.
  /// Inputs: `stem`, the `row` table, and the `accept` sink.
  /// Returns: None.
  /// Side effects: Calls `accept` for each class whose row kana matches.
  /// Notes: Internal helper used within this file only. Several classes can
  /// share a row kana in principle; the lexicon is what rejects the ones that
  /// are not words.
  static void _godanFromRow(
    String stem,
    Map<ConjClass, String> row,
    void Function(String, Set<ConjClass>) accept,
  ) {
    if (stem.isEmpty) return;
    final last = stem[stem.length - 1];
    final head = stem.substring(0, stem.length - 1);
    for (final entry in row.entries) {
      if (entry.value != last) continue;
      accept('$head${godanURow[entry.key]}', {entry.key});
    }
  }

  /// Purpose: Propose godan lemmas for a te-stem, which is the irregular one.
  /// Inputs: `stem`, whether the auxiliary was `voiced` (で/だ), and `accept`.
  /// Returns: None.
  /// Side effects: Calls `accept`.
  /// Notes: Internal helper used within this file only. The te-stem is where
  /// godan verbs stop being regular: う, つ and る all become っ, ぬ, ぶ and む
  /// all become ん, ぐ becomes い, and く becomes い too except for 行く, whose
  /// て-form is 行って. Proposing all of them and letting the lexicon reject
  /// the non-words is both shorter and more honest than encoding exceptions.
  static void _teStemGodan(
    String stem, {
    required bool voiced,
    required void Function(String, Set<ConjClass>) accept,
  }) {
    if (stem.isEmpty) return;
    final last = stem[stem.length - 1];
    final head = stem.substring(0, stem.length - 1);
    if (!voiced) {
      if (last == 'っ') {
        accept('$headう', {ConjClass.godanU});
        accept('$headつ', {ConjClass.godanTsu});
        accept('$headる', {ConjClass.godanRu});
        accept('$headく', {ConjClass.godanKu}); // 行って
      } else if (last == 'し') {
        accept('$headす', {ConjClass.godanSu});
      } else if (last == 'い') {
        accept('$headく', {ConjClass.godanKu});
      }
    } else {
      if (last == 'ん') {
        accept('$headぬ', {ConjClass.godanNu});
        accept('$headぶ', {ConjClass.godanBu});
        accept('$headむ', {ConjClass.godanMu});
      } else if (last == 'い') {
        accept('$headぐ', {ConjClass.godanGu});
      }
    }
  }

  /// The stems 来る takes, by shape. Both spellings are listed because a
  /// learner may write either, and the reading differs from the surface in
  /// every one of them.
  static const _kuruStems = {
    'masu': ['き', '来'],
    'nai': ['こ', '来'],
    'te': ['き', '来'],
  };

  /// Purpose: Accept する and 来る, which no row table describes.
  /// Inputs: `stem`, the `out` sink, and which shape is being resolved.
  /// Returns: None.
  /// Side effects: Appends to `out`.
  /// Notes: Internal helper used within this file only. する's masu- and
  /// te-stem is し and its nai-stem is し too; 来る's are written above, in both
  /// spellings, because a learner may write either and the reading differs
  /// from the surface in every one of them.
  ///
  /// The stem must match **exactly**. An earlier version tested `endsWith`,
  /// and 映画を見まし then de-inflected to する — one edge swallowing half the
  /// sentence at the price of one verb, which the shortest path duly preferred.
  /// A noun tagged `suru-verb` followed by し is rejoined by the chunker
  /// instead: the catalog has 勉強, not 勉強する.
  void _acceptIrregular(
    String stem,
    List<DeinflectedStem> out, {
    bool masu = false,
    bool nai = false,
    bool te = false,
  }) {
    void add(String lemmaReading) {
      for (final entry in _lexicon.entriesAt(lemmaReading)) {
        if (entry.conj != ConjClass.suru && entry.conj != ConjClass.kuru) {
          continue;
        }
        if (out.any((s) => s.entry.vocabId == entry.vocabId)) continue;
        out.add(DeinflectedStem(entry: entry, surface: stem));
      }
    }

    if (stem == 'し') {
      add('する');
    }
    final kuruKey = masu || te ? 'masu' : (nai ? 'nai' : null);
    if (kuruKey != null && (_kuruStems[kuruKey] ?? const []).contains(stem)) {
      add('くる');
      add('来る');
    }
  }
}
