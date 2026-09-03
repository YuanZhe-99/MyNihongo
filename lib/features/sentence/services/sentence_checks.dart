import '../models/function_word.dart';
import '../models/sentence_analysis.dart';
import '../models/token.dart';

/// Looks for the mistakes a learner at this level actually makes.
///
/// Every finding is a **possible** issue, and the wording in the UI says so.
/// The analyser has no model of what the writer meant: it can see that a
/// pattern is unusual, not that it is wrong. A learner told they are wrong when
/// they are not stops trusting the tool, and then the true findings are wasted
/// too — so every check here is written to stay silent when it is unsure, and
/// each one carries the exemptions that keep it quiet.
class SentenceChecks {
  const SentenceChecks(this._table);

  final FunctionWordTable _table;

  /// Purpose: Run every check over an analysed sentence.
  /// Inputs: `tokens` and `chunks`.
  /// Returns: `List<Issue>` in token order.
  /// Side effects: None.
  /// Notes: The checks are independent and each returns at most a few issues;
  /// a sentence that trips several is more likely to be tokenized badly than
  /// to be that wrong, which is why the count is capped.
  List<Issue> run(List<Token> tokens, List<Bunsetsu> chunks) {
    final issues = <Issue>[
      ..._particleFrame(tokens, chunks),
      ..._naNoConfusion(tokens),
      ..._tenseTimeWord(tokens, chunks),
      ..._missingCopula(tokens, chunks),
    ];
    issues.sort((a, b) => a.first.compareTo(b.first));
    return issues.length > 3 ? issues.sublist(0, 3) : issues;
  }

  /// Purpose: Flag an を-marked phrase on a verb that cannot take one.
  /// Inputs: `tokens`, `chunks`.
  /// Returns: `List<Issue>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Fires only when the
  /// catalog tags the verb `intransitive` and **not** `transitive` — a great
  /// many verbs are tagged both, and those never fire. Verbs of motion along a
  /// path take を legitimately (公園を歩く), so the `path-verbs` set is
  /// exempt. When the verb is half of a transitivity pair, the message can name
  /// the partner; otherwise it only reports the mismatch.
  List<Issue> _particleFrame(List<Token> tokens, List<Bunsetsu> chunks) {
    final issues = <Issue>[];
    final pathVerbs = _table.set('path-verbs');
    for (final chunk in chunks) {
      if (chunk.marker != 'を') continue;
      final target = chunk.dependsOn;
      if (target == null || target >= chunks.length) continue;
      final verb = tokens[chunks[target].head];
      if (verb.category != TokenCategory.verb) continue;
      if (!verb.pos.contains('intransitive')) continue;
      if (verb.pos.contains('transitive')) continue;
      if (pathVerbs.contains(verb.lemma)) continue;
      String? suggestion;
      for (final pair in _table.transitivityPairs) {
        if (pair.$2 == verb.lemma) suggestion = pair.$1;
      }
      issues.add(
        Issue(
          kind: IssueKind.particleFrame,
          first: chunk.first,
          last: chunks[target].last,
          detail: verb.lemma,
          suggestion: suggestion,
        ),
      );
    }
    return issues;
  }

  /// Purpose: Flag な where の belongs, and the reverse.
  /// Inputs: `tokens`.
  /// Returns: `List<Issue>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. A na-adjective before
  /// a noun takes な, a noun takes の, and swapping them is the single most
  /// common mistake at N5. Entries tagged **both** noun and na-adjective are
  /// exempt in both directions, as are `no-adjective` entries — those are the
  /// words for which both are correct, and firing on them would be the kind of
  /// false positive that makes a learner ignore the rest.
  List<Issue> _naNoConfusion(List<Token> tokens) {
    final issues = <Issue>[];
    for (var i = 1; i < tokens.length - 1; i++) {
      final particle = tokens[i];
      final before = tokens[i - 1];
      final after = tokens[i + 1];
      if (!after.isNominal) continue;
      if (before.pos.contains('no-adjective')) continue;

      if (particle.refId == 'fw:no' &&
          before.category == TokenCategory.naAdjective &&
          !before.pos.contains('noun')) {
        issues.add(
          Issue(
            kind: IssueKind.naNoConfusion,
            first: i - 1,
            last: i + 1,
            detail: before.surface,
            suggestion: 'な',
          ),
        );
      } else if (particle.refId == 'fw:na-attributive' &&
          before.category == TokenCategory.noun &&
          !before.pos.contains('na-adjective')) {
        issues.add(
          Issue(
            kind: IssueKind.naNoConfusion,
            first: i - 1,
            last: i + 1,
            detail: before.surface,
            suggestion: 'の',
          ),
        );
      }
    }
    return issues;
  }

  /// Purpose: Flag a past time word with a non-past predicate, or the reverse.
  /// Inputs: `tokens`, `chunks`.
  /// Returns: `List<Issue>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Skipped whenever the
  /// predicate carries a form that legitimately breaks the agreement: a
  /// volitional, a たい, or a progressive — 明日食べたいです is correct, and so
  /// is 昨日から働いています. A time word with から or まで on it is a span rather
  /// than a point and is exempt too.
  List<Issue> _tenseTimeWord(List<Token> tokens, List<Bunsetsu> chunks) {
    final past = _table.set('time-past');
    final future = _table.set('time-future');
    if (past.isEmpty && future.isEmpty) return const [];
    final issues = <Issue>[];
    for (final chunk in chunks) {
      final head = tokens[chunk.head];
      final isPast = past.contains(head.surface) || past.contains(head.reading);
      final isFuture =
          future.contains(head.surface) || future.contains(head.reading);
      if (!isPast && !isFuture) continue;
      if (chunk.marker == 'から' || chunk.marker == 'まで') continue;
      final target = chunk.dependsOn;
      if (target == null || target >= chunks.length) continue;
      final predicate = chunks[target];
      if (!predicate.isPredicate) continue;
      if (predicate.forms.contains(InflectionForm.volitional) ||
          predicate.forms.contains(InflectionForm.tai) ||
          predicate.forms.contains(InflectionForm.te)) {
        continue;
      }
      final predicateIsPast = predicate.forms.contains(InflectionForm.past);
      if (isPast && !predicateIsPast) {
        issues.add(
          Issue(
            kind: IssueKind.tenseTimeWord,
            first: chunk.first,
            last: predicate.last,
            detail: head.surface,
          ),
        );
      } else if (isFuture && predicateIsPast) {
        issues.add(
          Issue(
            kind: IssueKind.tenseTimeWord,
            first: chunk.first,
            last: predicate.last,
            detail: head.surface,
          ),
        );
      }
    }
    return issues;
  }

  /// Purpose: Flag a sentence that ends on a bare noun.
  /// Inputs: `tokens`, `chunks`.
  /// Returns: `List<Issue>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Only fires when the
  /// sentence has at least two chunks and one of them is marked with は or が —
  /// that is a sentence making a statement, and a statement needs a predicate.
  /// A single noun is a perfectly good answer to a question, a title, or a
  /// label, and would be the most annoying false positive in the set.
  List<Issue> _missingCopula(List<Token> tokens, List<Bunsetsu> chunks) {
    if (chunks.length < 2) return const [];
    final last = chunks.last;
    if (last.isPredicate) return const [];
    final head = tokens[last.head];
    if (!head.isNominal && head.category != TokenCategory.naAdjective) {
      return const [];
    }
    if (last.marker != null) return const [];
    final hasSubject = chunks.any((c) => c.marker == 'は' || c.marker == 'が');
    if (!hasSubject) return const [];
    return [
      Issue(
        kind: IssueKind.missingCopula,
        first: last.first,
        last: last.last,
        detail: head.surface,
        suggestion: 'です',
      ),
    ];
  }
}
