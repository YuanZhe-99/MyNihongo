# lib/features/content/models/parts_of_speech.dart

The closed set of part-of-speech tags a catalog entry may carry. JMdict's own tag vocabulary is
much larger and much finer; `tool/import_vocab.dart` maps it onto these names, and
`content_catalog_test.dart` asserts every shipped entry uses only them. The file imports nothing so
the tool can share it rather than keeping a second copy that drifts.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | `library` | B | Name the closed set of part-of-speech tags the content files use. |
| `vocabPartsOfSpeech` | top-level `const Set<String>` | — | Every part-of-speech tag a `vocab.json` entry may carry. |
