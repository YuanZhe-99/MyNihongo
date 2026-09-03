# lib/features/sentence/models/token.dart

One word as the analyser found it, plus the two enums that describe it: what kind of word it is, and
what was done to it grammatically.

`TokenCategory` is coarser than the catalog's 23 part-of-speech tags on purpose — it is what the
chunker and the grammar matcher branch on, and what colours a chip. The raw tags stay on the token
for the checks that need them. `InflectionForm` is a **chain**, innermost first, so a causative
passive polite negative past reads as five steps rather than as one opaque label.

Consumers: every file under `features/sentence/`, plus `token_chips.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `TokenCategory` | enum | B | What kind of word a token is: 24 values grouped into the six the UI names. |
| `InflectionForm` | enum | B | A grammatical form recovered by de-inflection. |
| `Token` | class | B | One word, with its surface, reading, lemma, category, tags, forms, id and span. |
| `Token.isParticle` | getter | B | Whether this is a particle of any kind. |
| `Token.isPredicateHead` | getter | B | Whether this can head a predicate. |
| `Token.isNominal` | getter | B | Whether this can head a noun phrase. |
| [`Token.attachesLeft`](#attachesleft) | getter | A | Whether this leans on the word before it. |
| `Token.toString` | method | B | The fixture rendering: surface, category and form chain. |

## Documentation

### `bool get attachesLeft` <a id="attachesleft"></a>

- **Kind:** getter
- **Purpose:** Decide whether a token belongs to the chunk already open.
- **Inputs:** None.
- **Returns:** `true` for particles, the copula, auxiliaries, auxiliary verbs and suffixes.
- **Side effects:** None.
- **Algorithm:** A category test.
- **Usage:** `Chunker._joins` and `Chunker._build`.
- **Notes:** This is the whole basis of bunsetsu grouping: a particle belongs to the word before it
  and moves with it, which is why Japanese dependency is described between chunks rather than
  between words. The three cases it does **not** cover — a counter after a number, the verb する
  after a `suru-verb` noun, a verb behind a te-form — are positional rather than lexical, so the
  chunker decides those with the neighbouring token in hand.
