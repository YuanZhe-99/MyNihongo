# lib/features/content/models/content_catalog.dart

`ContentCatalog` holds everything the bundled content files describe — the vocabulary list and the
grammar list in file order — with linear lookups by id. `fromJson` takes the two decoded files and
skips malformed entries rather than failing. See
[../../../../features/content-catalog.md](../../../../features/content-catalog.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `ContentCatalog.new` | constructor | B | Create a content catalog instance. |
| `ContentCatalog.fromJson` | factory constructor | B | Parse the two content files (`entries` and `points` arrays), skipping malformed entries. |
| `ContentCatalog.vocabById` | method | B | Look a vocabulary entry up by id (linear; index it when JMdict lands). |
| `ContentCatalog.grammarById` | method | B | Look a grammar point up by id. |
