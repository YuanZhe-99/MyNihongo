# lib/features/speech/widgets/pronunciation_practice_sheet.dart

The practice sheet: say the item, see which morae matched. Opened from the microphone button on the
vocabulary and kana detail sheets, and from **Practise** in an example row's overflow menu.

Modal rather than a page, for the same reason the detail sheets are: practising is something done to
an item you are already looking at, and coming back to it should take no navigation. One column at
every window size, capped at `pageMaxContentWidth` — it holds a target line, a button and a row of
mora chips, and none of that is worth splitting into panes.

Consumers: `content_sheets.dart`, `example_actions.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `PracticeTarget` | class | B | What is being practised: what is shown, and the kana it is scored against. |
| [`showPronunciationPracticeSheet`](#showsheet) | top-level function | A | Open the practice sheet for one item. |
| `_PracticeSheet` | class | B | The sheet itself. |
| `_PracticeSheetState.initState` | method | B | Reset the shared recognizer and subscribe to it. |
| `_PracticeSheetState.dispose` | method | B | Cancel any session and unsubscribe. |
| `_onSpeechChanged` | method | B | Rebuild, and score the attempt once it is final. |
| [`_startListening`](#startlistening) | method | A | Start a recording, explaining the microphone first if needed. |
| `_PracticeSheetState.build` | method | B | Build the sheet in whichever state the session is in. |
| `_buildControl` | method | B | Build the record button and the live partial transcript. |
| `_buildResult` | method | B | Build the mora diff, the score, and what was heard. |
| `_moraChip` | method | B | Render one aligned mora. |
| `_legend` | method | B | Render one legend entry. |
| `_colorsFor` | method | B | Pick the background and foreground colour for a mora state. |
| `_failureMessage` | method | B | Turn a recognizer failure into something the learner can act on. |

## Documentation

### `Future<void> showPronunciationPracticeSheet(BuildContext context, PracticeTarget target)` <a id="showsheet"></a>

- **Kind:** top-level function
- **Purpose:** Open pronunciation practice for one kana, word or sentence.
- **Inputs:** `context`, and the target with its display form and its kana reading.
- **Returns:** Completes when the sheet closes.
- **Side effects:** Presents a modal bottom sheet, which opens the microphone once the learner
  starts a recording.
- **Algorithm:** A `showModalBottomSheet` with a drag handle and scroll control.
- **Usage:** The microphone buttons on the detail sheets, and the example overflow menu.
- **Notes:** The target's `reading` is what is scored, so callers pass the catalog's kana rather than
  a kanji surface. The sheet cancels any in-flight session in `dispose`, so a dismissed sheet closes
  the microphone rather than delivering a score to nobody.

### `Future<void> _startListening()` <a id="startlistening"></a>

- **Kind:** method
- **Purpose:** Begin a recording, having explained why the microphone is needed.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** May show a dialog; opens the microphone.
- **Algorithm:** When the permission is not already granted and the rationale has not been shown
  this session, present it and stop unless the learner continues. Then ask the service to listen.
- **Usage:** The record button.
- **Notes:** `PLAN.md` M2.2 requires the microphone to be requested at first use with a reason,
  never at install. The rationale runs **before** the platform prompt, so the system dialog never
  arrives unexplained, and it is skipped entirely once the permission exists — an explanation shown
  every time would be noise.
