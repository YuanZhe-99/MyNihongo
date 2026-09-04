# lib/features/learn/widgets/today_card.dart

The first card on the Learn tab: the study streak, what is due, and what is new. The one thing a
returning learner should be able to read without scrolling.

It states counts only. The buttons that act on them arrive with the quiz modes in M3.2.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `TodayCard` | class | B | Show what there is to do today. |
| [`build`](#build) | method | A | Build the card from the review queue. |
| `_lines` | method | B | Say what is due and what is new, or that there is nothing. |

## Documentation

### `Widget build(BuildContext context, WidgetRef ref)` <a id="build"></a>

- **Kind:** method
- **Purpose:** Build the card from the review queue.
- **Inputs:** `context`, `ref`.
- **Returns:** The widget tree for the current state.
- **Side effects:** Creates UI widgets from the current state.
- **Algorithm:** Watch `reviewQueueProvider` and `learnerProfileProvider`. Draw a header row with the
  streak, then either a progress bar (queue still null) or the due and new lines.
- **Usage:** `learn_page.dart`, above the dashboard cards.
- **Notes:** A null queue shows a progress bar rather than "nothing due": those are different claims
  and only one of them is true before the data has loaded. The streak sits in an `Expanded` rather
  than after a `Spacer`, because "No streak yet — one answer starts it" is several times wider than
  "3-day streak" and has to wrap rather than overflow on a narrow phone — an overflow the smoke test
  caught in English while the Chinese layout tests passed.
