# lib/features/ai/widgets/generated_examples.dart

The **More examples** action in a word's detail sheet, and whatever the model wrote for it.

Shown only where the Prompt API can actually run, and only when the learner taps the button. Nothing
is generated on opening a sheet, and nothing generated is stored: the examples live for as long as
the sheet does. Each one carries the same generated label every generated thing in this app carries,
above the text rather than below it, so it is read before the Japanese is.

Consumer: `content_sheets.dart`, inside `showVocabDetailSheet`.

Two things were wrong until `v0.4.3`, and together they were reported as "the AI examples do not
work". The widget read `canExplain` through a plain `Provider`, which never rebuilds on
`notifyListeners`, **and** it lives inside a `showModalBottomSheet` builder that runs once — so a
sheet opened while AICore was still being probed showed no action at all for as long as it stayed
open. It now listens to the service, as the sentence lab has since it was written. And `_ask`
returned in silence when the prompt could not be built, so the button looked broken rather than
unavailable; it now says so.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `GeneratedExamples` | class | B | The More examples action and its results. |
| `GeneratedExamples.new` | constructor | B | Build the action for one word. |
| `entry` | field | B | The word the examples are for. |
| `initState` | method | B | Follow the service, so the action appears when the device is ready. |
| `dispose` | method | B | Stop following the service. |
| `_onServiceChanged` | method | B | Rebuild when the device's answer changes. |
| `build` | method | B | Build the button and whatever came back. |
| [`_ask`](#ask) | method | A | Ask the model for example sentences. |

## Documentation

### `Future<void> _ask()` <a id="ask"></a>

- **Kind:** method
- **Purpose:** Ask the model for example sentences using this word.
- **Inputs:** None; reads the widget's `entry` and the current locale.
- **Returns:** `Future<void>`.
- **Side effects:** Runs a model on the device; sets the widget's state.
- **Algorithm:** Await the prompt builder, build the prompt, run it through `AiPracticeService` with
  the asset's token budget, parse the reply into whole examples, and show them — or show a failure.
- **Usage:** The button, once per tap.
- **Notes:** A reply that does not parse into whole lines is dropped rather than partly shown: a
  generated sentence sits beside the catalog's own and would otherwise look exactly as authoritative
  as one somebody wrote. Every path now ends in either examples or a message; the two silent returns
  this method used to have were indistinguishable from a dead button.
