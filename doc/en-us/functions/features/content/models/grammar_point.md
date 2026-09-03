# lib/features/content/models/grammar_point.dart

`GrammarPoint` is one grammar point from the bundled content: id, JLPT level, pattern, optional
structure, language-keyed meaning and explanation, and examples. `fromJson` returns null when the
id, level or pattern is missing. Search matches the pattern, structure and meaning but deliberately
not the explanation. See
[../../../../features/content-catalog.md](../../../../features/content-catalog.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `GrammarPoint.new` | constructor | B | Create a grammar point instance. |
| `GrammarPoint.fromJson` | static method | B | Parse from content JSON; null when the id, level, or pattern is missing. |
| `GrammarPoint.matches` | method | B | Test whether a lowercased query is a substring of the pattern, the structure, or any meaning in any language. |

`matchForms` arrived with `PLAN.md` M1.2, from the JSON key `match`: literal strings that mark this
point in a sentence, used by the cross-linking in `content_links.dart`. A single-character particle
needs an explicit list, because a form derived from its pattern would match nearly every sentence.
