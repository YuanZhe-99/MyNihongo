import '../models/sentence_analysis.dart';
import '../models/token.dart';

/// Groups tokens into bunsetsu and guesses what attaches to what.
///
/// A bunsetsu is a content word plus everything that leans on it: particles,
/// the copula, auxiliaries. Japanese dependency is described between these
/// rather than between words, because a particle belongs to the word before it
/// and moves with it.
///
/// The attachment rule is the standard right-headed one — every chunk attaches
/// to something later in the sentence, and the last chunk of a clause is its
/// root. That is a **guess**: it is right for the overwhelming majority of the
/// sentences a learner writes at this level, and wrong for some. The UI shows
/// it as a tree, not as an assertion, and nothing else in the app depends on
/// it being right.
class Chunker {
  const Chunker();

  /// Purpose: Group tokens into bunsetsu.
  /// Inputs: `tokens`.
  /// Returns: `List<Bunsetsu>` in order.
  /// Side effects: None.
  /// Notes: A token joins the open chunk when it leans left — a particle, the
  /// copula, an auxiliary, a suffix — or when it is a counter after a number,
  /// する after a `suru-verb` noun, or a verb behind a て-form, which is the
  /// one place an ordinary verb acts as an auxiliary. Punctuation closes the
  /// chunk and is dropped from it, so a trailing 。 is not part of a word.
  List<Bunsetsu> chunk(List<Token> tokens) {
    final chunks = <Bunsetsu>[];
    var start = -1;

    void close(int end) {
      if (start < 0) return;
      chunks.add(_build(tokens, start, end));
      start = -1;
    }

    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (token.category == TokenCategory.punctuation) {
        close(i - 1);
        continue;
      }
      if (start < 0) {
        start = i;
        continue;
      }
      if (_joins(tokens, i)) continue;
      close(i - 1);
      start = i;
    }
    close(tokens.length - 1);

    return _attach(tokens, chunks);
  }

  /// Purpose: Decide whether a token continues the open chunk.
  /// Inputs: `tokens` and the index `i`.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  static bool _joins(List<Token> tokens, int i) {
    final token = tokens[i];
    final previous = tokens[i - 1];
    if (token.attachesLeft) return true;
    if (token.category == TokenCategory.counter &&
        previous.category == TokenCategory.number) {
      return true;
    }
    // 勉強 + し: the catalog stores the noun, so the verb rejoins it here.
    if (token.lemma == 'する' && previous.pos.contains('suru-verb')) {
      return true;
    }
    // 食べて + いる: a verb behind a て-form is acting as an auxiliary.
    if (token.category == TokenCategory.verb &&
        previous.forms.contains(InflectionForm.te) &&
        token.pos.contains('auxiliary')) {
      return true;
    }
    return false;
  }

  /// Purpose: Build one chunk from a token range.
  /// Inputs: `tokens`, `first`, `last`.
  /// Returns: `Bunsetsu`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The head is the last
  /// token that is not leaning left, so 新しい映画を has 映画 as its head and
  /// 見ました has 見る. The forms are collected from the head onwards, which is
  /// what makes a chunk's tense readable without walking its tokens again.
  static Bunsetsu _build(List<Token> tokens, int first, int last) {
    var head = first;
    for (var i = first; i <= last; i++) {
      if (!tokens[i].attachesLeft) head = i;
    }
    String? marker;
    for (var i = head; i <= last; i++) {
      if (tokens[i].isParticle) marker = tokens[i].surface;
    }
    final forms = <InflectionForm>[];
    for (var i = head; i <= last; i++) {
      for (final form in tokens[i].forms) {
        if (!forms.contains(form)) forms.add(form);
      }
    }
    final headToken = tokens[head];
    final endsInCopula = tokens[last].category == TokenCategory.copula;
    return Bunsetsu(
      first: first,
      last: last,
      head: head,
      marker: marker,
      isPredicate: headToken.isPredicateHead || endsInCopula,
      forms: forms,
    );
  }

  /// Purpose: Guess what each chunk attaches to.
  /// Inputs: `tokens` and the chunks.
  /// Returns: A new list with `dependsOn` filled in.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Three rules, tried in
  /// order, all of them looking rightwards:
  ///
  /// 1. A chunk whose head modifies a noun — の, a plain-form adjective, な, an
  ///    adnominal, a number with a counter — attaches to the next nominal
  ///    chunk.
  /// 2. Anything else attaches to the next predicate chunk.
  /// 3. Failing both, it attaches to the next chunk, and the last chunk in the
  ///    sentence is the root.
  ///
  /// Clause boundaries are not modelled: a chunk may attach across a て-form
  /// or a から, which is usually right and occasionally not. Modelling them
  /// properly needs the clause structure the analyser deliberately does not
  /// claim to have.
  static List<Bunsetsu> _attach(List<Token> tokens, List<Bunsetsu> chunks) {
    final out = <Bunsetsu>[];
    for (var i = 0; i < chunks.length; i++) {
      final chunk = chunks[i];
      final modifiesNoun = _modifiesNoun(tokens, chunk);
      int? target;
      if (i < chunks.length - 1) {
        target = modifiesNoun
            ? _next(chunks, i, (c) => tokens[c.head].isNominal)
            : _next(
                chunks,
                i,
                (c) => c.isPredicate && !_modifiesNoun(tokens, c),
              );
        target ??= i + 1;
      }
      out.add(
        Bunsetsu(
          first: chunk.first,
          last: chunk.last,
          head: chunk.head,
          dependsOn: target,
          marker: chunk.marker,
          // An adjective sitting in front of a noun is describing it, not
          // predicating it: 新しい映画 has one predicate, and it is not 新しい.
          isPredicate: chunk.isPredicate && !modifiesNoun,
          forms: chunk.forms,
        ),
      );
    }
    return out;
  }

  /// Purpose: Decide whether a chunk modifies a noun rather than a predicate.
  /// Inputs: `tokens`, `chunk`.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. A plain-form verb
  /// directly before a noun is a relative clause and modifies it, but the
  /// chunk cannot see what follows, so that case is left to rule 2 and the
  /// fallback — being wrong towards the predicate is the less confusing error
  /// for a learner reading a tree.
  static bool _modifiesNoun(List<Token> tokens, Bunsetsu chunk) {
    if (chunk.marker == 'の') return true;
    final head = tokens[chunk.head];
    if (head.category == TokenCategory.adnominal) return true;
    if (head.category == TokenCategory.iAdjective &&
        chunk.marker == null &&
        !chunk.forms.contains(InflectionForm.polite)) {
      return true;
    }
    if (head.category == TokenCategory.naAdjective &&
        chunk.forms.contains(InflectionForm.attributive)) {
      return true;
    }
    if (head.category == TokenCategory.number &&
        tokens[chunk.last].category == TokenCategory.counter) {
      return true;
    }
    return false;
  }

  /// Purpose: Find the next chunk after `i` that satisfies a test.
  /// Inputs: `chunks`, `i`, `test`.
  /// Returns: The index, or null.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  static int? _next(
    List<Bunsetsu> chunks,
    int i,
    bool Function(Bunsetsu) test,
  ) {
    for (var j = i + 1; j < chunks.length; j++) {
      if (test(chunks[j])) return j;
    }
    return null;
  }
}
