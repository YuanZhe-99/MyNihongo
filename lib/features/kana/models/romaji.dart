/// Purpose: Romanize a kana string in Hepburn, the spelling the app teaches.
/// Inputs: The compiled kana tables, plus the three rules no table row covers.
/// Returns: A lowercase ASCII string.
/// Side effects: None.
/// Notes: Written for Phase 2's pronunciation scoring, which has to compare
/// what the recognizer heard against what the item says, and used today to
/// romanize content that ships without a `romaji` field. Not a general
/// transliterator: it romanizes kana, and leaves anything else alone.
library;

import 'kana.dart';

/// Kana to romaji, built once from the tables so the two cannot drift.
Map<String, String>? _table;

/// Longest kana sequence in the table, so the greedy match knows where to stop.
int _maxUnitLength = 1;

/// Purpose: Build the lookup the first time it is needed.
/// Inputs: None.
/// Returns: The kana-to-romaji map.
/// Side effects: Populates the file-level cache.
/// Notes: Internal helper used within this file only. Both scripts map to the
/// same romaji, so katakana input works without a second table.
Map<String, String> _buildTable() {
  final table = <String, String>{};
  for (final entry in allKanaEntries()) {
    table[entry.hiragana] = entry.romaji;
    table[entry.katakana] = entry.romaji;
    _maxUnitLength = _maxUnitLength > entry.hiragana.length
        ? _maxUnitLength
        : entry.hiragana.length;
  }
  return table;
}

/// The small kana that double the following consonant.
const _sokuon = {'っ', 'ッ'};

/// The katakana long-vowel mark.
const _chouonpu = 'ー';

/// Purpose: Romanize a kana string.
/// Inputs: `kana` — hiragana, katakana, or a mix.
/// Returns: `String` — lowercase Hepburn romaji.
/// Side effects: Builds the lookup table on the first call.
/// Notes: Greedy longest-match, so `きょ` becomes `kyo` rather than `kiyo`.
/// Three rules are not in the tables: `っ` doubles the next consonant (`がっこう`
/// → `gakkou`); `ー` repeats the previous vowel (`コーヒー` → `koohii`); and a
/// long vowel is written out rather than macronned, because that is what the
/// app's `romaji` fields do and what a learner types. A character with no kana
/// reading is copied through unchanged, so a mixed string degrades instead of
/// throwing.
String romajiFromKana(String kana) {
  final table = _table ??= _buildTable();
  final out = StringBuffer();
  var i = 0;
  while (i < kana.length) {
    if (_sokuon.contains(kana[i])) {
      // Look ahead for the consonant to double; a trailing っ produces nothing.
      final rest = romajiFromKana(kana.substring(i + 1));
      if (rest.isEmpty) return out.toString();
      out.write(rest[0] == 'c' ? 't' : rest[0]);
      out.write(rest);
      return out.toString();
    }
    if (kana[i] == _chouonpu) {
      final soFar = out.toString();
      if (soFar.isNotEmpty) out.write(soFar[soFar.length - 1]);
      i += 1;
      continue;
    }
    var matched = false;
    for (var len = _maxUnitLength; len >= 1; len--) {
      if (i + len > kana.length) continue;
      final unit = kana.substring(i, i + len);
      final romaji = table[unit];
      if (romaji != null) {
        out.write(romaji);
        i += len;
        matched = true;
        break;
      }
    }
    if (!matched) {
      out.write(kana[i]);
      i += 1;
    }
  }
  return out.toString();
}
