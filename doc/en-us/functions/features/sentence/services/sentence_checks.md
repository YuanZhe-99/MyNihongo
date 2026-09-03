# lib/features/sentence/services/sentence_checks.dart

Looks for the mistakes a learner at this level actually makes. Four checks run today; the fifth kind
is declared but unreachable, because the lattice makes an adjective with a verb ending fail to parse
rather than parse wrongly.

Every finding is a **possible** issue, and the UI says so. The trigger conditions and — more
importantly — the exemptions are derived in
[../../../../algorithms/sentence-analysis.md](../../../../algorithms/sentence-analysis.md).

Consumers: `sentence_analyzer.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `SentenceChecks` | class | B | Run the checks over an analysed sentence. |
| [`run`](#run) | method | A | Run every check and return the findings in token order. |
| [`_particleFrame`](#particleframe) | method | A | Flag an object-marked phrase on a verb that cannot take one. |
| `_naNoConfusion` | method | B | Flag the attributive particle where the genitive belongs, and the reverse. |
| `_tenseTimeWord` | method | B | Flag a past time word with a non-past predicate, or the reverse. |
| `_missingCopula` | method | B | Flag a statement that ends on a bare noun. |

## Documentation

### `List<Issue> run(List<Token> tokens, List<Bunsetsu> chunks)` <a id="run"></a>

- **Kind:** method
- **Purpose:** Produce the "possible issues" section.
- **Inputs:** The tokens and the chunks.
- **Returns:** At most three issues, in token order.
- **Side effects:** None.
- **Algorithm:** Each check independently, then sort and truncate.
- **Usage:** `SentenceAnalyzer.analyze`.
- **Notes:** The cap is not cosmetic. A sentence that trips four checks is far likelier to have been
  tokenized badly than to be that wrong, and a wall of findings on a sentence the analyser did not
  understand is the fastest way to teach a learner to ignore the section.

### `List<Issue> _particleFrame(List<Token> tokens, List<Bunsetsu> chunks)` <a id="particleframe"></a>

- **Kind:** method
- **Purpose:** Notice an object marked on a verb that takes no object.
- **Inputs:** The tokens and the chunks.
- **Returns:** One issue per offending chunk.
- **Side effects:** None.
- **Algorithm:** For each object-marked chunk, look at the predicate it depends on; fire only when
  the catalog tags that verb intransitive and **not** transitive, and it is not in the `path-verbs`
  set. When the verb is half of a transitivity pair, the partner is offered as a suggestion.
- **Usage:** `run`.
- **Notes:** The exemptions carry this check. A great many verbs are tagged both ways and must never
  fire; verbs of motion along a path take the object particle legitimately. Suggesting a replacement
  only when the pair table names one is deliberate — a suggestion the analyser is unsure of is worse
  than none.
