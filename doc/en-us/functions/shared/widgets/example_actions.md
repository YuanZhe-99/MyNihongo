# lib/shared/widgets/example_actions.dart

The controls beside one example sentence. Today that is the speak button; the widget exists as its
own file because more per-example actions arrive with the rest of Phase 2 — practise the sentence,
open it in the sentence lab — and a row of three icon buttons does not fit a phone-width example.

Consumers: `reference_widgets.dart` (`exampleList`), which the vocabulary and grammar detail sheets
share.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `ExampleActions` | class | B | The controls beside one example sentence. |
| [`ExampleActions.build`](#build) | method | A | Build the per-example controls. |

## Documentation

### `Widget build(BuildContext context)` <a id="build"></a>

- **Kind:** method
- **Purpose:** Render the actions for this example.
- **Inputs:** The build context; the widget's `example`.
- **Returns:** `Widget`.
- **Side effects:** None until tapped.
- **Algorithm:** A `SpeakButton` over the example's kana `reading`, falling back to its surface.
- **Usage:** One per example row in `exampleList`.
- **Notes:** Passing the reading rather than the surface is what stops the engine guessing a kanji's
  reading. Later actions go behind an overflow menu; the speak button stays inline because it is the
  one used constantly.
