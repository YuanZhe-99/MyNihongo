# lib/features/sentence/services/chunker.dart

Groups tokens into bunsetsu and guesses what attaches to what. A bunsetsu is a content word plus
everything leaning on it; Japanese dependency is described between these rather than between words,
because a particle belongs to the word before it and moves with it.

The attachment rules are derived in
[../../../../algorithms/sentence-analysis.md](../../../../algorithms/sentence-analysis.md).

Consumers: `sentence_analyzer.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `Chunker` | class | B | Group tokens into bunsetsu and attach them. |
| [`chunk`](#chunk) | method | A | Group tokens into bunsetsu. |
| [`_joins`](#joins) | static method | A | Decide whether a token continues the open chunk. |
| `_build` | static method | B | Build one chunk from a token range: head, marker, forms, predicate. |
| [`_attach`](#attach) | static method | A | Guess what each chunk attaches to. |
| `_modifiesNoun` | static method | B | Decide whether a chunk modifies a noun rather than a predicate. |
| `_next` | static method | B | Find the next chunk after an index that satisfies a test. |

## Documentation

### `List<Bunsetsu> chunk(List<Token> tokens)` <a id="chunk"></a>

- **Kind:** method
- **Purpose:** Turn a token list into the structure the UI draws.
- **Inputs:** The tokens, in order.
- **Returns:** Chunks in order, with `dependsOn` filled in.
- **Side effects:** None.
- **Algorithm:** One pass opening and closing chunks, then `_attach`.
- **Usage:** `SentenceAnalyzer.analyze`.
- **Notes:** Punctuation closes the open chunk and is left out of it, so a trailing full stop is not
  part of a word.

### `static bool _joins(List<Token> tokens, int i)` <a id="joins"></a>

- **Kind:** static method
- **Purpose:** Decide where one bunsetsu ends and the next begins.
- **Inputs:** The tokens and the index being considered.
- **Returns:** `true` when the token continues the chunk.
- **Side effects:** None.
- **Algorithm:** `Token.attachesLeft`, plus three positional cases: a counter after a number, the
  verb する after a `suru-verb` noun, and a verb behind a te-form.
- **Usage:** `chunk`.
- **Notes:** The three positional cases are the ones a token cannot answer on its own. The last is
  the only place an ordinary verb acts as an auxiliary, and it is why the catalog's `auxiliary` tag
  is not read when the token's category is assigned — a verb tagged that way is still a verb when
  nothing precedes it.

### `static List<Bunsetsu> _attach(List<Token> tokens, List<Bunsetsu> chunks)` <a id="attach"></a>

- **Kind:** static method
- **Purpose:** Fill in what each chunk depends on.
- **Inputs:** The tokens and the chunks.
- **Returns:** A new list with `dependsOn` set and `isPredicate` corrected.
- **Side effects:** None.
- **Algorithm:** Rightwards: a noun-modifying chunk attaches to the next nominal chunk, anything
  else to the next predicate chunk, and failing both to the next chunk. The last chunk is the root.
- **Usage:** `chunk`.
- **Notes:** A chunk that modifies a noun is **not** a predicate, even when its head is an
  adjective. Without that correction, an attributive adjective in the middle of a sentence attracted
  every earlier chunk — and the tense check then fired on a perfectly correct sentence, because a
  past time word had attached to an adjective that carries no tense.
