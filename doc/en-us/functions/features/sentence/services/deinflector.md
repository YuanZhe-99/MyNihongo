# lib/features/sentence/services/deinflector.dart

Turns an inflected stem back into the word it came from. The second stage of de-inflection: the
lattice has already found an auxiliary, each auxiliary declares the stem shape it attaches to, and
this answers which catalog entries could have produced the characters before it.

Running backwards is what keeps the tables small. Forwards, every class has a dozen forms;
backwards, each shape is one row transformation per class — and **the lexicon rejects everything
that is not a word**, so the rules can be generous. The row tables and the worked examples are in
[../../../../algorithms/sentence-analysis.md](../../../../algorithms/sentence-analysis.md).

Consumers: `tokenizer.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `DeinflectedStem` | class | B | One conjugable word recovered from an inflected stem, with the stem as written. |
| `Deinflector` | class | B | Recover words from inflected stems. |
| [`stemsFor`](#stemsfor) | method | A | Find the words an inflected stem could have come from. |
| `adjectiveStemsFor` | method | B | Recover an i-adjective from an inflected stem. |
| `_godanFromRow` | static method | B | Propose godan lemmas for a stem ending in a known row. |
| [`_teStemGodan`](#testemgodan) | static method | A | Propose godan lemmas for a te-stem, which is the irregular one. |
| [`_acceptIrregular`](#acceptirregular) | method | A | Accept the two irregular verbs, which no row table describes. |

## Documentation

### `List<DeinflectedStem> stemsFor(String stem, StemShape shape)` <a id="stemsfor"></a>

- **Kind:** method
- **Purpose:** Answer which words an inflected stem could be.
- **Inputs:** The characters before an auxiliary, and the shape that auxiliary attaches to.
- **Returns:** Every catalog entry that fits; empty when nothing does.
- **Side effects:** None.
- **Algorithm:** A switch on the shape, proposing an ichidan lemma, the godan row shift, and the
  irregular verbs; the adjective shape delegates to `adjectiveStemsFor`.
- **Usage:** `Tokenizer._stemEdges`, and the bare masu-stem edge.
- **Notes:** Every candidate is confirmed against the lexicon, which is what makes generous rules
  safe: a voiced te-stem proposes three different verb classes, and only the one that is a real word
  survives.

### `static void _teStemGodan(String stem, {required bool voiced, required void Function(String, Set<ConjClass>) accept})` <a id="testemgodan"></a>

- **Kind:** static method
- **Purpose:** Undo the te-form, which is where godan verbs stop being regular.
- **Inputs:** The stem, whether the auxiliary was the voiced one, and the sink.
- **Returns:** None.
- **Side effects:** Calls `accept` for each class the stem's last kana could belong to.
- **Algorithm:** Three godan classes collapse onto one small-tsu stem, three more onto one moraic-n
  stem, and two more onto one i-stem — plus the single verb whose te-form takes the small tsu
  against its class.
- **Usage:** `stemsFor`, for both te-stem shapes.
- **Notes:** Proposing every class and letting the lexicon reject the non-words is both shorter and
  more honest than encoding the exceptions: the exception list would have to be maintained against
  the catalog, and the catalog is already the authority.

### `void _acceptIrregular(String stem, List<DeinflectedStem> out, {bool masu, bool nai, bool te})` <a id="acceptirregular"></a>

- **Kind:** method
- **Purpose:** Recover the two irregular verbs, which no row table describes.
- **Inputs:** The stem, the output sink, and which shape is being resolved.
- **Returns:** None.
- **Side effects:** Appends to `out`.
- **Algorithm:** Exact string comparison against a small stem list per shape, in both spellings.
- **Usage:** `stemsFor`.
- **Notes:** The stem must match **exactly**. An earlier version tested `endsWith`, and a six-character
  span ending in the right kana then de-inflected to one irregular verb — a single edge swallowing
  half a sentence at the price of one word, which the shortest path duly preferred. A noun tagged
  `suru-verb` followed by that stem is rejoined by the chunker instead: the catalog holds the noun,
  not the compound verb.
