import '../../content/models/content_catalog.dart';
import '../../content/services/content_links.dart';

import '../models/sentence_analysis.dart';
import '../models/token.dart';

/// Finds the taught grammar points a sentence uses.
///
/// Phase 1 matched a grammar point's `match` strings against the raw sentence
/// as substrings, which is what `content_links.dart` still does for the
/// reference pages. That is wrong often enough to notice: 〜は matches every
/// 歯 and every は inside a longer word.
///
/// This matches the same strings against the **token sequence** instead. A
/// match has to start at a token boundary and end at one, so the particle は
/// matches only where the tokenizer decided there is a particle は, and です
/// matches only where there is a copula. It needs no new content: the schema
/// stays at version 2 and the existing `match` lists become useful as they
/// stand.
class GrammarMatcher {
  const GrammarMatcher(this._catalog);

  final ContentCatalog _catalog;

  /// Purpose: Find the grammar points a token sequence uses.
  /// Inputs: `tokens`.
  /// Returns: `List<GrammarMatch>`, longest span first.
  /// Side effects: None.
  /// Notes: Overlaps are resolved by keeping the longest span: 〜てもいいです
  /// covers です, and reporting both would tell the learner they used two
  /// patterns where they used one. Equal spans both survive, because at that
  /// point the analyser has no basis for preferring either.
  List<GrammarMatch> match(List<Token> tokens) {
    if (tokens.isEmpty) return const [];

    // The surfaces to match against, and where each token starts within them.
    final buffer = StringBuffer();
    final tokenAt = <int, int>{}; // offset → token index
    final endAt = <int, int>{}; // offset → token index whose end it is
    for (var i = 0; i < tokens.length; i++) {
      tokenAt[buffer.length] = i;
      buffer.write(tokens[i].surface);
      endAt[buffer.length] = i;
    }
    final joined = buffer.toString();

    final found = <GrammarMatch>[];
    for (final point in _catalog.grammar) {
      for (final form in effectiveMatchForms(point)) {
        if (form.length < 2 && !_isSingleCharParticle(tokens, form)) continue;
        var from = 0;
        while (true) {
          final at = joined.indexOf(form, from);
          if (at < 0) break;
          from = at + 1;
          final first = tokenAt[at];
          final last = endAt[at + form.length];
          // Both ends have to fall on a token boundary, which is what stops
          // 〜は matching the は inside はな or the 歯 that is a noun.
          if (first == null || last == null) continue;
          if (found.any((m) => m.pointId == point.id && m.first == first)) {
            continue;
          }
          found.add(GrammarMatch(pointId: point.id, first: first, last: last));
        }
      }
    }

    found.sort((a, b) {
      final bySpan = b.span.compareTo(a.span);
      return bySpan != 0 ? bySpan : a.first.compareTo(b.first);
    });

    // Drop any match strictly contained in a longer one.
    final kept = <GrammarMatch>[];
    for (final candidate in found) {
      final covered = kept.any(
        (m) =>
            m.first <= candidate.first &&
            m.last >= candidate.last &&
            m.span > candidate.span,
      );
      if (!covered) kept.add(candidate);
    }
    return kept;
  }

  /// Purpose: Decide whether a one-character match form is worth matching.
  /// Inputs: `tokens` and the `form`.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Grammar points like
  /// 〜を and 〜は carry a single character as their whole match form, which as
  /// a substring is useless — but as a token it is exactly right. So a
  /// one-character form is allowed through only when the sentence actually
  /// contains a particle token spelled that way.
  static bool _isSingleCharParticle(List<Token> tokens, String form) {
    return tokens.any((t) => t.isParticle && t.surface == form);
  }
}
