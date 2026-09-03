# lib/features/sentence/services/tokenizer.dart

Splits Japanese text into tokens with a lattice and a shortest path. Japanese has no spaces, so
segmentation is a search: at every position the tokenizer proposes every reading it can, prices each
one, and takes the cheapest path through the sentence.

The cost table and the reasoning behind each number are derived in
[../../../../algorithms/sentence-analysis.md](../../../../algorithms/sentence-analysis.md); this
page documents the declarations.

Consumers: `sentence_analyzer.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `_Edge` | class | B | One candidate reading of a span, with its tokens, its end and its cost. |
| `_Edge.start` | getter | B | Where the edge starts — not always where it was proposed from. |
| `Tokenizer` | class | B | Split text into tokens. |
| [`tokenize`](#tokenize) | method | A | Split text into tokens by shortest path. |
| `normalize` | static method | B | Width-normalize text without touching kana or kanji. |
| [`_edgesAt`](#edgesat) | method | A | Propose every reading of the text starting at one position. |
| `_entryPenalty` | static method | B | Price one catalog candidate against its context. |
| [`_stemEdges`](#stemedges) | method | A | Propose an auxiliary together with the stem before it. |
| `_stemForm` | static method | B | Name the stem shape as a form, for the token's form chain. |
| `_functionWordToken` | static method | B | Build the token for a function word. |
| `_runEnd` | static method | B | Find how far a run of one character class extends. |
| `_isNumeral`, `_isKatakana`, `_isKana`, `_isPunctuation` | static methods | B | Character classes. |

## Documentation

### `List<Token> tokenize(String text)` <a id="tokenize"></a>

- **Kind:** method
- **Purpose:** Turn a sentence into words.
- **Inputs:** `text` as the learner typed it.
- **Returns:** Tokens in order, with offsets into the normalized text.
- **Side effects:** None.
- **Algorithm:** Dynamic programming over positions: `best[i]` is the cheapest way to reach `i`, and
  each edge relaxes from **its own start**. Then the path is walked back and reversed.
- **Usage:** `SentenceAnalyzer.analyze`.
- **Notes:** Relaxing from the edge's start rather than from the position it was proposed at is
  load-bearing: a stem edge is proposed where the auxiliary is but covers the stem before it, and
  getting that wrong was this pipeline's first bug — a polite past verb parsed as an unknown stem
  followed by an unexplained auxiliary.

### `List<_Edge> _edgesAt(String input, int i, _Edge? incoming)` <a id="edgesat"></a>

- **Kind:** method
- **Purpose:** Enumerate the candidate readings at one position.
- **Inputs:** The normalized `input`, the position, and the edge that reached it.
- **Returns:** Every edge starting at or covering this position.
- **Side effects:** None.
- **Algorithm:** Longest-first over the lexicon's key length: function words, catalog words, stem
  edges. Then a numeral run, a katakana run, punctuation, a bare masu-stem, and always a
  single-character unknown so the path can always reach the end.
- **Usage:** `tokenize`.
- **Notes:** The `incoming` edge is only used to price a counter: a counter straight after a number
  is discounted, and one with no number is penalised, because a word that is both a noun and a
  counter is the noun unless a number says otherwise.

### `List<_Edge> _stemEdges(String input, int start, int end, FunctionWord word, String surface)` <a id="stemedges"></a>

- **Kind:** method
- **Purpose:** Propose an inflected verb or adjective as one edge.
- **Inputs:** The input, the auxiliary's span, the auxiliary and its surface.
- **Returns:** One edge per word the stem could have come from.
- **Side effects:** None.
- **Algorithm:** Try every stem length backwards from the auxiliary; ask the de-inflector which
  catalog entries could have produced that stem in the shape the auxiliary requires.
- **Usage:** `_edgesAt`, whenever a function word declares a stem shape.
- **Notes:** **This is where de-inflection enters the search.** An auxiliary is only ever proposed
  together with a real word it could attach to, so a polite ending after a noun is never taken, and
  an inflected verb arrives as two tokens that already know the dictionary form. The edge starts at
  the stem, which is what lets the shortest path weigh the whole verb against the alternatives.
