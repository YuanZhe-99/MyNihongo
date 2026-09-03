# lib/features/content/models/content_catalog.dart

`ContentCatalog` holds everything the bundled content files describe — the vocabulary list, the
grammar points from every level file, and the kana notes — with constant-time lookups by id. The
catalog grew from 24 words to roughly 7,700 in `PLAN.md` M1.2, so the lookups are maps built once
at construction rather than the linear scans the seed could afford. Aliases point at the same entry
object as the primary id, so a caller cannot tell which id it arrived by. See
[../../../../features/content-catalog.md](../../../../features/content-catalog.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | `library` | B | Hold everything the bundled content files describe, parsed once. |
| `ContentCatalog.new` | constructor | B | Create a content catalog instance and build its id lookups. |
| `ContentCatalog.fromJson` | factory constructor | B | Parse the content files, skipping malformed entries. |
| `ContentCatalog.vocabById` | method | B | Look a vocabulary entry up by id or alias, in constant time. |
| `ContentCatalog.grammarById` | method | B | Look a grammar point up by id. |
| `ContentCatalog.canonicalId` | method | B | Resolve any id to the one the catalog ships it under. |
| `ContentCatalog.allVocabIds` | getter | B | List every vocabulary id the catalog answers to, aliases included. |

`fromJson` takes the grammar files as an iterable, because grammar ships one file per level so a
level can be written and reviewed on its own. `canonicalId` is for grouping and display only:
progress records keep whichever id they were written with, and are never rewritten.
