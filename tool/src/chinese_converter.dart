import 'dart:io';

/// Simplified → Traditional (Taiwan) conversion over OpenCC's own dictionaries.
///
/// This is a Dart re-implementation of OpenCC's `s2tw` conversion chain, not a
/// binding: the app must not carry a native dependency for something that runs
/// once at build time. It is deliberately **phrase-based**. A character table
/// alone gets 干净, 头发 and 软件 wrong, because the right Traditional form of a
/// simplified character depends on the word it sits in.
class OpenCcConverter {
  const OpenCcConverter(this._passes, this.preserved);

  /// The conversion chain, applied in order.
  final List<_Pass> _passes;

  /// Japanese tokens copied through untouched, longest first.
  ///
  /// The content mixes languages: a Chinese grammar note quotes the Japanese
  /// word it is about. 来る is Japanese and stays 来る; the same character in
  /// the surrounding Chinese prose must still become 來.
  final List<String> preserved;

  /// The dictionary files each pass reads, in OpenCC's own `s2tw` order.
  ///
  /// Within a pass the files are unioned, longest match first; between passes
  /// the output of one is the input of the next.
  ///
  /// `s2tw`, not `s2twp`: OpenCC's Taiwan **vocabulary** table is deliberately
  /// left out. It is domain vocabulary, mostly computing, and it rewrites
  /// ordinary prose wrongly — it turns 连接 into 連線 and 对象 into 物件 in a
  /// grammar note about which noun a particle connects. What this app needs is
  /// Taiwan character variants; it never says 软件.
  static const passFiles = <List<String>>[
    ['STPhrases.txt', 'STCharacters.txt'],
    ['TWVariantsPhrases.txt', 'TWVariants.txt'],
  ];

  /// The file listing the Japanese tokens to leave alone.
  static const preserveFile = 'preserve.txt';

  /// Purpose: Load the converter from a directory of OpenCC dictionaries.
  /// Inputs: `directory` — normally `tool/content/opencc`.
  /// Returns: `OpenCcConverter`.
  /// Side effects: Reads the dictionary files and the preserve list.
  /// Notes: Throws when a file is missing rather than silently converting less
  /// than it should — a half-loaded converter would produce text that looks
  /// right and is wrong in exactly the places the phrase tables exist for.
  factory OpenCcConverter.load(String directory) {
    final passes = <_Pass>[];
    for (final files in passFiles) {
      final table = <String, String>{};
      var maxKey = 0;
      for (final name in files) {
        final file = File('$directory/$name');
        if (!file.existsSync()) {
          throw StateError('Missing OpenCC dictionary ${file.path}');
        }
        for (final line in file.readAsLinesSync()) {
          if (line.isEmpty || line.startsWith('#')) continue;
          final tab = line.indexOf('\t');
          if (tab <= 0) continue;
          final key = line.substring(0, tab);
          final value = line.substring(tab + 1).split(' ').first.trim();
          if (value.isEmpty) continue;
          // Earlier files in a pass win, which is what OpenCC's union with a
          // longest-match policy does: the phrase tables come first.
          table.putIfAbsent(key, () => value);
          if (key.length > maxKey) maxKey = key.length;
        }
      }
      passes.add(_Pass(table, maxKey));
    }
    final preserveSource = File('$directory/$preserveFile');
    if (!preserveSource.existsSync()) {
      throw StateError('Missing ${preserveSource.path}');
    }
    final preserved = [
      for (final line in preserveSource.readAsLinesSync())
        if (line.trim().isNotEmpty && !line.startsWith('#')) line.trim(),
    ]..sort((a, b) => b.length.compareTo(a.length));
    return OpenCcConverter(passes, preserved);
  }

  /// Purpose: Convert Simplified Chinese text to Traditional (Taiwan).
  /// Inputs: `text`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Anything with no entry — kana, Latin, punctuation, a character that
  /// is already Traditional — is copied through unchanged, so a string that is
  /// not Simplified Chinese at all survives untouched. The [preserved] tokens
  /// are cut out first and the gaps converted around them.
  String convert(String text) {
    if (preserved.isEmpty) return _convertSpan(text);
    final out = StringBuffer();
    var i = 0;
    var plain = 0;
    while (i < text.length) {
      String? hit;
      for (final token in preserved) {
        if (text.startsWith(token, i)) {
          hit = token;
          break;
        }
      }
      if (hit == null) {
        i++;
        continue;
      }
      out
        ..write(_convertSpan(text.substring(plain, i)))
        ..write(hit);
      i += hit.length;
      plain = i;
    }
    out.write(_convertSpan(text.substring(plain)));
    return out.toString();
  }

  /// Purpose: Convert text as if nothing were preserved.
  /// Inputs: `text`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: This is what a preserved Japanese token *would* have become. The
  /// content test uses it to recognise the broken form in a shipped file
  /// without hard-coding it, so the check follows the preserve list instead of
  /// having to be updated alongside it.
  String convertIgnoringPreserved(String text) => _convertSpan(text);

  /// Purpose: Run the whole chain over one span of convertible text.
  /// Inputs: `text`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  String _convertSpan(String text) {
    var result = text;
    for (final pass in _passes) {
      result = pass.apply(result);
    }
    return result;
  }
}

/// One stage of the conversion chain.
class _Pass {
  const _Pass(this.table, this.maxKey);

  /// The merged lookup table for this stage.
  final Map<String, String> table;

  /// The longest key in [table], which bounds the match window.
  final int maxKey;

  /// Purpose: Apply this stage to a string.
  /// Inputs: `text`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Greedy longest match, left to right, on UTF-16 code units. Keys are
  /// whole words or single characters, never partial surrogate pairs, so the
  /// windows always cut on character boundaries.
  String apply(String text) {
    final out = StringBuffer();
    var i = 0;
    while (i < text.length) {
      var matched = false;
      final limit = (i + maxKey <= text.length) ? i + maxKey : text.length;
      for (var end = limit; end > i; end--) {
        final value = table[text.substring(i, end)];
        if (value == null) continue;
        out.write(value);
        i = end;
        matched = true;
        break;
      }
      if (!matched) {
        out.write(text[i]);
        i++;
      }
    }
    return out.toString();
  }
}
