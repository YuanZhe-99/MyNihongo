# lib/shared/widgets/history_list.dart

The remembered sentences of one page, with one tap to bring an entry back and one to forget it.

Shared by the sentence lab and writing practice, which want exactly the same list. Where it is *put*
differs — a pane beside the result on a wide window, a sheet behind an app-bar button on a narrow
one — and that is the page's decision, recorded in
[`../../adaptive-layout.md`](../../adaptive-layout.md).

Consumers: `sentence_lab_page.dart`, `writing_practice_page.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `HistoryList` | class | B | One page's history as a list. |
| [`build`](#build) | method | A | Build the list, or the line that says it is empty. |
| `_formatTime` | static method | B | Say when an entry was written, in the reader's zone. |
| [`showHistorySheet`](#showhistorysheet) | top-level function | A | Show a page's history in a bottom sheet. |
| `_SheetHistory` | class | B | The sheet's own copy of the list. |
| `_SheetHistoryState.build` | method | B | Render the copy and remove a deleted row from it. |

## Documentation

### `Widget build(BuildContext context)` <a id="build"></a>

- **Kind:** method
- **Purpose:** Draw the entries, newest first.
- **Inputs:** The build context; the widget's entries and callbacks.
- **Returns:** `Widget`.
- **Side effects:** None.
- **Algorithm:** An empty list returns the "nothing here yet" line. Otherwise a `ListView.builder`
  of dense tiles: the text on one line, ellipsised; the time under it; a delete button on the end.
- **Usage:** Inside a scrolling pane with `shrinkWrap`, or owning the scroll inside the sheet.
- **Notes:** An empty history says so rather than rendering nothing, for the same reason the issue
  list does: an absence is something the reader has to interpret, and a sentence is not. `shrinkWrap`
  carries `NeverScrollableScrollPhysics` with it, because a scrollable inside a scrollable with
  unbounded height is the classic way to get an unusable list.

### `Future<void> showHistorySheet(BuildContext context, {...})` <a id="showhistorysheet"></a>

- **Kind:** top-level function
- **Purpose:** Show the history on a window too narrow for a second pane.
- **Inputs:** `context`, the `entries`, and the open and delete callbacks.
- **Returns:** A future completing when the sheet closes.
- **Side effects:** Opens a modal route.
- **Algorithm:** A modal bottom sheet capped at 60% of the screen height, holding a titled
  `_SheetHistory`. Opening an entry pops the sheet first.
- **Usage:** The app-bar history button on both pages, below the split threshold.
- **Notes:** The narrow half of the layout decision: there is no room for a second pane, and a list
  the learner has to scroll past to reach the field would make the common case worse to serve the
  rare one. Opening an entry closes the sheet because the result it produces is on the page behind
  it. The sheet keeps its **own** copy of the list, because it is a route of its own and the provider
  behind the page rebuilds the page rather than this — removing the row locally is what makes a
  delete look immediate without waiting for the file to be written.
