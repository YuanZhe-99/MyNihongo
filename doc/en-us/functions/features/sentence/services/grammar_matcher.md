# lib/features/sentence/services/grammar_matcher.dart

Finds the taught grammar points a sentence uses, by matching each point's `match` strings against
the **token sequence** rather than against the raw text.

Phase 1 matched them as substrings, which is what `content_links.dart` still does for the reference
pages; that is wrong often enough to notice, because a one-character particle matches inside every
longer word containing it. Matching on token boundaries fixes it and needed no content change — the
grammar schema stays at version 2.

Consumers: `sentence_analyzer.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `GrammarMatcher` | class | B | Find the grammar points a token sequence uses. |
| [`match`](#match) | method | A | Find the grammar points, longest span first. |
| `_isSingleCharParticle` | static method | B | Decide whether a one-character match form is worth matching. |

## Documentation

### `List<GrammarMatch> match(List<Token> tokens)` <a id="match"></a>

- **Kind:** method
- **Purpose:** Report which taught patterns the sentence contains.
- **Inputs:** The tokens, in order.
- **Returns:** Matches, longest span first, with contained matches dropped.
- **Side effects:** None.
- **Algorithm:** Join the token surfaces, remembering where each token starts and ends. For every
  match form of every point, find each occurrence and keep it only when **both ends fall on a token
  boundary**. Then sort by span and drop any match strictly contained in a longer one.
- **Usage:** `SentenceAnalyzer.analyze`.
- **Notes:** The boundary test is the whole point: a particle matches where the tokenizer decided
  there is a particle, and not inside a longer word spelled with the same character. Dropping
  contained matches means a compound pattern is reported once rather than as itself plus each of its
  parts. Equal spans both survive — at that point there is no basis for preferring either, and
  showing two possibilities is more honest than picking one.
