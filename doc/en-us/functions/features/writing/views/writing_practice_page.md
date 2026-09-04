# lib/features/writing/views/writing_practice_page.dart

Writing practice: a prompt from a lesson unit, a field, and a check that runs the sentence lab's own
analysis over each sentence. The feature is described in
[`../../../../features/writing-practice.md`](../../../../features/writing-practice.md).

A full-screen route at `/writing`, outside the shell, reached from a unit that has a `writingPrompt`.

Consumers: `router.dart`; opened from `lesson_path_view.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `WritingPrompt` | class | B | What a writing exercise is about, passed as the route's `extra`. |
| `writingWordTarget` | top-level constant | B | How many of the unit's words a piece of writing should use. |
| `WritingPracticePage` | class | B | The page. |
| `_onAiChanged` | method | B | Rebuild when the on-device AI's state changes. |
| [`build`](#build) | method | A | Build the page in one or two panes. |
| `_buildInput` | method | B | The prompt, the field and the button row. |
| `_canExplain`, `_canProofread` | getters | B | Which on-device feature may be offered. |
| `_aiText` | method | B | Word whatever the model produced. |
| [`_deterministic`](#deterministic) | method | A | Show what the app itself can say about the writing. |
| `_catalog` | getter | B | The content catalog, or null while it loads. |
| [`_unitWordsUsed`](#unitwordsused) | method | A | Count the unit's words the learner actually used. |
| [`_check`](#check) | method | A | Run the deterministic pipeline over what was written. |
| `_remember` | method | B | Add what was written to the history. |
| `_openHistory` | method | B | Put a remembered piece of writing back and check it again. |
| `_deleteHistory` | method | B | Forget one remembered piece of writing. |
| [`_ask`](#ask) | method | A | Ask the model to improve what was written. |
| `_askPrompt` | method | B | Ask the Prompt API for a rewrite and notes. |
| [`_askProofreader`](#askproofreader) | method | A | Ask the proofreader to correct each sentence. |

## Documentation

### `Widget build(BuildContext context)` <a id="build"></a>

- **Kind:** method
- **Purpose:** Lay the page out for the window it is in.
- **Inputs:** The build context.
- **Returns:** `Widget`.
- **Side effects:** None until a button is tapped.
- **Algorithm:** Build the feedback list once, then either one `ListView` capped at
  `pageMaxContentWidth`, or a `Row` of an input pane at `labInputPaneWidth` and the feedback in the
  rest, gated on `canSplitLayout` against the whole screen.
- **Usage:** The `/writing` route.
- **Notes:** The same rule the sentence lab follows and for the same reason: the feedback about one
  sentence is a chain and stays one column, while the prompt, the field and the history go in a pane
  of their own when there is room. Below the threshold the history moves behind an app-bar button.
  `_buildInput` is shared by both branches so the two layouts cannot drift apart.

### `List<Widget> _deterministic(BuildContext context, AppLocalizations l10n)` <a id="deterministic"></a>

- **Kind:** method
- **Purpose:** Show the app's own answer, which is the whole exercise without a model.
- **Inputs:** `context`, `l10n`; reads the analyses and the unit.
- **Returns:** The widgets for the deterministic part.
- **Side effects:** None.
- **Algorithm:** The unit-word count when the exercise came from a unit, then one
  `AnalysisResultView` per sentence, numbered when there is more than one.
- **Usage:** `build`.
- **Notes:** Through `AnalysisResultView` rather than a private layout, which is the `v0.3.2` change:
  the page used to draw unlabelled chips and a bare issue list, so a learner who had met the sentence
  lab met a thinner version of an answer they already knew how to read. A single sentence is not
  numbered, because "Sentence 1" with no sentence 2 is noise.

### `Set<String> _unitWordsUsed()` <a id="unitwordsused"></a>

- **Kind:** method
- **Purpose:** Count how many of the unit's words the writing actually used.
- **Inputs:** None; reads the analyses and the unit.
- **Returns:** `Set<String>` of catalog ids.
- **Side effects:** None.
- **Algorithm:** Collect every token `refId` that is in the unit's vocabulary list.
- **Usage:** `_deterministic`.
- **Notes:** Counted from the **parse** rather than by searching the text, so an inflected form
  counts: somebody who wrote 食べました used 食べる. A substring search would miss that and would also
  match a word inside another word.

### `Future<void> _check()` <a id="check"></a>

- **Kind:** method
- **Purpose:** Analyse what is in the field.
- **Inputs:** None; reads the text field.
- **Returns:** None.
- **Side effects:** Builds the analyser if it is not built; writes the history; rebuilds.
- **Algorithm:** Split on the Japanese full stop, analyse each part, keep the analyser's enhancer,
  then remember the text.
- **Usage:** The Check button, and `_openHistory`.
- **Notes:** Split rather than analysed whole because the analyser is built for one sentence at a
  time. Nothing here writes a progress record about how the writing scored — a piece of writing is
  not an item with a recall interval. What is written is the text, to the history, and a failure
  there is swallowed: the feedback on screen is the feature.

### `Future<void> _ask()` <a id="ask"></a>

- **Kind:** method
- **Purpose:** Offer a rewrite, using whichever model the device has.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** Runs a model on the device.
- **Algorithm:** With the Prompt API, `_askPrompt`; otherwise `_askProofreader`.
- **Usage:** The rewrite button, which appears when either feature is ready.
- **Notes:** Two paths because the two on-device features answer different questions and a device may
  have either. Before `v0.3.2` this was gated on the Prompt API alone, so a device with a working
  proofreader was offered nothing at all. The button's label changes with the path, because the two
  promise different amounts.

### `Future<void> _askProofreader()` <a id="askproofreader"></a>

- **Kind:** method
- **Purpose:** Correct each sentence with the proofreading model.
- **Inputs:** None; reads the analyses.
- **Returns:** None.
- **Side effects:** One inference per sentence, in sequence; rebuilds.
- **Algorithm:** Run `_check` first if nothing has been analysed, then `proofreadSentences`. A null
  answer becomes the "nothing different" line.
- **Usage:** `_ask` on a proofreading-only device.
- **Notes:** The sentences have to have been analysed first, because the proofreader is handed the
  **normalized** sentence the analysis refers to; so a learner who has not pressed Check gets the
  deterministic pass run for them rather than an error. The sequencing and the unchanged-writing rule
  live in [`../../ai/services/writing_rewrite.md`](../../ai/services/writing_rewrite.md).
