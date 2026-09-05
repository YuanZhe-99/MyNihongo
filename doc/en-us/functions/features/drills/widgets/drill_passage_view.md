# lib/features/drills/widgets/drill_passage_view.dart

The text a reading question is about: one line per `DialogueLine`, with furigana where the content
supplies a reading, and the translation behind a toggle.

The translation is a toggle rather than a column because 読解 is the skill of reading Japanese — a
translation beside the text turns the exercise into reading English.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`DrillPassageView`](#view) | class | A | Show one passage, with its translation behind a toggle. |
| `_DrillPassageViewState` | class | B | Holds whether the translation is currently revealed. |
| `build` | method | B | Build the passage, its speakers and its translation toggle. |

## Documentation

### `class DrillPassageView` <a id="view"></a>

- **Kind:** class
- **Purpose:** Show one passage.
- **Inputs:** The `passage`; `allowTranslation` — whether the toggle is offered at all.
- **Returns:** A widget.
- **Side effects:** None; the toggle is local state.
- **Algorithm:** A card holding one block per line — the speaker where the content named one, the
  Japanese as `FuriganaText`, and the line's own translation when revealed — followed by the whole
  passage's translation when revealed, and the toggle button when it is allowed.
- **Usage:** `quiz_page.dart`'s `_passageFor`, as the runner's leading widget for a reading question.
- **Notes:** `allowTranslation` is false in a timed block. A mock is meant to measure what the learner
  can read unaided, and a translation is the one aid that answers most questions outright. A line
  with a speaker is laid out as a dialogue turn; a line without one is a paragraph — that is the
  difference between a 会話 and a 説明文, and the content files say which by whether they wrote a
  `speaker`. Both the per-line and the whole-passage translations are optional, and both stay hidden
  until the question has been answered.
