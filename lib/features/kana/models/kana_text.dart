/// Purpose: Normalize Japanese text to comparable hiragana morae.
/// Inputs: Text from the content catalog and from a speech recognizer.
/// Returns: Hiragana strings and mora lists.
/// Side effects: None.
/// Notes: Written for the pronunciation scoring in
/// `doc/en-us/algorithms/pronunciation-scoring.md`, which has to compare what
/// the recognizer heard against what the item says. The two arrive in
/// different scripts and different widths — a recognizer answers in katakana
/// or kanji depending on the platform, the catalog stores hiragana readings —
/// so both sides are reduced to the same shape before anything is compared.
library;

/// The distance between a katakana code point and its hiragana twin.
const _kanaShift = 0x30A1 - 0x3041;

/// The small kana that attach to the mora before them rather than standing on
/// their own. `っ` and `ん` are deliberately absent: both are full morae, and
/// counting them is the point of counting morae at all.
const _smallKana = {'ゃ', 'ゅ', 'ょ', 'ぁ', 'ぃ', 'ぅ', 'ぇ', 'ぉ', 'ゎ', 'ヵ', 'ヶ'};

/// The vowel each hiragana ends on, for expanding the long-vowel mark.
const _vowelOf = <String, String>{
  'あ': 'あ',
  'か': 'あ',
  'さ': 'あ',
  'た': 'あ',
  'な': 'あ',
  'は': 'あ',
  'ま': 'あ',
  'や': 'あ',
  'ら': 'あ',
  'わ': 'あ',
  'が': 'あ',
  'ざ': 'あ',
  'だ': 'あ',
  'ば': 'あ',
  'ぱ': 'あ',
  'ゃ': 'あ',
  'ぁ': 'あ',
  'い': 'い',
  'き': 'い',
  'し': 'い',
  'ち': 'い',
  'に': 'い',
  'ひ': 'い',
  'み': 'い',
  'り': 'い',
  'ぎ': 'い',
  'じ': 'い',
  'ぢ': 'い',
  'び': 'い',
  'ぴ': 'い',
  'ぃ': 'い',
  'う': 'う',
  'く': 'う',
  'す': 'う',
  'つ': 'う',
  'ぬ': 'う',
  'ふ': 'う',
  'む': 'う',
  'ゆ': 'う',
  'る': 'う',
  'ぐ': 'う',
  'ず': 'う',
  'づ': 'う',
  'ぶ': 'う',
  'ぷ': 'う',
  'ゅ': 'う',
  'ぅ': 'う',
  'え': 'え',
  'け': 'え',
  'せ': 'え',
  'て': 'え',
  'ね': 'え',
  'へ': 'え',
  'め': 'え',
  'れ': 'え',
  'げ': 'え',
  'ぜ': 'え',
  'で': 'え',
  'べ': 'え',
  'ぺ': 'え',
  'ぇ': 'え',
  'お': 'お',
  'こ': 'お',
  'そ': 'お',
  'と': 'お',
  'の': 'お',
  'ほ': 'お',
  'も': 'お',
  'よ': 'お',
  'ろ': 'お',
  'を': 'お',
  'ご': 'お',
  'ぞ': 'お',
  'ど': 'お',
  'ぼ': 'お',
  'ぽ': 'お',
  'ょ': 'お',
  'ぉ': 'お',
};

/// Purpose: Reduce a Japanese string to bare hiragana.
/// Inputs: `text` — any mix of hiragana, katakana, kanji, ASCII and marks.
/// Returns: `String` — hiragana only.
/// Side effects: None.
/// Notes: Katakana become hiragana; the long-vowel mark `ー` becomes the vowel
/// of the mora before it; full-width ASCII becomes ASCII; whitespace and
/// punctuation, both Japanese and Western, are dropped. **Kanji are left as
/// they are** — this function cannot read them, and a caller that needs kana
/// for a kanji surface resolves it through the catalog first.
String toHiragana(String text) {
  final out = StringBuffer();
  for (final rune in text.runes) {
    var char = String.fromCharCode(rune);

    // Full-width ASCII to ASCII, so a recognizer's ＡＢＣ compares with ABC.
    if (rune >= 0xFF01 && rune <= 0xFF5E) {
      char = String.fromCharCode(rune - 0xFEE0);
    }

    if (char == 'ー' || char == '－' || char == '—') {
      final written = out.toString();
      final vowel = written.isEmpty ? null : _vowelOf[written.characters.last];
      if (vowel != null) out.write(vowel);
      continue;
    }

    // Katakana (excluding the marks handled above) to hiragana.
    final code = char.runes.first;
    if (code >= 0x30A1 && code <= 0x30F6) {
      out.write(String.fromCharCode(code - _kanaShift));
      continue;
    }

    if (_isDroppable(char)) continue;
    out.write(char);
  }
  return out.toString();
}

/// Purpose: Split hiragana into morae — the unit pronunciation is scored in.
/// Inputs: `hiragana` — output of [toHiragana].
/// Returns: `List<String>`; each entry is one mora.
/// Side effects: None.
/// Notes: A small kana joins the mora before it, so `きょ` is one mora and not
/// two. `っ` and `ん` stand alone, because a learner who drops either has made
/// exactly the mistake the score is meant to show. Anything that is not kana
/// — a kanji the caller could not resolve, a stray letter — becomes its own
/// entry rather than being dropped, so it still costs an edit.
List<String> splitMorae(String hiragana) {
  final morae = <String>[];
  for (final char in hiragana.characters) {
    if (morae.isNotEmpty && _smallKana.contains(char)) {
      morae[morae.length - 1] = '${morae.last}$char';
    } else {
      morae.add(char);
    }
  }
  return morae;
}

/// Purpose: Decide whether a character carries no pronunciation.
/// Inputs: `char`.
/// Returns: `bool`.
/// Side effects: None.
/// Notes: Internal helper used within this file only. Punctuation and spaces
/// are dropped rather than compared: a recognizer decides on its own whether
/// to punctuate, and that is not something the learner said.
bool _isDroppable(String char) {
  if (char.trim().isEmpty) return true;
  const marks = '。、．，・？！?!「」『』（）()"\'“”‘’…〜~-ー：；:;';
  return marks.contains(char);
}

/// A tiny grapheme walker, so this file needs no extra dependency.
extension _Characters on String {
  /// Purpose: Iterate the string one code point at a time.
  /// Inputs: None.
  /// Returns: `Iterable<String>`.
  /// Side effects: None.
  /// Notes: Kana are all in the basic multilingual plane, so code points are
  /// the right unit here; this exists only so the code reads as characters
  /// rather than as UTF-16 indices.
  Iterable<String> get characters =>
      runes.map((rune) => String.fromCharCode(rune));
}
