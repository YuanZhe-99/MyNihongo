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
