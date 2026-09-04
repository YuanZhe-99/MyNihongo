import 'token.dart';

/// What a function word does, which is what the chunker and the checks branch
/// on.
enum FunctionWordCategory {
  particleCase,
  particleBinding,
  particleConjunctive,
  particleFinal,
  copula,
  auxiliary,
  formalNoun,
}

/// What the word before an auxiliary has to be.
///
/// ます attaches to a masu-stem, た to a te-stem, ば to an e-stem. Declaring it
/// is what lets the de-inflector run backwards: it knows which stem shape to
/// look for before it starts guessing at a verb class.
enum StemShape {
  /// No requirement: particles attach to whatever came before.
  any,

  /// 食べ, 行き — the stem ます attaches to.
  masuStem,

  /// 食べ, 行か — the stem ない attaches to.
  naiStem,

  /// 食べ, 行っ — the stem て and た attach to.
  teStem,

  /// The voiced half of the te-stem: 飲ん, 読ん, 泳い.
  teStemVoiced,

  /// 食べれ, 行け — the stem ば attaches to.
  eStem,

  /// 行こ, 飲も — the godan stem the plain volitional う attaches to. An
  /// ichidan verb has none: 食べよう is the ない-stem plus よう.
  oStem,

  /// 高, 忙し — an i-adjective minus its final い, which every adjective
  /// ending attaches to: く, くて, かった, くない, ければ.
  adjectiveStem,

  /// A finished plain form: 食べる, 高い, 学生だ.
  plain,

  /// A dictionary form specifically.
  dictionary,

  /// A noun or noun-like word.
  nominal,
}

/// One entry from `assets/content/function_words.json`.
class FunctionWord {
  const FunctionWord({
    required this.id,
    required this.surface,
    required this.reading,
    required this.category,
    required this.lemma,
    required this.needs,
    required this.forms,
    required this.gloss,
  });

  /// `fw:` plus a slug. A compatibility contract like the catalog's ids: a
  /// shipped one is never renamed.
  final String id;

  /// How the word is written.
  final String surface;

  /// Its kana reading — は as わ, を as お.
  final String reading;

  /// What it does.
  final FunctionWordCategory category;

  /// The base form of its family: ません and ました both lemmatize to ます.
  final String lemma;

  /// What has to precede it.
  final StemShape needs;

  /// The forms it contributes to the chunk it closes.
  final List<InflectionForm> forms;

  /// A short explanation, by language code. Function words have no catalog
  /// entry to open, so the chip carries its own meaning.
  final Map<String, String> gloss;

  /// The token category this word produces.
  TokenCategory get tokenCategory => switch (category) {
    FunctionWordCategory.particleCase => TokenCategory.particleCase,
    FunctionWordCategory.particleBinding => TokenCategory.particleBinding,
    FunctionWordCategory.particleConjunctive =>
      TokenCategory.particleConjunctive,
    FunctionWordCategory.particleFinal => TokenCategory.particleFinal,
    FunctionWordCategory.copula => TokenCategory.copula,
    FunctionWordCategory.auxiliary => TokenCategory.auxiliary,
    FunctionWordCategory.formalNoun => TokenCategory.formalNoun,
  };

  /// Purpose: Parse one entry from the asset.
  /// Inputs: `json`.
  /// Returns: `FunctionWord?` — null when the entry is unusable.
  /// Side effects: None.
  /// Notes: An unknown category or form name makes the entry null rather than
  /// throwing, so a newer asset read by an older build loses one word instead
  /// of failing to load the analyser at all.
  static FunctionWord? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final surface = json['surface'];
    if (id is! String || surface is! String || surface.isEmpty) return null;
    final category = _categoryOf(json['category']);
    if (category == null) return null;
    return FunctionWord(
      id: id,
      surface: surface,
      reading: json['reading'] is String ? json['reading'] as String : surface,
      category: category,
      lemma: json['lemma'] is String ? json['lemma'] as String : surface,
      needs: _shapeOf(json['needs']),
      forms: [
        if (json['forms'] is List)
          for (final name in json['forms'] as List) ?_formOf(name),
      ],
      gloss: {
        if (json['gloss'] is Map)
          for (final entry in (json['gloss'] as Map).entries)
            entry.key.toString(): entry.value.toString(),
      },
    );
  }

  /// Purpose: Read the category name.
  /// Inputs: `value`.
  /// Returns: `FunctionWordCategory?`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  static FunctionWordCategory? _categoryOf(Object? value) => switch (value) {
    'particle-case' => FunctionWordCategory.particleCase,
    'particle-binding' => FunctionWordCategory.particleBinding,
    'particle-conjunctive' => FunctionWordCategory.particleConjunctive,
    'particle-final' => FunctionWordCategory.particleFinal,
    'copula' => FunctionWordCategory.copula,
    'auxiliary' => FunctionWordCategory.auxiliary,
    'formal-noun' => FunctionWordCategory.formalNoun,
    _ => null,
  };

  /// Purpose: Read the required stem shape.
  /// Inputs: `value`.
  /// Returns: `StemShape` — [StemShape.any] when absent or unknown.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  static StemShape _shapeOf(Object? value) => switch (value) {
    'masuStem' => StemShape.masuStem,
    'naiStem' => StemShape.naiStem,
    'teStem' => StemShape.teStem,
    'teStemVoiced' => StemShape.teStemVoiced,
    'eStem' => StemShape.eStem,
    'oStem' => StemShape.oStem,
    'adjectiveStem' => StemShape.adjectiveStem,
    'plain' => StemShape.plain,
    'dictionary' => StemShape.dictionary,
    'nominal' => StemShape.nominal,
    _ => StemShape.any,
  };

  /// Purpose: Read one form name.
  /// Inputs: `value`.
  /// Returns: `InflectionForm?`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  static InflectionForm? _formOf(Object? value) {
    for (final form in InflectionForm.values) {
      if (form.name == value) return form;
    }
    return null;
  }
}

/// The whole function-word table, plus the named sets the checks use.
class FunctionWordTable {
  const FunctionWordTable({
    required this.words,
    required this.sets,
    required this.transitivityPairs,
  });

  /// Every function word, in asset order.
  final List<FunctionWord> words;

  /// Named word lists: time expressions, motion verbs, transitivity pairs.
  final Map<String, List<String>> sets;

  /// Verb pairs that mean the same event from the two sides: the transitive
  /// member first. The frame check suggests the partner when the particles
  /// contradict the one that was written.
  final List<(String, String)> transitivityPairs;

  /// An empty table, for a build where the asset failed to load.
  static const empty = FunctionWordTable(
    words: [],
    sets: {},
    transitivityPairs: [],
  );

  /// Purpose: Look one named set up.
  /// Inputs: `name`.
  /// Returns: `List<String>` — empty when the set is absent.
  /// Side effects: None.
  /// Notes: Absent rather than throwing, so a check whose set was renamed
  /// stops firing instead of crashing the analyser.
  List<String> set(String name) => sets[name] ?? const [];

  /// Purpose: Parse the asset.
  /// Inputs: `json` — the decoded `function_words.json`.
  /// Returns: `FunctionWordTable`.
  /// Side effects: None.
  /// Notes: Unusable entries are skipped, not fatal; see [FunctionWord.fromJson].
  static FunctionWordTable fromJson(Object? json) {
    if (json is! Map) return empty;
    final words = <FunctionWord>[];
    if (json['words'] case final List raw) {
      for (final entry in raw) {
        final word = FunctionWord.fromJson(entry);
        if (word != null) words.add(word);
      }
    }
    final sets = <String, List<String>>{};
    if (json['sets'] case final Map raw) {
      for (final entry in raw.entries) {
        final value = entry.value;
        if (value is! List) continue;
        sets[entry.key.toString()] = [
          for (final item in value)
            if (item is String) item,
        ];
      }
    }
    return FunctionWordTable(
      words: words,
      sets: sets,
      transitivityPairs: [
        for (final pair in pairsFromJson(json))
          if (pair.length == 2) (pair[0], pair[1]),
      ],
    );
  }

  /// Purpose: Read the transitivity pairs, which are nested arrays.
  /// Inputs: `json` — the decoded asset.
  /// Returns: `List<List<String>>`.
  /// Side effects: None.
  /// Notes: Kept separate from [fromJson]'s flat sets because this one set has
  /// a different shape; flattening it there would lose the pairing.
  static List<List<String>> pairsFromJson(Object? json) {
    if (json is! Map) return const [];
    final sets = json['sets'];
    if (sets is! Map) return const [];
    final pairs = sets['transitivity-pairs'];
    if (pairs is! List) return const [];
    return [
      for (final pair in pairs)
        if (pair is List && pair.length == 2)
          [pair[0].toString(), pair[1].toString()],
    ];
  }
}
