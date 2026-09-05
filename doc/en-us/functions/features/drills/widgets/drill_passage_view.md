# lib/features/drills/widgets/drill_passage_view.dart

The text a reading question is about: one line per `DialogueLine`, with furigana where the content
supplies a reading, and the translation behind a toggle.

The translation is a toggle rather than a column because 読解 is the skill of reading Japanese — a
translation beside the text turns the exercise into reading English.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`DrillPassageView`](#view) | class | A | Show one passage, with its translation behind a toggle. |
| `level` | field | B | The level a paraphrase should stay within. |
| `_DrillPassageViewState` | class | B | Holds whether the translation is revealed, and what came back for each line. |
| `build` | method | B | Build the passage, its speakers and its translation toggle. |
| `_paraphraseOf` | method | B | Render whatever came back for one line. |
| `_paraphrase` | method | B | Ask for one line in easier Japanese. |

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

With on-device AI switched on, and only where the translation toggle is offered, each line carries a
button asking for that sentence again in easier Japanese. It is gated on `allowTranslation` for the
same reason the translation is: in a timed block an easier version of the sentence the question turns
on is very nearly the answer.

The paraphrase sits **under its own line** rather than in a card at the bottom, because the whole
point of it is seeing the two versions of one sentence together — and it carries the generated label,
because this is model-written Japanese sitting directly under content the app wrote and the two must
not be indistinguishable. A reply the parser cannot read leaves the line with the original only:
nothing half-parsed is put in front of a learner as Japanese to imitate.
