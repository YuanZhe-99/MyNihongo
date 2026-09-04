import '../../kana/models/kana_text.dart';
import '../models/function_word.dart';
import '../models/token.dart';
import 'deinflector.dart';
import 'lexicon.dart';

/// One candidate reading of a span, with what it would cost.
class _Edge {
  const _Edge({required this.tokens, required this.end, required this.cost});

  /// The tokens this edge produces — more than one when an auxiliary and the
  /// stem it attached to were recovered together.
  final List<Token> tokens;

  /// Where the edge ends in the normalized text, exclusive.
  final int end;

  /// Where it starts. **Not always the position it was proposed from:** an
  /// auxiliary is proposed where the auxiliary is, but the edge covers the stem
  /// before it too, so the shortest path has to relax from the stem.
  int get start => tokens.first.start;

  /// What taking this edge costs. Lower is better.
  final int cost;
}

/// Splits Japanese text into tokens, with a lattice and a shortest path.
///
/// Japanese has no spaces, so segmentation is a search rather than a split.
/// At every position the tokenizer proposes every reading it can — a catalog
/// word, a function word, an auxiliary plus the stem it de-inflects to, a
/// numeral run, a katakana run — gives each a cost, and takes the cheapest
/// path through the whole sentence.
///
/// **Why a lattice rather than greedy longest-match.** Greedy is wrong on
/// sentences the catalog's own N5 examples contain: ここではなしてはいけません
/// splits as ここ/で/はなして or ここ/では/なして depending on what follows, and
/// a left-to-right pass cannot know. Costs also make the tie-breaks explicit
/// and testable instead of hiding them in the order of a loop.
///
/// The derivation of the cost table is in
/// `doc/en-us/algorithms/sentence-analysis.md`.
class Tokenizer {
  Tokenizer(this._lexicon) : _deinflector = Deinflector(_lexicon);

  final Lexicon _lexicon;
  final Deinflector _deinflector;

  // ── Costs ──
  //
  // Integers, and small: what matters is the order, and integers keep the
  // comparison exact so a fixture cannot drift on a rounding change.

  /// A word the catalog knows. The cheapest thing there is.
  static const _costVocab = 10;

  /// A function word. Cheaper than a catalog word, because a surface that is
  /// both — は, に, から — is the function word far more often.
  static const _costFunctionWord = 8;

  /// Per auxiliary recovered with a stem, on top of the stem's own cost.
  static const _costPerAuxiliary = 2;

  /// A run of digits or kanji numerals.
  static const _costNumber = 6;

  /// Taking a counter straight after a number is a discount, not a cost.
  static const _bonusCounterAfterNumber = -3;

  /// A katakana run the catalog does not know: a loanword or a name. Not free,
  /// so a known word always wins, but far cheaper than an unknown kanji.
  static const _costKatakana = 15;

  /// A single character nothing explained. Deliberately expensive.
  static const _costUnknownKanji = 40;
  static const _costUnknownKana = 30;

  /// A word usually written in kanji, found spelled in kana. Weaker than the
  /// same word written as it normally is: ます is 増す's reading, and reading
  /// it that way in 勉強しています would cost the sentence its verb.
  static const _penaltyViaReading = 4;

  /// A counter with no number in front of it. 本 is both a book and the
  /// counter for long thin things, and without a number the book is meant.
  static const _penaltyBareCounter = 5;

  /// A word the catalog does not mark common.
  ///
  /// 殊に, 生かす, がる and よって are all real words, and all of them are what
  /// ことに, かしら, たがる and によって look like to a lattice that weighs every
  /// entry the same. Charging a rare word more is what lets the ordinary
  /// reading win: the penalty is large enough to lose to a function word plus
  /// a particle, and small enough that a rare word still beats an unknown
  /// kanji by a wide margin. Found by the N4 authoring batches, every one of
  /// which tripped over it.
  static const _penaltyRareWord = 7;

  /// A masu-stem with no auxiliary behind it, used as a noun. Above a real
  /// catalog word, so one is never displaced by a stem that happens to fit.
  static const _costBareStem = 14;

  /// Punctuation and the spaces a learner may type between words.
  static const _costPunctuation = 1;

  /// Purpose: Split text into tokens.
  /// Inputs: `text` — as the learner typed it.
  /// Returns: `List<Token>`, in order, with offsets into the normalized text.
  /// Side effects: None.
  /// Notes: The text is width-normalized first (see [normalize]) but **not**
  /// converted to hiragana: the tokens have to carry the characters the
  /// learner wrote, and a kanji sentence read as kana would lose every word
  /// boundary the kanji provide.
  List<Token> tokenize(String text) {
    final input = normalize(text);
    if (input.isEmpty) return const [];

    // Shortest path by dynamic programming. `best[i]` is the cheapest way to
    // reach position i; `from[i]` is the edge that got there.
    final best = List<int>.filled(input.length + 1, 1 << 30);
    final from = List<_Edge?>.filled(input.length + 1, null);
    best[0] = 0;

    for (var i = 0; i < input.length; i++) {
      if (best[i] == 1 << 30) continue;
      for (final edge in _edgesAt(input, i, from[i])) {
        if (best[edge.start] == 1 << 30) continue;
        final total = best[edge.start] + edge.cost;
        if (total < best[edge.end]) {
          best[edge.end] = total;
          from[edge.end] = edge;
        }
      }
    }

    // Walk the path back, then reverse it.
    final tokens = <Token>[];
    var position = input.length;
    while (position > 0) {
      final edge = from[position];
      if (edge == null) break;
      tokens.insertAll(0, edge.tokens);
      position = edge.tokens.first.start;
    }
    return tokens;
  }

  /// Purpose: Put text into the shape the tokenizer indexes on.
  /// Inputs: `text`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Full-width ASCII becomes ASCII and half-width katakana becomes
  /// full-width, so a learner's input method cannot change the answer. Kana
  /// and kanji are otherwise untouched: unlike pronunciation scoring, the
  /// analyser needs the script it was given.
  static String normalize(String text) {
    final out = StringBuffer();
    for (final rune in text.runes) {
      if (rune >= 0xFF01 && rune <= 0xFF5E) {
        out.writeCharCode(rune - 0xFEE0);
      } else if (rune == 0x3000) {
        out.write(' ');
      } else {
        out.writeCharCode(rune);
      }
    }
    return out.toString().trim();
  }

  /// Purpose: Propose every reading of the text starting at one position.
  /// Inputs: `input`, the position `i`, and the edge that reached it.
  /// Returns: `List<_Edge>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Ordered from most to
  /// least specific only for readability; the search does not depend on the
  /// order, because equal costs are broken by the loop's `<` comparison, which
  /// keeps whichever was proposed first.
  List<_Edge> _edgesAt(String input, int i, _Edge? incoming) {
    final edges = <_Edge>[];
    final maxLength = _lexicon.maxKeyLength < input.length - i
        ? _lexicon.maxKeyLength
        : input.length - i;

    for (var length = maxLength; length >= 1; length--) {
      final surface = input.substring(i, i + length);
      final end = i + length;

      // Function words first: they are what a bare は or に almost always is.
      for (final word in _lexicon.functionWordsAt(surface)) {
        if (word.needs == StemShape.any) {
          edges.add(
            _Edge(
              tokens: [_functionWordToken(word, surface, i, end)],
              end: end,
              cost: _costFunctionWord,
            ),
          );
        } else {
          edges.addAll(_stemEdges(input, i, end, word, surface));
        }
      }

      // Catalog words.
      for (final entry in _lexicon.entriesAt(surface)) {
        edges.add(
          _Edge(
            tokens: [
              Token(
                surface: surface,
                reading: entry.reading,
                lemma: entry.lemma,
                category: entry.category,
                pos: entry.pos,
                refId: entry.vocabId,
                start: i,
                end: end,
              ),
            ],
            end: end,
            cost: _costVocab + _entryPenalty(entry, incoming),
          ),
        );
      }
    }

    // A masu-stem used as a noun: 食べに行く, 話し方. Priced above a real word,
    // so a catalog entry always wins, but far below leaving the characters
    // unexplained.
    for (var length = 1; length <= 4 && i + length <= input.length; length++) {
      final surface = input.substring(i, i + length);
      for (final candidate in _deinflector.stemsFor(
        surface,
        StemShape.masuStem,
      )) {
        edges.add(
          _Edge(
            tokens: [
              Token(
                surface: surface,
                reading: candidate.entry.reading,
                lemma: candidate.entry.lemma,
                category: candidate.entry.category,
                pos: candidate.entry.pos,
                refId: candidate.entry.vocabId,
                forms: const [InflectionForm.masuStem],
                start: i,
                end: i + length,
              ),
            ],
            end: i + length,
            cost: _costBareStem,
          ),
        );
      }
    }

    // Runs: numbers, katakana, punctuation. Each is one edge, as long as it
    // can be, so a five-digit number is one token and not five.
    final numberEnd = _runEnd(input, i, _isNumeral);
    if (numberEnd > i) {
      edges.add(
        _Edge(
          tokens: [
            Token(
              surface: input.substring(i, numberEnd),
              reading: input.substring(i, numberEnd),
              lemma: input.substring(i, numberEnd),
              category: TokenCategory.number,
              start: i,
              end: numberEnd,
            ),
          ],
          end: numberEnd,
          cost: _costNumber,
        ),
      );
    }

    final katakanaEnd = _runEnd(input, i, _isKatakana);
    if (katakanaEnd > i) {
      final surface = input.substring(i, katakanaEnd);
      edges.add(
        _Edge(
          tokens: [
            Token(
              surface: surface,
              reading: toHiragana(surface),
              lemma: surface,
              category: TokenCategory.katakanaUnknown,
              start: i,
              end: katakanaEnd,
            ),
          ],
          end: katakanaEnd,
          cost: _costKatakana,
        ),
      );
    }

    final char = input[i];
    if (_isPunctuation(char) || char == ' ') {
      edges.add(
        _Edge(
          tokens: [
            Token(
              surface: char,
              reading: char,
              lemma: char,
              category: TokenCategory.punctuation,
              start: i,
              end: i + 1,
            ),
          ],
          end: i + 1,
          cost: _costPunctuation,
        ),
      );
    }

    // Last resort, so the path always reaches the end.
    edges.add(
      _Edge(
        tokens: [
          Token(
            surface: char,
            reading: char,
            lemma: char,
            category: TokenCategory.unknown,
            start: i,
            end: i + 1,
          ),
        ],
        end: i + 1,
        cost: _isKana(char) ? _costUnknownKana : _costUnknownKanji,
      ),
    );
    return edges;
  }

  /// Purpose: Price one catalog candidate against its context.
  /// Inputs: The `entry` and the edge that reached this position.
  /// Returns: The penalty to add to the base word cost.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Three adjustments,
  /// each one a case the plain "a word costs ten" rule gets wrong:
  /// a counter straight after a number is what a counter is for and is
  /// discounted; a counter with no number is almost always the homographic
  /// noun; and a word found through its kana reading, where it is normally
  /// written in kanji, is a weaker candidate than one found as written.
  static int _entryPenalty(LexEntry entry, _Edge? incoming) {
    var penalty = 0;
    if (entry.category == TokenCategory.counter) {
      penalty += incoming?.tokens.last.category == TokenCategory.number
          ? _bonusCounterAfterNumber
          : _penaltyBareCounter;
    }
    if (entry.viaReading) penalty += _penaltyViaReading;
    if (!entry.common) penalty += _penaltyRareWord;
    return penalty;
  }

  /// Purpose: Propose an auxiliary together with the stem before it.
  /// Inputs: `input`, the auxiliary's `start` and `end`, the `word` itself and
  /// its `surface`.
  /// Returns: `List<_Edge>` — one per word the stem could have come from.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. **This is where
  /// de-inflection happens.** An auxiliary is only proposed together with a
  /// real word it could attach to, so ます after a noun is never taken, and
  /// 食べます arrives as two tokens that already know 食べる is the lemma. The
  /// edge starts at the stem, not at the auxiliary, which is what lets the
  /// shortest path weigh the whole verb against the alternatives.
  List<_Edge> _stemEdges(
    String input,
    int start,
    int end,
    FunctionWord word,
    String surface,
  ) {
    final edges = <_Edge>[];
    // The stem is what precedes the auxiliary. Try every length backwards,
    // longest first; the lexicon rejects everything that is not a word.
    for (var stemLength = 1; stemLength <= start; stemLength++) {
      final stemStart = start - stemLength;
      final stem = input.substring(stemStart, start);
      final candidates = _deinflector.stemsFor(stem, word.needs);
      for (final candidate in candidates) {
        edges.add(
          _Edge(
            tokens: [
              Token(
                surface: candidate.surface,
                reading: candidate.entry.reading,
                lemma: candidate.entry.lemma,
                category: candidate.entry.category,
                pos: candidate.entry.pos,
                refId: candidate.entry.vocabId,
                forms: _stemForm(word.needs),
                start: stemStart,
                end: start,
              ),
              _functionWordToken(word, surface, start, end),
            ],
            end: end,
            cost:
                _costVocab +
                _costPerAuxiliary +
                (candidate.entry.common ? 0 : _penaltyRareWord),
          ),
        );
      }
    }
    return edges;
  }

  /// Purpose: Name the stem shape as a form, for the token's form chain.
  /// Inputs: `shape`.
  /// Returns: `List<InflectionForm>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  static List<InflectionForm> _stemForm(StemShape shape) => switch (shape) {
    StemShape.masuStem => const [InflectionForm.masuStem],
    StemShape.naiStem => const [InflectionForm.naiStem],
    StemShape.teStem || StemShape.teStemVoiced => const [InflectionForm.teStem],
    StemShape.eStem => const [InflectionForm.eStem],
    _ => const [],
  };

  /// Purpose: Build the token for a function word.
  /// Inputs: `word`, its `surface`, and the span.
  /// Returns: `Token`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  static Token _functionWordToken(
    FunctionWord word,
    String surface,
    int start,
    int end,
  ) => Token(
    surface: surface,
    reading: word.reading,
    lemma: word.lemma,
    category: word.tokenCategory,
    forms: word.forms,
    refId: word.id,
    gloss: word.gloss,
    start: start,
    end: end,
  );

  /// Purpose: Find how far a run of one character class extends.
  /// Inputs: `input`, the start `i`, and the `test`.
  /// Returns: The end index, exclusive; equal to `i` when the first character
  /// fails the test.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  static int _runEnd(String input, int i, bool Function(String) test) {
    var end = i;
    while (end < input.length && test(input[end])) {
      end++;
    }
    return end;
  }

  /// Purpose: Report whether a character is a digit or a kanji numeral.
  /// Inputs: `char`.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  static bool _isNumeral(String char) =>
      (char.codeUnitAt(0) >= 0x30 && char.codeUnitAt(0) <= 0x39) ||
      '〇一二三四五六七八九十百千万'.contains(char);

  /// Purpose: Report whether a character is katakana.
  /// Inputs: `char`.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The long-vowel mark is
  /// included, so コーヒー is one run.
  static bool _isKatakana(String char) {
    final code = char.codeUnitAt(0);
    return (code >= 0x30A1 && code <= 0x30F6) || char == 'ー';
  }

  /// Purpose: Report whether a character is kana of either script.
  /// Inputs: `char`.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Used only to price an
  /// unknown character: an unreadable kanji is a bigger gap than an unreadable
  /// kana, because the kana was probably part of a word the catalog has.
  static bool _isKana(String char) {
    final code = char.codeUnitAt(0);
    return (code >= 0x3041 && code <= 0x309F) ||
        (code >= 0x30A1 && code <= 0x30FF);
  }

  /// Purpose: Report whether a character is punctuation.
  /// Inputs: `char`.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. 。！？ also end a
  /// clause; the chunker reads that from the token, not from here.
  static bool _isPunctuation(String char) =>
      '。、．，・？！?!「」『』（）()"\'“”‘’…〜~-'.contains(char);
}
