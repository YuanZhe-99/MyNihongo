# lib/features/sentence/widgets/analysis_result_view.dart

One analysed sentence drawn as the four sections the sentence lab defines: the words, the structure,
the grammar used, and the possible issues, each under its heading, with the unknown-token banner
above them when it applies.

This exists because the lab and writing practice were rendering the same analysis two different ways
— the lab with headings and all four sections, writing practice with unlabelled chips and a bare
issue list. A learner who had met one met a second, thinner version of an answer they already knew
how to read. There is now one widget, and the two pages cannot drift apart.

Consumers: `sentence_lab_page.dart`, `writing_practice_page.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `AnalysisResultView` | class | B | The four sections of one analysed sentence. |
| [`build`](#build) | method | A | Build the banner and the four sections. |
| `_heading` | method | B | Render one section heading. |
| `_unknownBanner` | method | B | Warn that some words are not in the dictionary. |

## Documentation

### `Widget build(BuildContext context)` <a id="build"></a>

- **Kind:** method
- **Purpose:** Draw one analysis in full.
- **Inputs:** The build context; the widget's analysis, catalog and optional issue hooks.
- **Returns:** `Widget`.
- **Side effects:** None.
- **Algorithm:** The unknown-token banner when `hasUnknown`, then `TokenChips`, `BunsetsuTree`,
  `GrammarUsedList` and `IssueList`, each under a heading. `onExplain` and `issueCardBuilder` pass
  straight through to `IssueList`.
- **Usage:** Once on the lab page; once per sentence on the writing page.
- **Notes:** Always a `Column` — the sections are a chain, the structure refers to the words, the
  grammar to the structure, the issues to both, and putting a reference beside its referent would
  make the reading order ambiguous. That holds whatever the page around it does with its width, which
  is why the widget measures nothing and the page owns the split. The banner comes first when it
  applies: everything below it is derived from the tokens, so a reader who knows the split is partly
  wrong reads the rest with the right amount of trust.
