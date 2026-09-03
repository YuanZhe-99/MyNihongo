# lib/features/sentence/views/sentence_lab_page.dart

The sentence lab: type a sentence, see what it is made of. A full-screen route at `/lab`, outside
the navigation shell.

The feature is described in
[../../../../features/sentence-lab.md](../../../../features/sentence-lab.md); this page documents
the declarations.

Consumers: `router.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `SentenceLabPage` | class | B | The lab page, optionally opened with a sentence to analyse. |
| `_SentenceLabPageState.initState` | method | B | Schedule the first analysis when the page was opened with a sentence. |
| `_analyze` | method | B | Analyse what is in the text field. |
| [`build`](#build) | method | A | Build the page. |
| `_buildResult` | method | B | Build the four result sections. |

## Documentation

### `Widget build(BuildContext context)` <a id="build"></a>

- **Kind:** method
- **Purpose:** Lay the page out.
- **Inputs:** The build context; watches `contentCatalogProvider`.
- **Returns:** `Widget`.
- **Side effects:** None.
- **Algorithm:** A `ListView` inside a `ConstrainedBox` at `pageMaxContentWidth`: the input, the
  analyse button, then either the empty-state line or the four result sections, then the limits
  note.
- **Usage:** The `/lab` route.
- **Notes:** **One column at every window size**, which is a deliberate exception to the app's usual
  "split when it fits" rule and is recorded as such in `adaptive-layout.md`. The sections are a
  chain — the structure refers to the words, the grammar to the structure, the issues to both — and
  putting a reference beside its referent would make the reading order ambiguous. The limits note at
  the bottom is part of the page rather than a tooltip for the same reason the practice sheet's is:
  a tool that guesses has to say so where the guess is read.
