/// Aligns a kanji surface with its kana reading so the reading can be printed
/// over the characters it belongs to.
///
/// The content carries one reading per word and one per sentence, never a
/// per-character mapping — see `doc/en-us/data-formats.md`. This file recovers
/// the mapping from the two strings alone, and says so honestly when it cannot:
/// a wrong alignment prints the wrong kana over the wrong kanji, which teaches
/// something false, so every function here returns null rather than guessing.
library;

import '../../kana/models/kana_text.dart';
import '../../sentence/models/token.dart';

/// One run of the surface, with the reading that belongs to it.
class FuriganaSegment {
  /// Purpose: Hold one run of surface characters and its reading.
  /// Inputs: `text`, `reading`, and the code-unit ranges both came from.
  /// Returns: A new `FuriganaSegment` instance.
  /// Side effects: None.
  /// Notes: `reading` is null for a run that already reads itself — kana,
  /// punctuation, spaces — which is what tells the widget not to print ruby
  /// over it.
  const FuriganaSegment({
    required this.text,
    required this.surfaceStart,
    required this.surfaceEnd,
    required this.readingStart,
    required this.readingEnd,
    this.reading,
  });

  /// The characters as they appear in the surface.
  final String text;

  /// The kana to print above [text], or null when there are none to print.
  final String? reading;

  /// Where [text] starts in the surface, in code units.
  final int surfaceStart;

  /// Where [text] ends in the surface, exclusive.
  final int surfaceEnd;

  /// Where this run's kana start in the reading, in code units.
  final int readingStart;

  /// Where this run's kana end in the reading, exclusive.
  final int readingEnd;

  /// Whether this run needs ruby printed over it.
  bool get isRuby => reading != null;

  @override
  String toString() => reading == null ? text : '$text[$reading]';
}

/// Purpose: Decide whether a character reads itself.
/// Inputs: `code` — one UTF-16 code unit.
/// Returns: `bool`.
/// Side effects: None.
/// Notes: Internal helper used within this file only. Kana, the long-vowel
/// mark, punctuation, spaces and the quiz's own blank all read themselves and
/// so anchor the alignment. Everything else — kanji, digits, Latin letters,
/// the repeat marks, an unpaired surrogate — is something a reading has to
/// supply kana for.
bool _readsItself(int code) {
  // Hiragana, katakana, the prolonged sound mark and the kana marks.
  if (code >= 0x3040 && code <= 0x30FF) return true;
  // Halfwidth katakana, which a hand-edited file may still contain.
  if (code >= 0xFF66 && code <= 0xFF9F) return true;
  // CJK punctuation, minus 々 (3005), 〆 (3006) and 〇 (3007), which are read.
  if (code >= 0x3000 && code <= 0x3004) return true;
  if (code >= 0x3008 && code <= 0x303F) return true;
  // Fullwidth punctuation, minus the fullwidth digits, which are read.
  if (code >= 0xFF01 && code <= 0xFF0F) return true;
  if (code >= 0xFF1A && code <= 0xFF20) return true;
  if (code >= 0xFF3B && code <= 0xFF40) return true;
  if (code >= 0xFF5B && code <= 0xFF65) return true;
  final char = String.fromCharCode(code);
  if (char.trim().isEmpty) return true;
  return '。、，．・？！?!"\'()[]{}<>:;,.-–—…〜~＿'.contains(char);
}

/// Purpose: Reduce one character to the form the reading would spell it in.
/// Inputs: `code`.
/// Returns: `int` — the folded code unit.
/// Side effects: None.
/// Notes: Internal helper used within this file only. Only katakana are folded,
/// and only onto hiragana. This is deliberately **not** [toHiragana], which
/// drops punctuation and rewrites the long-vowel mark: an aligner has to keep
/// every character, because it is matching positions and not sounds.
int _fold(int code) {
  if (code >= 0x30A1 && code <= 0x30F6) return code - 0x60;
  return code;
}

/// One run of the surface before a reading has been attached to it.
typedef _Run = ({int start, int end, bool ruby});

/// Purpose: Split a surface into runs that need a reading and runs that do not.
/// Inputs: `surface`.
/// Returns: `List<_Run>` in order.
/// Side effects: None.
/// Notes: Internal helper used within this file only. Adjacent characters of
/// the same kind form one run, so 東京 asks for one reading rather than two —
/// which is the only granularity the content supports. Per-character furigana
/// would need a per-character mapping the catalog does not have.
List<_Run> _runs(String surface) {
  final runs = <_Run>[];
  var start = 0;
  bool? kind;
  for (var i = 0; i < surface.length; i++) {
    final ruby = !_readsItself(surface.codeUnitAt(i));
    if (kind == null) {
      kind = ruby;
      continue;
    }
    if (ruby != kind) {
      runs.add((start: start, end: i, ruby: kind));
      start = i;
      kind = ruby;
    }
  }
  if (kind != null) runs.add((start: start, end: surface.length, ruby: kind));
  return runs;
}

/// Purpose: Attach a reading to every run of a surface.
/// Inputs: `surface` — the word or sentence as written; `reading` — its kana.
/// Returns: `List<FuriganaSegment>?` — null when no alignment fits.
/// Side effects: None.
/// Notes: The kana runs of the surface are anchors: each must appear, in
/// order, at exactly the point the reading has reached, and everything between
/// two anchors belongs to the kanji between them. Kanji runs are tried
/// **shortest first** and the search backtracks until the whole reading is
/// consumed, which is what separates 母は/ははは (母 = はは) from 花は/はなは
/// (花 = はな). A surface with no kanji aligns trivially; a reading that does
/// not fit at all returns null, and every caller then falls back to printing
/// the reading on its own line.
List<FuriganaSegment>? alignFurigana(String surface, String? reading) {
  if (surface.isEmpty) return null;
  final runs = _runs(surface);
  if (!runs.any((r) => r.ruby)) {
    return [
      FuriganaSegment(
        text: surface,
        surfaceStart: 0,
        surfaceEnd: surface.length,
        readingStart: 0,
        readingEnd: 0,
      ),
    ];
  }
  if (reading == null || reading.isEmpty) return null;

  final out = List<FuriganaSegment?>.filled(runs.length, null);
  // Without this, a sentence with a dozen kanji runs is exponential: each run
  // that fails is retried for every earlier run's next guess. The state that
  // decides the rest of the search is only (which run, how far into the
  // reading), so a failure at one pair can never succeed at it later.
  final dead = <int>{};
  return _match(surface, reading, runs, 0, 0, out, dead)
      ? [for (final segment in out) segment!]
      : null;
}

/// Purpose: Place run `index` and everything after it.
/// Inputs: The two strings, the runs, the run `index`, the position `at`
/// reached in the reading, and `out` to fill.
/// Returns: `bool` — whether an alignment was found.
/// Side effects: Fills `out`.
/// Notes: Internal helper used within this file only. A kanji run is given at
/// least one kana per character, because no reading is shorter than the
/// characters it covers, and at most whatever the runs after it can still
/// leave. `dead` remembers the (run, position) pairs already shown to fail,
/// which is what turns a search that is exponential in the number of kanji
/// runs into one bounded by runs × reading length — the difference between a
/// word and a sentence with a dozen of them.
bool _match(
  String surface,
  String reading,
  List<_Run> runs,
  int index,
  int at,
  List<FuriganaSegment?> out,
  Set<int> dead,
) {
  if (index == runs.length) return at == reading.length;
  final state = index * (reading.length + 1) + at;
  if (dead.contains(state)) return false;
  final run = runs[index];
  final text = surface.substring(run.start, run.end);

  if (!run.ruby) {
    if (at + text.length > reading.length) return false;
    for (var i = 0; i < text.length; i++) {
      if (_fold(reading.codeUnitAt(at + i)) != _fold(text.codeUnitAt(i))) {
        return false;
      }
    }
    out[index] = FuriganaSegment(
      text: text,
      surfaceStart: run.start,
      surfaceEnd: run.end,
      readingStart: at,
      readingEnd: at + text.length,
    );
    if (_match(
      surface,
      reading,
      runs,
      index + 1,
      at + text.length,
      out,
      dead,
    )) {
      return true;
    }
    out[index] = null;
    dead.add(state);
    return false;
  }

  var rest = 0;
  for (var i = index + 1; i < runs.length; i++) {
    rest += runs[i].end - runs[i].start;
  }
  final most = reading.length - at - rest;
  for (var take = text.length; take <= most; take++) {
    out[index] = FuriganaSegment(
      text: text,
      reading: reading.substring(at, at + take),
      surfaceStart: run.start,
      surfaceEnd: run.end,
      readingStart: at,
      readingEnd: at + take,
    );
    if (_match(surface, reading, runs, index + 1, at + take, out, dead)) {
      return true;
    }
  }
  out[index] = null;
  dead.add(state);
  return false;
}

/// Purpose: Find the kana that belong to one span of the surface.
/// Inputs: The aligned `segments`, and `start`/`end` code-unit offsets into the
/// surface they were built from.
/// Returns: `({int start, int end})?` — the matching span of the reading, or
/// null when the span cuts a kanji run in half.
/// Side effects: None.
/// Notes: Used to blank the same word out of both the sentence and its reading,
/// so a fill-in-the-blank question can be shown with furigana. A span that ends
/// inside 東京 has no answer — half of とうきょう is not the reading of 東 —
/// and the caller shows the question without ruby rather than with a guess.
({int start, int end})? readingRangeFor(
  List<FuriganaSegment> segments,
  int start,
  int end,
) {
  if (start > end) return null;
  int? from;
  int? to;
  for (final segment in segments) {
    if (segment.surfaceStart == start) from ??= segment.readingStart;
    if (segment.surfaceEnd == end) to = segment.readingEnd;
    if (!segment.isRuby) {
      // A kana run maps one code unit to one, so a span may start or end
      // anywhere inside it.
      if (start > segment.surfaceStart && start < segment.surfaceEnd) {
        from ??= segment.readingStart + (start - segment.surfaceStart);
      }
      if (end > segment.surfaceStart && end < segment.surfaceEnd) {
        to = segment.readingStart + (end - segment.surfaceStart);
      }
    }
  }
  if (from == null || to == null || to < from) return null;
  return (start: from, end: to);
}

/// Purpose: Work out how one analysed token is read as it stands in the
/// sentence, rather than how its dictionary form is read.
/// Inputs: `token`.
/// Returns: `String?` — the reading of `token.surface`, or null when it cannot
/// be recovered.
/// Side effects: None.
/// Notes: `Token.reading` is the **dictionary form's** reading — 食べ carries
/// たべる — because that is what the lexicon stores and what de-inflection
/// needs. Printing たべる over 食べ would be wrong, so the kanji part is taken
/// from the lemma's own alignment and the kana tail is taken from the surface
/// as written. 来る is the one word whose kanji changes reading as it inflects
/// (き, こ, く), and it is special-cased rather than mis-printed.
String? surfaceReadingOfToken(Token token) {
  final surface = token.surface;
  if (surface.isEmpty) return null;
  final runs = _runs(surface);
  if (!runs.any((r) => r.ruby)) return null;

  if (token.forms.isEmpty && token.lemma == surface) {
    return alignFurigana(surface, token.reading) == null ? null : token.reading;
  }

  final lemma = alignFurigana(token.lemma, token.reading);
  if (lemma == null) return null;

  final out = StringBuffer();
  var consumed = 0;
  for (final segment in lemma) {
    if (consumed >= surface.length) break;
    if (!segment.isRuby) break;
    if (segment.surfaceEnd > surface.length ||
        surface.substring(segment.surfaceStart, segment.surfaceEnd) !=
            segment.text) {
      return null;
    }
    var reading = segment.reading!;
    if (token.lemma == '来る' && segment.text == '来') {
      final kuru = _kuruStem(token, surface, segment.surfaceEnd);
      if (kuru == null) return null;
      reading = kuru;
    }
    out.write(reading);
    consumed = segment.surfaceEnd;
  }
  if (consumed == 0) return null;
  out.write(surface.substring(consumed));
  final result = out.toString();
  return alignFurigana(surface, result) == null ? null : result;
}

/// Purpose: Read the kanji of 来る for the form the token is in.
/// Inputs: `token`, the `surface` as written, and where 来 ends in it.
/// Returns: `String?` — き, こ or く, or null when the form does not say.
/// Side effects: None.
/// Notes: Internal helper used within this file only. 来る is the one common
/// word whose kanji changes reading as it inflects, and the kana that would
/// disambiguate it are usually in the next token: 来ます is split into 来 and
/// ます. So the answer comes from the recovered forms, and a chain that does
/// not decide it returns null — a chip with no ruby is better than 来 read as
/// く when the learner is about to say きます.
String? _kuruStem(Token token, String surface, int after) {
  final tail = surface.length > after ? surface.substring(after) : '';
  if (tail.startsWith('る') || tail.startsWith('れ')) return 'く';
  if (tail.startsWith('な') || tail.startsWith('ら') || tail.startsWith('さ')) {
    return 'こ';
  }
  if (tail.startsWith('い') || tail.startsWith('よ')) return 'こ';
  if (tail.startsWith('て') || tail.startsWith('た') || tail.startsWith('ま')) {
    return 'き';
  }
  if (tail.isNotEmpty) return null;
  for (final form in token.forms) {
    switch (form) {
      case InflectionForm.negative:
      case InflectionForm.naiStem:
      case InflectionForm.passive:
      case InflectionForm.causative:
      case InflectionForm.potential:
      case InflectionForm.volitional:
        return 'こ';
      case InflectionForm.masuStem:
      case InflectionForm.polite:
      case InflectionForm.te:
      case InflectionForm.teStem:
      case InflectionForm.past:
      case InflectionForm.tai:
      case InflectionForm.tari:
      case InflectionForm.nagara:
      case InflectionForm.request:
      case InflectionForm.progressive:
      case InflectionForm.conditionalTara:
        return 'き';
      case InflectionForm.imperative:
        return 'こ';
      case InflectionForm.dictionary:
      case InflectionForm.attributive:
      case InflectionForm.conditionalBa:
      case InflectionForm.eStem:
        return 'く';
      default:
        continue;
    }
  }
  return token.forms.isEmpty ? 'く' : null;
}
