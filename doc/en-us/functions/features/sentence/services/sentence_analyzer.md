# lib/features/sentence/services/sentence_analyzer.dart

Runs the whole sentence pipeline — tokenize, chunk, match grammar, check — and holds the three
providers that supply it.

Every stage is deterministic, offline and separately tested. This file only wires them together, and
is where an optional on-device model would attach without any stage depending on one.

Consumers: `sentence_lab_page.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `SentenceAnalyzer` | class | B | The pipeline facade. |
| `SentenceAnalyzer.enhancer` | field | B | An optional on-device model; null in every build today. |
| [`analyze`](#analyze) | method | A | Analyse one sentence. |
| `functionWordsProvider` | provider | B | The function-word table, loaded once per app run. |
| [`lexiconProvider`](#lexiconprovider) | provider | A | The surface-to-entry index, built once from the catalog and the table. |
| `promptTemplatesProvider` | provider | B | The prompt templates the optional on-device model is driven by. |
| `sentenceAnalyzerProvider` | provider | B | The analyser itself, ready to use, with an enhancer where one could run. |

## Documentation

### `SentenceAnalysis analyze(String text)` <a id="analyze"></a>

- **Kind:** method
- **Purpose:** Turn a sentence into words, structure, grammar points and possible issues.
- **Inputs:** `text` as the learner typed it.
- **Returns:** `SentenceAnalysis`.
- **Side effects:** None.
- **Algorithm:** Normalize, tokenize, chunk, match, check.
- **Usage:** The sentence lab page.
- **Notes:** Synchronous, and fast enough to run on every keystroke once the lexicon exists — a
  sentence is tens of characters and the lattice is linear in that with a bounded number of edges
  per position. The expensive part is building the lexicon, which happens once per app run.

### `final lexiconProvider` <a id="lexiconprovider"></a>

- **Kind:** provider
- **Purpose:** Build the index once and share it.
- **Inputs:** Watches `contentCatalogProvider` and `functionWordsProvider`.
- **Returns:** `FutureProvider<Lexicon>`.
- **Side effects:** None beyond the two loads it awaits.
- **Algorithm:** Await both, then `Lexicon.build`.
- **Usage:** `sentenceAnalyzerProvider`, and pronunciation scoring by way of the practice sheet.
- **Notes:** Depending on both means it rebuilds if either is reloaded and can never hold a stale
  half. The function-word table is a separate provider from the catalog because it is a few
  kilobytes and only the lab needs it — loading it with the 2 MB catalog would make every page pay
  for a page that may never be opened.
