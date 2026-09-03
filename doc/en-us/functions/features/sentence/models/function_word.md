# lib/features/sentence/models/function_word.dart

The model for `assets/content/function_words.json`: particles, copula forms, auxiliaries and formal
nouns, plus the named word sets the checks read.

The table is **authoritative over the vocabulary catalog** for the same surface. The topic marker is
written the same way as a common noun, and it is the particle far more often; an analyser that
weighed the two equally would be wrong in most sentences.

Consumers: `lexicon.dart` (indexes it), `tokenizer.dart` (proposes from it), `deinflector.dart` (the
stem shapes), `sentence_checks.dart` (the sets), `content_repository.dart` (loads it).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `FunctionWordCategory` | enum | B | What a function word does: the four particle roles, copula, auxiliary, formal noun. |
| [`StemShape`](#stemshape) | enum | A | What the word before an auxiliary has to be. |
| `FunctionWord` | class | B | One entry: id, surface, reading, category, lemma, required stem, forms, gloss. |
| `FunctionWord.tokenCategory` | getter | B | The token category this word produces. |
| `FunctionWord.fromJson` | static method | B | Parse one entry; an unusable one is null, not an exception. |
| `FunctionWord._categoryOf` | static method | B | Read the category name. |
| `FunctionWord._shapeOf` | static method | B | Read the required stem shape; unknown means `any`. |
| `FunctionWord._formOf` | static method | B | Read one form name. |
| `FunctionWordTable` | class | B | The whole table, plus the named sets and the transitivity pairs. |
| `FunctionWordTable.set` | method | B | Look one named set up; absent is empty, not an exception. |
| `FunctionWordTable.fromJson` | static method | B | Parse the asset, skipping unusable entries. |
| `FunctionWordTable.pairsFromJson` | static method | B | Read the transitivity pairs, which are nested arrays. |

## Documentation

### `enum StemShape` <a id="stemshape"></a>

- **Kind:** enum
- **Purpose:** Say what a given auxiliary attaches to.
- **Inputs:** —
- **Returns:** —
- **Side effects:** None.
- **Algorithm:** —
- **Usage:** `Deinflector.stemsFor` switches on it; `Tokenizer._stemEdges` passes it through.
- **Notes:** **This is what lets de-inflection run backwards.** The polite auxiliary declares
  `masuStem`, the plain past declares `teStem`, the conditional declares `eStem`, the adjective past
  declares `adjectiveStem`; the de-inflector therefore knows which row transformation to try before
  it starts guessing at a verb class, and the tables stay one rule per class per shape instead of
  one per form. `any` is the particles, which attach to whatever came before and need no stem.
