/// The kind of word a token is.
///
/// Coarser than the catalog's 23 part-of-speech tags, because this is what the
/// chunker and the grammar matcher branch on and what colours a chip. The raw
/// tags stay on the token for anything that needs them.
enum TokenCategory {
  noun,
  pronoun,
  properNoun,
  number,
  counter,
  verb,

  /// An auxiliary *verb* — いる, ある, みる and the rest that attach behind て.
  auxVerb,
  iAdjective,
  naAdjective,
  adverb,
  adnominal,
  conjunction,
  interjection,
  prefix,
  suffix,
  expression,

  /// が, を, に, へ, で, と, から, まで, より, の.
  particleCase,

  /// は, も, しか, だけ, ばかり and the rest that mark, rather than govern.
  particleBinding,

  /// から, ので, けど, し, ながら, ば, たら — particles that join clauses.
  particleConjunctive,

  /// か, ね, よ, な, わ at the end of a sentence.
  particleFinal,

  /// です, だ, でした and the rest of the copula family.
  copula,

  /// ます, ない, た, て, たい — the endings that attach to a stem.
  auxiliary,

  /// こと, もの, ほう, つもり, はず, とき, ため.
  formalNoun,

  /// A katakana run the catalog does not know: a loanword or a name. Not an
  /// error — it is a word, and saying which kind would need a dictionary the
  /// app does not ship.
  katakanaUnknown,
  punctuation,

  /// Nothing else matched. Every one of these is a gap in the catalog.
  unknown,
}

/// A grammatical form recovered by de-inflection.
///
/// A token carries the whole chain, innermost first, so 食べさせられませんでした
/// reads as causative → passive → polite → negative → past rather than as one
/// opaque label.
enum InflectionForm {
  dictionary,
  masuStem,
  naiStem,
  teStem,
  eStem,
  polite,
  negative,
  past,
  te,
  tai,
  potential,
  passive,
  causative,
  imperative,
  volitional,
  conditionalBa,
  conditionalTara,
  tari,
  nagara,
  adverbial,
  attributive,
  progressive,
  request,
}

/// One word, as the analyser found it.
class Token {
  const Token({
    required this.surface,
    required this.reading,
    required this.lemma,
    required this.category,
    required this.start,
    required this.end,
    this.pos = const [],
    this.forms = const [],
    this.refId,
    this.gloss,
  });

  /// The characters as they appear in the input.
  final String surface;

  /// The kana reading, where one is known; the surface otherwise.
  final String reading;

  /// The dictionary form this token came from.
  final String lemma;

  /// What kind of word it is.
  final TokenCategory category;

  /// The catalog's own part-of-speech tags, for the checks that need them.
  final List<String> pos;

  /// The forms recovered by de-inflection, innermost first.
  final List<InflectionForm> forms;

  /// `vocab:…` or `fw:…`; null when nothing in the catalog matched.
  final String? refId;

  /// A short gloss for a function word, which has no catalog entry to open.
  final Map<String, String>? gloss;

  /// Where the token starts in the normalized input.
  final int start;

  /// Where it ends, exclusive.
  final int end;

  /// Whether this token is a particle of any kind.
  bool get isParticle =>
      category == TokenCategory.particleCase ||
      category == TokenCategory.particleBinding ||
      category == TokenCategory.particleConjunctive ||
      category == TokenCategory.particleFinal;

  /// Whether this token can head a predicate.
  bool get isPredicateHead =>
      category == TokenCategory.verb ||
      category == TokenCategory.iAdjective ||
      category == TokenCategory.auxVerb;

  /// Whether this token can be the head of a noun phrase.
  bool get isNominal =>
      category == TokenCategory.noun ||
      category == TokenCategory.pronoun ||
      category == TokenCategory.properNoun ||
      category == TokenCategory.number ||
      category == TokenCategory.formalNoun ||
      category == TokenCategory.katakanaUnknown;

  /// Whether this token attaches to the word before it rather than standing
  /// on its own — what the chunker uses to decide where a bunsetsu ends.
  bool get attachesLeft =>
      isParticle ||
      category == TokenCategory.copula ||
      category == TokenCategory.auxiliary ||
      category == TokenCategory.auxVerb ||
      category == TokenCategory.suffix;

  @override
  String toString() {
    final formLabel = forms.isEmpty
        ? ''
        : '/${forms.map((f) => f.name).join('+')}';
    return '$surface/${category.name}$formLabel';
  }
}
