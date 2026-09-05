# lib/features/drills/widgets/listening_script_player.dart

Plays a listening script line by line, and hides the transcript until it is no longer the answer.

The transcript is what makes 聴解 practice worth anything — the learner has to be able to see what
they missed — and it is also the thing that would make the question free. So it appears after the
question has been answered, and never before.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`ListeningScriptPlayer`](#player) | class | A | Play one script, under a play limit, with the transcript gated. |
| `_ListeningScriptPlayerState` | class | B | Holds the play count, whether it is playing, and which line is lit. |
| `dispose` | method | B | Stop the engine so a script left playing does not talk over what comes next. |
| [`_play`](#play) | method | A | Read the script aloud, one line at a time. |
| [`build`](#build) | method | A | Build the play control and, once answered, the transcript. |

## Documentation

### `class ListeningScriptPlayer` <a id="player"></a>

- **Kind:** class
- **Purpose:** Play one listening script.
- **Inputs:** The `passage`; `maxPlays` — how many times it may be heard; `revealed` — whether the
  transcript may be shown.
- **Returns:** A widget.
- **Side effects:** None until played.
- **Algorithm:** A play button with the plays remaining beside it, and the transcript below once
  `revealed`.
- **Usage:** `quiz_page.dart`'s `_passageFor`, as the runner's leading widget for a listening
  question.
- **Notes:** `maxPlays` is unlimited in practice and one in a mock, because the real 聴解 plays each
  item once and practising against a different rule teaches a habit the exam punishes. `revealed`
  follows the session's outcome, so the transcript is never on screen while the question is still
  open.

### `Future<void> _play()` <a id="play"></a>

- **Kind:** method
- **Purpose:** Read the script aloud, one line at a time.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** Produces audio; highlights each line as it is spoken.
- **Algorithm:** Refuse when already playing, when there is no Japanese voice, or when the play limit
  is reached; then walk the lines, lighting each and awaiting its speech before the next begins.
- **Usage:** The play button.
- **Notes:** Internal helper used within this file only. Each line is awaited before the next begins,
  which is what makes the highlight mean anything. `stop()` runs before each line because
  `TtsService.speak` treats a repeat of the text it is already speaking as a request to stop — a
  script with two identical lines would otherwise go silent on the second. The reading is spoken
  where the content has one: an engine handed 一日 has to guess between ついたち and いちにち, and a
  listening question whose audio guessed wrong is unanswerable.

### `Widget build(BuildContext context)` <a id="build"></a>

- **Kind:** method
- **Purpose:** Build the play control and, once answered, the transcript.
- **Inputs:** `context`.
- **Returns:** The widget tree for the current state.
- **Side effects:** Creates UI widgets from the current state.
- **Algorithm:** The button, the plays-left label when there is a limit, the no-voice reason when
  there is no voice, and — only when `revealed` — the transcript with the line currently being spoken
  highlighted.
- **Usage:** Flutter, on every rebuild.
- **Notes:** Keep this method cheap because Flutter may call it often. Without a Japanese voice the
  control is **disabled rather than hidden**, with the reason beside it: a listening question with no
  visible way to listen looks like a bug, and this is the same rule `SpeakButton` follows.
