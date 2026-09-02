/// Purpose: The kana catalog — every hiragana/katakana pair the app teaches,
/// arranged in the three tables the reference page draws.
/// Inputs: None; the data is compiled in.
/// Returns: Immutable `KanaEntry` and `KanaRow` values.
/// Side effects: None.
/// Notes: Pulled out of the page so quizzes, pronunciation practice, and the
/// progress catalog can share one source. Progress records for kana use the
/// id `kana:<hiragana>`; see [KanaEntry.progressId].
library;

/// Which script the kana page is showing.
enum KanaScript { hiragana, katakana }

/// One kana with its two scripts and its romanization.
class KanaEntry {
  final String hiragana;
  final String katakana;
  final String romaji;

  /// Purpose: Create a kana entry instance.
  /// Inputs: `hiragana`, `katakana`, `romaji`.
  /// Returns: A new `KanaEntry` instance.
  /// Side effects: None.
  /// Notes: `romaji` may carry alternatives, as in `o/wo`.
  const KanaEntry(this.hiragana, this.katakana, this.romaji);

  /// Purpose: Return the stable id progress records use for this kana.
  /// Inputs: None.
  /// Returns: `String` — `kana:` followed by the hiragana form.
  /// Side effects: None.
  /// Notes: Hiragana rather than romaji, because romaji is not unique
  /// (`ji` and `zu` each appear twice).
  String get progressId => 'kana:$hiragana';

  /// Purpose: Return this entry in the requested script.
  /// Inputs: `script`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: None.
  String kana(KanaScript script) {
    return switch (script) {
      KanaScript.hiragana => hiragana,
      KanaScript.katakana => katakana,
    };
  }

  /// Purpose: Test whether a search query matches this entry.
  /// Inputs: `query` — expected already trimmed and lowercased.
  /// Returns: `bool` — true when the query is a substring of the hiragana,
  /// the katakana, or the lowercased romaji.
  /// Side effects: None.
  /// Notes: Substring match only; no romanization variants (`si` does not
  /// find `shi`).
  bool matches(String query) {
    return hiragana.contains(query) ||
        katakana.contains(query) ||
        romaji.toLowerCase().contains(query);
  }
}

/// One labeled row of a kana table; `null` marks a combination that does not
/// exist, such as `yi` or `wu`.
class KanaRow {
  final String label;
  final List<KanaEntry?> entries;

  /// Purpose: Create a kana row instance.
  /// Inputs: `label`, `entries`.
  /// Returns: A new `KanaRow` instance.
  /// Side effects: None.
  /// Notes: None.
  const KanaRow(this.label, this.entries);
}

/// Column headers of the gojūon and dakuten tables.
const kanaVowelColumns = ['a', 'i', 'u', 'e', 'o'];

/// Column headers of the yōon table.
const kanaYoonColumns = ['ya', 'yu', 'yo'];

/// The basic gojūon table, plus ん on its own row.
const kanaBasicRows = [
  KanaRow('v', [
    KanaEntry('あ', 'ア', 'a'),
    KanaEntry('い', 'イ', 'i'),
    KanaEntry('う', 'ウ', 'u'),
    KanaEntry('え', 'エ', 'e'),
    KanaEntry('お', 'オ', 'o'),
  ]),
  KanaRow('k', [
    KanaEntry('か', 'カ', 'ka'),
    KanaEntry('き', 'キ', 'ki'),
    KanaEntry('く', 'ク', 'ku'),
    KanaEntry('け', 'ケ', 'ke'),
    KanaEntry('こ', 'コ', 'ko'),
  ]),
  KanaRow('s', [
    KanaEntry('さ', 'サ', 'sa'),
    KanaEntry('し', 'シ', 'shi'),
    KanaEntry('す', 'ス', 'su'),
    KanaEntry('せ', 'セ', 'se'),
    KanaEntry('そ', 'ソ', 'so'),
  ]),
  KanaRow('t', [
    KanaEntry('た', 'タ', 'ta'),
    KanaEntry('ち', 'チ', 'chi'),
    KanaEntry('つ', 'ツ', 'tsu'),
    KanaEntry('て', 'テ', 'te'),
    KanaEntry('と', 'ト', 'to'),
  ]),
  KanaRow('n', [
    KanaEntry('な', 'ナ', 'na'),
    KanaEntry('に', 'ニ', 'ni'),
    KanaEntry('ぬ', 'ヌ', 'nu'),
    KanaEntry('ね', 'ネ', 'ne'),
    KanaEntry('の', 'ノ', 'no'),
  ]),
  KanaRow('h', [
    KanaEntry('は', 'ハ', 'ha'),
    KanaEntry('ひ', 'ヒ', 'hi'),
    KanaEntry('ふ', 'フ', 'fu'),
    KanaEntry('へ', 'ヘ', 'he'),
    KanaEntry('ほ', 'ホ', 'ho'),
  ]),
  KanaRow('m', [
    KanaEntry('ま', 'マ', 'ma'),
    KanaEntry('み', 'ミ', 'mi'),
    KanaEntry('む', 'ム', 'mu'),
    KanaEntry('め', 'メ', 'me'),
    KanaEntry('も', 'モ', 'mo'),
  ]),
  KanaRow('y', [
    KanaEntry('や', 'ヤ', 'ya'),
    null,
    KanaEntry('ゆ', 'ユ', 'yu'),
    null,
    KanaEntry('よ', 'ヨ', 'yo'),
  ]),
  KanaRow('r', [
    KanaEntry('ら', 'ラ', 'ra'),
    KanaEntry('り', 'リ', 'ri'),
    KanaEntry('る', 'ル', 'ru'),
    KanaEntry('れ', 'レ', 're'),
    KanaEntry('ろ', 'ロ', 'ro'),
  ]),
  KanaRow('w', [
    KanaEntry('わ', 'ワ', 'wa'),
    null,
    null,
    null,
    KanaEntry('を', 'ヲ', 'o/wo'),
  ]),
  KanaRow('n', [KanaEntry('ん', 'ン', 'n'), null, null, null, null]),
];

/// The dakuten and handakuten table.
const kanaVoicedRows = [
  KanaRow('g', [
    KanaEntry('が', 'ガ', 'ga'),
    KanaEntry('ぎ', 'ギ', 'gi'),
    KanaEntry('ぐ', 'グ', 'gu'),
    KanaEntry('げ', 'ゲ', 'ge'),
    KanaEntry('ご', 'ゴ', 'go'),
  ]),
  KanaRow('z', [
    KanaEntry('ざ', 'ザ', 'za'),
    KanaEntry('じ', 'ジ', 'ji'),
    KanaEntry('ず', 'ズ', 'zu'),
    KanaEntry('ぜ', 'ゼ', 'ze'),
    KanaEntry('ぞ', 'ゾ', 'zo'),
  ]),
  KanaRow('d', [
    KanaEntry('だ', 'ダ', 'da'),
    KanaEntry('ぢ', 'ヂ', 'ji'),
    KanaEntry('づ', 'ヅ', 'zu'),
    KanaEntry('で', 'デ', 'de'),
    KanaEntry('ど', 'ド', 'do'),
  ]),
  KanaRow('b', [
    KanaEntry('ば', 'バ', 'ba'),
    KanaEntry('び', 'ビ', 'bi'),
    KanaEntry('ぶ', 'ブ', 'bu'),
    KanaEntry('べ', 'ベ', 'be'),
    KanaEntry('ぼ', 'ボ', 'bo'),
  ]),
  KanaRow('p', [
    KanaEntry('ぱ', 'パ', 'pa'),
    KanaEntry('ぴ', 'ピ', 'pi'),
    KanaEntry('ぷ', 'プ', 'pu'),
    KanaEntry('ぺ', 'ペ', 'pe'),
    KanaEntry('ぽ', 'ポ', 'po'),
  ]),
];

/// The yōon (contracted sound) table.
const kanaYoonRows = [
  KanaRow('k', [
    KanaEntry('きゃ', 'キャ', 'kya'),
    KanaEntry('きゅ', 'キュ', 'kyu'),
    KanaEntry('きょ', 'キョ', 'kyo'),
  ]),
  KanaRow('s', [
    KanaEntry('しゃ', 'シャ', 'sha'),
    KanaEntry('しゅ', 'シュ', 'shu'),
    KanaEntry('しょ', 'ショ', 'sho'),
  ]),
  KanaRow('t', [
    KanaEntry('ちゃ', 'チャ', 'cha'),
    KanaEntry('ちゅ', 'チュ', 'chu'),
    KanaEntry('ちょ', 'チョ', 'cho'),
  ]),
  KanaRow('n', [
    KanaEntry('にゃ', 'ニャ', 'nya'),
    KanaEntry('にゅ', 'ニュ', 'nyu'),
    KanaEntry('にょ', 'ニョ', 'nyo'),
  ]),
  KanaRow('h', [
    KanaEntry('ひゃ', 'ヒャ', 'hya'),
    KanaEntry('ひゅ', 'ヒュ', 'hyu'),
    KanaEntry('ひょ', 'ヒョ', 'hyo'),
  ]),
  KanaRow('m', [
    KanaEntry('みゃ', 'ミャ', 'mya'),
    KanaEntry('みゅ', 'ミュ', 'myu'),
    KanaEntry('みょ', 'ミョ', 'myo'),
  ]),
  KanaRow('r', [
    KanaEntry('りゃ', 'リャ', 'rya'),
    KanaEntry('りゅ', 'リュ', 'ryu'),
    KanaEntry('りょ', 'リョ', 'ryo'),
  ]),
  KanaRow('g', [
    KanaEntry('ぎゃ', 'ギャ', 'gya'),
    KanaEntry('ぎゅ', 'ギュ', 'gyu'),
    KanaEntry('ぎょ', 'ギョ', 'gyo'),
  ]),
  KanaRow('j', [
    KanaEntry('じゃ', 'ジャ', 'ja'),
    KanaEntry('じゅ', 'ジュ', 'ju'),
    KanaEntry('じょ', 'ジョ', 'jo'),
  ]),
  KanaRow('b', [
    KanaEntry('びゃ', 'ビャ', 'bya'),
    KanaEntry('びゅ', 'ビュ', 'byu'),
    KanaEntry('びょ', 'ビョ', 'byo'),
  ]),
  KanaRow('p', [
    KanaEntry('ぴゃ', 'ピャ', 'pya'),
    KanaEntry('ぴゅ', 'ピュ', 'pyu'),
    KanaEntry('ぴょ', 'ピョ', 'pyo'),
  ]),
];

/// Purpose: List every kana entry across the three tables, once each.
/// Inputs: None.
/// Returns: `List<KanaEntry>` in table order: basic, voiced, yōon.
/// Side effects: None.
/// Notes: Null slots are skipped. The three tables never share an entry today;
/// the dedup guards a future table that reuses one.
List<KanaEntry> allKanaEntries() {
  final seen = <String>{};
  final entries = <KanaEntry>[];
  for (final row in [...kanaBasicRows, ...kanaVoicedRows, ...kanaYoonRows]) {
    for (final entry in row.entries) {
      if (entry == null) continue;
      if (seen.add(entry.progressId)) entries.add(entry);
    }
  }
  return entries;
}

/// Purpose: Find every kana entry matching a search query.
/// Inputs: `query` — raw user input; trimmed and lowercased here.
/// Returns: `List<KanaEntry>` in table order; empty for a blank query.
/// Side effects: None.
/// Notes: See [KanaEntry.matches] for what counts as a match.
List<KanaEntry> matchingKanaEntries(String query) {
  final folded = query.trim().toLowerCase();
  if (folded.isEmpty) return const [];
  return [
    for (final entry in allKanaEntries())
      if (entry.matches(folded)) entry,
  ];
}
