# tool/convert_zh_tw.dart

Regenerates the Traditional Chinese text in the bundled content.

Run it after editing any Simplified Chinese text. **Every `zh_TW` string in the content is generated
from the `zh` beside it and never hand-edited** — `test/content_zh_tw_test.dart` compares the two and
fails when they have drifted, so a forgotten run is a red test rather than a silent divergence.

The tool is idempotent: a second run leaves an empty `git diff`, which is what makes "did anyone
forget to run it" an answerable question. The hand-written exception is `lib/l10n/app_zh_TW.arb` and
`assets/content/prompts/`, which this tool does not touch — UI strings and prompts are translated by
a person, because a converted UI reads like a machine wrote it and a converted prompt would be
instructions nobody checked.

Usage: `dart run tool/convert_zh_tw.dart`, with `--opencc <dir>` and `--assets <dir>` for tests.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | Regenerate the Traditional Chinese text in the bundled content. |
| [`main`](#main) | function | A | Walk the content directories and rewrite what changed. |
| `_rewriteCatalog` | function | B | Rewrite the vocabulary catalog in its own committed shape. |
| `_rewritePretty` | function | B | Rewrite a hand-authored content file with the standard two-space encoder. |
| `_writeIfChanged` | function | B | Write a file only when its content differs. |

## Documentation

### `Future<void> main(List<String> args)` <a id="main"></a>

- **Kind:** function
- **Purpose:** Walk the content directories and rewrite what changed.
- **Inputs:** `args` — `--opencc <dir>` and `--assets <dir>`, both for tests.
- **Returns:** None; sets the exit code.
- **Side effects:** Rewrites files under `assets/content/`.
- **Algorithm:** Load the OpenCC dictionaries, then walk a **hard-coded, non-recursive list** of
  content directories, sending the vocabulary catalog through `_rewriteCatalog` and everything else
  through `_rewritePretty`. Report how many files changed.
- **Usage:** By hand after a content edit, and by `test/content_zh_tw_test.dart` indirectly, which
  checks the result rather than running the tool.
- **Notes:** The directory list is hard-coded and flat, not a recursive walk. That is why the drill
  files are named `drills/n5-reading.json` rather than `drills/n5/reading.json` — a flat layout cost
  one entry here and one in `content_zh_tw_test.dart`, and a nested one would have cost five of each.
  A new content directory must be added to both lists or its Traditional text is quietly never
  generated.

  The catalog keeps its one-entry-per-line encoding through `encodeCatalog`, the same function the
  importer writes it with, so running this tool never reformats 7,744 entries into a different shape.
  Everything else uses the two-space encoder every JSON file in the series is written with, so the
  first run reformats a file once and every run after that is a no-op.

  `_writeIfChanged` skips an identical write to keep the file's timestamp, so a build system watching
  the assets is not woken by a tool that changed nothing.
