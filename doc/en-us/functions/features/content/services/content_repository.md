# lib/features/content/services/content_repository.dart

`ContentRepository.load` reads the generated vocabulary file, the per-level grammar files and the
kana notes through `rootBundle` (or an injected `AssetBundle` in tests) and parses them into a
`ContentCatalog`. `contentCatalogProvider` is the `FutureProvider` pages watch; it loads once per
run. See [../../../../features/content-catalog.md](../../../../features/content-catalog.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | `library` | B | Read and parse the bundled content files. |
| `ContentRepository._` | private constructor | B | Prevent direct instantiation and expose only static members. |
| `ContentRepository.load` | static method | B | Read and parse every content file into a `ContentCatalog`. |
| `ContentRepository.parseContent` | static method | B | Turn the raw file contents into a catalog. |
| `parseContent` | top-level function | B | Parse content on a background isolate. |

Decoding runs on a background isolate through `compute`, so the roughly 2 MB vocabulary file does
not drop the first frame after launch. The vocabulary asset is read with `cache: false`: it is
parsed exactly once, and leaving it in the bundle's string cache would hold a second copy for the
life of the process. `parseInIsolate` is a `@visibleForTesting` seam — widget tests set it to false
because `compute` never completes under `FakeAsync`, and
`test/content_repository_test.dart` asserts both paths produce the same catalog.

`ContentSources` is a record typedef rather than three arguments, because `compute` takes one
message. `contentCatalogProvider` is a top-level `final FutureProvider<ContentCatalog>` with an
ordinary doc comment; it is not counted.
