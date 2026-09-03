# tool/import_vocab.dart

The offline command that regenerates `assets/content/vocab.json` from JMdict and the JLPT lists.
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
| `_readOverlay` | top-level function | B | Parse the Chinese overlay file. |
| `_applyOverlayOnly` | top-level function | B | Re-apply the overlay to an existing catalog. |
| `_write` | top-level function | B | Write the catalog file. |

### `main`

- **Purpose:** Run the import.
- **Inputs:** `args` — `--data`, `--out`, `--overlay`, `--seed`, `--overlay-only`.
- **Returns:** None; sets the exit code.
- **Side effects:** Reads the dictionary, the five lists, the seed and the overlay; rewrites the
  vocabulary asset.
- **Algorithm:** Read the overlay, then either re-apply it alone or do a full import: index the
  dictionary by sequence number, parse each list, fold in the seed, and write. A missing dictionary
  or a list row naming a sequence number the dictionary does not carry exits 1 rather than writing
  a catalog with holes in it.
- **Usage:** `dart run tool/import_vocab.dart`, or `--overlay-only` to re-apply Chinese without the
  download.
- **Notes:** No timestamp is written and the entries are sorted, so a re-run with unchanged inputs
  leaves an empty `git diff` — the property that makes it worth re-running. The header is
  pretty-printed for review and each entry is one compact line, so a 2 MB file still diffs
  readably.
