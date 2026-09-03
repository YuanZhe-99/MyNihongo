# lib/features/ai/widgets/ai_explanation_card.dart

One answer from the on-device model, or the reason there is not one.

Everything generated in this app is shown inside one of these, and every one carries the same label.
That is the whole point of the widget.

Consumers: `sentence_lab_page.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `AiExplanationCard` | class | B | A labelled card holding one generated answer. |
| [`build`](#build) | method | A | Build the card. |
| [`messageFor`](#messagefor) | static method | A | Word one failure for the learner. |

## Documentation

### `Widget build(BuildContext context)` <a id="build"></a>

- **Kind:** method
- **Purpose:** Draw the label, the title, and either a spinner, the answer, or the failure line.
- **Inputs:** The build context.
- **Returns:** `Widget`.
- **Side effects:** None.
- **Algorithm:** A tertiary-container `Card`: the generated label and an optional dismiss button,
  then the title, then one of the three states.
- **Usage:** Every generated answer in the app.
- **Notes:** The label sits **above** the answer rather than below it, because a reader who has
  already read the text cannot un-read it — the warning has to arrive first to do its job. The card
  is drawn in the tertiary container so it is visibly a different kind of thing from the sections
  around it, and the label repeats in words what the colour says, so the distinction survives a
  colour-blind reader and a grayscale screenshot.

### `static String messageFor(AppLocalizations l10n, GenAiFailure? failure)` <a id="messagefor"></a>

- **Kind:** static method
- **Purpose:** Turn a failure, or the absence of one, into a sentence.
- **Inputs:** The localizations and an optional failure.
- **Returns:** `String`.
- **Side effects:** None.
- **Algorithm:** A switch over the six failures plus null.
- **Usage:** `build`, and reusable by any future generated surface.
- **Notes:** A **null** failure with no text means the model ran and answered with nothing usable.
  That reads as the generic line rather than as an error, because saying "something went wrong" would
  send the learner looking for a fault that is not there. `cancelled` shares that line for the
  opposite reason: a request the learner cancelled by leaving the page needs no explanation at all.
