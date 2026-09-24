# tool/import_vocab.dart

The offline command that regenerates `assets/content/vocab.json` from JMdict and the JLPT lists,
layering on the Chinese gloss overlay (`vocab_zh.json`), the example overlay
(`vocab_examples.json`) and the Japanese definition overlay (`vocab_ja.json`).
All file I/O lives here; the rules live in [`src/vocab_import_core.md`](src/vocab_import_core.md)
so they can be unit-tested without the 117 MB dictionary. See
[`../../features/content-catalog.md`](../../features/content-catalog.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | `library` | B | Regenerate the vocabulary asset from JMdict and the JLPT lists. |
| `main` | top-level function | A | Run the import. |
| `_parseArgs` | top-level function | B | Read the command line. |
| `_findJmdict` | top-level function | B | Find the unpacked JMdict JSON by name prefix. |
| `_readOverlay` | top-level function | B | Parse an overlay file keyed by catalog id — the Chinese overlay and the Japanese definition overlay alike. |
| `_reportOrphans` | top-level function | B | Report on stderr each overlay row naming an id the catalog no longer has; reported, never dropped silently. |
| `_applyOverlayOnly` | top-level function | B | Re-apply the overlays (Chinese glosses, Japanese definitions through `applyJapaneseOverlay`, examples) to an existing catalog. |
| `_write` | top-level function | B | Write the catalog file. |

### `main`

- **Purpose:** Run the import.
- **Inputs:** `args` — `--data`, `--out`, `--overlay`, `--overlay-ja`, `--examples`, `--seed`,
  `--overlay-only`. `--overlay-ja` defaults to `assets/content/vocab_ja.json`.
- **Returns:** None; sets the exit code.
- **Side effects:** Reads the dictionary, the five lists, the seed and the three overlays (Chinese
  glosses, Japanese definitions, examples); rewrites the vocabulary asset.
- **Algorithm:** Read the overlays, then either re-apply them alone or do a full import: index the
  dictionary by sequence number, parse each list, fold in the seed, apply the examples and then the
  Japanese definitions (`applyJapaneseOverlay`, reporting orphaned rows with `_reportOrphans`), and
  write. A missing dictionary or a list row naming a sequence number the dictionary does not carry
  exits 1 rather than writing a catalog with holes in it. A missing overlay file is treated as an
  empty overlay.
- **Usage:** `dart run tool/import_vocab.dart`, or `--overlay-only` to re-apply the overlays without
  the download.
- **Notes:** No timestamp is written and the entries are sorted, so a re-run with unchanged inputs
  leaves an empty `git diff` — the property that makes it worth re-running. The header is
  pretty-printed for review and each entry is one compact line, so a 2 MB file still diffs
  readably. The Japanese overlay is applied by **both** modes: a full import rebuilds every entry
  from JMdict, so applying it only in `--overlay-only` would let the next JMdict refresh delete every
  Japanese definition while `vocab_ja.json` still held them.
