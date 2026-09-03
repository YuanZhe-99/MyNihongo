# lib/features/speech/widgets/speak_button.dart

One button that reads one piece of Japanese aloud, used everywhere the app speaks. It watches
`TtsService.speaking`, so the button whose text is playing shows a stop icon and every other one
stays idle.

Consumers: `content_sheets.dart` (vocabulary headword, kana row), `example_actions.dart` (every
example sentence).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `SpeakButton` | class | B | A button that speaks one piece of Japanese. |
| [`SpeakButton.build`](#build) | method | A | Build the speak/stop button for this text. |

## Documentation

### `Widget build(BuildContext context)` <a id="build"></a>

- **Kind:** method
- **Purpose:** Render the button in whichever of its three states applies.
- **Inputs:** The build context; the widget's `text`, optional `tooltip` and `iconSize`.
- **Returns:** An `IconButton` inside a `ValueListenableBuilder` on `TtsService.speaking`.
- **Side effects:** None until tapped.
- **Algorithm:** Enabled when the engine reported a Japanese voice. The icon is a stop symbol while
  `speaking` equals this button's trimmed text, and a speaker otherwise.
- **Usage:** The detail sheets and the example rows.
- **Notes:** Disabled rather than hidden when there is no Japanese voice: that is a device state the
  user can fix, and a button that vanished would look like a feature that does not exist. The
  tooltip says which state it is in.
