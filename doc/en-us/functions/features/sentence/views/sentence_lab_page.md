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
| `_buildResult` | method | B | Build the four result sections, plus the AI actions. |
| `_AiResult` | class | B | One pending or finished answer from the on-device model. |
| `_onAiChanged` | method | B | Rebuild when the on-device AI state changes. |
| `dispose` | method | B | Stop following the AI service and cancel anything running. |
| `_clearGenerated` | method | B | Forget every generated answer. |
| [`_generate`](#generate) | method | A | Run one generation and file its outcome. |
| `_canExplain` | getter | B | Whether the on-device model can be offered right now. |
| [`_buildAiActions`](#aiactions) | method | A | Build the whole-sentence AI actions and their cards. |
| `_explainIssue` | method | B | Explain one flagged issue. |
| `_cardFor` | method | B | Build the card for one result, when there is one. |

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

### `Future<void> _generate(Future<String?> Function() request, void Function(_AiResult) store)` <a id="generate"></a>

- **Kind:** method
- **Purpose:** Run one generation and put its outcome where the UI reads it.
- **Inputs:** The `request` to run, and `store` which files the result.
- **Returns:** None.
- **Side effects:** Runs a model on the device; rebuilds twice.
- **Algorithm:** Store a loading result, await the request, store the text or the failure.
- **Usage:** All three AI actions.
- **Notes:** Internal helper used within this file only. One place for the loading-then-outcome dance,
  so a new action cannot forget to clear its own spinner. A null answer is stored with neither text
  nor failure, which the card words as "nothing could be generated" — the honest description of a
  model that ran and said nothing useful, and a different thing from an error.

### `List<Widget> _buildAiActions(...)` <a id="aiactions"></a>

- **Kind:** method
- **Purpose:** Build the whole-sentence AI actions and the cards under them.
- **Inputs:** The context, localizations, theme and the analysis.
- **Returns:** `List<Widget>` — empty when the feature is off.
- **Side effects:** None until a button is used.
- **Algorithm:** Nothing while the switch is off; one hint line when it is on but no model is
  downloaded; otherwise the buttons, disabled while busy, then any cards.
- **Usage:** `_buildResult`, at the very end.
- **Notes:** Internal helper used within this file only. These sit **below** every deterministic
  section on purpose: the analysis is the page, and the model comments on it. The three states are
  each a deliberate choice — nothing at all while the switch is off, so a learner who never opted in
  never meets the feature; one line pointing at Settings when a model could be fetched, because a
  button that always fails teaches distrust rather than the fix; and nothing again on a device that
  cannot run a model at all, because there is nothing there to fix and saying so would be a false
  promise.
