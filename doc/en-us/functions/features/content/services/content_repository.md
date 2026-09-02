# lib/features/content/services/content_repository.dart

`ContentRepository.load` reads `assets/content/vocab_seed.json` and `assets/content/grammar_seed.json`
through `rootBundle` (or an injected `AssetBundle` in tests) and parses them into a
`ContentCatalog`. `contentCatalogProvider` is the `FutureProvider` pages watch; it loads once per
run. Parsing runs on the calling isolate — fine for the seed, to be moved to `compute` when the
JMdict-sized catalog arrives. See
[../../../../features/content-catalog.md](../../../../features/content-catalog.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `ContentRepository._` | private constructor | B | Prevent direct instantiation and expose only static members. |
| `ContentRepository.load` | static method | B | Read and parse both content files into a `ContentCatalog`. |

`contentCatalogProvider` is a top-level `final FutureProvider<ContentCatalog>` with an ordinary doc
comment; it is not counted.
